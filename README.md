# HelloTags - Event-Driven Cloud Backend (AWS)

### API Gateway · Lambda · DynamoDB · EventBridge · EC2 · RDS PostgreSQL · Secrets Manager · Terraform · Python

[![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python)](https://www.python.org/)
[![Lambda](https://img.shields.io/badge/Lambda-Serverless-FF9900?logo=amazon-aws)](https://aws.amazon.com/lambda/)
[![DynamoDB](https://img.shields.io/badge/DynamoDB-NoSQL-4053D6?logo=amazon-aws)](https://aws.amazon.com/dynamodb/)
[![PostgreSQL](https://img.shields.io/badge/RDS-PostgreSQL-336791?logo=postgresql)](https://aws.amazon.com/rds/)
[![EventBridge](https://img.shields.io/badge/EventBridge-Event--Driven-FF4F8B?logo=amazon-aws)](https://aws.amazon.com/eventbridge/)

---

## What this is

HelloTags is an NFC digital business card startup I co-founded. The idea is simple: tap a card, get a digital profile. But every implementation I looked at had the same problem. The card works, the profile page loads, and that's it. No tap tracking, no analytics, no way to know if anyone actually engaged with it.

This is the backend I built to fix that. Tap a card, it hits an API, gets stored in DynamoDB, fires an event to EventBridge, and fans out to a notification handler and an analytics handler that writes to PostgreSQL on RDS. The whole thing runs in private subnets with no public exposure on any compute or database resource.

Region: eu-central-1. IaC: Terraform with remote state on S3 and DynamoDB locking. EC2 access via SSM, no SSH, no bastion.

---

## Architecture

![Architecture Diagram](architecture/hellotags-architecture.png)

```
NFC Card Tap (HTTP POST)
        |
        v
API Gateway (hellotags-public-api)
    POST /tap
        |
        v
Lambda: tap-handler  -- Python 3.12, VPC-attached, private subnet
        |
        |---> DynamoDB (tap-events)  -- card_id + timestamp key
        |
        +---> EventBridge (default bus)  -- source: hellotags.tap
                    |
            EventBridge Rule (tap-events-rule)
                    |
          +---------+---------+
          v                   v
Lambda: notification-handler  Lambda: analytics-handler
(VPC, private subnet)        (VPC, private subnet)
                                    |
                                    v  HTTP internal
                              EC2: Flask API  -- private subnet, SSM only
                                    |
                                    v
                              RDS PostgreSQL  -- private subnet
                              (tap_analytics table)

VPC 10.0.0.0/16
  Public Subnet 10.0.1.0/24   -- IGW, NAT Gateway, Elastic IP
  Private Subnet A 10.0.2.0/24 -- Lambda, EC2
  Private Subnet B 10.0.3.0/24 -- RDS (spans both AZs)

Security
  EC2 SG  -- no inbound, egress only, SSM access
  RDS SG  -- port 5432 from EC2 SG only

State
  S3 (hellotags-terraform-state)  -- encrypted remote state
  DynamoDB (hellotags-terraform-locks)  -- state locking
```

---

## Services

| Service | What it does here |
|---|---|
| API Gateway (HTTP) | Public POST /tap endpoint |
| Lambda: tap-handler | Writes to DynamoDB, fires EventBridge event |
| Lambda: notification-handler | Picks up EventBridge events, handles notifications |
| Lambda: analytics-handler | Picks up EventBridge events, POSTs to internal Flask API |
| DynamoDB | Raw tap storage, on-demand, composite key |
| EventBridge | Routes tap events to both Lambda consumers |
| EC2 + Flask | Internal analytics API, private subnet, SSM only |
| RDS PostgreSQL | Structured analytics storage, encrypted, private |
| Secrets Manager | RDS credentials fetched at runtime, never hardcoded |
| SSM Session Manager | EC2 access without SSH or public IP |
| VPC | Full network isolation, private subnets, NAT, IGW |
| CloudWatch | Lambda logs across all three functions |
| IAM | Per-function execution roles, least privilege |
| Terraform | Full stack provisioned and destroyed as code |

---

## How a tap flows through the system

1. Card is tapped, triggers HTTP POST to API Gateway with a card_id payload
2. tap-handler Lambda picks it up, generates a timestamp, writes to DynamoDB, fires a TapEvent to EventBridge
3. HTTP 200 goes back to the client. DynamoDB write happens before the response returns
4. EventBridge matches on `source: hellotags.tap` and fans out to both targets at the same time
5. notification-handler processes the event for downstream notifications
6. analytics-handler POSTs the tap data to the Flask API on EC2 over the private subnet
7. Flask writes the record to RDS PostgreSQL
8. RDS credentials come from Secrets Manager at runtime, not from env vars or source code

---

## Project structure

```
hellotags-cloud-backend/
|
+-- architecture/
|   +-- hellotags-architecture.png
|
+-- lambda/
|   +-- tap_handler.py
|   +-- notification_handler.py
|   +-- analytics_handler.py
|
+-- terraform/
|   +-- main.tf
|   +-- api_gateway.tf
|   +-- lambda.tf
|   +-- dynamodb.tf
|   +-- eventbridge.tf
|   +-- ec2.tf
|   +-- rds.tf
|   +-- security_groups.tf
|   +-- iam.tf
|   +-- backend.tf
|   +-- outputs.tf
|
+-- README.md
```

---

## Deployment

### Requirements

- AWS CLI configured
- Terraform >= 1.0
- S3 bucket and DynamoDB table for remote state must exist before `terraform init`

### Spin it up

```bash
terraform init
terraform plan
terraform apply
```

### Test a tap

```bash
curl -X POST https://<your-api-id>.execute-api.eu-central-1.amazonaws.com/prod/tap \
  -H "Content-Type: application/json" \
  -d '{"card_id": "card-abc-123"}'
```

Expected:
```json
{"message": "tap recorded"}
```

Within a few seconds: record in DynamoDB, both Lambda targets fired, analytics row written to RDS PostgreSQL.

### EC2 access

```bash
aws ssm start-session --target <instance-id> --region eu-central-1
```

No SSH. No key pair. No public IP. SSM only.

### Tear it down

```bash
terraform destroy
```

---

## Screenshots

### Infrastructure
![Backend](architecture/01-terraform-backend-created.png)
![Init](architecture/02-terraform-init-success.png)
![VPC](architecture/03-vpc-subnets-created.png)
![Apply](architecture/03-vpc-terraform-apply-success.png)

### Security
![Security Groups](architecture/04-security-groups-created.png)

### Compute and access
![SSM](architecture/06-ec2-ssm-connected.png)
![Flask](architecture/21-ec2-flask-running.png)

### Database
![RDS Connection](architecture/07-ec2-connected-to-rds.png)
![RDS Data](architecture/22-rds-analytics-data.png)

### Secrets
![Secrets](architecture/20-Secrets-Manager.png)

### DynamoDB
![Table](architecture/08-dynamodb-tap-events-table.png)
![After tap](architecture/12-dynamodb-after-api.png)

### Lambda
![All functions](architecture/09-lambda-created.png)
![Tap handler](architecture/16-lambda-tap-handler.png)
![Notification](architecture/17-lambda-notofication-handler.png)
![Analytics code](architecture/15-lambda-analytics-code.png)
![Analytics env](architecture/19-lambda-analytics-env.png)

### API Gateway
![API](architecture/10-api-gateway-created.png)
![Call](architecture/11-api-call-success.png)

### EventBridge
![Rule](architecture/13-eventbridge-rule.png)
![Targets](architecture/18-eventbridge-target.png)

### Logs
![Logs](architecture/14-notification-lambda-logs.png)

### Teardown
![Destroy](architecture/24-terraform-destroy.png)

---

## Security decisions

No public compute. Every Lambda, EC2, and RDS runs in private subnets. Nothing has a public IP.

No SSH. The EC2 security group has zero inbound rules. Access goes through SSM Session Manager, authenticated via IAM, logged to CloudWatch.

No hardcoded credentials. RDS password is generated by Terraform, stored in Secrets Manager, fetched at runtime. It never touches an environment variable or source file.

RDS only accepts connections on port 5432 from the EC2 security group. Nothing else can reach it.

Remote state is stored in S3 with server-side encryption. DynamoDB lock table prevents concurrent applies from corrupting state.

---

## Why I built it this way

**EventBridge fan-out instead of chaining Lambdas directly**

tap-handler fires one event and forgets. EventBridge routes it to notification-handler and analytics-handler at the same time, and tap-handler has no idea either of them exists. If I need a third consumer later, I add an EventBridge target. I don't touch tap-handler. That's the right pattern for anything that needs to scale without turning into spaghetti.

**DynamoDB for raw taps, RDS for analytics**

DynamoDB made sense for tap ingestion: write-heavy, simple key-value access, no joins, millisecond latency. RDS made sense for analytics: structured schema, queryable by time range, aggregatable with SQL. Using one for both would mean compromising somewhere. Matching the store to the access pattern is the whole point.

**EC2 + Flask instead of another Lambda for database writes**

The Flask API is a persistent service that owns the connection pool and schema logic. Lambda handles stateless event processing, EC2 handles stateful service logic. In production this would probably be ECS Fargate behind an ALB, but EC2 is the minimal version that demonstrates the same pattern.

**SSM over SSH**

SSH means open port 22, a key pair to manage, and either a public IP or a bastion host. SSM means none of those things. The security group has no inbound rules at all. Access is IAM-authenticated and logged. This is how private EC2 should be managed.

**Secrets Manager over environment variables**

Environment variables show up in the Lambda console and get included in function config exports. Secrets Manager stores them encrypted, access is controlled by IAM, and rotation works without redeploying anything. One extra SDK call at cold start is a fine tradeoff.

**Single NAT Gateway**

One NAT Gateway per AZ gives you AZ-level fault tolerance for private subnet egress. It also costs roughly 30 euros a month per gateway. For a dev project this is not worth it. Documented here on purpose, not overlooked.

---

## Things that broke

### Lambda not triggering from EventBridge

EventBridge rule was configured, targets were set, Lambda was doing nothing. No errors anywhere, just silence.

Turned out Lambda needs explicit permission to be invoked by EventBridge. Missing `aws_lambda_permission` resource in Terraform. EventBridge was trying to invoke it and getting silently denied.

```hcl
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rule.arn
}
```

This is a common one in EventBridge setups. The rule existing does not mean Lambda will accept the invocation.

---

### analytics-handler timing out trying to reach EC2

Lambda was invoking, hitting the timeout, failing. EC2 was running. Flask was running. Nothing obviously wrong.

The Lambda was either in the wrong VPC, pointing at the wrong subnet, or using the public IP instead of the private one. Fixed by verifying the Lambda VPC config matched the EC2 VPC, switching to the private IP (10.x.x.x), and confirming the security group allowed outbound traffic. All three need to line up.

---

### EC2 could not connect to RDS

Tried to connect from EC2 and got nothing. RDS was up, credentials were correct.

The RDS security group was not allowing port 5432 from the EC2 security group. Classic mistake: people open 0.0.0.0/0 to fix it fast, which works but defeats the point. Fixed it properly by allowing 5432 from the EC2 SG ID specifically.

---

### API returning 200 but DynamoDB table empty

Curl was returning 200. Table was empty. Lambda was not throwing errors.

Wrong TABLE_NAME environment variable, or the IAM role was missing `dynamodb:PutItem`. Both are easy to overlook and produce no visible error in the response. Checked the env var first, then the IAM policy. One of them was wrong.

---

## What I took away from this

VPC networking was harder than any of the Lambda or EventBridge work. Getting the routing right across private subnets, NAT, security groups, and VPC-attached Lambdas took more debugging than everything else combined. Once that was solid, the rest connected quickly.

EventBridge decoupling is genuinely useful, not just a pattern for pattern's sake. Being able to add a consumer without touching the producer is the kind of thing that sounds theoretical until you actually do it and realize how clean it keeps things.

Distributed systems are harder to debug because the failure can be silent at every layer. Lambda succeeds, EventBridge delivers, analytics-handler times out, nothing in the tap-handler logs shows anything wrong. Logs everywhere from the start, not as an afterthought.

---

## What I would add in production

- Dedicated IAM role per Lambda. Right now they share one role. tap-handler only needs `dynamodb:PutItem` and `events:PutEvents`. It should not have anything else.
- Dead-letter queue on EventBridge targets. Failed invocations currently disappear. A DLQ captures them for inspection and replay.
- Secrets Manager caching in Lambda. Right now it fetches on every cold start. Module-level caching with a TTL reduces the SDK calls.
- RDS connection pooling. psycopg2 reconnects on every invocation. A simple connection pool fixes that.
- ECS Fargate with ALB instead of EC2 for the Flask API. Managed, scalable, no instance to babysit.
- NAT Gateway per AZ if this were handling real traffic.
- API Gateway authorizer on POST /tap. Right now anyone can write to it.
- Input validation in tap-handler. Malformed card_id payloads should get a 400, not a DynamoDB write attempt.
- GitHub Actions for Lambda deploy on push to main.

---

## Author

**Sergiu Gota**
AWS Certified Solutions Architect – Associate · AWS Cloud Practitioner

[![GitHub](https://img.shields.io/badge/GitHub-sergiugotacloud-181717?logo=github)](https://github.com/sergiugotacloud)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-sergiu--gota--cloud-0A66C2?logo=linkedin)](https://linkedin.com/in/sergiu-gota-cloud)
