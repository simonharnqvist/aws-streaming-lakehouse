resource "aws_scheduler_schedule" "api_poll_trigger" {
  name = "api-trigger-schedule"
  group_name = "default"

  # run on schedule, not flexible
  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 minutes)"

  target {
    arn = aws_lambda_function.nr_poller.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda.arn
  }
}
