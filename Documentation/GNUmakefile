#
#  Documentation makefile for the GNUstep GUI Library
#  Copyright (C) 1995 Free Software Foundation, Inc.
#
#  Written by: Adam Fedor <fedor@gnu.org>
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
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

# The documents to be generated
DOCUMENT_NAME = gnustep-gui

# The text documents to be generated
DOCUMENT_TEXT_NAME = \
INSTALL NEWS README ANNOUNCE BUGS

gnustep-gui_TEXI_FILES = \
gnustep-gui.texi \
version.texi 
gnustep-gui_DOC_INSTALL_DIR = Developer/Gui/Manual

TOP_DOC_FILES = INSTALL NEWS README ANNOUNCE BUGS

INSTALL_TEXI_FILES = version.texi
INSTALL_TEXT_MAIN = install.texi
INSTALL_DOC_INSTALL_DIR = Developer/Gui/ReleaseNotes/$(VERSION)

NEWS_TEXI_FILES = version.texi
NEWS_TEXT_MAIN = news.texi
NEWS_DOC_INSTALL_DIR = Developer/Gui/ReleaseNotes/$(VERSION)

README_TEXI_FILES = version.texi
README_TEXT_MAIN = readme.texi
README_DOC_INSTALL_DIR = Developer/Gui/ReleaseNotes/$(VERSION)

ANNOUNCE_TEXI_FILES = version.texi
ANNOUNCE_TEXT_MAIN = announce.texi
ANNOUNCE_DOC_INSTALL_DIR = Developer/Gui/ReleaseNotes/$(VERSION)

BUGS_TEXI_FILES = version.texi
BUGS_TEXT_MAIN = todo.texi
BUGS_DOC_INSTALL_DIR = Developer/Gui/ReleaseNotes/$(VERSION)

-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/documentation.make

-include Makefile.postamble

regenerate: $(DOCUMENT_TEXT_NAME)
	mv $(TOP_DOC_FILES) ..

version.texi: ../Version
	rm -f version.texi
	echo '@set GNUSTEP-GUI-VERSION' $(GNUSTEP_GUI_VERSION) \
		> version.texi
	echo '@set GNUSTEP-GUI-GCC $(GNUSTEP_GUI_GCC)' \
		>> version.texi
	echo '@set GNUSTEP-GUI-BASE $(GNUSTEP_GUI_BASE)' \
		>> version.texi
	echo '@set GNUSTEP-GUI-LIBTIFF $(GNUSTEP_GUI_LIBTIFF)' \
		>> version.texi
	if [ $(GNUSTEP_GUI_FTP_MACHINE) ]; then \
	  echo '@set GNUSTEP-GUI-FTP-MACHINE $(GNUSTEP_GUI_FTP_MACHINE)' \
		>> version.texi; fi
	if [ $(GNUSTEP_GUI_FTP_DIRECTORY) ]; then \
	  echo '@set GNUSTEP-GUI-FTP-DIRECTORY $(GNUSTEP_GUI_FTP_DIRECTORY)' \
		>> version.texi; fi

