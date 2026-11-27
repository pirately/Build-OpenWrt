#!/usr/bin/env bash
set -Eeuo pipefail

# 强制确保工作目录在 openwrt 源码根目录
[ -f "./scripts/feeds" ] || cd ..
ROOT="$PWD"

# 安装和更新软件包函数
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=${4:-}
	local PKG_LIST=("$PKG_NAME" ${5:-})
	local REPO_NAME=${PKG_REPO#*/}
	local REPO_PATH="./package/$REPO_NAME"

	echo " "
	for NAME in "${PKG_LIST[@]}"; do
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ./feeds/luci/ ./feeds/packages/ -maxdepth 3 -type d -iname "$NAME" 2>/dev/null)
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not found directory: $NAME"
		fi
	done

	git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git" "$REPO_PATH"

	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find "$REPO_PATH"/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./package \;
		rm -rf "$REPO_PATH"
	fi
}

# 拉取现代 LuCI 主题（已剔除不兼容 master 的旧版主题）
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
UPDATE_PACKAGE "shadcn" "eamonxg/luci-theme-shadcn" "main"
UPDATE_PACKAGE "vantage" "anothaDev/luci-theme-vantage" "main"

# 其他插件: passwall|passwall2|nikki|adguardhome
if [[ $WRT_PLUGIN == "passwall" || $WRT_PLUGIN == "passwall2" ]]; then
	echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >> feeds.conf.default
	if [[ "$WRT_PLUGIN" == "passwall" ]]; then
		echo 'src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' >> feeds.conf.default
	else
		echo 'src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall2.git;main' >> feeds.conf.default
	fi
fi
if [[ "$WRT_PLUGIN" == "nikki" ]]; then
	grep -q '^src-git nikki ' feeds.conf.default ||
		echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main' >> feeds.conf.default
fi

cat feeds.conf.default
./scripts/feeds update -a

# Install the distribution feeds first.
./scripts/feeds install -a

# Force-install the custom feeds last to make the intended package definitions win.
case "$WRT_PLUGIN" in
  passwall|passwall2) ./scripts/feeds install -a -f -p passwall_packages; ./scripts/feeds install -a -f -p passwall_luci ;;
  nikki) ./scripts/feeds install -a -f -p nikki ;;
esac

# 刷新索引，消除删除旧包后留下的死链接
./scripts/feeds update -i
