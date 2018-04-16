DESCRIPTION = "Versioned Operating System Repository."
HOMEPAGE = "https://ostree.readthedocs.io"
LICENSE = "LGPLv2.1"

LIC_FILES_CHKSUM = "file://COPYING;md5=5f30f0716dfdd0d91eb439ebec522ec2"

SRC_URI = " \
    gitsm://git@github.com/ostreedev/ostree;protocol=https \
    file://0001-autogen.sh-fall-back-to-no-gtkdocize-if-it-is-there-.patch \
    file://0001-ostree-tmpfiles-Include-ref-changes.patch \
    file://0001-switchroot-Don-t-log-if-running-as-pid1-minor-code-s.patch \
"

SRCREV = "d699a968623e238cf1f835a1a69852d78cc8a283"

PV := "${PV}+git${SRCPV}"
S = "${WORKDIR}/git"

inherit autotools pkgconfig gobject-introspection distro_features_check systemd
REQUIRED_DISTRO_FEATURES_class-target = "systemd"

do_install_append_class-target () {
    rm -r ${D}${sysconfdir}/grub.d
    rm ${D}${libexecdir}/libostree/grub2-15_ostree
}

DEPENDS = " \
    glib-2.0 libsoup-2.4 gpgme e2fsprogs \
    libcap fuse libarchive zlib xz \
    systemd \
"

DEPENDS_class-native = " \
    glib-2.0-native libsoup-2.4-native gpgme-native e2fsprogs-native \
    libcap-native fuse-native libarchive-native zlib-native xz-native \
"

RDEPENDS_${PN}_class-target = " \
    gnupg \
    ${PN}-prepare-root \
"

AUTO_LIBNAME_PKGS = ""

# package configuration
PACKAGECONFIG ??= ""

PACKAGECONFIG[curl] = "--with-curl, --without-curl, curl"
PACKAGECONFIG[man] = "--enable-man, --disable-man"
PACKAGECONFIG[no-http2] = "--disable-http2"

EXTRA_OECONF += " \
    --with-static-compiler='${CC} ${CFLAGS} ${CPPFLAGS} ${LDFLAGS}' \
"

EXTRA_OECONF_class-native += " \
    --with-builtin-grub2-mkconfig \
    --enable-wrpseudo-compat \
    --disable-otmpfile \
"

# package content
PACKAGES += " \
    ${PN}-systemd-generator \
    ${PN}-bash-completion \
    ${PN}-prepare-root \
"

SYSTEMD_SERVICE_${PN} = "ostree-remount.service"
SYSTEMD_SERVICE_${PN}-prepare-root = "ostree-prepare-root.service"

FILES_${PN} = " \
    ${bindir}/* \
    ${sysconfdir} \
    ${libdir}/lib*${SOLIBS} \
    ${libdir}/girepository-1.0 \
    ${libdir}/tmpfiles.d/ostree*.conf \
    ${libdir}/${BPN}/ostree-remount \
    ${datadir}/${BPN} \
    ${datadir}/gir-1.0 \
    ${libexecdir}/* \
"
FILES_${PN}-systemd-generator = "${libdir}/systemd/system-generators"
FILES_${PN}-bash-completion = "${datadir}/bash-completion/completions/ostree"
FILES_${PN}-prepare-root = " \
    ${libdir}/ostree/ostree-prepare-root \
    ${libdir}/systemd/system/ostree-prepare-root.service \
"

do_configure_prepend() {
    cd ${S}
    NOCONFIGURE=1 ./autogen.sh
    cd -
}

BBCLASSEXTEND = "native"
