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

# Lets myapp-deploy manage its OWN attached-policy set and the content of the
# two customer-managed policies below, so future permission changes can go
# through Terraform instead of a console bootstrap step every time.
#
# Residual risk (accepted, see infra/terraform/README.md): since this policy
# can CreatePolicyVersion on itself, a compromised myapp-deploy credential
# could in principle rewrite its own guard rail and re-escalate. Closing that
# fully would require a Permissions Boundary set by a separate identity,
# which we've deliberately not added yet.
resource "aws_iam_policy" "deploy_iam_bootstrap" {
  name = "myapp-deploy-iam-bootstrap"
  # No description: it's an immutable attribute on aws_iam_policy (forces
  # replacement), and this resource must never be destroy/recreated by an
  # apply run as myapp-deploy itself — see the comment above.

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SelfUserRead"
        Effect   = "Allow"
        Action   = ["iam:GetUser", "iam:ListAttachedUserPolicies"]
        Resource = "arn:aws:iam::${var.account_id}:user/myapp-deploy"
      },
      {
        Sid      = "SelfAttachDetachGuarded"
        Effect   = "Allow"
        Action   = ["iam:AttachUserPolicy", "iam:DetachUserPolicy"]
        Resource = "arn:aws:iam::${var.account_id}:user/myapp-deploy"
        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = concat(
              local.deploy_managed_policy_arns,
              [
                aws_iam_policy.deploy_billing.arn,
                "arn:aws:iam::${var.account_id}:policy/myapp-deploy-iam-bootstrap",
              ]
            )
          }
        }
      },
      {
        Sid    = "ManageOwnPolicies"
        Effect = "Allow"
        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:ListPolicyTags",
        ]
        Resource = [
          aws_iam_policy.deploy_billing.arn,
          "arn:aws:iam::${var.account_id}:policy/myapp-deploy-iam-bootstrap",
        ]
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

resource "aws_iam_user_policy_attachment" "deploy_iam_bootstrap" {
  user       = data.aws_iam_user.deploy.user_name
  policy_arn = aws_iam_policy.deploy_iam_bootstrap.arn
}
