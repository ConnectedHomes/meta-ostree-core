do_install_append() {
    rm ${D}/${datadir}/refkit-ostree/hooks/post-apply.d/00-update-uefi-app
}
