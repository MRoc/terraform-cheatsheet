provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "webserver" {
  ami           = "ami-0e872aee57663ae2d"
  instance_type = "t2.micro"
  tags = {
    Name        = "webserver"
    Description = "An webserver on Ubuntu"
  }
  user_data              = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install nginx -y
              systemctl enable nginx
              systemctl start nginx
              EOF
  key_name               = aws_key_pair.web.id
  vpc_security_group_ids = [aws_security_group.ssh-access.id]
}

resource "aws_key_pair" "web" {
  public_key = file("./web.pub")
}

resource "aws_security_group" "ssh-access" {
  name        = "ssh-access"
  description = "Allows SSH access from internet"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "eip" {
  domain   = "vpc"
  instance = aws_instance.webserver.id
}

output "publicip" {
  value = aws_eip.eip.public_ip
}