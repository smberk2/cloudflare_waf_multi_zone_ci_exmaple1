# backend.tf

terraform {
  cloud {
    organization = "my_term" # 替换成你创建的 Organization 名字

    workspaces {
      name = "cloudflare-waf-manager" # 替换成你创建的 Workspace 名字
    }
  }
}
