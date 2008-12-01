#install:
#	cp git-prompt.sh /etc/
#	[ -s /etc/prompt ] || ln -sf /etc/git-prompt.sh /etc/prompt

tgit:
	xclip -i git-demo
	echo "ready to paste ..."

DESTDIR ?= /tmp/html-lopti
ASCIIDOC ?= asciidoc


show: install
	firefox $(DESTDIR)/index.html

index.html: index.txt
	$(ASCIIDOC)  -o $@  $<

install: index.html *.png
	mkdir -p  $(DESTDIR)
	cp -uv $^ $(DESTDIR)

clean:
	rm -f *.html
