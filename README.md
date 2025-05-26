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

如果您想添加或修改 WAF 規則，請編輯 `rules.yaml` 文件。該文件遵循以下格式：

```yaml
rules:
- action: skip|block|managed_challenge|js_challenge|...
  expression: <Cloudflare 過濾表達式>
  name: <規則名稱>
  products:  # 僅當 action 為 skip 時需要
  - waf
  - bic
  - rateLimit
```

### 規則示例

1. **阻擋特定國家的流量**:
```yaml
- action: block
  expression: ip.geoip.country in {"RU" "IR" "KP"}
  name: Block High Risk Countries
```

2. **對可疑用戶代理發起挑戰**:
```yaml
- action: managed_challenge
  expression: http.user_agent contains "suspicious-string"
  name: Challenge Suspicious User Agents
```

3. **阻擋特定 IP 範圍**:
```yaml
- action: block
  expression: ip.src in {192.0.2.0/24 198.51.100.0/24}
  name: Block Specific IP Ranges
```

### 規則優先順序

規則按照在 `rules.yaml` 文件中的順序執行，靠前的規則優先級更高。

### 測試您的規則

添加新規則後，建議先在單個網站上測試，確認規則按預期工作後再應用到所有網站。

### Cloudflare 表達式語法

Cloudflare 使用特定的表達式語法來定義規則。詳細語法請參考 [Cloudflare 過濾表達式文檔](https://developers.cloudflare.com/ruleset-engine/rules-language/expressions/)。

## 故障排除

如果遇到問題，請檢查：

1. Cloudflare API Token 是否有正確的權限
2. Zone ID 是否正確
3. GitHub Actions 日誌中的錯誤信息

## 注意事項

- 此工具會刪除並重新創建名稱包含 "Terraform"、"WAF" 或 "managed" 的現有 WAF 規則集
- 請確保您了解所應用的規則對您網站的影響
