#!/bin/bash

#修改argon主题设置
#ARGON_FILE="$GITHUB_WORKSPACE/wrt/feeds/luci/applications/luci-app-argon-config/root/etc/config/argon"
#DIY_FILE="$GITHUB_WORKSPACE/files/etc/config/argon"
#if [ -f "$ARGON_FILE" ]; then
# 
#    cp -f "$DIY_FILE" "$ARGON_FILE"
#
#	echo "argon主题参数设置成功!"
#fi

#修改qca-nss-drv启动顺序
NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then

	sed -i 's/START=.*/START=85/g' $NSS_DRV

	echo "qca-nss-drv已被修复!"
fi

#修改qca-nss-pbuf启动顺序
NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then

	sed -i 's/START=.*/START=86/g' $NSS_PBUF

	echo "qca-nss-pbuf已被修复!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then

	sed -i '/\/files/d' $TS_FILE

	echo "tailscale已被修复!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	echo "rust已被修复!"
fi

#修复DiskMan编译失败
DM_FILE="../package/luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then

	sed -i 's/fs-ntfs/fs-ntfs3/g' $DM_FILE
    sed -i '/ntfs-3g-utils /d' $DM_FILE
    sed -i '/config PACKAGE_$(PKG_NAME)_INCLUDE_ntfs_3g_utils/,/default y/d' "$DM_FILE"
	echo "diskman已被修复!"
fi

#去除luci-app-attendedsysupgrade
LUCI_MAKEFILE="../feeds/luci/collections/luci/Makefile"
NGINX_MAKEFILE="../feeds/luci/collections/luci-nginx/Makefile"

if [ -f "$LUCI_MAKEFILE" ]; then
    sed -i '/+luci-app-attendedsysupgrade/d' "$LUCI_MAKEFILE"
    echo "已从 luci 集合中删除 luci-app-attendedsysupgrade"
else
    echo "错误：未找到 $LUCI_MAKEFILE"
fi

if [ -f "$NGINX_MAKEFILE" ]; then
    sed -i '/+luci-app-attendedsysupgrade/d' "$NGINX_MAKEFILE"
    echo "已从 luci-nginx 集合中删除 luci-app-attendedsysupgrade"
else
    echo "错误：未找到 $NGINX_MAKEFILE"
fi

# 精简passwall：
PASSWALL_MAKEFILE="../feeds/luci/applications/luci-app-passwall/Makefile"

if [ -f "$PASSWALL_MAKEFILE" ]; then
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Haproxy/d' "$PASSWALL_MAKEFILE"
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Hysteria/d' "$PASSWALL_MAKEFILE"
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_NaiveProxy/d' "$PASSWALL_MAKEFILE"
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Shadowsocks_Rust_/d' "$PASSWALL_MAKEFILE"
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Shadow_TLS/d' "$PASSWALL_MAKEFILE"
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Simple_Obfs/d' "$PASSWALL_MAKEFILE"
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_tuic_client/d' "$PASSWALL_MAKEFILE"
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_V2ray_Plugin/d' "$PASSWALL_MAKEFILE"
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Xray/d' "$PASSWALL_MAKEFILE"
    sed -i '/CONFIG_PACKAGE_$(PKG_NAME)_INCLUDE_Xray_Plugin/d' "$PASSWALL_MAKEFILE"

    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_Brook:brook/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_Haproxy:haproxy/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_Hysteria:hysteria/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_NaiveProxy:naiveproxy/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_Shadowsocks_Rust_/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_Shadow_TLS:shadow-tls/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_Simple_Obfs:simple-obfs/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_tuic_client:tuic-client/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_V2ray_Plugin:v2ray-plugin/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_Xray:xray-core/d' "$PASSWALL_MAKEFILE"
    sed -i '/PACKAGE_$(PKG_NAME)_INCLUDE_Xray_Plugin:xray-plugin/d' "$PASSWALL_MAKEFILE"

    echo "PassWall 已精简，只保留 Sing-box + Geo 支持！"
else
    echo "文件未找到，请检查路径：$PASSWALL_MAKEFILE"
fi

#设置nginx默认配置
NGINX_FILE="../feeds/packages/net/nginx-util/files/nginx.config"
DIY_NGINX="$GITHUB_WORKSPACE/files/nginx.config"

if [ -f "$DIY_NGINX" ]; then
    cp -f "$DIY_NGINX" "$NGINX_FILE"
    echo "nginx默认配置已通过本地文件成功替换！"
fi

