#
#  Gui gsdoc makefile for the GNUstep Gui Library
#  Copyright (C) 2000 Free Software Foundation, Inc.
#
#  Written by:	Adam Fedor <fedor@gnu.org>
#
#  This file is part of the GNUstep Gui Library.
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

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

# The documents to be generated
DOCUMENT_NAME = Gui

Gui_AGSDOC_FILES = \
	Introduction.gsdoc \
	DefaultsSummary.gsdoc \
	LanguageSetup.gsdoc \
	NSBundleAdditions.gsdoc \
	NSCoderAdditions.gsdoc \
	NSMutableAttributedStringAdditions.gsdoc \
	NSMutableParagraphStyle.gsdoc \
	NSStringAdditions.gsdoc \

Gui_AGSDOC_FLAGS = \
	-DocumentationDirectory . \
	-Declared AppKit \
	-Standards YES \
	-WordMap '{\
	APPKIT_EXPORT=extern;APPKIT_DECLARE="";\
	}' -Up Gui

Gui_DOC_INSTALL_DIR = Developer/Gui/Reference

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/documentation.make

-include GNUmakefile.postamble
