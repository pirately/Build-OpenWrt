#!/bin/bash

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)

	rm -rf $(find ./ ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune)

	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	if [[ $PKG_SPECIAL == "pkg" ]]; then
		cp -rf $(find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune) ./
		rm -rf ./$REPO_NAME/
	elif [[ $PKG_SPECIAL == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

#UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
# UPDATE_PACKAGE "tinyfilemanager" "muink/luci-app-tinyfilemanager" "master"

UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "$([[ $WRT_REPO == *"lede"* ]] && echo "18.06" || echo "master")"
UPDATE_PACKAGE "design" "0x676e67/luci-theme-design" "$([[ $WRT_REPO == *"lede"* ]] && echo "main" || echo "js")"
UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "$([[ $WRT_REPO == *"lede"* ]] && echo "main" || echo "js")"

UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
UPDATE_PACKAGE "mihomo" "morytyann/OpenWrt-mihomo" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "xiaorouji/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "xiaorouji/openwrt-passwall2" "main" "pkg"
UPDATE_PACKAGE "passwall-packages" "xiaorouji/openwrt-passwall-packages" "main"
UPDATE_PACKAGE "ssr-plus" "fw876/helloworld" "master"

UPDATE_PACKAGE "luci-app-gecoosac" "lwb1978/openwrt-gecoosac" "main"
UPDATE_PACKAGE "easytier" "lazyoop/networking-artifact" "main" "pkg"
UPDATE_PACKAGE "vnt" "lazyoop/networking-artifact" "main" "pkg"
UPDATE_PACKAGE "luci-app-easytier" "EasyTier/luci-app-easytier" "main"
UPDATE_PACKAGE "luci-app-vnt" "lmq8267/luci-app-vnt" "main"

if [[ $WRT_URL == *"openwrt-6.x"* ]]; then
	UPDATE_PACKAGE "qmi-wwan" "immortalwrt/wwan-packages" "master" "pkg"
fi
