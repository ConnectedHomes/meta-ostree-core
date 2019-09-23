FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://ostree-reffiles.conf"

do_install_append_class-target () {
    install -Dm0644 ${WORKDIR}/ostree-reffiles.conf ${D}${exec_prefix}/lib/tmpfiles.d/ostree-reffiles.conf
}

FILES_${PN} += " \
    ${libdir}/tmpfiles.d/ostree-reffiles.conf \
"
