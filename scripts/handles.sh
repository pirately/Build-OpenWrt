#!/bin/bash

FEEDS_PATH="$GITHUB_WORKSPACE/openwrt/feeds"
PACKAGE_PATH="$GITHUB_WORKSPACE/openwrt/package"
cd "$PACKAGE_PATH" || exit 1

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

# 1. 修改官方自带 argon 主题字体和颜色
FIX "theme-argon" "$FEEDS_PATH/luci/applications/luci-app-argon-config/root/etc/config" sed -i \
	"s/primary '.*'/primary '#31a1a1'/g; s/'0.2'/'0.5'/g; s/'none'/'bing'/g; s/'600'/'normal'/g" \
	"$FEEDS_PATH/luci/applications/luci-app-argon-config/root/etc/config/argon"

# 2. 修改 aurora 菜单式样
FIX "theme-aurora" "$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora" find \
	"$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec sed -i \
	"s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +

# 3. 修改 vantage 进度条标签字体
FIX "theme-vantage" "$PACKAGE_PATH/luci-theme-vantage/htdocs/luci-static/vantage" sed -i \
	-e '/^\/\* progress bars: thin track/,$ { /^\.cbi-progressbar::before {/,/^}/ { s/^[[:space:]]*font: 500 var(--fs-micro)\/1\.2 var(--mono);/\tfont: inherit; line-height: normal;/; } }' \
	"$PACKAGE_PATH/luci-theme-vantage/htdocs/luci-static/vantage/vantage.css"

# 4. 修改 mini-diskmanager 菜单位置
DISKMAN_JSON=$(find "$PACKAGE_PATH" -maxdepth 4 -path "*luci-app-mini-diskmanager*/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json" 2>/dev/null | head -n 1)
[ -n "$DISKMAN_JSON" ] && FIX "mini-diskmanager" "$(dirname "$DISKMAN_JSON")" sed -i "s/services/system/g" "$DISKMAN_JSON"

# 5. 修改 natmapt 菜单位置
NATMAPT_JSON=$(find "$PACKAGE_PATH" -maxdepth 4 -path "*luci-app-natmapt*/root/usr/share/luci/menu.d/luci-app-natmap.json" 2>/dev/null | head -n 1)
[ -n "$NATMAPT_JSON" ] && FIX "natmapt" "$(dirname "$NATMAPT_JSON")" sed -i "s/network/services/g" "$NATMAPT_JSON"

# 6. 安装 OpenClash 内核（自动查找实际目录，兼容 OpenClash 或 luci-app-openclash）
OC_DIR=$(find "$PACKAGE_PATH" -maxdepth 3 -type d -path "*openclash*/root/etc/openclash" 2>/dev/null | head -n 1)
if [ -n "$OC_DIR" ]; then
	CORE_TYPE=$(echo "$WRT_TARGET" | grep -Eiq "64|86" && echo "amd64" || echo "arm64")
	CORE_META="https://github.com/vernesong/OpenClash/raw/core/master/meta/clash-linux-$CORE_TYPE-compatible.tar.gz"
	GEO_MMDB="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb"
	GEO_SITE="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
	GEO_IP="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat"
	GEO_ASN="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb"

	cd "$OC_DIR"
	curl -sL -o country.mmdb "$GEO_MMDB" && echo "Country.mmdb done!"
	curl -sL -o GeoSite.dat "$GEO_SITE" && echo "GeoSite.dat done!"
	curl -sL -o GeoIP.dat "$GEO_IP" && echo "GeoIP.dat done!"
	curl -sL -o GeoLite2-ASN.mmdb "$GEO_ASN" && echo "GeoAsn.mmdb done!"

	mkdir -p ./core/ && cd ./core/
	curl -sL -o meta.tar.gz "$CORE_META" && tar -zxf meta.tar.gz && mv -f clash clash_meta && echo "meta done!"
	chmod +x ./* && rm -rf ./*.gz

	cd "$PACKAGE_PATH" && echo "openclash data has been updated!"
fi

# 7. 安装 EasyTier 内核（自动查找实际目录）
ET_DIR=$(find "$PACKAGE_PATH" -maxdepth 4 -type d -path "*luci-app-easytier*/root/etc/easytier" 2>/dev/null | head -n 1)
if [ -n "$ET_DIR" ]; then
	ET_VER=$(curl -sSL "https://api.github.com/repos/EasyTier/EasyTier/releases/latest" | grep "tag_name" | head -n 1 | awk -F'"' '{print $4}')
	case "$WRT_TARGET" in
	  *x86_64*) ET_TYPE="x86_64" ;;
	  *aarch64*|*armv8*|*filogic*|*ipq807x*|*ipq60xx*) ET_TYPE="aarch64" ;;
	  *mipsel*) ET_TYPE="mipsel" ;;
	  *mips*) ET_TYPE="mips" ;;
	  *) ET_TYPE="arm" ;;
	esac

	ET_PKG="https://github.com/EasyTier/EasyTier/releases/download/$ET_VER/easytier-linux-$ET_TYPE-$ET_VER.zip"
	
	cd "$ET_DIR"
	curl -sL -o easytier-core.zip "$ET_PKG" && unzip -oq easytier-core.zip && find . -name "easytier-core" -exec cp -f {} ./ \; && echo "easytier done!"
	chmod +x ./easytier-core && rm -rf ./easytier-core.zip ./easytier-linux-*

	cd "$PACKAGE_PATH" && echo "easytier data has been updated!"
fi
