#!/usr/bin/env bash
# On-demand AWS cost snapshot for the myapp account.
# Cost Explorer / Budgets are billing-global APIs, only served from us-east-1,
# regardless of where the actual resources (ap-northeast-1) live.
set -euo pipefail

ACCOUNT_ID="${AWS_ACCOUNT_ID:-743334887511}"
BUDGET_NAME="${BUDGET_NAME:-myapp-monthly-budget}"
BILLING_REGION="us-east-1"

MONTH_START="$(date +%Y-%m-01)"
TODAY="$(date +%Y-%m-%d)"

echo "== Month-to-date cost (${MONTH_START} .. ${TODAY}) by service =="
aws ce get-cost-and-usage \
  --time-period "Start=${MONTH_START},End=${TODAY}" \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --region "$BILLING_REGION" \
  --query 'ResultsByTime[0].Groups[?to_number(Metrics.UnblendedCost.Amount) > `0.001`].{Service:Keys[0],Cost:Metrics.UnblendedCost.Amount}' \
  --output table

TOTAL="$(aws ce get-cost-and-usage \
  --time-period "Start=${MONTH_START},End=${TODAY}" \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --region "$BILLING_REGION" \
  --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
  --output text)"
echo "TOTAL: \$${TOTAL}"

echo
echo "== Budget status (${BUDGET_NAME}) =="
aws budgets describe-budgets \
  --account-id "$ACCOUNT_ID" \
  --region "$BILLING_REGION" \
  --query "Budgets[?BudgetName=='${BUDGET_NAME}'].{Limit:BudgetLimit.Amount,Actual:CalculatedSpend.ActualSpend.Amount,Forecasted:CalculatedSpend.ForecastedSpend.Amount,Health:HealthStatus.Status}" \
  --output table
