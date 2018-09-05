SUMMARY = "Versioned Operating System Repository."
DESCRIPTION = "libostree is both a shared library and suite of command line tools that combines a "git-like" model for committing and downloading bootable filesystem trees, along with a layer for deploying them and managing the bootloader configuration."
HOMEPAGE = "https://ostree.readthedocs.io"
LICENSE = "LGPLv2.1"

LIC_FILES_CHKSUM = "file://COPYING;md5=5f30f0716dfdd0d91eb439ebec522ec2"

DEPENDS = " \
    glib-2.0 libsoup-2.4 gpgme e2fsprogs \
    libcap libarchive zlib xz \
    bison-native systemd \
    ${@bb.utils.contains('PACKAGECONFIG', 'rofiles-fuse', 'fuse', '', d)} \
"

DEPENDS_class-native = " \
    glib-2.0-native libsoup-2.4-native gpgme-native e2fsprogs-native \
    libcap-native libarchive-native zlib-native xz-native \
    bison-native \
    ${@bb.utils.contains('PACKAGECONFIG', 'rofiles-fuse', 'fuse-native', '', d)} \
"

PV .= "+git${SRCPV}"

SRC_URI = "gitsm://git@github.com/ostreedev/ostree;protocol=https \
           file://0001-autogen.sh-fall-back-to-no-gtkdocize-if-it-is-there-.patch \
           file://0001-ostree-tmpfiles-Include-ref-changes.patch \
           "

SRCREV = "7aa242c34cbfde2cd09d36d1ee2b32166287d9b6"

S = "${WORKDIR}/git"

inherit autotools pkgconfig gobject-introspection distro_features_check systemd
REQUIRED_DISTRO_FEATURES_class-target = "systemd"

# package configuration - match ostree defaults
PACKAGECONFIG ??= "rofiles-fuse"

PACKAGECONFIG[curl] = "--with-curl, --without-curl, curl"
PACKAGECONFIG[man] = "--enable-man, --disable-man"
PACKAGECONFIG[rofiles-fuse] = "--enable-rofiles-fuse, --disable-rofiles-fuse"
PACKAGECONFIG[no-http2] = "--disable-http2"

EXTRA_OECONF += " \
    --with-static-compiler='${CC} ${CFLAGS} ${CPPFLAGS} ${LDFLAGS}' \
"

EXTRA_OECONF_class-native += " \
    --with-builtin-grub2-mkconfig \
    --enable-wrpseudo-compat \
    --disable-otmpfile \
"

do_configure_prepend() {
    cd ${S}
    NOCONFIGURE=1 ./autogen.sh
    cd -
}

do_install_append_class-target () {
    rm -r ${D}${sysconfdir}/grub.d
    rm ${D}${libexecdir}/libostree/grub2-15_ostree
}

AUTO_LIBNAME_PKGS = ""

# package content
PACKAGES += " \
    ${PN}-systemd-generator \
    ${PN}-bash-completion \
    ${PN}-prepare-root \
"

FILES_${PN} = " \
    ${bindir}/* \
    ${sysconfdir} \
    ${libdir}/lib*${SOLIBS} \
    ${libdir}/girepository-1.0 \
    ${libdir}/tmpfiles.d/ostree*.conf \
    ${libdir}/${BPN}/ostree-remount \
    ${libdir}/systemd/system/ostree-finalize-staged.service \
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

RDEPENDS_${PN}_class-target = " \
    gnupg \
    ${PN}-prepare-root \
"

RRECOMMENDS_${PN} += "kernel-module-overlay"

SYSTEMD_SERVICE_${PN} = "ostree-remount.service"
SYSTEMD_SERVICE_${PN}-prepare-root = "ostree-prepare-root.service"

BBCLASSEXTEND = "native"
