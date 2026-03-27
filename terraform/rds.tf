# RANDOM PASSWORD
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# SECRETS MANAGER
resource "aws_secretsmanager_secret" "db_secret" {
  name = "hellotags-db-credentials"

  tags = {
    Project = "hellotags"
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = "postgres"
    password = random_password.db_password.result
  })
}

# DB SUBNET GROUP
resource "aws_db_subnet_group" "main" {
  name = "hellotags-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name    = "hellotags-db-subnet-group"
    Project = "hellotags"
  }
}

# RDS INSTANCE
resource "aws_db_instance" "postgres" {
  identifier = "hellotags-db"

  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"

  allocated_storage = 20

  username = "postgres"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
  storage_encrypted   = true

  depends_on = [aws_secretsmanager_secret_version.db_secret_version]

  tags = {
    Name    = "hellotags-postgres"
    Project = "hellotags"
  }
}
