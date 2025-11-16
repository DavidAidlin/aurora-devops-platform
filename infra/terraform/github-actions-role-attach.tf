resource "aws_iam_role_policy_attachment" "github_actions_role_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}
