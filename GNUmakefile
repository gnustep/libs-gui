#
#  Top level makefile for GNUstep GUI Library
#
#  Copyright (C) 1997 Free Software Foundation, Inc.
#
#  Author: Scott Christley <scottc@net-community.com>
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

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

RPM_DISABLE_RELOCATABLE=YES
PACKAGE_NEEDS_CONFIGURE = YES

CVS_MODULE_NAME = gui

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=gui.make
include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = gnustep-gui

include ./Version

#
# The list of subproject directories
#
SUBPROJECTS = \
Source \
Images \
Model \
Tools \
Panels \
PrinterTypes \
TextConverters \
ColorPickers \
KeyBindings \
Resources

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make

include GNUmakefile.postamble
