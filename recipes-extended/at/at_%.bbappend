FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://at-tmpfiles.conf"

do_install_append() {
    install -Dm0644 ${WORKDIR}/at-tmpfiles.conf ${D}${exec_prefix}/lib/tmpfiles.d/at.conf
}

FILES_${PN} += "${exec_prefix}/lib/tmpfiles.d/at.conf"
