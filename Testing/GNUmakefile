#
#  Testing level makefile for GNUstep GUI Library
#
#  Copyright (C) 1997 Free Software Foundation, Inc.
#
#  Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
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

ifeq ($(GNUSTEP_SYSTEM_ROOT),)
  GNUSTEP_SYSTEM_ROOT = $(TOPLEV)
endif

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

include ../Version
# The application to be compiled
TEST_TOOL_NAME = testpb

TEST_APP_NAME = buttons matrix menu nsbox nsbrowser nsbrowsercell \
		nscursor nsimage nsscroller scrollview scrollview2 \
		slider windows

# The source files to be compiled
testpb_OBJC_FILES = testpb.m Functions.m
buttons_OBJC_FILES = buttons.m
matrix_OBJC_FILES = matrix.m
menu_OBJC_FILES = menu.m
nsbox_OBJC_FILES = nsbox.m
nsbrowser_OBJC_FILES = nsbrowser.m
nsbrowsercell_OBJC_FILES = nsbrowsercell.m
nscursor_OBJC_FILES = nscursor.m ColorView.m
nsimage_OBJC_FILES = nsimage.m ImageView.m
nsscroller_OBJC_FILES = nsscroller.m
scrollview_OBJC_FILES = scrollview.m TestView.m
scrollview2_OBJC_FILES = scrollview2.m
slider_OBJC_FILES = slider.m


-include GNUmakefile.preamble
-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/test-tool.make
include $(GNUSTEP_MAKEFILES)/test-application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble
