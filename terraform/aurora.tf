resource "aws_rds_cluster" "default" {
  availability_zones                    = ["ap-northeast-1a", "ap-northeast-1c"]
  cluster_identifier                    = "private-isu-db"
  cluster_members                       = ["private-isu-aurora-instance"]
  database_insights_mode                = "advanced"
  database_name                         = "isuconp"
  db_cluster_parameter_group_name       = "default.aurora-mysql8.0"
  db_subnet_group_name                  = aws_db_subnet_group.aurora.name
  delete_automated_backups              = false
  deletion_protection                   = false
  enabled_cloudwatch_logs_exports       = ["slowquery"]
  engine                                = "aurora-mysql"
  engine_lifecycle_support              = "open-source-rds-extended-support-disabled"
  engine_mode                           = "provisioned"
  engine_version                        = "8.0.mysql_aurora.3.05.2"
  master_password                       = var.db_password # sensitive
  master_username                       = "isuconp"
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring_role.arn
  network_type                          = "IPV4"
  performance_insights_enabled          = true
  performance_insights_retention_period = 465
  port                                  = 3306
  storage_type                          = "aurora-iopt1"
  final_snapshot_identifier             = "test"
  skip_final_snapshot                   = true
  vpc_security_group_ids                = [aws_security_group.aurora.id]
}


resource "aws_rds_cluster_instance" "default" {
  availability_zone                     = "ap-northeast-1a"
  ca_cert_identifier                    = "rds-ca-rsa2048-g1"
  cluster_identifier                    = "private-isu-db"
  db_parameter_group_name               = "default.aurora-mysql8.0"
  db_subnet_group_name                  = aws_db_subnet_group.aurora.name
  engine                                = "aurora-mysql"
  engine_version                        = "8.0.mysql_aurora.3.05.2"
  identifier                            = "private-isu-aurora-instance"
  instance_class                        = "db.r5.large"
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring_role.arn
  performance_insights_enabled          = true
  performance_insights_retention_period = 465
  tags = {
    devops-guru-default = "private-isu-aurora"
  }
  tags_all = {
    devops-guru-default = "private-isu-aurora"
  }
  depends_on = [aws_rds_cluster.default]
}


resource "aws_db_subnet_group" "aurora" {
  name       = "private-isu-mysql-subnet-group"
  subnet_ids = [aws_subnet.mysql-a.id,aws_subnet.mysql-c.id]

  tags = {
    Name = "private-isu aurora subnet group"
  }
}

resource "aws_subnet" "mysql-a" {
    vpc_id = aws_vpc.vpc.id

    availability_zone = "ap-northeast-1a"
    cidr_block = "10.10.9.0/24"
}

resource "aws_subnet" "mysql-c" {
    vpc_id = aws_vpc.vpc.id

    availability_zone = "ap-northeast-1c"
    cidr_block = "10.10.11.0/24"
}

resource "aws_security_group" "aurora" {
  name   = "Private-isu-aurora"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
}

data "aws_iam_policy" "enhanced_monitoring" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role" # 任意のロール名を指定してください
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com" # Aurora クラスターのホストインスタンスが EC2 コンポーネントを持つため
        }
      },
    ]
  })

  tags = {
    Name = "private-isu RDS Monitoring Role"
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring_attachment" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = data.aws_iam_policy.enhanced_monitoring.arn
}