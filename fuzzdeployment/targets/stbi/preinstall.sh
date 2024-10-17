if [ ! -d stb ]; then
	git clone https://github.com/nothings/stb.git
	git -C stb checkout 5736b15f7ea0ffb08dd38af21067c314d6a3aae9
fi
