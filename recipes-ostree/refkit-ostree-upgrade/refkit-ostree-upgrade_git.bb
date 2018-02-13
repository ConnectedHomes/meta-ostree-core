SUMMARY = "IoT RefKit ostree helper, scripts, services, et al."

LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE-BSD;md5=f9f435c1bd3a753365e799edf375fc42"

SRC_URI = "git://git@github.com/intel/intel-iot-refkit.git;subpath=meta-refkit-core/recipes-ostree/refkit-ostree/files/refkit-ostree \
           file://0001-refkit-ostree-Use-nano-distribution.patch \
           file://0002-refkit-ostree-Conditionalise-UPDATER_MODE_PREPARE.patch \
           file://0003-Conditionalise-UPDATER_MODE_PATCH.patch \
           file://0004-refkit-ostree-Fix-warnings.patch \
           file://0001-Remove-refkit-patch-ostree-param.service.patch \
           file://00-update-uboot;subdir=git/hooks/post-apply.d \
           "

# Modify these as desired
PV = "0.0.0+git${SRCPV}"
SRCREV = "b90b795a69bbfdce1df85b77a5df52fc14458d1e"

S = "${WORKDIR}/refkit-ostree"

DEPENDS = "ostree"

inherit autotools pkgconfig systemd distro_features_check

REQUIRED_DISTRO_FEATURES = "ostree systemd"

PACKAGES += "${PN}-initramfs"

FILES_${PN}-initramfs = " \
    ${bindir}/refkit-ostree \
"

FILES_${PN} = " \
    ${bindir}/refkit-ostree-update \
    ${systemd_unitdir}/system/* \
    ${datadir}/refkit-ostree \
"

# Our systemd services.
SYSTEMD_SERVICE_${PN} = " \
    refkit-update.service \
    refkit-reboot.service \
    refkit-update-post-check.service \
"

EXTRA_OECONF += " \
    --with-systemdunitdir=${systemd_unitdir}/system \
"

RDEPENDS_${PN} += "ostree"

do_install_append() {
    rm ${D}/${datadir}/refkit-ostree/hooks/post-apply.d/00-update-uefi-app
}
