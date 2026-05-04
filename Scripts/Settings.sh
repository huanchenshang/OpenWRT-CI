#!/bin/bash

# 修改 ttyd 为免密自动登录
sed -i 's|/bin/login|/bin/login -f root|g' ./feeds/packages/utils/ttyd/files/ttyd.config
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
#添加wifi参数
WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
WIFI_CU="$GITHUB_WORKSPACE/files/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_CU" ] && [ -f "$WIFI_UC" ]; then
	#替换修改的WIFI配置文件
 	cp -f "$WIFI_CU" "$WIFI_UC"
	#修改WIFI名称
	sed -i "s/ImmortalWrt/'$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#设置NSS版本
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config

	#无WIFI配置调整Q6大小
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi

# 关闭dns重定向
dhcp_file="./package/network/services/dnsmasq/files/dhcp.conf"
if [ -f "$dhcp_file" ]; then
    sed -i "s/option dns_redirect\t1/option dns_redirect\t0/g" "$dhcp_file"
fi

#亚瑟修复USB2.0日志报错问题
wget -qO - https://github.com/davidtall/immortalwrt/commit/ce39feb4.patch | patch -p1
cat ./target/linux/qualcommax/dts/ipq6000-re-ss-01.dts

# --- 以下为添加 dae eBPF 支持的修复版 ---

# 1. 内核底层配置 (config-default)
conde_file="./target/linux/qualcommax/ipq60xx/config-default"
if [ -f "$conde_file" ]; then
    # 先清理掉可能存在的旧配置，防止重复追加
    sed -i '/CONFIG_BPF/d; /CONFIG_DEBUG_INFO_BTF/d; /CONFIG_TRANSPARENT_HUGEPAGE/d' "$conde_file"
    
    cat >> "$conde_file" <<EOF
CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_BPF_JIT=y
CONFIG_CGROUPS=y
CONFIG_KPROBES=y
CONFIG_NET_INGRESS=y
CONFIG_NET_EGRESS=y
CONFIG_NET_SCH_INGRESS=m
CONFIG_NET_CLS_BPF=m
CONFIG_NET_CLS_ACT=y
CONFIG_BPF_STREAM_PARSER=y
CONFIG_DEBUG_INFO=y
# CONFIG_DEBUG_INFO_REDUCED is not set
CONFIG_DEBUG_INFO_BTF=y
CONFIG_KPROBE_EVENTS=y
CONFIG_BPF_EVENTS=y
CONFIG_TRANSPARENT_HUGEPAGE=y
CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS=y
# 修复 6.18 内核编译中断的关键项
CONFIG_PERSISTENT_HUGE_ZERO_FOLIO=n
EOF
    echo "内核 eBPF 配置已修正并注入到 $conde_file"
fi

# 2. 全局编译配置 (.config)
config_file="./.config"
if [ -f "$config_file" ]; then
    # 确保全局层面也同步开启 BTF 支持
    cat >> "$config_file" <<EOF
CONFIG_DEVEL=y
CONFIG_KERNEL_DEBUG_INFO=y
CONFIG_KERNEL_DEBUG_INFO_REDUCED=n
CONFIG_KERNEL_DEBUG_INFO_BTF=y
CONFIG_KERNEL_CGROUPS=y
CONFIG_KERNEL_CGROUP_BPF=y
CONFIG_KERNEL_BPF_EVENTS=y
CONFIG_BPF_TOOLCHAIN_HOST=y
CONFIG_KERNEL_XDP_SOCKETS=y
CONFIG_PACKAGE_kmod-xdp-sockets-diag=y
EOF
    echo "全局 eBPF 标志位已注入到 .config"
fi

# 3. 修改内核大小 (保持你原有的逻辑，但确保路径正确)
image_file="./target/linux/qualcommax/image/ipq60xx.mk"
if [ -f "$image_file" ]; then
    # 扩大内核分区空间，防止开启 BTF 后固件超限
    sed -i 's/KERNEL_SIZE := 6144k/KERNEL_SIZE := 12288k/g' "$image_file"
    sed -i 's/KERNEL_SIZE := 8192k/KERNEL_SIZE := 12288k/g' "$image_file"
    echo "内核分区已扩容至 12M: $image_file"
fi