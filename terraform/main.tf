terraform {
  required_version = ">= 1.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    render = {
      source  = "render-oss/render"
      version = "~> 1.8"
    }
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.9"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "render" {
  api_key = var.render_api_key
}

provider "supabase" {
  access_token = var.supabase_access_token
}

resource "supabase_project" "app" {
  name                = var.app_name
  organization_id     = var.supabase_organization_id
  database_password   = var.supabase_db_password
  region              = var.supabase_region
  plan_id             = var.supabase_plan_id
}

resource "render_web_service" "app" {
  name       = var.app_name
  plan       = var.render_plan
  runtime_id = "image"
  region     = var.render_region
  auto_deploy = true
  image_url  = "ghcr.io/cdemeo92/daily_logos:latest"

  envs = [
    { key = "FEEDBACK_FORM_URL", value = var.feedback_form_url },
    { key = "BUY_ME_COFFEE_URL", value = var.buy_me_coffee_url },
  ]

  secret_envs = [
    { key = "DATABASE_URL", value = supabase_project.app.database_url },
    { key = "SECRET_KEY_BASE", value = var.secret_key_base },
  ]

  depends_on = [cloudflare_dns_record.app]
}

resource "cloudflare_zone" "domain" {
  account_id = var.cloudflare_account_id
  zone       = var.cloudflare_zone_name
}

resource "cloudflare_dns_record" "app" {
  zone_id = cloudflare_zone.domain.id
  name    = "@"
  type    = "CNAME"
  content = render_web_service.app.service_url
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "www" {
  zone_id = cloudflare_zone.domain.id
  name    = "www"
  type    = "CNAME"
  content = cloudflare_dns_record.app.fqdn
  ttl     = 1
  proxied = true
}

resource "cloudflare_page_rule" "cache_assets" {
  zone_id  = cloudflare_zone.domain.id
  target   = "${cloudflare_dns_record.app.fqdn}/assets/*"
  priority = 1
  actions {
    cache_level       = "cache_everything"
    browser_cache_ttl = 14400
    edge_cache_ttl    = 604800
  }
}

resource "cloudflare_page_rule" "cache_api" {
  zone_id  = cloudflare_zone.domain.id
  target   = "${cloudflare_dns_record.app.fqdn}/api/*"
  priority = 2
  actions {
    cache_level    = "cache_on_cookie"
    edge_cache_ttl = 300
  }
}

resource "cloudflare_page_rule" "no_cache_live" {
  zone_id  = cloudflare_zone.domain.id
  target   = "${cloudflare_dns_record.app.fqdn}/live/*"
  priority = 3
  actions {
    cache_level = "bypass"
  }
}

resource "cloudflare_zone_settings_override" "settings" {
  zone_id = cloudflare_zone.domain.id
  settings {
    minify           = { css = true; html = true; js = true }
    polish           = "lossless"
    rocket_loader    = "on"
    brotli           = "on"
    security_level   = "medium"
    ssl              = "flexible"
  }
}

resource "cloudflare_rate_limit" "api" {
  count   = 1
  zone_id = cloudflare_zone.domain.id
  match {
    request {
      url {
        path { matches = "/api/*" }
      }
    }
  }
  threshold = 100
  period    = 60
  action {
    mode    = "challenge"
    timeout = 86400
  }
}

output "app_url" {
  value = "https://${cloudflare_dns_record.app.fqdn}"
}

output "app_render_url" {
  value = render_web_service.app.service_url
}

output "nameservers" {
  value = cloudflare_zone.domain.name_servers
}
