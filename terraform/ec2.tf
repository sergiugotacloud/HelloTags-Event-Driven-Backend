resource "aws_iam_role" "ec2_ssm_role" {
  name = "hellotags-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = "hellotags"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "hellotags-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_instance" "admin" {
  ami           = "ami-0e872aee57663ae2d" # Amazon Linux 2 (eu-central-1)
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  # Ensure instance waits for networking to be ready
  depends_on = [aws_nat_gateway.nat]

  tags = {
    Name    = "hellotags-admin-ec2"
    Project = "hellotags"
  }
}
