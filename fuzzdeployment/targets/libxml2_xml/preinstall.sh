sudo dpkg --add-architecture i386
sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
        make autoconf libtool pkg-config \
        zlib1g-dev zlib1g-dev:i386 liblzma-dev liblzma-dev:i386 curl


sudo curl -LO http://mirrors.kernel.org/ubuntu/pool/main/a/automake-1.16/automake_1.16.5-1.3_all.deb && \
    sudo apt install ./automake_1.16.5-1.3_all.deb

if [ ! -d libxml2 ]; then
	git clone https://gitlab.gnome.org/GNOME/libxml2.git
	git -C libxml2 checkout c7260a47f19e01f4f663b6a56fbdc2dafd8a6e7e
fi
