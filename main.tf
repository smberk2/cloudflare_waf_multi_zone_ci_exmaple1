terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.16.0"
    }
  }
}

provider "cloudflare" {
  #api_token = var.cloudflare_api_token
  # 将 api_token 行删除或注释掉。
  # Cloudflare Provider 会自动从环境变量 CLOUDFLARE_API_TOKEN 中获取凭证。
}

locals {
  config = yamldecode(file("${path.module}/rules.yaml"))
}

resource "cloudflare_ruleset" "waf_ruleset" {
  for_each    = var.zone_ids
  zone_id     = each.value
  name        = "Terraform Managed WAF Rules"
  description = "WAF rules auto-updated from AbuseIPDB"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  # 【关键修改】添加 lifecycle 块来确保无缝切换
  # 这会告诉 Terraform：在销毁旧的规则集之前，必须先成功创建新的规则集。
  lifecycle {
    create_before_destroy = true
  }

  dynamic "rules" {
    for_each = { for idx, rule in local.config.rules : idx => rule }
    content {
      action      = rules.value.action
      description = rules.value.description # 修正：您的YAML中使用了'description'，这里应保持一致
      expression  = rules.value.expression
      enabled     = true
      # 注意：'ref' 字段在 Terraform 中通常用于唯一标识规则，以避免不必要的更新。
      # 使用索引作为 ref 是可以的，但如果规则顺序改变，会导致所有后续规则被更新。
      # 一个更稳健的方法是使用规则的 'name' 或内容的哈希值作为 ref。
      # 为了简单起见，我们暂时保留 tostring(rules.key)。
      ref         = tostring(rules.key)
      
      dynamic "action_parameters" {
        for_each = contains(["skip"], rules.value.action) ? [1] : []
        content {
          # 修正：根据您的 YAML，action_parameters 应该从 rule.value 中查找
          ruleset  = lookup(rules.value.action_parameters, "ruleset", null)
          products = lookup(rules.value.action_parameters, "products", null)
        }
      }

      dynamic "logging" {
        for_each = rules.value.action == "skip" ? [1] : []
        content {
          enabled = lookup(rules.value, "logging_enabled", true)
        }
      }
    }
  }
}
