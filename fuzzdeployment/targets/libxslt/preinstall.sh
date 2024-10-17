sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    make libtool pkg-config \
    libgcrypt-dev


if [ ! -d libxml2 ]; then
	git clone https://gitlab.gnome.org/GNOME/libxml2.git
	git -C libxml2 checkout c7260a47f19e01f4f663b6a56fbdc2dafd8a6e7e
fi

if [ ! -d libxslt ]; then
    git clone https://gitlab.gnome.org/GNOME/libxslt.git
    git -C libxslt checkout 180cdb804efedcba363016fcf6cd3dbd2adca60
fi

# XXX: Check if this is necessary, probably not
#
M4_VERSION=1.4.19
AUTOCONF_VERSION=2.71
AUTOMAKE_VERSION=1.16.5
wget https://ftp.gnu.org/gnu/m4/m4-$M4_VERSION.tar.gz && \
tar xf m4-$M4_VERSION.tar.gz && \
rm m4-$M4_VERSION.tar.gz && \
( \
    cd m4-$M4_VERSION/ && \
    ./configure && \
    make && \
    sudo make install \
) && \
wget https://ftp.gnu.org/gnu/autoconf/autoconf-$AUTOCONF_VERSION.tar.gz && \
tar xf autoconf-$AUTOCONF_VERSION.tar.gz && \
rm autoconf-$AUTOCONF_VERSION.tar.gz && \
( \
    cd autoconf-$AUTOCONF_VERSION/ && \
    ./configure && \
    make && \
    sudo make install \
) && \
wget https://ftp.gnu.org/gnu/automake/automake-$AUTOMAKE_VERSION.tar.gz && \
tar xf automake-$AUTOMAKE_VERSION.tar.gz && \
rm automake-$AUTOMAKE_VERSION.tar.gz && \
( \
    cd automake-$AUTOMAKE_VERSION && \
    ./configure && \
    make && \
    sudo make install \
)

