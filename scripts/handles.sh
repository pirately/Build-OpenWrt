#!/bin/bash

FEEDS_PATH="$GITHUB_WORKSPACE/openwrt/feeds"
PACKAGE_PATH="./package/"

# 修补命令统一入口：FIX <名称> <守卫目录> <命令...>
FIX() {
	local NAME=$1
	local GUARD=$2
	shift 2

	[ -d "$GUARD" ] || { echo "Skip $NAME fix (guard dir not found: $GUARD)"; return 0; }

	echo " "
	if "$@"; then
		echo "$NAME has been fixed!"
	else
		echo "$NAME fix failed; continuing!"
	fi
}

# 1. 修改 aurora 菜单式样（路径已核对，与 eamonxg/luci-app-aurora-config 仓库结构完全一致）
FIX "theme-aurora" "$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora" find \
	"$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec sed -i \
	"s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +

# 2. 修改 vantage 进度条标签字体（修正了原脚本中多余的一层嵌套目录）
FIX "theme-vantage" "$PACKAGE_PATH/luci-theme-vantage/htdocs/luci-static/vantage" sed -i \
	-e '/^\/\* progress bars: thin track/,$ { /^\.cbi-progressbar::before {/,/^}/ { s/^[[:space:]]*font: 500 var(--fs-micro)\/1\.2 var(--mono);/\tfont: inherit; line-height: normal;/; } }' \
	"$PACKAGE_PATH/luci-theme-vantage/htdocs/luci-static/vantage/vantage.css"

# 3. 修改 mini-diskmanager 菜单位置（兼容单层或套娃两种仓库结构）
DISKMAN_JSON=$(find "$PACKAGE_PATH" -maxdepth 4 -path "*luci-app-mini-diskmanager*/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json" 2>/dev/null | head -n 1)
[ -n "$DISKMAN_JSON" ] && FIX "mini-diskmanager" "$(dirname "$DISKMAN_JSON")" sed -i "s/services/system/g" "$DISKMAN_JSON"

# 4. 修改 natmapt 菜单位置（兼容单层或套娃两种仓库结构）
NATMAPT_JSON=$(find "$PACKAGE_PATH" -maxdepth 4 -path "*luci-app-natmapt*/root/usr/share/luci/menu.d/luci-app-natmap.json" 2>/dev/null | head -n 1)
[ -n "$NATMAPT_JSON" ] && FIX "natmapt" "$(dirname "$NATMAPT_JSON")" sed -i "s/network/services/g" "$NATMAPT_JSON"


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
