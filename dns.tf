resource "cloudflare_zero_trust_tunnel_cloudflared" "web" {
  account_id = var.cloudflare_account_id
  name       = var.project_name
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "web" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.web.id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "web" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.web.id

  config = {
    ingress = [
      {
        hostname = var.domain_name
        service  = "http://localhost:80"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

resource "aws_ssm_parameter" "tunnel_token" {
  name  = "/${var.project_name}/tunnel-token"
  type  = "SecureString"
  value = data.cloudflare_zero_trust_tunnel_cloudflared_token.web.token
}
