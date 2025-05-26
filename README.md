# Cloudflare WAF 自動更新工具

這個工具可以自動從 AbuseIPDB 獲取惡意 ASN 列表並更新到 Cloudflare WAF 規則中，保護您的網站免受惡意流量的侵害。

## 使用方法

### 1. Fork 這個儲存庫

點擊右上角的 Fork 按鈕，將此儲存庫複製到您的 GitHub 帳戶。

### 2. 設定 GitHub Secrets

在您 fork 的儲存庫中，前往 Settings > Secrets and variables > Actions，添加以下兩個 secrets：

| 名稱                    | 值                                                  |
| ---------------------- | -------------------------------------------------- |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API Token（需要 Zone:Edit 和 Zone:Read 權限） |
| `ABUSEIPDB_API_KEY`    | 您的 AbuseIPDB API 金鑰                               |

### 3. 修改 terraform.tfvars

編輯 `terraform.tfvars` 文件，填入您的 Cloudflare Zone ID：

```
cloudflare_api_token = ""  # 留空，將通過 GitHub Secrets 提供

zone_ids = {
  "example.com" = "your_zone_id_1"
  "example.org" = "your_zone_id_2"
}
```

您可以在 Cloudflare 儀表板的網站概述頁面底部找到 Zone ID。

### 4. 提交更改

```bash
git add terraform.tfvars
git commit -m "Update zone IDs"
git push origin main
```

### 5. 查看 GitHub Actions

提交後，GitHub Actions 將自動運行並部署 WAF 規則。您可以在儲存庫的 Actions 標籤中查看進度。

## 自動更新

WAF 規則將按照以下方式自動更新：

- 每當您推送到 main 分支時
- 每天凌晨 3 點（UTC）通過排程任務

## 自定義規則

如果您想自定義 WAF 規則，可以編輯 `rules.yaml` 文件。

## 故障排除

如果遇到問題，請檢查：

1. Cloudflare API Token 是否有正確的權限
2. Zone ID 是否正確
3. GitHub Actions 日誌中的錯誤信息

## 注意事項

- 此工具會刪除並重新創建名稱包含 "Terraform"、"WAF" 或 "managed" 的現有 WAF 規則集
- 請確保您了解所應用的規則對您網站的影響
