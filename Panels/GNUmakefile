#
#  Makefile for GNUstep GUI Panels
#
#  Copyright (C) 1997 Free Software Foundation, Inc.
#
#  Author: Lyndon Tremblay <tremblay2@home.com>
#  Date: November 1998
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
#  If you are interested in a warranty or support for this source code,
#  contact Scott Christley at scottc@net-community.com
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; see the file COPYING.LIB.
#  If not, write to the Free Software Foundation,
#  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

prefix           = $(GNUSTEP_INSTALLATION_DIR)
INSTALL          = install -c
INSTALL_PROGRAM  = ${INSTALL}
INSTALL_DATA     = ${INSTALL} -m 644

PANELS   =  SavePanel.gmodel

all::
	@

install:: all
	if [ ! -e $(prefix)/Library ]; then \
		mkdir $(prefix)/Library; \
	fi
	if [ ! -e $(prefix)/Library/Model ]; then \
		mkdir $(prefix)/Library/Model; \
	fi
	for f in $(PANELS); do \
		$(INSTALL_DATA) $$f $(prefix)/Library/Model/; \
	done

uninstall::
	for f in $(PANELS); do \
		rm -f $(prefix)/Library/Model/$$f; \
	done
	rmdir $(prefix)/Library/Model

clean::

-include GNUmakefile.preamble

#include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble
