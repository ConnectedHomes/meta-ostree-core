SUMMARY = "IoT RefKit ostree helper, scripts, services, et al."

LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE-BSD;md5=f9f435c1bd3a753365e799edf375fc42"

SRC_URI = "git://github.com/klihub/refkit-ostree-upgrade.git \
           file://0001-refkit-ostree-Use-nano-distribution.patch \
           file://0001-post-update-check-Merge-changes-from-refkit-core.patch \
           file://0001-refkit-ostree-Remove-unused-script.patch \
           file://0002-refkit-ostree-Conditionalise-UPDATER_MODE_PREPARE.patch \
           file://0003-Conditionalise-UPDATER_MODE_PATCH.patch \
           file://0004-refkit-ostree-Fix-warnings.patch \
           "

# Modify these as desired
PV = "0.0.0+git${SRCPV}"
SRCREV = "3b8c59421d67fea1b24e51ae6682a6a853702584"

S = "${WORKDIR}/git"

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
