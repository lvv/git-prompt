install:
	[ -f $(HOME)/.git-prompt.conf ] || ln -vfn -s $(shell pwd)/git-prompt.conf $(HOME)/.git-prompt.conf 
	@echo 
	@echo 'add to ~/.bashrc'
	@echo '[[ $$- == *i* ]] && . $(PWD)/git-prompt.sh'
clean: 
	[ -f $(HOME)/.git-prompt.conf ] &&  unlink $(HOME)/.git-prompt.conf
	@echo 
	@echo 'remove in ~/.bashrc'
	@echo '[[ $$- == *i* ]] && . $(PWD)/git-prompt.sh'
