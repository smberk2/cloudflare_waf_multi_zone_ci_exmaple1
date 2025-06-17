[中文版本](./README_zh-CN.md)

# Cloudflare WAF Auto Update Tool

This tool automatically fetches a list of malicious ASNs from AbuseIPDB and updates your Cloudflare WAF rules to protect your website from malicious traffic while allowing legitimate security scanners and monitoring services.

## 🚀 Key Features

- **Smart Protection**: Blocks malicious traffic while allowing legitimate services
- **SEO Friendly**: Supports all major search engines and social media crawlers
- **Security Scanner Support**: Allows legitimate security scanners (Expanse, Shodan, Censys, etc.)
- **Monitoring Service Support**: Compatible with uptime monitoring and performance testing tools
- **Automatic Updates**: Daily updates from AbuseIPDB threat intelligence
- **Multi-Zone Support**: Manage multiple Cloudflare zones from a single repository

## Usage

### 1. Fork this repository

Click the Fork button in the top right corner to copy this repository to your GitHub account.

### 2. Set up GitHub Secrets

In your forked repository, go to Settings > Secrets and variables > Actions, and add the following two secrets:

| Name                    | Value                                                     |
| ---------------------- | -------------------------------------------------------- |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API Token (requires Zone:Edit and Zone:Read permissions) |
| `ABUSEIPDB_API_KEY`    | Your AbuseIPDB API Key                                    |

### 3. Modify terraform.tfvars

Edit the `terraform.tfvars` file and **only** fill in your Cloudflare Zone ID:

```
# cloudflare_api_token is passed via environment variable TF_VAR_cloudflare_api_token from GitHub Secrets
# Do not set the API token in this file for improved security

zone_ids = {
  "example.com" = "your_zone_id_1"
  "example.org" = "your_zone_id_2"
}
```

**Important Security Note**:
- ❌ **Do not** set `cloudflare_api_token` in `terraform.tfvars`
- ✅ The API Token will be automatically passed from `CLOUDFLARE_API_TOKEN` in GitHub Secrets via the environment variable `TF_VAR_cloudflare_api_token`
- You can find the Zone ID at the bottom of your website's overview page in the Cloudflare dashboard.

### 4. Commit Changes

```bash
git add terraform.tfvars
git commit -m "Update zone IDs"
git push origin main
```

### 5. View GitHub Actions

After committing, GitHub Actions will automatically run and deploy the WAF rules. You can view the progress in the Actions tab of your repository.

## Automatic Updates

The WAF rules will be updated automatically in the following ways:

- Whenever you push to the main branch
- Daily at 3:00 AM (UTC) via a scheduled task

## 🛡️ Built-in Rule Categories

The WAF rules are organized into three priority levels:

### 1. **Allow Legitimate Security & Monitoring Services** (Highest Priority)
- **Expanse (Palo Alto Networks)** - Network asset discovery
- **Shodan, Censys** - Internet-wide scanning services
- **Monitoring Services** - UptimeRobot, Pingdom, StatusCake, Site24x7
- **Performance Testing** - GTmetrix, PageSpeed Insights, Lighthouse, WebPageTest

### 2. **Allow Known Bots & Crawlers** (Second Priority)
- **Search Engines** - Google, Bing, Yahoo, DuckDuckGo, Baidu, Yandex
- **Social Media** - Facebook, Twitter, LinkedIn, WhatsApp, Discord, Telegram
- **Other Services** - Apple Bot, Internet Archive

### 3. **Block Malicious User-Agents** (Third Priority)
- Attack tools (nmap, sqlmap, nikto, etc.)
- Automated scanners and vulnerability tools
- Suspicious or empty user agents

### 4. **Block Exploit Path Probes**
- Common attack paths (/.git, /.env, /wp-admin, etc.)
- Configuration files and sensitive directories

### 5. **Geographic and ASN Filtering**
- Challenge overseas traffic (configurable)
- Block known malicious ASNs from AbuseIPDB

## Custom Rules

If you want to add or modify WAF rules, edit the `rules.yaml` file. The file follows the format below:

