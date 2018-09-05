FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://initramfs-framework.patch \
"

RDEPENDS_initramfs-module-rootfs_append += " \
    util-linux-fsck \
    e2fsprogs-e2fsck \
"
