FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

DEPENDS += "glib-networking"

BBCLASSEXTEND_append = " native"
