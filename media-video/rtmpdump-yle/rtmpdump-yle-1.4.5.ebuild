# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# http://www.kosunen.fi/gentoo/portage/media-video/rtmpdump-yle/rtmpdump-yle-1.3.0.ebuild
# retrieved on 2011-11-26, and updated for 1.4.5 by teknohog

DESCRIPTION="RTMP stream dumper RTMPDump-YLE"
HOMEPAGE="http://users.tkk.fi/~aajanki/rtmpdump-yle/"
SRC_URI="http://users.tkk.fi/~aajanki/${PN}/${PN}-${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~x86"
IUSE=""

DEPEND="dev-libs/libgcrypt
	dev-libs/openssl
	dev-lang/python
	dev-libs/json-c"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${PN}-${PV}
#: ${PREFIX:=/usr}

src_unpack() {
	if [ "${A}" != "" ]; then
		unpack ${A}
	fi
}

src_compile() {
	if [ -f Makefile ]; then
		emake -j1 prefix="${DESTTREE}" || die "emake failed"
	fi
}

src_install() {
	dobin rtmpdump-yle
	dobin yle-dl
	dodoc README
}