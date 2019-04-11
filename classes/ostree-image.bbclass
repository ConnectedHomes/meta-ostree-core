# Support for OSTree-upgradable images.
#
# This class adds support for building images with OSTree system
# update support. It is an addendum to refkit-image.bbclass (i.e.
# not tested with anything else) and is supposed to be inherited
# by it conditionally when the "ostree" distro feature is set.
#
# When enabled both in the distro and image, the class adds:
#
#     - publishing builds to an HTTP-serviceable repository
#     - boot-time selection of the most recent rootfs tree
#     - booting an OSTree enabled image into a rootfs
#     - pulling in image upgrades using OSTree
#
###########################################################################

# Declare an image feature for OSTree-upgradeable images.
# OSTree support in the image is still off unless that
# feature gets selected elsewhere.
IMAGE_FEATURES[validitems] += " \
    ostree \
"

FEATURE_PACKAGES_ostree = " \
    ostree \
    ostree-systemd-generator \
    os-release \
"

# Additional sanity checking. Complements ostree-sanity in INHERIT.
REQUIRED_DISTRO_FEATURES += "ostree usrmerge"
inherit distro_features_check

# Force the removal of the packages listed in ROOTFS_RO_UNNEEDED during
# the generation of the root filesystem
FORCE_RO_REMOVE = "1"

###########################################################################

# These are intermediate working directories that are not meant to
# be overridden:
# - build content as it gets committed to the OSTree repos
# - intermediate, bare OSTree repo
# - rootfs with OSTree set up
OSTREE_SYSROOT = "${WORKDIR}/ostree-sysroot"
OSTREE_BARE = "${WORKDIR}/ostree-repo"
OSTREE_ROOTFS = "${IMAGE_ROOTFS}.ostree"

# OS deployment name on the target device.
OSTREE_OS ?= "${DISTRO}"

# Each image is committed to its own, unique branch.
OSTREE_BRANCHNAME ?= "${DISTRO}/${DISTRO_CODENAME}/${MACHINE}/${PN}"

# The subject of the commit that gets added to OSTREE_BRANCHNAME for
# the current build.
OSTREE_COMMIT_SUBJECT ?= 'Build ${BUILD_ID} of ${PN} in ${DISTRO} (${DISTRO_CODENAME})'

# This is where we export our builds in archive-z2 format. This repository
# can be exposed over HTTP for clients to pull upgrades from. It can be
# shared between different distributions, architectures and images
# because each image has its own branch in the common repository.
#
# Beware that this repo is under TMPDIR by default. Just like other
# build output it should be moved to a permanent location if it
# is meant to be preserved after a successful build (for example,
# with "ostree pull-local" in a permanent repo), or the variable
# needs to point towards an external directory which exists
# across builds.
#
# This can be set to an empty string to disable publishing.
OSTREE_REPO ?= "${DEPLOY_DIR}/ostree-repo"

# OSTREE_GPGDIR is where our GPG keyring is located at and
# OSTREE_GPGID is the default key ID we use to sign (commits in) the
# repository. These two need to be customized for real builds.
#
# In development images the default is to use a pregenerated key from
# an in-repo keyring. Production images do not have a default.
#
OSTREE_GPGDIR ?= "${@ '' if (d.getVar('IMAGE_MODE') or 'production') == 'production' else '${META_OSTREE_CORE_BASE}/files/gnupg' }"
OSTREE_GPGID_DEFAULT = "${@d.getVar('DISTRO').replace(' ', '_') + '-development-signing@key'}"
OSTREE_GPGID ?= "${@ '' if (d.getVar('IMAGE_MODE') or 'production') == 'production' else '${OSTREE_GPGID_DEFAULT}' }"

python () {
    if bb.utils.contains('IMAGE_FEATURES', 'ostree', True, False, d) and \
       not d.getVar('OSTREE_GPGID'):
        raise bb.parse.SkipRecipe('OSTREE_GPGID not set')
}

# OSTree remote (HTTP URL) where updates will be published.
# Host the content of OSTREE_REPO there.
OSTREE_REMOTE ?= "https://update.example.org/ostree/"

# These variables are read by OSTreeUpdate and thus contribute to the vardeps.
def ostree_update_vardeps(d):
    from ostree.ostreeupdate import VARIABLES
    return ' '.join(VARIABLES)

# Take a pristine rootfs as input, shuffle its layout around to make it
# OSTree-compatible, commit the rootfs into a per-build bare-user OSTree
# repository, and finally produce an OSTree-enabled rootfs by cloning
# and checking out the rootfs as an OSTree deployment.
fakeroot python do_ostree_prepare_rootfs () {
    from ostree.ostreeupdate import OSTreeUpdate
    OSTreeUpdate(d).prepare_rootfs()
}
do_ostree_prepare_rootfs[vardeps] += "${@ ostree_update_vardeps(d) }"

# .pub/.sec keys get created in the current directory, so
# we have to be careful to always run from the same directory,
# regardless of the image.
do_ostree_prepare_rootfs[dirs] = "${TOPDIR}"

