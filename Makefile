ifeq ($(USER),lvv)
        HOMEDIR := /home/lvv/p/volnitsky.com/
        INCLUDE := $(HOMEDIR)/include.mk
else
        INCLUDE := /dev/null
endif

include $(INCLUDE)


COPY_LIST = git-prompt.sh


install:
	[ -f $(HOME)/.git-prompt.conf ] || ln -v -s $(shell pwd)/git-prompt.conf $(HOME)/.git-prompt.conf 
	
tgit:
	xclip -i git-demo
	echo "ready to paste ..."

