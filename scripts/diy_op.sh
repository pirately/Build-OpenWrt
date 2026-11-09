#!/bin/bash

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

# 安装sirpdboy/luci-app-ddns-go
# 1. 彻底粉碎官方 feeds 树中自带的旧 luci-app-ddns-go 界面包，防止其产生软链接冲突
rm -rf feeds/luci/applications/luci-app-ddns-go
# 2. 调用你的函数，精准下载 sirpdboy 仓库中的 luci-app-ddns-go 文件夹
# 这里的参数分别对应：分支"main"、仓库地址、临时目录、目标文件夹路径
git_sparse_clone "main" "https://github.com/sirpdboy/luci-app-ddns-go.git" "sirpdboy_ddnsgo" "luci-app-ddns-go"
# 3. 将拉取下来的文件夹安全移动到自定义 package 目录
# 你的函数执行完后会在当前目录生成一个 luci-app-ddns-go 文件夹，将其移入 package 即可
mv -f ./luci-app-ddns-go ./package/
# 4. 强制在 .config 中注入编译标记
# 勾选 ImmortalWrt 官方 packages 源自带的 ddns-go 核心二进制
# echo "CONFIG_PACKAGE_ddns-go=y" >> .config
# 勾选刚才用你的函数拉取下来的 sirpdboy 全功能界面
echo "CONFIG_PACKAGE_luci-app-ddns-go=y" >> .config
# 自动勾选国际化中文语言包
# echo "CONFIG_PACKAGE_luci-i18n-ddns-go-zh-cn=y" >> .config
# 强行补充 https 证书支持包，确保核心正常请求域名商 API
# echo "CONFIG_PACKAGE_ca-certificates=y" >> .config

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
  echo "CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_V2ray_Plugin=n" >> .config
  echo "CONFIG_PACKAGE_v2ray-plugin=n" >> .config
fi
if [[ $WRT_PLUGIN == "ssrplus" ]] ; then
  rm -rf feeds/luci/applications/luci-app-ssr-plus
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-ssr-plus=y" >> .config
  echo "CONFIG_PACKAGE_haproxy=y" >> .config
fi

UCI_FILE="./package/base-files/files/etc/uci-defaults"
SH_PATH="$GITHUB_WORKSPACE/openwrt/files/etc/init.d"
mkdir -p $SH_PATH

# openclash或nikki插件
if [[ $WRT_PLUGIN == "openclash" || $WRT_PLUGIN == "nikki" ]]; then
  sed -i '/EOI/i set dhcp.@dnsmasq[0].dns_redirect="0"' $UCI_FILE/99-custom
  if [[ $WRT_PLUGIN == "openclash" ]]; then
    # rm -rf feeds/luci/applications/luci-app-openclash
    echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config

    # 设置openclash启动，否则第一次运行需要手动点
    OCL_FILE="$SH_PATH/set_openclash.sh"
    # 创建目录并写入脚本内容
    cat << 'EOF' > $OCL_FILE
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
    chmod +x $OCL_FILE
  elif [[ $WRT_PLUGIN == "nikki" ]]; then
    echo "CONFIG_PACKAGE_luci-app-nikki=y" >> ./.config
  fi
fi
