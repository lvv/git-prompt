HOMEDIR ?= /home/lvv/p/volnitsky.com/
include $(HOMEDIR)/include.mk
COPY_LIST = git-prompt.sh

install:
	cp -v git-prompt.sh 	/etc/
	[ -f /etc/git-prompt.conf ]  || cp -v git-prompt.conf /etc/
	
tgit:
	xclip -i git-demo
	echo "ready to paste ..."

