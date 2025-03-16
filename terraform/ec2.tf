resource "aws_security_group" "public" {
    name = "Private-isu"
    vpc_id = aws_vpc.vpc.id
    ingress {
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["${var.your_ip}"]
    }
    ingress {
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["${var.your_ip}"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
}

resource "aws_instance" "web" {
    ami           = "ami-0bed62bba4100a4b7" #Private-isu-AMI
    instance_type = "c7g.large"
    iam_instance_profile = aws_iam_instance_profile.example_profile.name
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.public.id]
    subnet_id = aws_subnet.public_1a.id
    user_data = <<-EOF
        snap install amazon-ssm-agent --classic
        snap start amazon-ssm-agent

    EOF
    tags = {
        Name = "Private-isu"
    }
}

