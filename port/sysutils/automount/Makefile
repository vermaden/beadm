# New ports collection makefile for:	automount
# Date created:        21 February 2012
# Whom:                vermaden
#
# $FreeBSD$
#

PORTNAME=     automount
PORTVERSION=  1.2
CATEGORIES=   sysutils
MASTER_SITES= https://github.com/vermaden/automount/

MAINTAINER=   vermaden@interia.pl
COMMENT=      FreeBSD's devd(8) based automount sollution

LICENSE=      BSD

PLIST_FILES=  sbin/automount etc/devd/automount_devd.conf etc/automount.conf.sample

NO_BUILD=      yes

do-install:
	${INSTALL_SCRIPT} ${WRKSRC}/automount             ${PREFIX}/sbin
	${INSTALL_DATA}   ${WRKSRC}/automount_devd.conf   ${PREFIX}/etc/devd/automount_devd.conf
	${INSTALL_DATA}   ${WRKSRC}/automount.conf.sample ${PREFIX}/etc/automount.conf.sample
	${SH} ${PKGINSTALL} ${PKGNAME} POST-INSTALL

.include <bsd.port.mk>
