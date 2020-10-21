# TerraformLambdaCanary
Super simple Lambda that does a Canary check and publishes a message via SNS on failure. Deployed using Terraform

This terraform template creates:
- A Python Lambda function
- An IAM role and policy for cloudwatch log access
- An IAM role and policy for SNS publish access

## Requirements
- Terraform
- Python3

## Setting up
1. Get your terraform environment setup by doing
```
terraform init
```

2. Setup the Python virtual env
```
virtualenv -p python3 venv
source venv/bin/activate
pip install -r requirements.txt
```

3. View the terraform plan
```
terraform plan
```

4. Deploy
```
terraform apply
```
