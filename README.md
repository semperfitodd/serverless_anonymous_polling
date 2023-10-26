# Serverless Anonymous Polling

This project provides a serverless solution to conduct anonymous polls. It leverages AWS services such as API Gateway, Lambda, DynamoDB, S3, CloudFront, and SES to deliver a seamless experience. Respondents receive a custom URL via email and can participate in the poll anonymously. The results can be viewed via an admin page.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Setup and Deployment](#setup-and-deployment)
- [Project Structure](#project-structure)

## Architecture Overview
![architecture.png](images%2Farchitecture.png)
1. **API Gateway**: Handles incoming requests and routes them to the appropriate Lambda functions.
2. **Lambda Functions**: There are three distinct functions:
   - Backend processing
   - Gathering poll results
   - Sending emails to potential respondents
3. **DynamoDB**: Stores poll responses and ensures anonymity by hashing user IDs. It also keeps track of email addresses of respondents.
4. **S3 and CloudFront**: Serve the React frontend and admin pages.
5. **SES**: Sends out emails to potential respondents with custom URLs.

## Setup and Deployment

### Prerequisites

1. **AWS Account**: Ensure you have an AWS account set up and access to create resources.
2. **Terraform**: This project uses Terraform for infrastructure as code. Ensure Terraform is installed and you're familiar with its basic commands.

### Deployment Steps:

1. **AWS Credentials**: Setup your AWS credentials, typically by using the `aws configure` command or setting environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

2. **Initialize Terraform**:
    ```bash
    cd terraform
    terraform init
    ```
3. **Apply Terraform Configurations**:
Review the Terraform plan to understand the resources that will be created:
    ```bash
    terraform plan -out=plan.out
    ```
4. **Apply the configurations**:
    ```bash
    terraform apply plan.out
    ```
5. **Post Deployment**:
Once the infrastructure is set up, you can access the React frontend via the provided CloudFront URL. Ensure that your email sending limits on AWS SES are lifted if you're deploying this in a production environment.
Note: Always remember to destroy the resources after testing to avoid unnecessary costs:
    ```bash
    terraform destroy
    ```
## Project Structure
```bash
├── images
│   │   └── architecture.png - Architecture diagram
├── terraform
│   ├── api_gw.tf - API Gateway configuration
│   ├── backend
│   │   └── backend.py - Backend Lambda function logic
│   ├── backend.tf - Backend configurations
│   ├── cloudfront.tf - CloudFront distribution settings
│   ├── data.tf - Data sources and other configurations
│   ├── dynamo.tf - DynamoDB tables setup
│   ├── get_results
│   │   └── get_results.py - Lambda function to get poll results
│   ├── lambda_*.tf - Various Lambda function configurations
│   ├── r53.tf - Route53 DNS settings
│   ├── s3.tf - S3 bucket configurations
│   ├── secrets.tf - AWS secrets management
│   ├── send_emails
│   │   ├── requirements.txt - Python dependencies for the email function
│   │   └── send_emails.py - Lambda function to send out emails
│   ├── ses.tf - AWS Simple Email Service configurations
│   ├── static_site
│   │   └── site - React frontend for the polling application
│   ├── variables.tf - Terraform variables and defaults
│   └── versions.tf - Terraform and provider version constraints

```
