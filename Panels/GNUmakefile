#
#  Makefile for GNUstep GUI Panels
#
#  Copyright (C) 2001 Free Software Foundation, Inc.
#
#  Author: Adam Fedor <fedor@gnu.org>
#  Date: November 2001
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

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

LANGUAGES = English

LOCALIZED_RESOURCE_FILES = GSPrintPanel.gorm GSPageLayout.gorm \
	SpellPanel.gmodel \
	GSDataLinkPanel.gorm

-include GNUmakefile.preamble
-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/rules.make

include GNUmakefile.postamble
