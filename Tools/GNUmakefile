#
#  Tools level makefile for GNUstep GUI Library
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

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../config.make

include ../Version
# The applications to be compiled
TOOL_NAME = make_services set_show_service gopen
SERVICE_NAME = example GSspell

# The source files to be compiled
gopen_OBJC_FILES = gopen.m

make_services_OBJC_FILES = make_services.m 

set_show_service_OBJC_FILES = set_show_service.m 

example_OBJC_FILES = example.m 

GSspell_OBJC_FILES = GSspell.m

include GNUmakefile.preamble

-include GNUmakefile.local

GNUSTEP_MAKE_SERVICES=./$(GNUSTEP_OBJ_DIR)/make_services

include $(GNUSTEP_MAKEFILES)/tool.make
include $(GNUSTEP_MAKEFILES)/service.make

-include GNUmakefile.local.service
include GNUmakefile.postamble
