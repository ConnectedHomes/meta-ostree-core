FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://nfs-utils-client-tmpfiles.conf"

do_install_append() {
    install -Dm0644 ${WORKDIR}/nfs-utils-client-tmpfiles.conf ${D}${exec_prefix}/lib/tmpfiles.d/nfs-utils-client.conf
}

FILES_${PN}-client += "${exec_prefix}/lib/tmpfiles.d/nfs-utils-client.conf"
