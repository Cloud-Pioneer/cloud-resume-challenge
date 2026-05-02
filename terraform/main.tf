# ── PROVIDER ─────────────────────────────────────────────────────────────────
# Tells Terraform we're using AWS and which region to build in

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── S3 BUCKET ─────────────────────────────────────────────────────────────────
# This is where your HTML, CSS and JS files will live in the cloud

resource "aws_s3_bucket" "portfolio" {
  bucket = "${var.project_name}-site-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Block all direct public access — CloudFront will be the only way in
resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket                  = aws_s3_bucket.portfolio.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── CLOUDFRONT ORIGIN ACCESS ──────────────────────────────────────────────────
# Gives CloudFront permission to read files from your private S3 bucket

resource "aws_cloudfront_origin_access_control" "portfolio" {
  name                              = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 bucket policy — only CloudFront can read from this bucket
resource "aws_s3_bucket_policy" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontAccess"
      Effect    = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.portfolio.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.portfolio.arn
        }
      }
    }]
  })
}

# ── CLOUDFRONT DISTRIBUTION ───────────────────────────────────────────────────
# The CDN that serves your website globally at speed

resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # Europe + North America (cheapest)

  origin {
    domain_name              = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id                = "s3-portfolio"
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-portfolio"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# ── DYNAMODB TABLE ────────────────────────────────────────────────────────────
# The database that stores and increments your visitor count

resource "aws_dynamodb_table" "visitors" {
  name         = "${var.project_name}-visitors"
  billing_mode = "PAY_PER_REQUEST" # You only pay when it's actually used
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# ── IAM ROLE FOR LAMBDA ───────────────────────────────────────────────────────
# Gives the Lambda function permission to read/write DynamoDB and write logs

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:UpdateItem", "dynamodb:GetItem"]
        Resource = aws_dynamodb_table.visitors.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ── LAMBDA FUNCTION ───────────────────────────────────────────────────────────
# Packages your Python code and deploys it as a serverless function

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/counter.py"
  output_path = "${path.module}/lambda/counter.zip"
}

resource "aws_lambda_function" "visitor_counter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-visitor-counter"
  role             = aws_iam_role.lambda_role.arn
  handler          = "counter.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitors.name
    }
  }
}

# ── API GATEWAY ───────────────────────────────────────────────────────────────
# Creates an HTTP endpoint the website can call to trigger the Lambda function

resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.visitor_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.visitor_counter.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "visitor" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "POST /visitor"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.visitor_api.id
  name        = "$default"
  auto_deploy = true
}

# Permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}