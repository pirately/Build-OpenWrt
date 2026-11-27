#!/bin/bash

FEEDS_PATH="$GITHUB_WORKSPACE/openwrt/feeds"
PACKAGE_PATH="$GITHUB_WORKSPACE/openwrt/package"
cd "$PACKAGE_PATH" || exit 1

# 修补命令统一入口
FIX() {
    local NAME=$1
    local GUARD=$2
    shift 2

    if [ ! -d "$GUARD" ]; then
        echo "Skip $NAME fix (guard dir not found: $GUARD)"
        return 0
    fi

    echo " "
    if "$@"; then
        echo "$NAME has been fixed!"
    else
        echo "WARNING: $NAME fix failed; continuing!"
    fi

    return 0
}

# 1. 修改官方自带 argon 主题字体和颜色
FIX "theme-argon" \
    "$FEEDS_PATH/luci/applications/luci-app-argon-config/root/etc/config" \
    sed -i \
    "s/primary '.*'/primary '#31a1a1'/g; s/'0.2'/'0.5'/g; s/'none'/'bing'/g; s/'600'/'normal'/g" \
    "$FEEDS_PATH/luci/applications/luci-app-argon-config/root/etc/config/argon"

# 2. 修改 aurora 菜单式样
FIX "theme-aurora" \
    "$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora" \
    find "$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora/" \
    -type f -name '*.template' -exec sed -i \
    "s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +

# 3. 修改 vantage 进度条标签字体
FIX "theme-vantage" \
    "$PACKAGE_PATH/luci-theme-vantage/htdocs/luci-static/vantage" \
    sed -i \
    -e '/^\/\* progress bars: thin track/,$ { /^\.cbi-progressbar::before {/,/^}/ { s/^[[:space:]]*font: 500 var(--fs-micro)\/1\.2 var(--mono);/\tfont: inherit; line-height: normal;/; } }' \
    "$PACKAGE_PATH/luci-theme-vantage/htdocs/luci-static/vantage/vantage.css"

# 4. 修改 mini-diskmanager 菜单位置
DISKMAN_JSON=$(find "$PACKAGE_PATH" "$FEEDS_PATH" \
    -type f -name 'luci-app-mini-diskmanager.json' \
    2>/dev/null | head -n 1)

if [ -n "$DISKMAN_JSON" ]; then
    FIX "mini-diskmanager" "$(dirname "$DISKMAN_JSON")" \
        sed -i "s/services/system/g" "$DISKMAN_JSON"
else
    echo "Skip mini-diskmanager fix (file not found)"
fi

# 5. 修改 natmapt 菜单位置
NATMAPT_JSON=$(find "$PACKAGE_PATH" "$FEEDS_PATH" \
    -type f -path '*luci-app-natmapt*/root/usr/share/luci/menu.d/luci-app-natmap.json' \
    2>/dev/null | head -n 1)

if [ -n "$NATMAPT_JSON" ]; then
    FIX "natmapt" "$(dirname "$NATMAPT_JSON")" \
        sed -i "s/network/services/g" "$NATMAPT_JSON"
else
    echo "Skip natmapt fix (file not found)"
fi

echo "All optional package fixes completed."
exit 0