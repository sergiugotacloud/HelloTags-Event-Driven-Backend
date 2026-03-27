resource "aws_instance" "api" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_a.id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}
