#
#  ColorPickers makefile for GNUstep GUI
#
#  Copyright (C) 2000 Free Software Foundation, Inc.
#
#  Author: Fred Kiefer <FredKiefer@gmx.de>
#  Author: Alexander Malmberg <alexander@malmberg.org>
#  Date: May 2002
#
#  This file is part of the GNUstep GUI.
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

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES = ../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

# The color picker bundle to be compiled
#BUNDLE_NAME = StandardPicker NamedPicker WheelPicker
BUNDLE_NAME = StandardPicker WheelPicker

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ColorPickers

ADDITIONAL_INCLUDE_DIRS += -I../Headers -I../Headers/gnustep

# The Objective-C source files to be compiled
StandardPicker_OBJC_FILES =  	GSStandardColorPicker.m \
			     	GSRGBColorPicker.m \
				GSCMYKColorPicker.m \
				GSHSBColorPicker.m \
				GSGrayColorPicker.m
NamedPicker_OBJC_FILES =  GSNamedColorPicker.m
WheelPicker_OBJC_FILES =  GSWheelColorPicker.m

# The class to load
StandardPicker_PRINCIPAL_CLASS = GSStandardColorPicker
NamedPicker_PRINCIPAL_CLASS = GSNamedColorPicker
WheelPicker_PRINCIPAL_CLASS = GSWheelColorPicker

# The Resource files to be copied into the app's resources directory
StandardPicker_RESOURCE_FILES = GSRGBColorPicker.tiff \
				GSHSBColorPicker.tiff \
				GSGrayColorPicker.tiff \
				GSCMYKColorPicker.tiff
StandardPicker_LOCALIZED_RESOURCE_FILES = StandardPicker.strings
StandardPicker_LANGUAGES = English French Swedish

NamedPicker_RESOURCE_FILES = GSNamedColorPicker.tiff
WheelPicker_RESOURCE_FILES = GSWheelColorPicker.tiff

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

