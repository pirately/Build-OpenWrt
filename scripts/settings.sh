#!/bin/bash

if [[ -d feeds/luci/collections ]]; then
  # 移除 luci-app-attendedsysupgrade
  find feeds/luci/collections -type f -name Makefile -exec sed -i '/luci-app-attendedsysupgrade/d' {} +
  # 修改默认主题
  find feeds/luci/collections -type f -name Makefile -exec sed -i "s/luci-theme-bootstrap/luci-theme-${WRT_THEME}/g" {} +
fi

# 添加编译日期标识
find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" -exec sed -i "s/luciversion || ''/luciversion || '' + ' \/ $WRT_SOURCE-$WRT_TIME'/g" {} +


# 修改默认主机名
CFG_FILE="./package/base-files/files/bin/config_generate"
sed -i "s/hostname='[^']*'/hostname='${WRT_NAME}'/g" "$CFG_FILE"

# 配置文件修改（保留 bootstrap 保底，去除无效的 luci-app-主题名）
echo "CONFIG_PACKAGE_luci-theme-bootstrap=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
if [[ "$WRT_THEME" == "argon" || "$WRT_THEME" == "aurora" ]]; then
  echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config
fi

#修改默认IP地址
# sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
