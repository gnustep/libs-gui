#
#  Themes makefile for GNUstep GUI Library
#  Copyright (C) 2009 Free Software Foundation, Inc.
#
#  Author:  Gregory Casamento <greg.casamento@gmail.com>
#  Date:  August 2009
#
#  This file is part of the GNUstep GUI Library.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; see the file COPYING.LIB.
#  If not, see <http://www.gnu.org/licenses/> or write to the 
#  Free Software Foundation, 51 Franklin Street, Fifth Floor, 
#  Boston, MA 02110-1301, USA.

PACKAGE_NAME = gnustep-gui
GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

themedir = $(GNUSTEP_LIBRARY)/Themes

THEME_FILES =

-include GNUmakefile.preamble

-include GNUmakefile.local
# We don't actually build anything in this directory so
# just include the common makefile rules
include $(GNUSTEP_MAKEFILES)/rules.make

include GNUmakefile.postamble
