# Generated automatically from Makefile.in by configure.
#
#  Documentation makefile for GNUstep GUI Library
#  Copyright (C) 1996 Free Software Foundation, Inc.
#
#  Author:  Scott Christley <scottc@net-community.com>
#  Date:  August 1996
#
#  This file is part of the GNUstep GUI Library.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; see the file COPYING.LIB.
#  If not, write to the Free Software Foundation, Inc.,
#  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

include $(GNUSTEP_SYSTEM_ROOT)/Makefiles/common.make

#### Start of system configuration section. ####

srcdir = .

MAKEINFO = makeinfo
TEXI2DVI = texi2dvi
TEXI2HTML = texi2html

#### End of system configuration section. ####

include $(srcdir)/../Version

ORIG_FILES = \
version.tmpl.texi \
gnustep-gui.tmpl.texi \
announce.tmpl.texi \
install.tmpl.texi \
news.tmpl.texi \
readme.tmpl.texi \
status.tmpl.texi \
todo.tmpl.texi \
faq.tmpl.texi

TEXI_FILES = \
version.texi \
gnustep-gui.texi \
announce.texi \
install.texi \
news.texi \
readme.texi \
status.texi \
todo.texi \
faq.texi \

TEXT_FILES = \
TODO INSTALL NEWS README ANNOUNCE FAQ STATUS

DVI_FILES = gnustep-gui.dvi
PS_FILES = gnustep-gui.ps
HTML_FILES = gnustep-gui_toc.html
INFO_FILES = gnustep-gui.info

INFO_FLAGS = -I $(srcdir) -D NO-TEXI2HTML --no-header
HTML_FLAGS = -split_chapter -expandinfo -I $(srcdir)
TEXT_FLAGS = -I $(srcdir) -D NO-TEXI2HTML -D TEXT-ONLY --no-header --no-split

all: info dvi html text ps

info: $(INFO_FILES)
dvi: $(DVI_FILES)
html: $(HTML_FILES)
text: $(TEXT_FILES)
ps: $(PS_FILES)

version.tmpl.texi: $(srcdir)/../Version
	rm -f version.tmpl.texi
	echo '@set GNUSTEP-GUI-VERSION' $(GNUSTEP_GUI_VERSION) \
		> version.tmpl.texi
	echo '@set GNUSTEP-GUI-GCC $(GNUSTEP_GUI_GCC)' \
		>> version.tmpl.texi
	echo '@set GNUSTEP-GUI-BASE $(GNUSTEP_GUI_BASE)' \
		>> version.tmpl.texi
	echo '@set LIB-FOUNDATION $(LIB_FOUNDATION)' \
		>> version.tmpl.texi
	echo '@set GNUSTEP-GUI-LIBTIFF $(GNUSTEP_GUI_LIBTIFF)' \
		>> version.tmpl.texi
	echo '@set GNUSTEP-GUI-DGS $(GNUSTEP_GUI_DGS)' \
		>> version.tmpl.texi
	echo '@set GNUSTEP-GUI-DPSCLIENT $(GNUSTEP_GUI_DPSCLIENT)' \
		>> version.tmpl.texi
	if [ $(GNUSTEP_GUI_FTP_MACHINE) ]; then \
	  echo '@set GNUSTEP-GUI-FTP-MACHINE $(GNUSTEP_GUI_FTP_MACHINE)' \
		>> version.tmpl.texi; fi
	if [ $(GNUSTEP_GUI_FTP_DIRECTORY) ]; then \
	  echo '@set GNUSTEP-GUI-FTP-DIRECTORY $(GNUSTEP_GUI_FTP_DIRECTORY)' \
		>> version.tmpl.texi; fi
	if [ $(GNUSTEP_GUI_SNAP_FTP_MACHINE) ]; then \
	  echo '@set GNUSTEP-GUI-SNAP-FTP-MACHINE \
		$(GNUSTEP_GUI_SNAP_FTP_MACHINE)' \
		>> version.tmpl.texi; fi
	if [ $(GNUSTEP_GUI_SNAP_FTP_DIRECTORY) ]; then \
	  echo '@set GNUSTEP-GUI-SNAP-FTP-DIRECTORY \
		$(GNUSTEP_GUI_SNAP_FTP_DIRECTORY)' \
		>> version.tmpl.texi; fi
	cp version.tmpl.texi version.texi

gnustep-gui.dvi: $(ORIG_FILES)
	rm -f $(TEXI_FILES)
	for i in $(ORIG_FILES); do \
		cp $$i `basename $$i .tmpl.texi`.texi ; \
	done
	$(TEXI2DVI) $(srcdir)/gnustep-gui.texi

gnustep-gui.info: $(ORIG_FILES)
	rm -f $(TEXI_FILES)
	for i in $(ORIG_FILES); do \
	   sed -e 's,@email{\([^}]*\)},<\1>,g' \
		$(srcdir)/$$i \
		| sed -e 's,@url{\([^}]*\)},@samp{\1},g' \
		> `basename $$i .tmpl.texi`.texi ; \
	done
	$(MAKEINFO) $(INFO_FLAGS) -o gnustep-gui.info $(srcdir)/gnustep-gui.texi

gnustep-gui.ps: gnustep-gui.dvi
	dvips gnustep-gui.dvi -o gnustep-gui.ps

gnustep-gui_toc.html: $(ORIG_FILES)
	rm -f $(TEXI_FILES)
	for i in $(ORIG_FILES); do \
	   sed -e 's,@email{\([^}]*\)},<A HREF="mailto:\1">\1</A>,g' \
		$(srcdir)/$$i \
		| sed -e 's,@url{\([^}]*\)},<A HREF="\1">\1</A>,g' \
		| sed -e 's,^ *$$,@br{},g' \
		> `basename $$i .tmpl.texi`.texi ; \
	done
	$(TEXI2HTML) $(HTML_FLAGS) gnustep-gui.texi