```yaml
rules:
- action: skip|block|managed_challenge|js_challenge|...
  expression: <Cloudflare Filter Expression>
  name: <Rule Name>
  products:  # Required only if action is skip
  - waf
  - bic
  - rateLimit
```

### Rule Examples

1. **Block traffic from specific countries**:
```yaml
- action: block
  expression: ip.geoip.country in {"RU" "IR" "KP"}
  name: Block High Risk Countries
```

2. **Challenge suspicious user agents**:
```yaml
- action: managed_challenge
  expression: http.user_agent contains "suspicious-string"
  name: Challenge Suspicious User Agents
```

3. **Block specific IP ranges**:
```yaml
- action: block
  expression: ip.src in {192.0.2.0/24 198.51.100.0/24}
  name: Block Specific IP Ranges
```

### Rule Priority

Rules are executed in the order they appear in the `rules.yaml` file. Rules listed earlier have higher priority.

**Important**: The current rule order is optimized to:
1. First allow legitimate services (security scanners, monitoring tools)
2. Then allow search engines and social media crawlers
3. Finally block malicious traffic and attack tools

### Test Your Rules

After adding new rules, it is recommended to test them on a single website first to confirm they work as expected before applying them to all websites.

## 🔍 Monitoring and Analytics

### Checking Rule Effectiveness
You can monitor your WAF rules through:
- **Cloudflare Dashboard** → Security → WAF → Custom rules
- **Analytics** → Security → WAF events
- **Logs** → HTTP requests (Enterprise plan)

### Common Legitimate Services to Monitor
If you notice these services being blocked, they should be added to the allow list:
- Security scanners (Qualys, Rapid7, etc.)
- SEO tools (Ahrefs, SEMrush, Moz, etc.)
- Monitoring services (New Relic, Datadog, etc.)
- Performance testing tools

### Cloudflare Expression Syntax

Cloudflare uses a specific expression syntax to define rules. For detailed syntax, refer to the [Cloudflare Filter Expressions documentation](https://developers.cloudflare.com/ruleset-engine/rules-language/expressions/).

## Troubleshooting

If you encounter issues, check:

1. Whether the Cloudflare API Token has the correct permissions
2. Whether the Zone ID is correct
3. Error messages in the GitHub Actions logs

### Common Issues

**Legitimate services being blocked:**
- Check if the service's user agent is in the allow list
- Add the service to the first rule in `rules.yaml`
- Monitor WAF events to identify blocked legitimate traffic

**SEO impact concerns:**
- All major search engines are whitelisted by default
- Social media preview crawlers are supported
- Performance testing tools are allowed

**False positives:**
- Review the WAF events in Cloudflare Dashboard
- Adjust rules based on your specific needs
- Consider using `managed_challenge` instead of `block` for borderline cases

## Security Best Practices

### API Token Security
- ✅ **Correct**: Store the Cloudflare API Token in GitHub Secrets
- ✅ **Correct**: Pass it to Terraform via the environment variable `TF_VAR_cloudflare_api_token`
- ❌ **Incorrect**: Hardcode the API Token in `terraform.tfvars` or any code file
- ❌ **Incorrect**: Commit files containing the API Token to version control

### Zone ID Security
- ✅ Zone ID is not sensitive information and can be safely stored in `terraform.tfvars`
- ✅ Zone ID can be committed to version control

### Local Development
If you need to run Terraform locally:
```bash
export TF_VAR_cloudflare_api_token="your_api_token_here"
terraform plan
terraform apply
```

## 📋 Notes

- This tool will delete and recreate existing WAF rulesets whose names contain "Terraform", "WAF", or "managed".
- Please ensure you understand the impact of the rules you apply on your website.
- The rules are optimized for balancing security and accessibility for legitimate services.
- Regular monitoring of WAF events is recommended to fine-tune the rules.

## 🤝 Contributing

If you find legitimate services being blocked or have suggestions for improving the rules, please:
1. Open an issue with details about the blocked service
2. Include the user agent string and service purpose
3. Submit a pull request with the proposed changes

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
