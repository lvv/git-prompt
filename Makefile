install:
	cp -v git-prompt.sh 	/etc/
	[ -f /etc/git-prompt.conf ]  || cp -v git-prompt.conf /etc/

	
tgit:
	xclip -i git-demo
	echo "ready to paste ..."

WEB_DESTDIR ?= /tmp/localweb
ASCIIDOC ?= asciidoc --unsafe


show: localweb
	firefox $(WEB_DESTDIR)/index.html

index.html: index.txt
	$(ASCIIDOC)  -o $@  $<

localweb: index.html *.png git-prompt.sh
	mkdir -p  $(WEB_DESTDIR)
	cp -uv $^ $(WEB_DESTDIR)

clean:
	rm -f *.html
