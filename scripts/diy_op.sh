#!/bin/bash

# 加入作者信息, %Y表示4位数年份如2023, %y表示2位数年份如23
if [[ $WRT_URL == *"lede"* ]] ; then
  sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='OpenWrt by Jeffen'/g" package/lean/default-settings/files/zzz-default-settings
  sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' $WRT_TIME'/g" package/lean/default-settings/files/zzz-default-settings
else
  sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='OpenWrt by Jeffen'/g" package/base-files/files/etc/openwrt_release
  sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' $WRT_TIME'/g" package/base-files/files/etc/openwrt_release
fi


echo "CONFIG_PACKAGE_bash=y" >> .config # 安装bash
# echo "CONFIG_PACKAGE_tailscale=y" >> .config  # 安装tailscale
# echo "CONFIG_PACKAGE_luci-app-zerotier=y" >> .config  # 安装zerotier

# OpenWrt官方HaProxy
if [[ $WRT_URL == *"lede"* ]] ; then
  svn co https://github.com/openwrt/packages/branches/openwrt-23.05/net/haproxy
  rm -rf feeds/packages/net/haproxy
  mv haproxy feeds/packages/net
fi

# 删除自带的passwall
rm -rf feeds/luci/applications/luci-app-passwall
# 删除自带的packages
# rm -rf feeds/packages/net/xray-core
rm -rf feeds/packages/net/xray-plugin
rm -rf feeds/packages/net/hysteria
rm -rf feeds/packages/net/sing-box
# 相关插件
if [[ $OPENWRT_APPLICATIONS == "passwall" ]] ; then
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-passwall=y" >> .config
  echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Geodata=y" >> .config
fi
if [[ $OPENWRT_APPLICATIONS == "passwall2" ]] ; then
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-passwall2=y" >> .config
fi
if [[ $OPENWRT_APPLICATIONS == "ssrplus" ]] ; then
  rm -rf feeds/luci/applications/luci-app-ssr-plus
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-ssr-plus=y" >> .config
  echo "CONFIG_PACKAGE_haproxy=y" >> .config
fi
# openclash插件
if [[ $OPENWRT_APPLICATIONS == "openclash" ]] ; then
  rm -rf feeds/luci/applications/luci-app-openclash
  #增加luci界面
  echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config
fi

# EasyTier, VNT
echo "CONFIG_PACKAGE_luci-app-easytier=y" >> .config
echo "CONFIG_PACKAGE_luci-app-vnt=y" >> .config

# BBR
if [[ $WRT_URL == *"lede"* ]] ; then
  sed -i "s/option bbr_cca '0'/option bbr_cca '1'/g" feeds/luci/applications/luci-app-turboacc/root/etc/config/turboacc
fi

# 配置网络环境
# 旁路由
if [[ $WRT_URL == *"lede"* ]] ; then
  sed -i '$i uci set network.lan.ifname="eth0"' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci set network.lan.gateway="10.0.1.2"' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci set network.lan.dns="223.5.5.5"' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci add network route' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci set network.@route[-1].interface="lan"' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci set network.@route[-1].target="10.8.1.0/24"' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci set network.@route[-1].gateway="10.0.1.18"' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci commit network' package/lean/default-settings/files/zzz-default-settings
fi
if [[ $WRT_SOURCE == "immortalwrt" ]]; then
  sed -i '$i uci set network.lan.ifname="eth0"' package/emortal/default-settings/files/99-default-settings
  sed -i '$i uci set network.lan.gateway="10.0.1.2"' package/emortal/default-settings/files/99-default-settings
  sed -i '$i uci set network.lan.dns="223.5.5.5"' package/emortal/default-settings/files/99-default-settings
  sed -i '$i uci add network route' package/emortal/default-settings/files/99-default-settings
  sed -i '$i uci set network.@route[-1].interface="lan"' package/emortal/default-settings/files/99-default-settings
  sed -i '$i uci set network.@route[-1].target="10.8.1.0/24"' package/emortal/default-settings/files/99-default-settings
  sed -i '$i uci set network.@route[-1].gateway="10.0.1.18"' package/emortal/default-settings/files/99-default-settings
  sed -i '$i uci commit network' package/emortal/default-settings/files/99-default-settings
fi
