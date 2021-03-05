resource "aws_security_group" "lb_sg" {
  vpc_id = var.securecluster.vpc_id
}

resource "aws_lb" "lb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.securecluster_lists.subnets

  enable_deletion_protection = false

  //   access_logs {
  //     bucket  = aws_s3_bucket.lb_logs.bucket
  //     prefix  = "test-lb"
  //     enabled = true
  //   }

  tags = {
    Environment = "test-tf"
  }
}