# Rules for producing the text files
README: version.tmpl.texi readme.tmpl.texi
	sed -e 's,@email{\([^}]*\)},<\1>,g' \
		$(srcdir)/readme.tmpl.texi \
		| sed -e 's,@url{\([^}]*\)},@samp{\1},g' \
		> readme.texi ; \
	$(MAKEINFO) $(TEXT_FLAGS) -o README $(srcdir)/readme.texi

ANNOUNCE: version.tmpl.texi announce.tmpl.texi
	sed -e 's,@email{\([^}]*\)},<\1>,g' \
		$(srcdir)/announce.tmpl.texi \
		| sed -e 's,@url{\([^}]*\)},@samp{\1},g' \
		> announce.texi ; \
	$(MAKEINFO) $(TEXT_FLAGS) -o ANNOUNCE $(srcdir)/announce.texi

INSTALL: version.tmpl.texi install.tmpl.texi
	sed -e 's,@email{\([^}]*\)},<\1>,g' \
		$(srcdir)/install.tmpl.texi \
		| sed -e 's,@url{\([^}]*\)},@samp{\1},g' \
		> install.texi ; \
	$(MAKEINFO) $(TEXT_FLAGS) -o INSTALL $(srcdir)/install.texi

NEWS: version.tmpl.texi news.tmpl.texi
	sed -e 's,@email{\([^}]*\)},<\1>,g' \
		$(srcdir)/news.tmpl.texi \
		| sed -e 's,@url{\([^}]*\)},@samp{\1},g' \
		> news.texi ; \
	$(MAKEINFO) $(TEXT_FLAGS) -o NEWS $(srcdir)/news.texi

FAQ: version.tmpl.texi faq.tmpl.texi
	sed -e 's,@email{\([^}]*\)},<\1>,g' \
		$(srcdir)/faq.tmpl.texi \
		| sed -e 's,@url{\([^}]*\)},@samp{\1},g' \
		> faq.texi ; \
	$(MAKEINFO) $(TEXT_FLAGS) -o FAQ $(srcdir)/faq.texi

STATUS: version.tmpl.texi status.tmpl.texi
	sed -e 's,@email{\([^}]*\)},<\1>,g' \
		$(srcdir)/status.tmpl.texi \
		| sed -e 's,@url{\([^}]*\)},@samp{\1},g' \
		> status.texi ; \
	$(MAKEINFO) $(TEXT_FLAGS) -o STATUS $(srcdir)/status.texi

TODO: version.tmpl.texi todo.tmpl.texi
	sed -e 's,@email{\([^}]*\)},<\1>,g' \
		$(srcdir)/todo.tmpl.texi \
		| sed -e 's,@url{\([^}]*\)},@samp{\1},g' \
		> todo.texi ; \
	$(MAKEINFO) $(TEXT_FLAGS) -o TODO $(srcdir)/todo.texi

#
# GNU Objective-C Runtime Library Manual
#
objc-runtime.dvi: version.tmpl.texi objc-runtime.tmpl.texi
	rm -f $(TEXI_FILES)
	for i in version.tmpl.texi objc-runtime.tmpl.texi; do \
		cp $$i `basename $$i .tmpl.texi`.texi ; \
	done
	$(TEXI2DVI) $(srcdir)/objc-runtime.texi

objc-runtime.info: version.tmpl.texi objc-runtime.tmpl.texi
	rm -f $(TEXI_FILES)
	for i in version.tmpl.texi objc-runtime.tmpl.texi; do \
	   sed -e 's,@email{\([^}]*\)},<\1>,g' \
		$(srcdir)/$$i \
		| sed -e 's,@url{\([^}]*\)},@samp{\1},g' \
		> `basename $$i .tmpl.texi`.texi ; \
	done
	$(MAKEINFO) $(INFO_FLAGS) -o objc-runtime.info $(srcdir)/objc-runtime.texi

objc-runtime.ps: objc-runtime.dvi
	dvips objc-runtime.dvi -o objc-runtime.ps

objc-runtime_toc.html: version.tmpl.texi objc-runtime.tmpl.texi
	rm -f $(TEXI_FILES)
	for i in version.tmpl.texi objc-runtime.tmpl.texi; do \
	   sed -e 's,@email{\([^}]*\)},<A HREF="mailto:\1">\1</A>,g' \
		$(srcdir)/$$i \
		| sed -e 's,@url{\([^}]*\)},<A HREF="\1">\1</A>,g' \
		| sed -e 's,^ *$$,@br{},g' \
		> `basename $$i .tmpl.texi`.texi ; \
	done
	$(TEXI2HTML) $(HTML_FLAGS) objc-runtime.texi

install:
uninstall:

update-top: ANNOUNCE FAQ INSTALL NEWS README TODO STATUS
	cp ANNOUNCE ..
	cp FAQ ..
	cp INSTALL ..
	cp NEWS ..
	cp README ..
	cp TODO ..
	cp STATUS ..

mostlyclean:
	rm -f *~
	rm -f *.aux *.cp *.cps *.fn *.fns 
	rm -f *.ky *.log *.pg *.toc *.tp *.vr
	rm -f $(TEXI_FILES)
	rm -f objc-runtime.texi

clean: mostlyclean
	rm -f version.tmpl.texi
	rm -f $(TEXT_FILES)
	rm -f *.html
	rm -f *.info
	rm -f *.dvi
	rm -f *.ps

distclean: clean
	rm -f Makefile 

maintainer-clean: distclean

Makefile: Makefile.in
	cd ..; $(SHELL) config.status
