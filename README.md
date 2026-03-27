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

HelloTags is a production-style backend system for NFC-powered digital business cards.

Traditional NFC cards stop at redirecting users to a static profile. They provide zero visibility into engagement, no analytics, and no feedback loop for the card owner.

HelloTags solves this by introducing a fully event-driven backend that transforms each tap into structured, queryable data.

Each interaction is:

- captured in real time
- processed asynchronously
- stored in both raw and analytical formats
- available for future extensions (CRM, dashboards, notifications)

---

## The Problem

NFC cards without backend intelligence are blind systems.

You cannot answer:
- Who tapped my card?
- When did they tap it?
- How often is my card used?
- Are my campaigns working?

HelloTags introduces observability and intelligence into NFC interactions by:

- tracking every tap event
- decoupling ingestion from processing
- enabling analytics-ready storage
- designing for extensibility from day one

---

## Architecture

![Architecture](architecture/00-HelloTags-Diagram.png)

---

## Processing Flow

1. NFC tap triggers HTTP POST → API Gateway `/tap`
2. API Gateway invokes **tap-handler Lambda**
3. tap-handler:
   - writes event to DynamoDB (durable ingestion)
   - emits event to EventBridge
4. EventBridge rule fans out:
   - notification-handler (async processing)
   - analytics-handler (analytics pipeline)
5. analytics-handler sends HTTP request → EC2 Flask API (private)
6. Flask API writes structured data → RDS PostgreSQL

---

## Project Structure

```
hellotags-cloud-backend/
│
├── architecture/
│   ├── 00-HelloTags-Diagram.png
│   ├── 01-terraform-backend-created.png
│   ├── 02-terraform-init-success.png
│   ├── 03-vpc-subnets-created.png
│   ├── 03-vpc-terraform-apply-success.png
│   ├── 04-security-groups-created.png
│   ├── 06-ec2-ssm-connected.png
│   ├── 07-ec2-connected-to-rds.png
│   ├── 08-dynamodb-tap-events-table.png
│   ├── 09-lambda-created.png
│   ├── 10-api-gateway-created.png
│   ├── 11-api-call-success.png
│   ├── 12-dynamodb-after-api.png
│   ├── 13-eventbridge-rule.png
│   ├── 14-notification-lambda-logs.png
│   ├── 15-lambda-analytics-code.png
│   ├── 16-lambda-tap-handler.png
│   ├── 17-lambda-notofication-handler.png
│   ├── 18-eventbridge-target.png
│   ├── 19-lambda-analytics-env.png
│   ├── 20-Secrets-Manager.png
│   ├── 21-ec2-flask-running.png
│   ├── 22 - rds-analytics-data.png
│   └── 24-terraform-destroy.png
│
├── lambda/
├── terraform/
└── README.md
```

---

## Deployment Proof (Screenshots)

### Terraform Setup

![Backend](architecture/01-terraform-backend-created.png)  
![Init](architecture/02-terraform-init-success.png)

### Networking

![Subnets](architecture/03-vpc-subnets-created.png)  
![Apply](architecture/03-vpc-terraform-apply-success.png)

### Security

![Security Groups](architecture/04-security-groups-created.png)

### Compute + Access

![SSM](architecture/06-ec2-ssm-connected.png)  
![Flask Running](architecture/21-ec2-flask-running.png)

### Database Connectivity

![RDS Connection](architecture/07-ec2-connected-to-rds.png)  
![RDS Data](architecture/22 - rds-analytics-data.png)

### Secrets Management

![Secrets](architecture/20-Secrets-Manager.png)

### DynamoDB

![Table](architecture/08-dynamodb-tap-events-table.png)  
![After API](architecture/12-dynamodb-after-api.png)

### Lambda Layer

![Lambdas](architecture/09-lambda-created.png)  
![Tap Handler](architecture/16-lambda-tap-handler.png)  
![Notification Handler](architecture/17-lambda-notofication-handler.png)  
![Analytics Code](architecture/15-lambda-analytics-code.png)  
![Analytics Env](architecture/19-lambda-analytics-env.png)

### API Gateway

![API](architecture/10-api-gateway-created.png)  
![Call](architecture/11-api-call-success.png)

### Event System

![Rule](architecture/13-eventbridge-rule.png)  
![Targets](architecture/18-eventbridge-target.png)

### Async Proof (Logs)

![Logs](architecture/14-notification-lambda-logs.png)

### Infrastructure Teardown

![Destroy](architecture/24-terraform-destroy.png)

---

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

### Test API

```bash
curl -X POST https://<api-id>.execute-api.eu-central-1.amazonaws.com/prod/tap \
  -H "Content-Type: application/json" \
  -d '{"card_id": "card_123"}'
```

Expected:

```json
{"message": "tap recorded"}
```

---

## Security Design

- No public EC2 or RDS
- No SSH (SSM only)
- Secrets stored in AWS Secrets Manager
- Least privilege IAM roles
- Security groups restrict DB access to EC2 only
- Encrypted storage (RDS + Secrets)

---

## Engineering Decisions

EventBridge over direct invocation  
→ enables decoupling and horizontal extensibility

DynamoDB + RDS split  
→ optimized for ingestion vs analytics workloads

EC2 Flask layer  
→ persistent service boundary (connection reuse, schema ownership)

SSM instead of SSH  
→ zero inbound exposure

Secrets Manager  
→ secure credential lifecycle management

Single NAT Gateway  
→ intentional cost-performance tradeoff

---

## Things I learned while building this

1. EventBridge requires explicit Lambda permissions per target
2. Event payload is nested under `detail`
3. NAT Gateway provisioning is slow (~2 minutes)
4. Secrets Manager adds cold start latency
5. Proper VPC design is critical (routes, subnets, isolation)
6. Internal service communication (Lambda → EC2) must use private IPs
7. Debugging event-driven systems requires CloudWatch logs at every step

---

## Author

Sergiu Gota  
AWS Certified Solutions Architect – Associate · AWS Cloud Practitioner  

https://github.com/sergiugotacloud
