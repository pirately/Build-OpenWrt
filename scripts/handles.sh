#!/bin/bash

PKG_PATH="$GITHUB_WORKSPACE/openwrt/package/"

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#移除Shadowsocks组件
PW_FILE=$(find ./ -maxdepth 3 -type f -wholename "*/luci-app-passwall/Makefile")
if [ -f "$PW_FILE" ]; then
	sed -i '/config PACKAGE_$(PKG_NAME)_INCLUDE_Shadowsocks_Libev/,/x86_64/d' $PW_FILE
	sed -i '/config PACKAGE_$(PKG_NAME)_INCLUDE_ShadowsocksR/,/default n/d' $PW_FILE
	sed -i '/Shadowsocks_NONE/d; /Shadowsocks_Libev/d; /ShadowsocksR/d' $PW_FILE

	cd $PKG_PATH && echo "passwall has been fixed!"
fi

SP_FILE=$(find ./ -maxdepth 3 -type f -wholename "*/luci-app-ssr-plus/Makefile")
if [ -f "$SP_FILE" ]; then
	sed -i '/default PACKAGE_$(PKG_NAME)_INCLUDE_Shadowsocks_Libev/,/libev/d' $SP_FILE
	sed -i '/config PACKAGE_$(PKG_NAME)_INCLUDE_ShadowsocksR/,/x86_64/d' $SP_FILE
	sed -i '/Shadowsocks_NONE/d; /Shadowsocks_Libev/d; /ShadowsocksR/d' $SP_FILE

	cd $PKG_PATH && echo "ssr-plus has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

# 安装openclash内核
if [ -d *"openclash"* ]; then
	CORE_VER="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/core_version"
	CORE_TYPE=$(echo $WRT_TARGET | grep -Eiq "64|86" && echo "amd64" || echo "arm64")

	CORE_META="https://github.com/vernesong/OpenClash/raw/core/master/meta/clash-linux-$CORE_TYPE.tar.gz"

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

	cd $PKG_PATH && echo "openclash date has been updated!"
fi

# 安装EasyTier内核
if [ -d *"easytier"* ]; then
	ET_VER=$(curl -sSL "https://api.github.com/repos/EasyTier/EasyTier/releases/latest" | grep "tag_name" | head -n 1 | awk -F'"' '{print $4}')
	ET_TYPE=$(echo $WRT_TARGET | grep -Eiq "64|86" && echo "x86_64" || echo "arm")
	ET_PKG="https://github.com/EasyTier/EasyTier/releases/download/$ET_VER/easytier-linux-$ET_TYPE-$ET_VER.zip"
	
	cd ./luci-app-easytier/root/etc/easytier/
	curl -sL -o easytier-core.zip $ET_PKG && jar xvf easytier-core.zip && cp -rf ./easytier-linux-$ET_TYPE/easytier-core ./ && echo "easytier done!"

	chmod +x ./easytier-core && rm -rf ./easytier-core.zip && rm -rf ./easytier-linux-$ET_TYPE

	cd $PKG_PATH && echo "easytier date has been updated!"
fi

#修复argon主题进度条颜色不同步(原版作者)
if [ -d *"luci-theme-argon"* ]; then
	sed -i 's/(--bar-bg)/(--primary)/g' $(find ./luci-theme-argon -type f -iname "cascade.*")
	cd $PKG_PATH && echo "theme-argon has been fixed!"
fi

#修改argon主题字体和颜色
# if [ -d *"luci-theme-argon"* ]; then
# 	cd ./luci-theme-argon/
#
# 	sed -i '/font-weight:/ {/!important/! s/\(font-weight:\s*\)[^;]*;/\1normal;/}' $(find ./luci-theme-argon -type f -iname "*.css")
# 	sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/" ./luci-app-argon-config/root/etc/config/argon
#
# 	cd $PKG_PATH && echo "theme-argon has been fixed!"
# fi
