# EC2 + LAMBDA SECURITY GROUP (shared)
resource "aws_security_group" "ec2_sg" {
  name        = "hellotags-ec2-sg"
  description = "Outbound only - used by EC2 and Lambda (SSM + internal access)"
  vpc_id      = aws_vpc.main.id

  # No inbound rules → secure by default

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "hellotags-ec2-sg"
    Project = "hellotags"
  }
}

# RDS SECURITY GROUP
resource "aws_security_group" "rds_sg" {
  name        = "hellotags-rds-sg"
  description = "Allow PostgreSQL only from EC2/Lambda SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  # Optional but fine (default allow all egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "hellotags-rds-sg"
    Project = "hellotags"
  }
}
