variable "user_pool_name" {}
variable "user_pool_client" {}
variable "env" {}


resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.user_pool_name}-${var.env}"

  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {

    recovery_mechanism {
      name = "verified_email"
      priority = 1
    }

    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_numbers = true
    require_symbols = true
    require_uppercase = true
  }

  schema {
    attribute_data_type = "String"
    name = "email"
    required = true
  }

  username_configuration {
    case_sensitive = true
  }
}

resource "aws_cognito_user_pool_client"  "user_pool_client" {

  name = "${var.user_pool_client}-${var.env}"
  
  user_pool_id = aws_cognito_user_pool.user_pool.id
  
}