#修改CPU 性能优化调节名称显示
cpu_path="$GITHUB_WORKSPACE/wrt/feeds/luci/applications/luci-app-cpufreq"
po_file="$cpu_path/po/zh_Hans/cpufreq.po"

if [ -d "$cpu_path" ] && [ -f "$po_file" ]; then
    sed -i 's/msgstr "CPU 性能优化调节"/msgstr "性能调节"/g' "$po_file"
    echo "cpu调节更名成功"
else
    echo "cpufreq.po文件未找到"
fi

#修改Argon 主题设置名称显示
argon_path="$GITHUB_WORKSPACE/wrt/feeds/luci/themes/luci-theme-argon"
argonpo_file="$argon_path/po/zh_Hans/argon-config.po"

if [ -d "$argon_path" ] && [ -f "$argonpo_file" ]; then
    sed -i 's/msgstr "Argon 主题设置"/msgstr "主题设置"/g' "$argonpo_file"
    echo "主题设置更名成功"
else
    echo "argon-config.po文件没有找到"
fi

#修改Vlmcsd KMS名称显示
Vlmcsd_path="$GITHUB_WORKSPACE/wrt/feeds/luci/applications/luci-app-vlmcsd"
Vlmcsdpo_file="$Vlmcsd_path/po/zh_Hans/vlmcsd.po"

if [ -d "$Vlmcsd_path" ] && [ -f "$Vlmcsdpo_file" ]; then
    sed -i 's/msgstr "Vlmcsd KMS 服务器"/msgstr "KMS服务"/g' "$Vlmcsdpo_file"
    echo "Vlmcsd KMS更名成功"
else
    echo "vlmcsd.po文件没有找到"
fi

#更换argon源
#argon_url="https://github.com/huanchenshang/luci-theme-argon.git"
#dst_theme_path="../feeds/luci/themes/luci-theme-argon"
#tmp_dir=$(mktemp -d)
#
#    git clone --depth 1 "$argon_url" "$tmp_dir"
#
#    rm -rf "$dst_theme_path"
#    rm -rf "$tmp_dir/.git"
#    mv "$tmp_dir" "$dst_theme_path"
#
#    echo "luci-theme-argon 更新完成"

#修改argon背景图片
#theme_path="$GITHUB_WORKSPACE/wrt/feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img"
#source_path="$GITHUB_WORKSPACE/images"
#source_file="$source_path/bg1.jpg"
#target_file="$theme_path/bg1.jpg"
#
#if [ -f "$source_file" ]; then
#    cp -f "$source_file" "$target_file"
#    echo "背景图片更新成功"
#else
#    echo "错误：未找到源图片文件"
#fi

#修改automount自动加载和修复ntfs硬盘显示中文
# 注意: 上游 fstools-2026.10.18 已重构 handle_mount(改用 mount_opts_get/exec_mount),
# 老 0100/0200 patch 按行号打必然 FAILED,改用与版本无关的 sed 直接改源码
fstools_path="$GITHUB_WORKSPACE/wrt/package/system/fstools/patches"
BLOCK_C="$GITHUB_WORKSPACE/wrt/package/system/fstools/block.c"
if [ -f "$BLOCK_C" ]; then
    # 删除会打失败的老补丁,避免 block.c.rej 导致编译中断
    rm -f "$fstools_path/0100-automount.patch" "$fstools_path/0200-ntfs3-with-utf8.patch"
    # 自动挂载: enabled '0'->'1', anon_mount '0'->'1' (用单引号避免转义坑)
    sed -i 's/enabled\\t'"'0'"'/enabled\\t'"'1'"'/g' "$BLOCK_C"
    sed -i 's/anon_mount\\t'"'0'"'/anon_mount\\t'"'1'"'/g' "$BLOCK_C"
    # ntfs/fat 默认 utf8: 保留老0200补丁的本意(仅fat/ntfs才给iocharset,避免污染ext4/btrfs)
    # 老补丁: if (strstr(fstype,"fat")||strstr(fstype,"ntfs")) _data="iocharset=utf8..."; mount(...: _data)
    # 新block.c仍有 handle_mount(source,target,fstype,m) + mount(...(m && m->options) ? m->options : ""),直接把""换成条件式即可,行号无关
    if grep -q '(m && m->options) ? m->options : ""' "$BLOCK_C"; then
        sed -i 's/(m && m->options) ? m->options : ""/(m \&\& m->options) ? m->options : ((strstr(fstype, "fat") || strstr(fstype, "ntfs")) ? "iocharset=utf8,uid=65534,gid=65534" : "")/g' "$BLOCK_C"
        echo "fstools block.c 已用sed修复(automount+ntfs utf8,仅fat/ntfs生效)!"
    else
        echo "警告: block.c 未找到 mount 默认 options 行,跳过ntfs utf8 sed"
    fi
