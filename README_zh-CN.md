[English Version](./README.md)

# Cloudflare WAF 自動更新工具

這個工具可以自動從 AbuseIPDB 獲取惡意 ASN 列表並更新到 Cloudflare WAF 規則中，在保護您的網站免受惡意流量侵害的同時，允許合法的安全掃描器和監控服務正常訪問。

## 🚀 主要功能

- **智能防護**：阻擋惡意流量的同時允許合法服務
- **SEO 友好**：支持所有主要搜索引擎和社交媒體爬蟲
- **安全掃描器支持**：允許合法的安全掃描器（Expanse、Shodan、Censys 等）
- **監控服務支持**：兼容網站監控和性能測試工具
- **自動更新**：每日從 AbuseIPDB 威脅情報更新
- **多區域支持**：從單一儲存庫管理多個 Cloudflare 區域

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

編輯 `terraform.tfvars` 文件，**只**填入您的 Cloudflare Zone ID：

```
# cloudflare_api_token 通過環境變數 TF_VAR_cloudflare_api_token 從 GitHub Secrets 傳入
# 不要在此文件中設置 API token，以提高安全性

zone_ids = {
  "example.com" = "your_zone_id_1"
  "example.org" = "your_zone_id_2"
}
```

**重要安全提醒**：
- ❌ **不要**在 `terraform.tfvars` 中設置 `cloudflare_api_token`
- ✅ API Token 會自動從 GitHub Secrets 中的 `CLOUDFLARE_API_TOKEN` 通過環境變數 `TF_VAR_cloudflare_api_token` 傳入
- 您可以在 Cloudflare 儀表板的網站概述頁面底部找到 Zone ID

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

## 🛡️ 內建規則分類

WAF 規則分為三個優先級層次：

### 1. **允許合法的安全掃描和監控服務**（最高優先級）
- **Expanse (Palo Alto Networks)** - 網路資產發現服務
- **Shodan、Censys** - 全網掃描服務
- **監控服務** - UptimeRobot、Pingdom、StatusCake、Site24x7
- **性能測試** - GTmetrix、PageSpeed Insights、Lighthouse、WebPageTest

### 2. **允許已知的機器人和爬蟲**（第二優先級）
- **搜索引擎** - Google、Bing、Yahoo、DuckDuckGo、百度、Yandex
- **社交媒體** - Facebook、Twitter、LinkedIn、WhatsApp、Discord、Telegram
- **其他服務** - Apple Bot、Internet Archive

### 3. **阻擋惡意用戶代理**（第三優先級）
- 攻擊工具（nmap、sqlmap、nikto 等）
- 自動化掃描器和漏洞工具
- 可疑或空白的用戶代理

### 4. **阻擋漏洞路徑探測**
- 常見攻擊路徑（/.git、/.env、/wp-admin 等）
- 配置文件和敏感目錄

### 5. **地理位置和 ASN 過濾**
- 挑戰海外流量（可配置）
- 阻擋來自 AbuseIPDB 的已知惡意 ASN

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

**重要**：當前的規則順序經過優化，遵循以下邏輯：
1. 首先允許合法服務（安全掃描器、監控工具）
2. 然後允許搜索引擎和社交媒體爬蟲
3. 最後阻擋惡意流量和攻擊工具

### 測試您的規則

添加新規則後，建議先在單個網站上測試，確認規則按預期工作後再應用到所有網站。

## 🔍 監控和分析

### 檢查規則效果
您可以通過以下方式監控 WAF 規則：
- **Cloudflare 儀表板** → 安全性 → WAF → 自定義規則
- **分析** → 安全性 → WAF 事件
- **日誌** → HTTP 請求（企業版計劃）

### 需要監控的常見合法服務
如果您發現這些服務被阻擋，應該將它們添加到允許列表：
- 安全掃描器（Qualys、Rapid7 等）
- SEO 工具（Ahrefs、SEMrush、Moz 等）
- 監控服務（New Relic、Datadog 等）
- 性能測試工具

### Cloudflare 表達式語法

Cloudflare 使用特定的表達式語法來定義規則。詳細語法請參考 [Cloudflare 過濾表達式文檔](https://developers.cloudflare.com/ruleset-engine/rules-language/expressions/)。

## 故障排除

如果遇到問題，請檢查：

1. Cloudflare API Token 是否有正確的權限
2. Zone ID 是否正確
3. GitHub Actions 日誌中的錯誤信息

### 常見問題

**合法服務被阻擋：**
- 檢查該服務的用戶代理是否在允許列表中
- 將該服務添加到 `rules.yaml` 的第一個規則中
- 監控 WAF 事件以識別被阻擋的合法流量

**SEO 影響擔憂：**
- 所有主要搜索引擎默認已加入白名單
- 支持社交媒體預覽爬蟲
- 允許性能測試工具

**誤報問題：**
- 在 Cloudflare 儀表板中查看 WAF 事件
- 根據您的具體需求調整規則
- 對於邊界情況，考慮使用 `managed_challenge` 而不是 `block`

## 安全最佳實踐

### API Token 安全
- ✅ **正確做法**：將 Cloudflare API Token 存儲在 GitHub Secrets 中
- ✅ **正確做法**：通過環境變數 `TF_VAR_cloudflare_api_token` 傳遞給 Terraform
- ❌ **錯誤做法**：在 `terraform.tfvars` 或任何代碼文件中硬編碼 API Token
- ❌ **錯誤做法**：將包含 API Token 的文件提交到版本控制

### Zone ID 安全
- ✅ Zone ID 不是敏感信息，可以安全地存儲在 `terraform.tfvars` 中
- ✅ Zone ID 可以提交到版本控制

### 本地開發
如果需要在本地運行 Terraform：
```bash
export TF_VAR_cloudflare_api_token="your_api_token_here"
terraform plan
terraform apply
```

## 📋 注意事項

- 此工具會刪除並重新創建名稱包含 "Terraform"、"WAF" 或 "managed" 的現有 WAF 規則集
- 請確保您了解所應用的規則對您網站的影響
- 規則已針對安全性和合法服務的可訪問性進行平衡優化
- 建議定期監控 WAF 事件以微調規則

## 🤝 貢獻

如果您發現合法服務被阻擋或對改進規則有建議，請：
1. 開啟 issue 並詳細說明被阻擋的服務
2. 包含用戶代理字符串和服務用途
3. 提交包含建議更改的 pull request

## 📄 授權

此項目是開源的，採用 [MIT 授權](LICENSE)。