def get_file_list(filenames):
    filelist = []
    for filename in filenames:
        filelist.append(filename + ":" + str(os.path.exists(filename)))
    return ' '.join(filelist)

#do_ostree_prepare_rootfs[file-checksums] += "${@get_file_list(( \
#   '${FLATPAKBASE}/scripts/gpg-keygen.sh', \
#)}"

# TODO: ostree-native depends on ca-certificates,
# and is probably affected by https://bugzilla.yoctoproject.org/show_bug.cgi?id=9883.
# At least there are warnings in log.do_ostree_prepare_rootfs:
# (ostree:42907): GLib-Net-WARNING **: couldn't load TLS file database: Failed to open file '/fast/build/refkit/intel-corei7-64/tmp-glibc/work/x86_64-linux/glib-networking-native/2.50.0-r0/recipe-sysroot-native/etc/ssl/certs/ca-certificates.crt': No such file or directory
#
# In practice all our operations are local, so this probably
# doesn't matter.
do_ostree_prepare_rootfs[depends] += " \
    ostree-native:do_populate_sysroot \
    gnupg1-native:do_populate_sysroot \
"

# Take a per-build OSTree bare-user repository and export it to an
# archive-z2 repository which can then be exposed over HTTP for
# OSTree clients to pull in upgrades from.
fakeroot python do_ostree_publish_rootfs () {
    if d.getVar('OSTREE_REPO'):
       from ostree.ostreeupdate import OSTreeUpdate
       OSTreeUpdate(d).export_repo()
    else:
       bb.note("OSTree: OSTREE_REPO repository not set, not publishing.")
}
do_ostree_publish_rootfs[vardeps] += "${@ ostree_update_vardeps(d) }"

python () {
    # Don't do anything when OSTree image feature is off.
    if bb.utils.contains('IMAGE_FEATURES', 'ostree', True, False, d):
        # We must do this after do_image, because do_image
        # is still allowed to make changes to the files (for example,
        # prelink_image in IMAGE_PREPROCESS_COMMAND)
        #
        # We rely on wic to produce the actual images, so we inject our
        # custom rootfs creation task right before that.
        bb.build.addtask('do_ostree_prepare_rootfs', 'do_image_wic', 'do_image', d)

        # Publishing can run in parallel to wic image creation.
        bb.build.addtask('do_ostree_publish_rootfs', 'do_image_complete', 'do_ostree_prepare_rootfs', d)
}

# Create /usr/lib/ostree-boot/uEnv.txt
python install_ostree_boot_uenv () {
    import os

    uenvflags = d.getVarFlags('OSTREE_BOOT_UENV')
    if uenvflags:
        uenvflags.pop('doc', None)

        ostree_boot = os.path.join(d.getVar('IMAGE_ROOTFS'),
                                   'usr', 'lib', 'ostree-boot')
        bb.utils.mkdirhier(ostree_boot)
        with open(os.path.join(ostree_boot, 'uEnv.txt'), 'w') as f:
            # ensure reproducibility by sorting first
            for k in sorted(uenvflags):
                v = uenvflags[k]
                print("=".join([k, v]), file=f)
}
ROOTFS_POSTPROCESS_COMMAND += "install_ostree_boot_uenv;"

# Create /usr/lib/build.info
python install_build_info () {
    import os
    import json
    topdict = {}
    subdict = {}
    usrlib = os.path.join(d.getVar('IMAGE_ROOTFS'),
                          'usr', 'lib')
    binfoflags = d.getVarFlags('BUILD_INFO')
    valid = binfoflags.pop('cicd', None)
    # If cicd var flag has been set on BUILD_INFO (e.g. in auto.conf)
    if valid == 'hda':
        # Note the HDA-specifics here - other build systems
        # will have to adapt these for their own context.
        subdict['ostreeBranch'] = d.getVar['OSTREE_BRANCHNAME']
        subdict['legacyVersionString'] = d.getVar['HDA_HUB_LEGACY_VERSION']
        subdict['versionString'] = d.getVar['HDA_HUB_BASE_VERSION']
        subdict['distro'] = d.getVar['DISTRO']
        subdict['distroCodename'] = d.getVar['DISTRO_CODENAME']
        subdict['machine'] = d.getVar['MACHINE']
        subdict['dateTime'] = d.getVar['HDA_DATETIME_STAMP']
        # Wrap it all up in a substructure for downstream inclusion
        topdict['buildInfo'] = subdict
        # Directory should be there, but just make sure
        bb.utils.mkdirhier(usrlib)
        with open(os.path.join(usrlib, 'build.info'), 'w') as fp:
            # Let's be friendly and make it readable.
            json.dump(topdict, fp, sort_keys=True, indent=4, separators=(',', ': '))
    # Could add a Jenkins flag-handler here if we wanted.
}
ROOTFS_POSTPROCESS_COMMAND += "install_build_info;"
