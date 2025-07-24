#variable "cloudflare_api_token" {
#  type        = string
#  sensitive   = true
#  description = "Cloudflare API Token with Zone:Edit and Zone:Read permissions"
#}

variable "zone_ids" {
  type        = map(string)
  description = "Map of zone names to zone IDs. Format: { \"example.com\" = \"zone_id_1\", \"example.org\" = \"zone_id_2\" }"
}
