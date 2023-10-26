resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.environment}_secret"
  description             = "${var.environment} openai org and key"
  recovery_window_in_days = "7"
}
