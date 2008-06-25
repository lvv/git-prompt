install:
	cp prompt /etc/

clean:
	git clean -df

tgit:
	xclip -i git-demo
	echo "ready to paste ..."
