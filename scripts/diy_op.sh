#!/bin/bash

set -euo pipefail

# ImmortalWrt 默认设置包
if [[ "$WRT_REPO" != *"immortalwrt"* ]]; then
    git clone --depth=1 --filter=blob:none --sparse \
        https://github.com/immortalwrt/immortalwrt.git immortalwrt_local
    (
        cd immortalwrt_local
        git sparse-checkout set package/emortal/default-settings
        cp -a package/emortal/default-settings ../package/
    )
    rm -rf immortalwrt_local
fi

#安装immortalwrt的配置
echo "CONFIG_PACKAGE_default-settings=y" >> .config
echo "CONFIG_PACKAGE_default-settings-chn=y" >> .config

# 1. 修改固件版本信息
# 加入作者信息, %Y表示4位数年份如2023, %y表示2位数年份如23
INFO_FILE="package/base-files/files/etc/openwrt_release"
sed -i "s/DISTRIB_REVISION='[^']*'/DISTRIB_REVISION=' $WRT_TIME'/g" "$INFO_FILE"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='ImmortalWrt by Jeffen '/g" "$INFO_FILE"
# 2. 修改内核编译者信息（建议放在 make defconfig 之后）
echo 'CONFIG_KERNEL_BUILD_USER="Jeffen"' >> .config
echo 'CONFIG_KERNEL_BUILD_DOMAIN="ImmortalWrt"' >> .config

# 相关插件
if [[ $WRT_PLUGIN == "passwall" ]] ; then
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-passwall=y" >> .config
fi
if [[ $WRT_PLUGIN == "passwall2" ]] ; then
  echo "CONFIG_PACKAGE_luci-app-passwall2=y" >> .config
  # 适配新版 PassWall2 Makefile 的单选菜单（同时包含 Xray 和 SingBox）
  echo "CONFIG_PACKAGE_luci-app-passwall2_Basic_Core_All=y" >> .config
  # 强制选中底层内核包
  echo "CONFIG_PACKAGE_xray-core=y" >> .config
  echo "CONFIG_PACKAGE_sing-box=y" >> .config
  # 关闭不需要的 v2ray-plugin
  echo "CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_V2ray_Plugin=n" >> .config
  echo "CONFIG_PACKAGE_v2ray-plugin=n" >> .config
fi

if [[ "${WRT_PLUGIN:-nikki}" != "nikki" ]]; then
    echo "This build profile is designed for WRT_PLUGIN=nikki; got: ${WRT_PLUGIN:-unset}" >&2
    exit 1
fi

# Nikki + Mihomo
cat >> .config <<'KCONFIG'
CONFIG_PACKAGE_nikki=y
CONFIG_PACKAGE_luci-app-nikki=y
CONFIG_PACKAGE_luci-i18n-nikki-zh-cn=y

# AdGuardHome LuCI management panel
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_luci-i18n-adguardhome-zh-cn=y

# Ensure PassWall2 / OpenClash are not built into this image
# CONFIG_PACKAGE_luci-app-passwall2 is not set
# CONFIG_PACKAGE_luci-app-openclash is not set
KCONFIG
