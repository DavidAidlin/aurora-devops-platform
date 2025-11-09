output "public_ip" {
  value = aws_instance.aurora_test_env.public_ip
}

output "instance_id" {
  value = aws_instance.aurora_test_env.id
}

output "logs_bucket" {
  value = aws_s3_bucket.aurora_logs.bucket
}
