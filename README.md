This is my implementation of the Cloud Resume Challenge — a hands-on project that demonstrates real cloud engineering skills by building and deploying a live portfolio website using AWS, Terraform, Python, and GitHub Actions.

# Live Demo
https://d3u4h2nbq6vb36.cloudfront.net/

# Project Overview

This project is not just a personal website — it is a complete cloud architecture implementation designed to simulate how modern applications are built and deployed in production environments.

It demonstrates:
- Serverless backend architecture
- Infrastructure as Code (IaC)
- CI/CD automation
- Cloud-native security practices
- Real-time data handling using AWS services
- 
# Tech Stack
 # Frontend
- HTML5, CSS3, JavaScript
- Hosted on Amazon S3
- Delivered via AWS CloudFront (CDN)

# Backend
- AWS Lambda (Python)
- Amazon API Gateway
- Amazon DynamoDB

 # DevOps / Infrastructure
- Terraform (Infrastructure as Code)
- GitHub Actions (CI/CD Pipeline)

# Key Features
  # 1. Serverless Visitor Counter
- Tracks real-time visits using DynamoDB
- Backend logic handled via AWS Lambda
- Exposed securely through API Gateway

  # 2. Fully Serverless Architecture
- No EC2 instances
- Scalable and cost-efficient design

  # 3. CI/CD Pipeline
- Automatic deployment on code push
- Implemented using GitHub Actions

  # 4. Infrastructure as Code
- Entire AWS infrastructure defined using Terraform
- Enables reproducibility and version control

  # 5. Global Content Delivery
- AWS CloudFront ensures low latency worldwide

# Security Considerations
- IAM roles with least privilege access
- API Gateway controls access to backend services
- No hardcoded credentials
- Secure communication between services

# Business Value
This project demonstrates the ability to:
- Design scalable cloud solutions for real-world use cases
- Automate infrastructure deployment
- Reduce operational costs using serverless technologies
- Implement production-grade DevOps workflows

# What I Learned
 -How to architect a fully serverless application on AWS from scratch
 -Writing Terraform that provisions real, interdependent AWS resources
 -How CloudFront Origin Access Control secures S3 without public bucket policies
 -Building a CI/CD pipeline with GitHub Actions that deploys to AWS in seconds
 -Debugging IAM permission errors, CORS issues, and Terraform state conflicts
 -The difference between infrastructure that works in a tutorial and infrastructure that works in production
