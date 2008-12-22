#install:
#	cp git-prompt.sh /etc/
#	[ -s /etc/prompt ] || ln -sf /etc/git-prompt.sh /etc/prompt

tgit:
	xclip -i git-demo
	echo "ready to paste ..."

WEB_DESTDIR ?= /tmp/html
ASCIIDOC ?= asciidoc


show: web_install
	firefox $(WEB_DESTDIR)/index.html

index.html: index.txt
	$(ASCIIDOC)  -o $@  $<

web_install: index.html *.png git-prompt.sh
	mkdir -p  $(WEB_DESTDIR)
	cp -uv $^ $(WEB_DESTDIR)

clean:
	rm -f *.html
