output "rds_endpoint" {
  description = "The RDS instance's public endpoint"
  value       = aws_db_instance.c14-ellie-bradley-museum_db.endpoint
}

output "rds_port" {
  description = "The RDS instance's port"
  value       = aws_db_instance.c14-ellie-bradley-museum_db.port
}

output "ec2_public_ip" {
  description = "EC2 instance public IP"
  value = aws_instance.c14-ellie-bradley-kafka_pipeline_ec2.public_ip
}