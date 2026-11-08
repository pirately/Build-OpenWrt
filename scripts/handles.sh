#!/bin/bash

FEEDS_PATH="$GITHUB_WORKSPACE/openwrt/feeds"
PACKAGE_PATH="./package/"

#修补命令统一入口：FIX <名称> <守卫目录> <命令...>
#守卫目录不存在时直接跳过，保证在 bash -e 下不中断
FIX() {
	local NAME=$1
	local GUARD=$2
	shift 2

	[ -d "$GUARD" ] || return 0

	echo " "
	if "$@"; then
		echo "$NAME has been fixed!"
	else
		echo "$NAME fix failed; continuing!"
	fi
}

# 修改argon主题字体和颜色
FIX "theme-argon" "$PACKAGE_PATH/luci-theme-argon" sed -i \
	"s/primary '.*'/primary '#31a1a1'/g; s/'0.2'/'0.5'/g; s/'none'/'bing'/g; s/'600'/'normal'/g" \
	"$PACKAGE_PATH/luci-theme-argon/luci-app-argon-config/root/etc/config/argon"

# 修改aurora菜单式样
FIX "theme-aurora" "$PACKAGE_PATH/luci-app-aurora-config" find \
	"$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec sed -i \
	"s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +

# 修改vantage进度条标签字体（anothaDev/luci-theme-vantage#52）
FIX "theme-vantage" "$PACKAGE_PATH/luci-theme-vantage" sed -i \
	-e '/^\/\* progress bars: thin track/,$ { /^\.cbi-progressbar::before {/,/^}/ { s/^[[:space:]]*font: 500 var(--fs-micro)\/1\.2 var(--mono);/\tfont: inherit; line-height: normal;/; } }' \
	"$PACKAGE_PATH/luci-theme-vantage/luci-theme-vantage/htdocs/luci-static/vantage/vantage.css"

# 修改mini-diskmanager菜单位置
FIX "mini-diskmanager" "$PACKAGE_PATH/luci-app-mini-diskmanager" sed -i "s/services/system/g" \
	"$PACKAGE_PATH/luci-app-mini-diskmanager/luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json"

#修改natmapt菜单位置
FIX "natmapt" "$PACKAGE_PATH/luci-app-natmapt" sed -i "s/network/services/g" \
	"$PACKAGE_PATH/luci-app-natmapt/root/usr/share/luci/menu.d/luci-app-natmap.json"

# 安装openclash内核
if [ -d *"openclash"* ]; then
	CORE_VER="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/core_version"
	CORE_TYPE=$(echo $WRT_TARGET | grep -Eiq "64|86" && echo "amd64" || echo "arm64")

	CORE_META="https://github.com/vernesong/OpenClash/raw/core/master/meta/clash-linux-$CORE_TYPE-compatible.tar.gz"

	GEO_MMDB="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb"
	GEO_SITE="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
	GEO_IP="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat"
	GEO_ASN="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb"

	cd ./luci-app-openclash/root/etc/openclash/

	curl -sL -o country.mmdb $GEO_MMDB && echo "Country.mmdb done!"
	curl -sL -o geosite.dat $GEO_SITE && echo "GeoSite.dat done!"
	curl -sL -o geoip.dat $GEO_IP && echo "GeoIP.dat done!"
	curl -sL -o GeoLite2-ASN.mmdb $GEO_ASN && echo "GeoAsn.mmdb done!"

	mkdir ./core/ && cd ./core/

	curl -sL -o meta.tar.gz $CORE_META && tar -zxf meta.tar.gz && mv -f clash clash_meta && echo "meta done!"

	chmod +x ./* && rm -rf ./*.gz

	cd $PACKAGE_PATH && echo "openclash date has been updated!"
fi

# 安装EasyTier内核
if [ -d *"easytier"* ]; then
	ET_VER=$(curl -sSL "https://api.github.com/repos/EasyTier/EasyTier/releases/latest" | grep "tag_name" | head -n 1 | awk -F'"' '{print $4}')
	ET_TYPE=$(echo $WRT_TARGET | grep -Eiq "64|86" && echo "x86_64" || echo "arm")
	ET_PKG="https://github.com/EasyTier/EasyTier/releases/download/$ET_VER/easytier-linux-$ET_TYPE-$ET_VER.zip"
	
	cd ./luci-app-easytier/luci-app-easytier/root/etc/easytier/
	curl -sL -o easytier-core.zip $ET_PKG && jar xvf easytier-core.zip && cp -rf ./easytier-linux-$ET_TYPE/easytier-core ./ && echo "easytier done!"

	chmod +x ./easytier-core && rm -rf ./easytier-core.zip && rm -rf ./easytier-linux-$ET_TYPE

	cd $PACKAGE_PATH && echo "easytier date has been updated!"
fi
