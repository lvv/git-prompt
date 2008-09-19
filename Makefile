install:
	cp git-prompt.sh /etc/
	[ -s /etc/prompt ] || ln -sf /etc/git-prompt.sh /etc/prompt

clean:
	git clean -df

tgit:
	xclip -i git-demo
	echo "ready to paste ..."

release: install
	 git tag  $(shell git tag -l | awk -F. 'END{printf "%s.%s\n", $$1,$$2+1}')
	 git push
