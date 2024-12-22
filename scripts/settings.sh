#!/bin/bash

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_SOURCE-$WRT_TIME')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
#修改默认时区
sed -i "s/timezone='.*'/timezone='CST-8'/g" $CFG_FILE
sed -i "s/zonename='.*'/zonename='Asia/Shanghai'/g" $CFG_FILE
# sed -i "/timezone='.*'/a\\\t\t\set system.@system[-1].zonename='Asia/Shanghai'" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#修改网络
UCI_FILE="./package/base-files/files/etc/uci-defaults"
mkdir -p $UCI_FILE
cat << "EOF" > $UCI_FILE/99-custom
uci -q batch << EOI
set network.lan.gateway="10.0.1.2"
set network.lan.ifname="eth0"
set network.lan.dns="223.5.5.5"
add network route
set network.@route[-1].interface="lan"
set network.@route[-1].target="10.8.1.0/24"
set network.@route[-1].gateway="10.0.1.18"
EOI
EOF
if [[ $OPENWRT_APPLICATIONS == "openclash" || $OPENWRT_APPLICATIONS == "mihomo" ]]; then
	sed -i '/EOI/i set dhcp.@dnsmasq[0].dns_redirect="0"' $UCI_FILE/99-custom
fi
