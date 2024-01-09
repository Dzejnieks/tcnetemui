include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI user interface for Traffic Control Network Emulation tool
LUCI_DEPENDS:=+tc-full +kmod-netem +bash +luci-base +lua +luci-compat
LUCI_DESCRIPTION:=LuCI user interface for Traffic Control Network Emulation tool
LUCI_PKGARCH:=all
PKG_VERSION:=v1.4.4
include $(TOPDIR)/feeds/luci/luci.mk

# Define post-installation script
define Package/tcnetemui/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Executing post-installation script."

    # Path to the WPS script
    WPS_SCRIPT_PATH="/etc/rc.button/wps"

    # Backup the existing WPS script, if it exists
    [ -f "$WPS_SCRIPT_PATH" ] && mv "$WPS_SCRIPT_PATH" "${WPS_SCRIPT_PATH}.backup"

    # Create the new WPS script
    cat << "EOF" > "$WPS_SCRIPT_PATH"
    #!/bin/sh

    wan_ifname=\$$(uci get network.wan.ifname)
    lan_ifname=\$$(uci get network.lan.ifname)

    wan_ifname=\$${wan_ifname:-"eth0.2"}
    lan_ifname=\$${lan_ifname:-"br-lan"}

    if [ "\$$ACTION" = "released" ] && [ "\$$BUTTON" = "wps" ]; then
        if [ "\$$SEEN" -lt 3 ] ; then
            tc qdisc del dev "\$$lan_ifname" root
            tc qdisc del dev "\$$wan_ifname" root
        else
            wps_done=0
            ubusobjs=\$$(ubus -S list hostapd.*)
            for ubusobj in \$\$ubusobjs; do
                ubus -S call \$\$ubusobj wps_start && wps_done=1
            done
            [ \$\$wps_done = 1 ] && exit 0

            wps_done=0
            ubusobjs=\$$(ubus -S list wpa_supplicant.*)
            for ubusobj in \$\$ubusobjs; do
                ifname=\$$(echo \$\$ubusobj | cut -d'.' -f2)
                multi_ap=""
                if [ -e "/var/run/wpa_supplicant-\$${ifname}.conf.is_multiap" ]; then
                    ubus -S call \$\$ubusobj wps_start '{ "multi_ap": true }' && wps_done=1
                else
                    ubus -S call \$\$ubusobj wps_start && wps_done=1
                fi
            done
            [ \$\$wps_done = 1 ] || wps_catch_credentials &
        fi
    fi
    EOF
    chmod +x "$WPS_SCRIPT_PATH"
fi
exit 0
endef

# call BuildPackage - OpenWrt buildroot signature