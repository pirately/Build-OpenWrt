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

#将指定的文件从远程仓库克隆到本地
function git_sparse_clone() {
  branch="$1" rurl="$2" localdir="$3" && shift 3
  git clone -b $branch --depth 1 --filter=blob:none --sparse $rurl $localdir
  cd $localdir
  git sparse-checkout init --cone
  git sparse-checkout set $@
  mv -n $@ ../
  cd ..
  rm -rf $localdir
}

#下载immortalwrt的文件
if [[ $WRT_REPO != *"immortalwrt"* ]]; then
	git_sparse_clone "master" "https://github.com/immortalwrt/immortalwrt.git" "immortalwrt_local" "package/emortal/default-settings"
	rm -rf ./package/emortal/default-settings
  mv ./default-settings ./package
fi

#安装immortalwrt的配置
echo "CONFIG_PACKAGE_default-settings=y" >> .config
echo "CONFIG_PACKAGE_default-settings-chn=y" >> .config

# 加入作者信息, %Y表示4位数年份如2023, %y表示2位数年份如23
INFO_FILE="package/base-files/files/etc/openwrt_release"
sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' $WRT_TIME'/g" $INFO_FILE
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='OpenWrt by Jeffen'/g" $INFO_FILE

# 相关插件
if [[ $WRT_PLUGIN == "passwall" ]] ; then
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-passwall=y" >> .config
fi
if [[ $WRT_PLUGIN == "passwall2" ]] ; then
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-passwall2=y" >> .config
fi
if [[ $WRT_PLUGIN == "ssrplus" ]] ; then
  rm -rf feeds/luci/applications/luci-app-ssr-plus
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-ssr-plus=y" >> .config
  echo "CONFIG_PACKAGE_haproxy=y" >> .config
fi
# openclash或mihomo插件
if [[ $WRT_PLUGIN == "openclash" || $WRT_PLUGIN == "mihomo" ]]; then
  sed -i '/EOI/i set dhcp.@dnsmasq[0].dns_redirect="0"' $UCI_FILE/99-custom
  if [[ $WRT_PLUGIN == "openclash" ]]; then
    # rm -rf feeds/luci/applications/luci-app-openclash
    echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config

    # 设置openclash启动，否则第一次运行需要手动点
    SH_PATH="$GITHUB_WORKSPACE/openwrt/files/etc/init.d"
    SH_FILE="$SH_PATH/set_openclash.sh"
    # 创建目录并写入脚本内容
    mkdir -p $SH_PATH
    cat << 'EOF' > $SH_FILE
#!/bin/sh /etc/rc.common
# Copyright (C) 2024 OpenWRT
# This script will enable OpenClash and reboot the device

START=99
start() {
  if ! grep -q "option enable '1'" /etc/config/openclash; then
    sed -i "s/option enable '0'/option enable '1'/g" /etc/config/openclash && reboot
    rm -f /etc/init.d/set_openclash.sh
  fi
}
EOF
    # 赋予脚本可执行权限
    chmod +x $SH_FILE
  elif [[ $WRT_PLUGIN == "mihomo" ]]; then
    echo "CONFIG_PACKAGE_luci-app-mihomo=y" >> ./.config
  fi
fi
