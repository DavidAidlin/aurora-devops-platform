resource "aws_iam_policy" "github_actions_policy" {
  name        = "aurora-github-actions-policy"
  description = "Permissions for GitHub Actions to run Terraform"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "iam:Get*",
          "iam:List*",
          "logs:*",
          "sts:AssumeRole",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}
