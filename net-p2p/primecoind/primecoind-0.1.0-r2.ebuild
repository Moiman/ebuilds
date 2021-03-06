# Copyright 2010-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-p2p/bitcoind/bitcoind-0.8.2.ebuild,v 1.1 2013/06/14 18:49:59 blueness Exp $

EAPI="4"

DB_VER="4.8"

inherit db-use eutils versionator toolchain-funcs

MyPV="${PV/_/}"
MyPN="primecoin"
MyP="${MyPN}-${MyPV}-linux"

DESCRIPTION="Primecoin crypto-currency wallet for automated services"
HOMEPAGE="http://primecoin.org/"
SRC_URI="mirror://sourceforge/${MyPN}/${MyP}.tar.gz"

LICENSE="MIT ISC GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="examples ipv6 logrotate upnp"

RDEPEND="
	>=dev-libs/boost-1.41.0[threads(+)]
	dev-libs/openssl:0[-bindist]
	logrotate? (
		app-admin/logrotate
	)
	upnp? (
		net-libs/miniupnpc
	)
	sys-libs/db:$(db_ver_to_slot "${DB_VER}")[cxx]
	=dev-libs/leveldb-1.9.0*[-snappy]
"
DEPEND="${RDEPEND}
	>=app-shells/bash-4.1
	sys-apps/sed
"

S="${WORKDIR}/${MyP}/src"

pkg_setup() {
	local UG='primecoin'
	enewgroup "${UG}"
	enewuser "${UG}" -1 -1 /var/lib/primecoin "${UG}"
}

src_prepare() {
	epatch "${FILESDIR}/${PV}-sys_leveldb.patch"
	epatch "${FILESDIR}/338e61568a32e74fa112edf1f3d8eee8d6780ae9.patch"
	epatch "${FILESDIR}/orogen-optimization.patch"

	rm -r src/leveldb

	if has_version '>=dev-libs/boost-1.52'; then
		sed -i 's/\(-l db_cxx\)/-l boost_chrono$(BOOST_LIB_SUFFIX) \1/' src/makefile.unix
	fi
}

src_compile() {
	OPTS=()

	OPTS+=("DEBUGFLAGS=")
	OPTS+=("CXXFLAGS=${CXXFLAGS}")
	OPTS+=("LDFLAGS=${LDFLAGS}")

	OPTS+=("BDB_INCLUDE_PATH=$(db_includedir "${DB_VER}")")
	OPTS+=("BDB_LIB_SUFFIX=-${DB_VER}")

	if use upnp; then
		OPTS+=(USE_UPNP=1)
	else
		OPTS+=(USE_UPNP=)
	fi
	use ipv6 || OPTS+=("USE_IPV6=-")

	OPTS+=("USE_SYSTEM_LEVELDB=1")

	cd src || die
	emake CC="$(tc-getCC)" CXX="$(tc-getCXX)" -f makefile.unix "${OPTS[@]}" ${PN}
}

src_test() {
	cd src || die
	emake CC="$(tc-getCC)" CXX="$(tc-getCXX)" -f makefile.unix "${OPTS[@]}" test_primecoin
	./test_primecoin || die 'Tests failed'
}

src_install() {
	dobin src/${PN}

	insinto /etc/primecoin
	newins "${FILESDIR}/primecoin.conf" primecoin.conf
	fowners primecoin:primecoin /etc/primecoin/primecoin.conf
	fperms 600 /etc/primecoin/primecoin.conf

	newconfd "${FILESDIR}/primecoin.confd" ${PN}
	newinitd "${FILESDIR}/primecoin.initd" ${PN}

	keepdir /var/lib/primecoin/.primecoin
	fperms 700 /var/lib/primecoin
	fowners primecoin:primecoin /var/lib/primecoin/
	fowners primecoin:primecoin /var/lib/primecoin/.primecoin
	dosym /etc/primecoin/primecoin.conf /var/lib/primecoin/.primecoin/primecoin.conf

	dodoc doc/README.md doc/release-notes.md

	if use examples; then
		docinto examples
		dodoc -r contrib/{bitrpc,pyminer,spendfrom,tidy_datadir.sh,wallettools}
	fi

	if use logrotate; then
		insinto /etc/logrotate.d
		newins "${FILESDIR}/primecoind.logrotate" primecoind
	fi
}
