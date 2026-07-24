# myapp-deploy was created out-of-band (before this Terraform code existed) and
# originally had AdministratorAccess attached. It's referenced here, not created,
# so Terraform never has the power to delete the IAM user itself.
data "aws_iam_user" "deploy" {
  user_name = "myapp-deploy"
}

resource "aws_iam_policy" "deploy_billing" {
  name        = "myapp-deploy-billing"
  description = "Budgets CRUD + Cost Explorer / Free Tier read access for the myapp deploy user"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BudgetsManage"
        Effect = "Allow"
        Action = [
          "budgets:ViewBudget",
          "budgets:ModifyBudget",
          "budgets:ListTagsForResource",
          "budgets:TagResource",
          "budgets:UntagResource",
        ]
        Resource = "*"
      },
      {
        Sid    = "CostExplorerRead"
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetTags",
        ]
        Resource = "*"
      },
      {
        Sid      = "FreeTierRead"
        Effect   = "Allow"
        Action   = ["freetier:GetFreeTierUsage"]
        Resource = "*"
      },
    ]
  })
}

locals {
  deploy_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
    "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
  ]
}

resource "aws_iam_user_policy_attachment" "deploy_managed" {
  for_each   = toset(local.deploy_managed_policy_arns)
  user       = data.aws_iam_user.deploy.user_name
  policy_arn = each.value
}

resource "aws_iam_user_policy_attachment" "deploy_billing" {
  user       = data.aws_iam_user.deploy.user_name
  policy_arn = aws_iam_policy.deploy_billing.arn
}
