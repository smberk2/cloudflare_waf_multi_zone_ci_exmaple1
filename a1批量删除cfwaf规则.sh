#!/bin/bash

# --- 配置区 ---

# 警告：请务必替换为你的真实 Cloudflare API Token。
API_TOKEN="tokenxxxx"

# 使用关联数组定义 Zones
declare -A ZONES=(
  ["123.xyz"]="tokenxxxx"
  ["456.xyz"]="tokenxxxx"
)

# 要查找和删除的规则集的特征
TARGET_DESCRIPTION="WAF rules auto-updated from AbuseIPDB"
TARGET_NAME="Terraform Managed WAF Rules"

# 每次处理完一个 Zone 后的延时（单位：秒）
DELAY_SECONDS=2


# --- 脚本主体 ---

# 检查依赖
if ! command -v jq &> /dev/null; then echo "[错误] jq 未安装。" >&2; exit 1; fi
if ! command -v curl &> /dev/null; then echo "[错误] curl 未安装。" >&2; exit 1; fi

# 检查 Token
if [[ "$API_TOKEN" == "YOUR_CLOUDFLARE_API_TOKEN" || -z "$API_TOKEN" ]]; then
    echo "[错误] 请在脚本中设置你的 Cloudflare API_TOKEN。" >&2
    exit 1
fi

# 设置通用的请求头
AUTH_HEADER="Authorization: Bearer $API_TOKEN"

# 遍历所有 Zone
for domain in "${!ZONES[@]}"; do
  ZONE_ID="${ZONES[$domain]}"
  echo ""
  echo "--- 正在处理 Zone: $domain (ID: $ZONE_ID) ---"

  # 1. 获取规则集列表 (强制使用 IPv4)
  LIST_URL="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets"
  echo "  [信息] 正在获取规则集列表..."
  API_RESPONSE=$(curl -4 -s -X GET "$LIST_URL" -H "$AUTH_HEADER")

  if ! echo "$API_RESPONSE" | jq -e '.success == true' > /dev/null; then
    echo "  [错误] 获取规则集列表失败。Cloudflare 返回:" >&2
    echo "$API_RESPONSE" | jq . >&2
    echo "  [信息] 暂停 ${DELAY_SECONDS} 秒后继续..."
    sleep "$DELAY_SECONDS"
    continue
  fi
  
  # 2. 查找匹配的规则集 ID
  RULESET_ID_TO_DELETE=$(echo "$API_RESPONSE" | jq -r --arg desc "$TARGET_DESCRIPTION" --arg name "$TARGET_NAME" '.result[] | select(.description == $desc and .name == $name) | .id')

  # 3. 如果找到，则执行删除
  if [ -n "$RULESET_ID_TO_DELETE" ]; then
    echo "  [发现] 找到目标规则集: ID = $RULESET_ID_TO_DELETE"
    DELETE_URL="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESET_ID_TO_DELETE"
    
    echo "  [操作] 正在发送删除请求..."
    
    # --- 关键修改 ---
    # 同时获取 HTTP 状态码和响应体
    # -w "%{http_code}" 会在最后输出状态码
    # -o /dev/null 表示不输出响应体到 stdout，因为成功时响应体为空
    HTTP_STATUS=$(curl -4 -s -w "%{http_code}" -o /dev/null -X DELETE "$DELETE_URL" -H "$AUTH_HEADER")
    
    # 检查状态码是否为 204 (No Content)，这表示删除成功
    if [ "$HTTP_STATUS" == "204" ]; then
      echo "  [成功] 已成功删除规则集 (API 返回 HTTP 204 No Content)。"
    else
      # 如果状态码不是 204，说明出错了，这时 API 应该会返回一个包含错误信息的 JSON
      # 我们需要重新请求一次来获取这个错误信息（因为上次请求的 body 被丢弃了）
      echo "  [错误] 删除失败，API 返回 HTTP 状态码: $HTTP_STATUS" >&2
      echo "  [信息] 正在获取详细错误信息..." >&2
      ERROR_RESPONSE=$(curl -4 -s -X DELETE "$DELETE_URL" -H "$AUTH_HEADER")
      echo "$ERROR_RESPONSE" | jq . >&2
    fi

  else
    echo "  [信息] 未在该 Zone 中找到需要删除的规则集。"
  fi
  
  echo "  [信息] 暂停 ${DELAY_SECONDS} 秒..."
  sleep "$DELAY_SECONDS"
done

echo ""
echo "--- 所有任务已完成 ---"
