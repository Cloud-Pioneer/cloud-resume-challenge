output "cloudfront_url" {
  description = "Your live website URL"
  value       = "https://${aws_cloudfront_distribution.portfolio.domain_name}"
}

output "api_gateway_url" {
  description = "The visitor counter API endpoint — paste this into script.js"
  value       = "${aws_apigatewayv2_api.visitor_api.api_endpoint}/visitor"
}

output "s3_bucket_name" {
  description = "The S3 bucket where your website files are stored"
  value       = aws_s3_bucket.portfolio.bucket
}