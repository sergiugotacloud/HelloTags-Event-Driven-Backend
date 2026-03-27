# HelloTags — Event-Driven Cloud Backend Architecture (AWS)

### API Gateway · Lambda · DynamoDB · EventBridge · EC2 · RDS PostgreSQL · Secrets Manager · Terraform · Python

[![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python)](https://www.python.org/)
[![Lambda](https://img.shields.io/badge/Lambda-Serverless-FF9900?logo=amazon-aws)](https://aws.amazon.com/lambda/)
[![DynamoDB](https://img.shields.io/badge/DynamoDB-NoSQL-4053D6?logo=amazon-aws)](https://aws.amazon.com/dynamodb/)
[![PostgreSQL](https://img.shields.io/badge/RDS-PostgreSQL-336791?logo=postgresql)](https://aws.amazon.com/rds/)
[![EventBridge](https://img.shields.io/badge/EventBridge-Event--Driven-FF4F8B?logo=amazon-aws)](https://aws.amazon.com/eventbridge/)

---

## Overview

HelloTags is a cloud backend for NFC-powered digital business cards. When a user taps an NFC card, an HTTP POST hits the API. Within milliseconds, the tap is stored in DynamoDB, an event is fired to EventBridge, a notification handler processes it asynchronously, and the analytics handler writes structured data to a PostgreSQL RDS instance via a VPC-internal Flask API running on EC2.

The system demonstrates a production-style event-driven architecture: serverless ingestion at the edge, decoupled async processing via EventBridge, durable analytics storage in RDS, and zero public exposure of compute or database resources. All infrastructure is provisioned by Terraform and destroyed completely with a single command.

**Region:** eu-central-1 · **IaC:** Terraform with remote state on S3 + DynamoDB locking · **Access:** SSM Session Manager — no SSH, no bastion host

---

## The Problem

NFC digital business cards solve the physical card problem — but most implementations stop at the card itself. The profile page is static. There is no tap tracking, no analytics, no insight into who engaged and when.

HelloTags transforms NFC cards into **observable, data-driven systems**:

- Every interaction becomes a structured event
- Events are processed asynchronously (decoupled architecture)
- Data is stored for analytics and future integrations
- The system is extensible (add new consumers without changing ingestion)

---

## Architecture

![Architecture Diagram](architecture/hellotags-architecture.png)

---

## Screenshots (End-to-End Proof)

### Infrastructure Provisioning
![Backend](architecture/01-terraform-backend-created.png)  
![Init](architecture/02-terraform-init-success.png)  
![VPC](architecture/03-vpc-subnets-created.png)  
![Apply](architecture/03-vpc-terraform-apply-success.png)

### Security + Networking
![Security Groups](architecture/04-security-groups-created.png)

### Compute + Access
![SSM](architecture/06-ec2-ssm-connected.png)  
![Flask Running](architecture/21-ec2-flask-running.png)

### Database
![RDS Connection](architecture/07-ec2-connected-to-rds.png)  
![RDS Data](architecture/22 - rds-analytics-data.png)

### Secrets Management
![Secrets](architecture/20-Secrets-Manager.png)

### DynamoDB
![Table](architecture/08-dynamodb-tap-events-table.png)  
![After API](architecture/12-dynamodb-after-api.png)

### Lambda
![Lambdas](architecture/09-lambda-created.png)  
![Tap Handler](architecture/16-lambda-tap-handler.png)  
![Notification](architecture/17-lambda-notofication-handler.png)  
![Analytics Code](architecture/15-lambda-analytics-code.png)  
![Analytics Env](architecture/19-lambda-analytics-env.png)

### API Gateway
![API](architecture/10-api-gateway-created.png)  
![Call](architecture/11-api-call-success.png)

### Event System
![Rule](architecture/13-eventbridge-rule.png)  
![Targets](architecture/18-eventbridge-target.png)

### Logs (Async Flow Proof)
![Logs](architecture/14-notification-lambda-logs.png)

### Teardown
![Destroy](architecture/24-terraform-destroy.png)

---

## Processing Flow

1. NFC tap → API Gateway `/tap`
2. API Gateway → Lambda (tap-handler)
3. Lambda:
   - writes to DynamoDB
   - sends event to EventBridge
4. EventBridge → fan-out:
   - notification-handler
   - analytics-handler
5. analytics-handler → EC2 Flask API → RDS

---

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

Test:

```bash
curl -X POST https://<api-id>.execute-api.eu-central-1.amazonaws.com/prod/tap \
  -H "Content-Type: application/json" \
  -d '{"card_id": "card_123"}'
```

---

## Security Design

- No public EC2 or RDS
- No SSH (SSM only)
- Secrets Manager for credentials
- Least privilege IAM
- Private subnets + strict SG rules
- Encrypted storage

---

## Troubleshooting

### 1. Lambda not triggered from EventBridge

Problem:
EventBridge rule exists but Lambda not invoked

Cause:
Missing `aws_lambda_permission`

Fix:
```hcl
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rule.arn
}
```

---

### 2. Lambda cannot reach EC2 (timeout)

Problem:
analytics-handler times out

Cause:
Wrong VPC / subnet / SG

Fix:
- Ensure Lambda is in same VPC
- Use **private IP (10.x.x.x)**
- Check SG allows outbound

---

### 3. RDS connection fails

Problem:
EC2 cannot connect to PostgreSQL

Cause:
Security group misconfiguration

Fix:
- RDS SG must allow **5432 from EC2 SG**
- Not from 0.0.0.0/0

---

### 4. API works but no data in DynamoDB

Problem:
200 response but table empty

Cause:
Wrong environment variable or IAM role

Fix:
- Verify `TABLE_NAME`
- Ensure role has `dynamodb:PutItem`

---

## Production Improvements

- Separate IAM roles per Lambda
- Add DLQ for EventBridge
- Secrets caching
- RDS connection pooling
- Move EC2 → ECS Fargate
- Add API authentication
- Add CI/CD pipeline

---

## Things I learned while building this

1. EventBridge decoupling is critical for scalability  
2. VPC networking is the hardest part, not Lambda  
3. Private communication requires correct routing + SG  
4. Secrets Manager is better than env vars  
5. Debugging distributed systems = logs everywhere  

---

## Author

**Sergiu Gota**  
AWS Certified Solutions Architect – Associate · AWS Cloud Practitioner  

https://github.com/sergiugotacloud
