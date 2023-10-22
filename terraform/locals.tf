locals {
  backend_name = var.environment

  domain = "brewsentry.com"

  environment = replace(var.environment, "_", "-")

  responses_name = "${var.environment}_responses"

  respondent_name = "${var.environment}_respondent"

  site_domain = "poll.${local.domain}"
}