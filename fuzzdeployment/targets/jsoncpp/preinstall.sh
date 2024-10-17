sudo apt-get update && \
	sudo apt-get install -y cmake

if [ ! -d jsoncpp ]; then
	git clone https://github.com/open-source-parsers/jsoncpp
	git -C jsoncpp checkout 8190e061bc2d95da37479a638aa2c9e483e58ec6
fi

