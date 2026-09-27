resource "aws_instance" "management" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devops.id]

  tags = {
    Name = "devops-management"
  }
}

resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devops.id]

  tags = {
    Name = "devops-jenkins"
  }
}

resource "aws_instance" "control_plane" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devops.id]

  tags = {
    Name = "k8s-control-plane"
  }
}

resource "aws_instance" "worker1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devops.id]

  tags = {
    Name = "k8s-worker-1"
  }
}

resource "aws_instance" "worker2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devops.id]

  tags = {
    Name = "k8s-worker-2"
  }
}