else
    echo "错误：未找到 $BLOCK_C,跳过fstools sed修复"
fi

#添加定时清理内存
#sh_dir="$GITHUB_WORKSPACE/wrt/package/base-files/files/etc/init.d"
#if [ -d "$sh_dir" ]; then
#    cat <<'EOF' >"$sh_dir/custom_task"
#!/bin/sh /etc/rc.common
# 设置启动优先级
#START=99
#
#boot() {
    # 重新添加缓存请求定时任务
#    sed -i '/drop_caches/d' /etc/crontabs/root
#    echo "15 3 * * * sync && echo 3 > /proc/sys/vm/drop_caches" >>/etc/crontabs/root
    # 应用新的 crontab 配置
#    crontab /etc/crontabs/root
#}
#EOF
#    chmod +x "$sh_dir/custom_task"
#    echo "添加定时清理内存成功!"
#else
#    echo "添加定时清理内存出错"
#fi

#设置使用bbr加速
BBR_CONF_PATH="$GITHUB_WORKSPACE/wrt/package/base-files/files/etc/sysctl.d/10-bbr.conf"
if [ ! -f "$BBR_CONF_PATH" ]; then
    cat <<'EOF' >"$BBR_CONF_PATH"
net.core.default_qdisc=fq
#net.ipv4.tcp_congestion_control=bbr
EOF
    echo "BBR 配置文件创建成功！"
fi

#允许安装未签名apk
APK_CONF="$GITHUB_WORKSPACE/wrt/package/base-files/files/etc/apk/config"
mkdir -p "$(dirname "$APK_CONF")"
echo "allow-untrusted" > "$APK_CONF"
echo "apk allow-untrusted 已设置!"

#修复unishare：未启用webdav共享时不再常驻webdav2
#上游 small-package/unishare/files/unishare.init 的 start_service() 无条件启动 webdav2，
#即使 share proto 只选了 samba 也会多出 /usr/sbin/webdav2 :8888 (约10MB RSS)。
#补丁：在 config_webdav 后检查 /var/run/unishare/root 是否为空，为空则直接 return，不起 daemon。
#Handles.sh 执行时 cwd 为 wrt/package，unishare 刚被 Packages.sh 以 pkg 模式拷到 ./unishare
UNISHARE_INIT="./unishare/files/unishare.init"
if [ -f "$UNISHARE_INIT" ]; then
    if ! grep -q "skip webdav2 when no webdav shares" "$UNISHARE_INIT"; then
        awk '
        /config_webdav \|\| return 1/ {
            print
            print "    # patch: skip webdav2 when no webdav shares"
            print "    if ls /var/run/unishare/root/* >/dev/null 2>&1; then"
            print "        :"
            print "    else"
            print "        return 0"
            print "    fi"
            print ""
            next
        }
        {print}
        ' "$UNISHARE_INIT" > /tmp/unishare.init.new && mv /tmp/unishare.init.new "$UNISHARE_INIT"
        echo "unishare已被修复(无webdav共享时跳过webdav2)!"
    else
        echo "unishare补丁已存在，跳过!"
    fi
else
    echo "未找到 $UNISHARE_INIT，跳过unishare修复"
fi

#nginx单worker：LuCI后台1个worker足够，4核默认auto会起4个，多占约15-20MB
#模板在 feeds/packages/net/nginx-util，uci.conf每次启动由模板重建，直接改uci.conf无效
for f in $(find ../feeds/packages/ -maxdepth 4 -type f -name "uci.conf.template" 2>/dev/null); do
    if grep -q "worker_processes auto;" "$f"; then
        sed -i 's/worker_processes auto;/worker_processes 1;/' "$f"
        echo "nginx已修复($f: worker_processes 1)!"
    fi
done
#兜底：当前package目录也找一下(不同feed布局)
for f in $(find ./ -maxdepth 4 -type f -name "uci.conf.template" 2>/dev/null); do
    if grep -q "worker_processes auto;" "$f"; then
        sed -i 's/worker_processes auto;/worker_processes 1;/' "$f"
        echo "nginx已修复($f: worker_processes 1)!"
    fi
done

