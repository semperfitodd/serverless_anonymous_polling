module "respondent_dynamo" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "3.3.0"

  name                           = local.respondent_name
  server_side_encryption_enabled = false
  deletion_protection_enabled    = false

  hash_key    = "respondent_id"
  table_class = "STANDARD"

  attributes = [
    {
      name = "respondent_id"
      type = "S"
  }]

  tags = var.tags
}

module "responses_dynamo" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "3.3.0"

  name                           = local.responses_name
  server_side_encryption_enabled = false
  deletion_protection_enabled    = false

  hash_key    = "response_id"
  table_class = "STANDARD"

  attributes = [
    {
      name = "response_id"
      type = "S"
  }]

  tags = var.tags
}
