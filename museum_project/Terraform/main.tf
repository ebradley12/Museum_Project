# Infrastructure for the AWS RDS instance with PostgreSQL and EC2 Instance

provider "aws" {
  region = var.AWS_REGION
}

#AWS Security Group for RDS
resource "aws_security_group" "c14-trainee-ellie-bradley-rds_sg" {
  name        = "c14-trainee-ellie-bradley-rds_sg"
  description = "Security group that allows access from anywhere on port 5432"
  vpc_id      = var.VPC_ID

  ingress {
    description = "Allow PostgreSQL inbound traffic"
    from_port   = 5432
    to_port     = 5432
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
    Name = "RDS Security group"
  }
}

# AWS RDS Instance
resource "aws_db_instance" "c14-ellie-bradley-museum_db" {
  allocated_storage         = 10
  db_name                   = var.DB_NAME
  identifier                = "c14-ellie-bradley-museum-db"
  engine                    = var.DB_ENGINE
  engine_version            = "16.3"
  instance_class            = "db.t3.micro"
  publicly_accessible       = true
  performance_insights_enabled = false
  skip_final_snapshot          = true
  username                  = var.DB_USERNAME
  password                  = var.DB_PASSWORD
  port                      = var.DB_PORT
  vpc_security_group_ids    = [aws_security_group.c14-trainee-ellie-bradley-rds_sg.id]
  db_subnet_group_name      = "c14-public-subnet-group"

  tags = {
    Name = "Museum RDS Instance"
  }
}

# Security Group for EC2 Instance
resource "aws_security_group" "c14-ellie-bradley-kafka_pipeline_sg" {
  name        = "c14-ellie-bradley-kafka-pipeline-sg"
  description = "Security group for EC2 instance to run Kafka pipeline"
  vpc_id      = var.VPC_ID

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "Allow Kafka-related traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow PostgreSQL inbound traffic"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "c14-ellie-bradley-kafka_pipeline_sg"
  }
}

# EC2 instance
resource "aws_instance" "c14-ellie-bradley-kafka_pipeline_ec2" {
  ami           = var.AMI_ID 
  instance_type = "t2.nano"
  subnet_id              = var.SUBNET_ID
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.c14-ellie-bradley-kafka_pipeline_sg.id]
  key_name               = "c14-ellie-bradley-2"

  tags = {
    Name = "c14-ellie-bradley-ec2"
  }
}
