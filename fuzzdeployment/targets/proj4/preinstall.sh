tar -xvf seeds.tar.gz

sudo apt-get update && \
	sudo apt-get install -y make automake autoconf libtool sqlite3 wget libsqlite3-dev zlib1g-dev libssl-dev liblzma-dev

if [ ! -d PROJ ]; then
	git clone https://github.com/OSGeo/PROJ
	git -C PROJ checkout a7482d3775f2e346f3680363dd2d641add3e68b 
fi

if [ ! -d PROJ/curl ]; then
	git clone https://github.com/curl/curl.git PROJ/curl
	git -C PROJ/curl checkout c12fb3ddaf48e709a7a4deaa55ec485e4df163ee
fi

if [ ! -d PROJ/libtiff ]; then
	git clone https://gitlab.com/libtiff/libtiff.git PROJ/libtiff
	git -C PROJ/libtiff checkout c8e1289deff3fa60ba833ccec6c030934b02c281
fi
