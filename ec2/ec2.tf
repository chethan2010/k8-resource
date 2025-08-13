resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh-agent-key"
  public_key = file("C:/Users/hp/Desktop/ec2pem/ec2-Raj.pem") # Make sure this is the PUBLIC key
}
resource "aws_instance" "db" {
  ami                    = "ami-09c813fb71547fc4f"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = aws_key_pair.ssh_key.key_name

  tags = {
    Name = "work-station"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "allowing SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "allow_ssh"
    CreatedBy  = "Hemanth"
  }
}



