#!/bin/bash

# 1. 移除 luci-app-attendedsysupgrade
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "/attendedsysupgrade/d" {} +

# 2. 修改默认主题（若 WRT_THEME=argon，请务必确保已注释掉 jerrykuku 的拉取，使用官方 feeds 自带版）
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" {} +

# 3. 添加编译日期标识
find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" -exec sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_SOURCE-$WRT_TIME')/g" {} +

# 4. 修改默认主机名
CFG_FILE="./package/base-files/files/bin/config_generate"
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

# 5. 配置文件修改（保留 bootstrap 保底，去除无效的 luci-app-主题名）
echo "CONFIG_PACKAGE_luci-theme-bootstrap=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#修改默认IP地址
# sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
