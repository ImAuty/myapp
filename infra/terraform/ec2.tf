resource "aws_instance" "app" {
  ami                         = "ami-003776ce0fee47dfe"
  instance_type               = "t4g.small"
  subnet_id                   = aws_subnet.public_1a.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  monitoring                  = false
  ebs_optimized               = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    iops                  = 3000
    encrypted             = false
    delete_on_termination = true
  }

  tags = {
    Name = "myapp-ec2"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
