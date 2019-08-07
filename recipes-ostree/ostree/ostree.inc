SUMMARY = "Versioned Operating System Repository."
DESCRIPTION = "libostree is both a shared library and suite of command line tools that combines a \"git-like\" model for committing and downloading bootable filesystem trees, along with a layer for deploying them and managing the bootloader configuration."
HOMEPAGE = "https://ostree.readthedocs.io"
LICENSE = "LGPLv2.1"

LIC_FILES_CHKSUM = "file://COPYING;md5=5f30f0716dfdd0d91eb439ebec522ec2"

DEPENDS = " \
    glib-2.0 \
    gpgme \
    e2fsprogs \
    libcap \
    zlib \
    xz \
    bison-native \
"

# The Yocto mirror has an old export of ostree:
# http://downloads.yoctoproject.org/mirror/sources/git2_github.com.ostreedev.ostree.tar.gz
PREMIRRORS = ""

SRC_URI = "gitsm://github.com/ostreedev/ostree \
           file://0001-autogen.sh-fall-back-to-no-gtkdocize-if-it-is-there-.patch \
           file://ostree-reffiles.conf \
           "
UPSTREAM_CHECK_GITTAGREGEX = "v(?P<pver>\d+\.\d+)"

S = "${WORKDIR}/git"

inherit autotools pkgconfig gobject-introspection systemd

# package configuration - match ostree defaults
PACKAGECONFIG ??= " \
    ${@bb.utils.filter('DISTRO_FEATURES', 'selinux smack', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd libmount', '', d)} \
    rofiles-fuse \
    soup \
"

PACKAGECONFIG[avahi] = "--with-avahi, --without-avahi, avahi"
PACKAGECONFIG[curl] = "--with-curl, --without-curl, curl"
PACKAGECONFIG[gnutls] = "--with-crypto=gnutls, , gnutls"
PACKAGECONFIG[libarchive] = "--with-libarchive, --without-libarchive, libarchive"
PACKAGECONFIG[libmount] = "--with-libmount, --without-libmount, util-linux"
PACKAGECONFIG[man] = "--enable-man, --disable-man"
PACKAGECONFIG[no-http2] = "--disable-http2, --enable-http2"
PACKAGECONFIG[openssl] = "--with-crypto=openssl, , openssl"
PACKAGECONFIG[rofiles-fuse] = "--enable-rofiles-fuse, --disable-rofiles-fuse, fuse"
PACKAGECONFIG[selinux] = "--with-selinux, --without-selinux, libselinux"
PACKAGECONFIG[smack] = "--with-smack, --without-smack, smack"
PACKAGECONFIG[soup] = "--with-soup, --without-soup --disable-glibtest, libsoup-2.4"
PACKAGECONFIG[static] = ""
PACKAGECONFIG[systemd] = "--with-libsystemd --with-systemdsystemunitdir=${systemd_unitdir}/system, --without-libsystemd, systemd"

# --disable-gtk-doc
# --disable-gtk-doc-html
# --disable-gtk-doc-pdf
# --with-builtin-grub2-mkconfig
# --enable-wrpseudo-compat
# --disable-otmpfile"

EXTRA_OECONF = " \
    ${@bb.utils.contains('PACKAGECONFIG', 'static', '--with-static-compiler=\'${CC} ${CFLAGS} ${CPPFLAGS} ${LDFLAGS}\'', '', d)} \
"

EXTRA_OECONF_class-native += " \
    --with-builtin-grub2-mkconfig \
    --enable-wrpseudo-compat \
    --disable-otmpfile \
    --without-soup --disable-glibtest \
    --disable-rofiles-fuse \
    --without-libarchive \
"

do_configure_prepend() {
    cd ${S}
    NOCONFIGURE=1 ./autogen.sh
    cd -
}

do_install_append_class-target () {
    rm -r ${D}${sysconfdir}/grub.d
    rm ${D}${libexecdir}/libostree/grub2-15_ostree
    install -Dm0644 ${WORKDIR}/ostree-reffiles.conf ${D}${exec_prefix}/lib/tmpfiles.d/ostree-reffiles.conf
}

AUTO_LIBNAME_PKGS = ""

# package content
PACKAGES += " \
    ${PN}-bash-completion \
    ${PN}-prepare-root \
"

FILES_${PN} = " \
    ${bindir}/ \
    ${sysconfdir} \
    ${libdir}/lib*${SOLIBS} \
    ${libdir}/girepository-1.0 \
    ${libdir}/tmpfiles.d/ostree*.conf \
    ${libdir}/${BPN}/ostree-remount \
    ${libdir}/systemd/system-generators \
    ${libdir}/systemd/system/ostree-* \
    ${datadir}/${BPN} \
    ${datadir}/gir-1.0 \
    ${libexecdir}/ \
"
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

SYSTEMD_SERVICE_${PN} = "ostree-remount.service ostree-finalize-staged.path"
SYSTEMD_SERVICE_${PN}-prepare-root = "ostree-prepare-root.service"

BBCLASSEXTEND = "native"
