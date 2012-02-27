# New ports collection makefile for:	automount
# Date created:        21 Febryaru 2012
# Whom:                vermaden
#
# $FreeBSD$
#

PORTNAME=     automount
PORTVERSION=  1.2
LICENSE=      BSD
CATEGORIES=   sysutils
MASTER_SITES= https://github.com/vermaden/automount/

MAINTAINER=   vermaden@interia.pl
COMMENT=      devd(8) based automount sollution

PLIST_FILES=  sbin/automount etc/devd/automount_devd.conf etc/automount.conf.sample

NO_BUILD=      yes

do-install:
	${INSTALL_SCRIPT} ${WRKSRC}/automount             ${PREFIX}/sbin
	${INSTALL_DATA}   ${WRKSRC}/automount_devd.conf   ${PREFIX}/etc/devd/automount_devd.conf
	${INSTALL_DATA}   ${WRKSRC}/automount.conf.sample ${PREFIX}/etc/automount.conf.sample
	${SH} ${PKGINSTALL} ${PKGNAME} POST-INSTALL

.include <bsd.port.mk>
