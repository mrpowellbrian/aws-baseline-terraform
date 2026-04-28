resource "aws_iam_account_password_policy" "this" {
  count = var.enable_iam_password_policy ? 1 : 0

  minimum_password_length        = var.iam_password_min_length
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = var.iam_password_max_age_days
  password_reuse_prevention      = var.iam_password_reuse_prevention

  # hard_expiry forces users to contact an admin after expiry rather than
  # self-serving a reset. Disabled to reduce support burden while still
  # enforcing rotation via max_password_age.
  hard_expiry = false
}
