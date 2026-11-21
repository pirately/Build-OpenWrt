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

# 加入作者信息, %Y表示4位数年份如2023, %y表示2位数年份如23
INFO_FILE="package/base-files/files/etc/openwrt_release"
sed -i "s/DISTRIB_REVISION='[^']*'/DISTRIB_REVISION=' $WRT_TIME'/g" "$INFO_FILE"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='ImmortalWrt by Jeffen '/g" "$INFO_FILE"

# 相关插件
if [[ $WRT_PLUGIN == "passwall" ]] ; then
  # 增加luci界面
  echo "CONFIG_PACKAGE_luci-app-passwall=y" >> .config
fi
if [[ $WRT_PLUGIN == "passwall2" ]] ; then
  echo "CONFIG_PACKAGE_luci-app-passwall2=y" >> .config
  echo "CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y" >> .config
  echo "CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Xray=y" >> .config
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

# openclash或nikki插件
if [[ $WRT_PLUGIN == "openclash" || $WRT_PLUGIN == "nikki" ]]; then
  if [ -f "$UCI_FILE/99-custom" ]; then
    sed -i '/EOI/i\set dhcp.@dnsmasq.dns_redirect='\''0'\''' "$UCI_FILE/99-custom"
  fi

  if [[ $WRT_PLUGIN == "openclash" ]]; then
    echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config
    if [ -f "$UCI_FILE/99-custom" ]; then
      sed -i '/EOI/i\set openclash.config.enable='\''1'\''' "$UCI_FILE/99-custom"
    fi
  elif [[ $WRT_PLUGIN == "nikki" ]]; then
    echo "CONFIG_PACKAGE_luci-app-nikki=y" >> .config
  fi
fi

