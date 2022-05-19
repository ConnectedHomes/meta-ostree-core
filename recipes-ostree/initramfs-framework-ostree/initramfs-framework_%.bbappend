FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://initramfs-framework.patch \
"

RDEPENDS:initramfs-module-rootfs:append = " \
    util-linux-fsck \
    e2fsprogs-e2fsck \
"
