install:
	cp prompt /etc/

clean:
	git clean -df

tgit:
	xclip -i git-demo
	echo "ready to paste ..."

release: install
	 git tag `git tag -l | awk -F. 'END{printf "%s.%s\n", $1,$2+1}'`
	 git push
