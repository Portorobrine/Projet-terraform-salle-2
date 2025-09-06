resource "aws_lb" "ecoshop_alb" {
  name               = "ecoshop-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_web_id]
  subnets            = var.web_public_subnet_ids

  tags = {
    Name = "ecoshop-alb"
  }
}

resource "aws_lb_target_group" "ecoshop_tg" {
  name     = "ecoshop-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/index.php"
    protocol = "HTTP"
    matcher  = "200"
    interval = 30
    timeout  = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "ecoshop_tg_attachment" {
  count            = length(var.app_instance_ids)
  target_group_arn = aws_lb_target_group.ecoshop_tg.arn
  target_id        = var.app_instance_ids[count.index]
  port             = 80
}

resource "aws_lb_listener" "ecoshop_listener" {
  load_balancer_arn = aws_lb.ecoshop_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecoshop_tg.arn
  }
}