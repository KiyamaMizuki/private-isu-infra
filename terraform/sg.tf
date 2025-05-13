data "aws_security_group" "vpc_origin_sg" {
  depends_on = [aws_cloudfront_vpc_origin.alb]
  filter {
    name   = "group-name"
    values = ["CloudFront-VPCOrigins-Service-SG"]
  }
}

resource "aws_security_group" "alb" {
  name   = "Private-isu-alb"
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# 循環参照を避けるためにdepends_onを使用
resource "aws_vpc_security_group_ingress_rule" "alb" {
  depends_on = [data.aws_security_group.vpc_origin_sg]

  security_group_id            = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.vpc_origin_sg.id
}

resource "aws_security_group" "web" {
  name   = "Private-isu"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "benchmark" {
  name   = "Private-isu-benchmark"
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#memcached用サブネット
resource "aws_security_group" "isucon_memcached_sg" {
  name   = "isucon_memcached_sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 11211
    to_port         = 11211
    protocol        = "http"
    security_groups = [aws_security_group.web.id]
  }
}