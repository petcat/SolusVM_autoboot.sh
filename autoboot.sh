#!/bin/bash
set -euo pipefail

declare -A VM_CONFIGS=(
    ["solusvm.virmach.com"]="ABCDE-12345-67890:pd50b209d31eec00ff113cab02083682eca5da00"
    ["solusvm.domain.com"]="ABCDE-12345-67890:another40charhash40charhash40charhash40"
)

for domain in "${!VM_CONFIGS[@]}"; do
    IFS=':' read -r key hash <<< "${VM_CONFIGS[$domain]}"

    echo "检查 $domain ..."

    status=$(curl -fsS "https://$domain/api/client/command.php" \
        --get \
        --data-urlencode "key=$key" \
        --data-urlencode "hash=$hash" \
        --data-urlencode "action=status" \
        || echo "ERROR")

    if [[ "$status" == "ERROR" ]]; then
        echo "❌ $domain 状态查询失败"
        continue
    fi

    if grep -qE '(^|[^a-zA-Z])offline([^a-zA-Z]|$)' <<< "$status"; then
        echo "⚠️  $domain 离线，正在开机..."
        curl -fsS "https://$domain/api/client/command.php" \
            --get \
            --data-urlencode "key=$key" \
            --data-urlencode "hash=$hash" \
            --data-urlencode "action=boot" \
            >/dev/null
        echo "✅ $domain 已发送开机命令"
    else
        echo "🟢 $domain 状态正常"
    fi

    sleep 1
done
