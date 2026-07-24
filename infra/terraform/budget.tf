# Cost Explorer / Budgets APIs are billing-global and only exist in us-east-1,
# regardless of where the actual resources (ap-northeast-1) live.
provider "aws" {
  alias  = "billing"
  region = "us-east-1"
}

resource "aws_budgets_budget" "monthly" {
  provider = aws.billing

  name         = "myapp-monthly-budget"
  budget_type  = "COST"
  limit_amount = "50"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = "2026-07-01_00:00"

  cost_types {
    include_tax                = true
    include_subscription       = true
    use_blended                = false
    include_refund             = true
    include_credit             = true
    include_upfront            = true
    include_recurring          = true
    include_other_subscription = true
    include_support            = true
    include_discount           = true
    use_amortized              = false
  }

  # Early warning, well before the original 80% alert.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  # Catches drift mid-month, before actual spend reaches the threshold.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}
