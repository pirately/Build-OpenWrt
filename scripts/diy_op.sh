#!/bin/bash
set -euo pipefail

# ImmortalWrt 默认设置包
if [[ "$WRT_REPO" != *"immortalwrt/immortalwrt"* ]]; then
  git clone --depth=1 --filter=blob:none --sparse \
    https://github.com/immortalwrt/immortalwrt.git "$ROOT/immortalwrt-defaults"
  (cd "$ROOT/immortalwrt-defaults" && git sparse-checkout set package/emortal/default-settings && cp -a package/emortal/default-settings "$ROOT/package/")
  rm -rf "$ROOT/immortalwrt-defaults"
fi

# 修改固件版本信息
# 加入作者信息, %Y表示4位数年份如2023, %y表示2位数年份如23
INFO_FILE="package/base-files/files/etc/openwrt_release"
if [[ -f "$INFO_FILE" ]]; then
  sed -i "s/DISTRIB_REVISION='[^']*'/DISTRIB_REVISION='${WRT_TIME}'/" "$INFO_FILE"
  sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='ImmortalWrt by Jeffen (${WRT_BRANCH})'/" "$INFO_FILE"
fi

cat >> .config <<'KCONFIG'
CONFIG_PACKAGE_default-settings=y
CONFIG_PACKAGE_default-settings-chn=y
CONFIG_KERNEL_BUILD_USER="Jeffen"
CONFIG_KERNEL_BUILD_DOMAIN="ImmortalWrt"
KCONFIG

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
if [[ $WRT_PLUGIN == "nikki" ]] ; then
  # 增加luci界面
  echo "CONFIG_PACKAGE_nikki=y" >> .config
  echo "CONFIG_PACKAGE_luci-app-nikki=y" >> .config
  echo "CONFIG_PACKAGE_luci-i18n-nikki-zh-cn=y" >> .config
fi
if [[ "$ENABLE_ADGUARDHOME" == true ]]; then
  echo "CONFIG_PACKAGE_adguardhome=y" >> .config
fi
