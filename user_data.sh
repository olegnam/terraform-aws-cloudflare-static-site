resource "cloudflare_zero_trust_access_policy" "allowed_viewers" {
  account_id = var.cloudflare_account_id
  name       = "${var.project_name}-allowed-viewers"
  decision   = "allow"

  include = [
    for email in var.access_allowed_emails : {
      email = {
        email = email
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "site" {
  account_id       = var.cloudflare_account_id
  type             = "self_hosted"
  name             = "${var.domain_name} private preview"
  domain           = var.domain_name
  session_duration = "24h"

  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.allowed_viewers.id
      precedence = 1
    }
  ]
}
