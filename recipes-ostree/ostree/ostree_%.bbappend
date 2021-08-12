FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://ostree-reffiles.conf"

do_install:append:class-target () {
    install -Dm0644 ${WORKDIR}/ostree-reffiles.conf ${D}${exec_prefix}/lib/tmpfiles.d/ostree-reffiles.conf
}

FILES:${PN} += " \
    ${libdir}/tmpfiles.d/ostree-reffiles.conf \
"
