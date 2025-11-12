# ============================================================================
# Cost Monitoring & Alerts
# ============================================================================
# This file sets up CloudWatch alarms to monitor AWS costs and prevent
# unexpected charges.
# ============================================================================

# SNS Topic for Cost Alerts (optional: can add email subscription manually)
resource "aws_sns_topic" "cost_alerts" {
  name = "${var.project_name}-cost-alerts-${var.environment}"

  tags = local.common_tags
}

# CloudWatch Alarm for Estimated Charges
resource "aws_cloudwatch_metric_alarm" "estimated_charges" {
  alarm_name          = "${var.project_name}-high-costs-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600  # 6 hours
  statistic           = "Maximum"
  threshold           = 10.0  # Alert if estimated monthly charges exceed $10
  alarm_description   = "Triggers when AWS estimated charges exceed $10/month"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = local.common_tags
}

# Outputs for easy access
output "cost_alert_topic_arn" {
  description = "SNS topic ARN for cost alerts - subscribe your email here"
  value       = aws_sns_topic.cost_alerts.arn
}

output "cost_alert_topic_name" {
  description = "SNS topic name for cost alerts"
  value       = aws_sns_topic.cost_alerts.name
}
