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
}

resource "render_web_service" "app" {
  name   = var.app_name
  plan   = var.render_plan
  region = var.render_region

  runtime_source = {
    image = {
      image_url = "ghcr.io/cdemeo92/daily_logos:${var.image_tag}"
    }
  }

  env_vars = {
    "FEEDBACK_FORM_URL" = { value = var.feedback_form_url }
    "BUY_ME_COFFEE_URL" = { value = var.buy_me_coffee_url }
    "DATABASE_URL"      = { value = supabase_project.app.database_url }
    "SECRET_KEY_BASE"   = { value = var.secret_key_base }
  }

  depends_on = [cloudflare_dns_record.app]
}

resource "cloudflare_zone" "domain" {
  count = var.cloudflare_zone_name != "" ? 1 : 0
  account = {
    id = var.cloudflare_account_id
  }
  name = var.cloudflare_zone_name
}

resource "cloudflare_dns_record" "app" {
  count   = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id = cloudflare_zone.domain[0].id
  name    = "@"
  type    = "CNAME"
  content = render_web_service.app.url
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "www" {
  count   = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id = cloudflare_zone.domain[0].id
  name    = "www"
  type    = "CNAME"
  content = cloudflare_dns_record.app[0].fqdn
  ttl     = 1
  proxied = true
}

resource "cloudflare_page_rule" "cache_assets" {
  count    = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id  = cloudflare_zone.domain[0].id
  target   = "${cloudflare_dns_record.app[0].fqdn}/assets/*"
  priority = 1
  actions {
    cache_level       = "cache_everything"
    browser_cache_ttl = 14400
    edge_cache_ttl    = 604800
  }
}

resource "cloudflare_page_rule" "cache_api" {
  count    = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id  = cloudflare_zone.domain[0].id
  target   = "${cloudflare_dns_record.app[0].fqdn}/api/*"
  priority = 2
  actions {
    cache_level    = "cache_on_cookie"
    edge_cache_ttl = 300
  }
}

resource "cloudflare_page_rule" "no_cache_live" {
  count    = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id  = cloudflare_zone.domain[0].id
  target   = "${cloudflare_dns_record.app[0].fqdn}/live/*"
  priority = 3
  actions {
    cache_level = "bypass"
  }
}

resource "cloudflare_zone_setting" "polish" {
  count      = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id    = cloudflare_zone.domain[0].id
  setting_id = "polish"
  value      = "lossless"
}

resource "cloudflare_zone_setting" "rocket_loader" {
  count      = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id    = cloudflare_zone.domain[0].id
  setting_id = "rocket_loader"
  value      = "on"
}

resource "cloudflare_zone_setting" "brotli" {
  count      = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id    = cloudflare_zone.domain[0].id
  setting_id = "brotli"
  value      = "on"
}

resource "cloudflare_zone_setting" "security_level" {
  count      = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id    = cloudflare_zone.domain[0].id
  setting_id = "security_level"
  value      = "medium"
}

resource "cloudflare_zone_setting" "ssl" {
  count      = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id    = cloudflare_zone.domain[0].id
  setting_id = "ssl"
  value      = "flexible"
}

resource "cloudflare_ruleset" "minify" {
  count   = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id = cloudflare_zone.domain[0].id
  name    = "Minify assets"
  kind    = "zone"
  phase   = "http_config_settings"

  rules = [
    {
      action      = "set_config"
      expression  = "true"
      description = "Minify CSS, HTML and JS"
      enabled     = true
      action_parameters = {
        autominify = {
          css  = true
          html = true
          js   = true
        }
      }
    }
  ]
}

resource "cloudflare_ruleset" "rate_limit_api" {
  count   = var.cloudflare_zone_name != "" ? 1 : 0
  zone_id = cloudflare_zone.domain[0].id
  name    = "Rate limit API"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules = [
    {
      action      = "challenge"
      expression  = "(http.request.uri.path matches \"^/api/\")"
      description = "Rate limit /api/* - 100 req/60s"
      enabled     = true
      ratelimit = {
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = 60
        requests_per_period = 100
        mitigation_timeout  = 86400
      }
    }
  ]
}

output "app_url" {
  value = var.cloudflare_zone_name != "" ? "https://${cloudflare_dns_record.app[0].fqdn}" : null
}

output "app_render_url" {
  value = render_web_service.app.url
}

output "nameservers" {
  value = var.cloudflare_zone_name != "" ? cloudflare_zone.domain[0].name_servers : null
}
