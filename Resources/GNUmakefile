#
#  Resources makefile for gnustep-gui
#  Copyright (C) 2001 Free Software Foundation, Inc.
#
#  Written by: Nicola Pero <n.pero@mi.flashnet.it>
#  Date: December 2001
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

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

gnustep_gui_resources = $(GNUSTEP_RESOURCES)/gnustep-gui/Resources

LANGUAGES = English Italian

LOCALIZED_RESOURCE_FILES = Localizable.strings

include $(GNUSTEP_MAKEFILES)/rules.make

$(gnustep_gui_resources):
	$(MKDIRS) $@

before-install:: $(gnustep_gui_resources)

after-uninstall::
	rm -rf $(gnustep_gui_resources)

after-install::
	@(echo "Installing localized resources..."; \
	for l in $(LANGUAGES); do \
	  if [ -d $$l.lproj ]; then \
	    $(MKDIRS) $(gnustep_gui_resources)/$$l.lproj; \
	    for f in $(LOCALIZED_RESOURCE_FILES); do \
	      if [ -f $$l.lproj/$$f ]; then \
	        $(INSTALL_DATA) $$l.lproj/$$f \
	                        $(gnustep_gui_resources)/$$l.lproj; \
	      fi; \
	    done; \
	  else \
	    echo "Warning: $$l.proj not found!"; \
	  fi; \
	done)


