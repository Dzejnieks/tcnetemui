include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI user interface for Traffic Control Network Emulation tool
LUCI_DEPENDS:=+tc-full +kmod-netem +bash +luci-base +lua +luci-compat
LUCI_DESCRIPTION:=LuCI user interface for Traffic Control Network Emulation tool
LUCI_PKGARCH:=all
PKG_VERSION:=1.4.1
include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature