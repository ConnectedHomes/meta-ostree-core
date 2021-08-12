FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://at-tmpfiles.conf"

do_install:append() {
    install -Dm0644 ${WORKDIR}/at-tmpfiles.conf ${D}${exec_prefix}/lib/tmpfiles.d/at.conf
}

FILES:${PN} += "${exec_prefix}/lib/tmpfiles.d/at.conf"
