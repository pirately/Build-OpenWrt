#!/bin/bash

#修改网络
UCI_FILE="./package/base-files/files/etc/uci-defaults"
mkdir -p $UCI_FILE
cat << "EOF" > $UCI_FILE/99-custom
uci -q batch << EOI
set network.lan.ipaddr='10.0.1.1'
set network.lan.gateway='10.0.1.2'
set network.lan.ifname='eth0'
set network.lan.dns='223.5.5.5'
add network route
set network.@route[-1].interface='lan'
set network.@route[-1].target='10.8.1.0/24'
set network.@route[-1].gateway='10.0.1.18'
set system.@system[0].log_size='64'
EOI
EOF
#下载immortalwrt的设置文件
svn co https://github.com/immortalwrt/immortalwrt/trunk/package/emortal/default-settings
rm -rf ./package/emortal/default-settings
mv default-settings $UCI_FILE
#安装配置
echo "CONFIG_PACKAGE_default-settings=y" >> .config
echo "CONFIG_PACKAGE_default-settings-chn=y" >> .config

# 加入作者信息, %Y表示4位数年份如2023, %y表示2位数年份如23
INFO_FILE="package/base-files/files/etc/openwrt_release"
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='OpenWrt by Jeffen'/g" $INFO_FILE
sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' $WRT_TIME'/g" $INFO_FILE

# echo "CONFIG_PACKAGE_tailscale=y" >> .config  # 安装tailscale
# echo "CONFIG_PACKAGE_luci-app-zerotier=y" >> .config  # 安装zerotier
# echo "CONFIG_PACKAGE_luci-app-easytier=y" >> .config  # EasyTier
# echo "CONFIG_PACKAGE_luci-app-vnt=y" >> .config # VNT
# echo "CONFIG_PACKAGE_luci-app-homeproxy=y" >> ./.config # 安装homeproxy

# 删除自带的packages
rm -rf feeds/packages/net/chinadns-ng
# rm -rf feeds/packages/net/hysteria

# 相关插件
if [[ $OPENWRT_APPLICATIONS == "passwall" ]] ; then
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-passwall=y" >> .config
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
# openclash或mihomo插件
if [[ $OPENWRT_APPLICATIONS == "openclash" || $OPENWRT_APPLICATIONS == "mihomo" ]]; then
  sed -i '/EOI/i set dhcp.@dnsmasq[0].dns_redirect="0"' $UCI_FILE/99-custom
  if [[ $OPENWRT_APPLICATIONS == "openclash" ]]; then
    # rm -rf feeds/luci/applications/luci-app-openclash
    echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config

    # 设置openclash启动，否则第一次运行需要手动点
    SH_PATH="$GITHUB_WORKSPACE/openwrt/files/etc/init.d"
    SH_FILE="$SH_PATH/openclash.sh"
    mkdir -p $SH_PATH
    echo '#!/bin/sh /etc/rc.common' > $SH_FILE
    echo '# Copyright (C) 2024 OpenWRT' >> $SH_FILE
    echo -e '# This script will enable OpenClash and reboot the device\n' >> $SH_FILE
    echo 'START=99' >> $SH_FILE
    echo 'start() {' >> $SH_FILE
    echo '  if ! grep -q "option enable '\''1'\''" /etc/config/openclash; then' >> $SH_FILE
    echo '    sed -i "s/option enable '\''0'\''/option enable '\''1'\''/g" /etc/config/openclash && reboot' >> $SH_FILE
    echo '    rm -f /etc/init.d/openclash.sh' >> $SH_FILE
    echo '  fi' >> $SH_FILE
    echo '}' >> $SH_FILE
    chmod +x $SH_FILE
  elif [[ $OPENWRT_APPLICATIONS == "mihomo" ]]; then
    echo "CONFIG_PACKAGE_luci-app-mihomo=y" >> ./.config
  fi
fi
