#
#  Resources makefile for gnustep-gui
#  Copyright (C) 2001, 2002 Free Software Foundation, Inc.
#
#  Written by: Nicola Pero <n.pero@mi.flashnet.it>
#  Date: December 2001, September 2002
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

RESOURCE_SET_NAME = gui-resources
gui-resources_RESOURCE_FILES_INSTALL_DIR = gnustep-gui
gui-resources_LANGUAGES = English Italian
gui-resources_LOCALIZED_RESOURCE_FILES = Localizable.strings

include $(GNUSTEP_MAKEFILES)/resource-set.make

# The following code is so that by typing 'make strings', all the
# Localizable.strings files are updated for the new localizable
# strings in the source code.  If we had the localized resources in
# the Source directory, this would be supported automatically by
# gnustep-make (but it would parse all files all the times ... which
# will be reasonable when more than two files actually contain
# something to translate :-)

# The list of OBJC_FILES containing localizable strings
strings_OBJC_FILES = \
 NSApplication.m \
 NSDocument.m

# The list of HEADER_FILES containing localizable strings
strings_HEADER_FILES = 

after-strings::
	make_strings -L "$(gui-resources_LANGUAGES)" \
	  $(addprefix ../Source/,$(strings_OBJC_FILES)) \
	  $(addprefix ../Headers/gnustep/gui/,$(strings_HEADER_FILES))
