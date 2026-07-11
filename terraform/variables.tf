variable "render_api_key" {
  type      = string
  sensitive = true
}

variable "render_owner_id" {
  type = string
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "app_name" {
  type = string
}

variable "render_plan" {
  type = string
}

variable "render_region" {
  type = string
}

variable "supabase_access_token" {
  type      = string
  sensitive = true
}

variable "supabase_organization_id" {
  type = string
}

variable "supabase_db_password" {
  type      = string
  sensitive = true
}

variable "supabase_region" {
  type = string
}

variable "secret_key_base" {
  type      = string
  sensitive = true
}

variable "feedback_form_url" {
  type = string
}

variable "buy_me_coffee_url" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
  default   = "placeholder"
}

variable "cloudflare_account_id" {
  type = string
}

variable "cloudflare_zone_name" {
  type = string
  default = ""
}
