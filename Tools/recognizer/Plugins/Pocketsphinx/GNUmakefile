#   GNUmakefile 
#
#   Copyright (C) 1999 Free Software Foundation, Inc.
#
#   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
#   Date: 1999
#   
#   This file is part of GNUstep.
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

PACKAGE_NAME = recognizer
include $(GNUSTEP_MAKEFILES)/common.make
include ../../../../config.make

BUNDLE_NAME = PocketSphinx
BUNDLE_EXTENSION = .recognizer
PocketSphinx_PRINCIPAL_CLASS = PocketsphinxSpeechRecognitionEngine
PocketSphinx_OBJC_FILES = PocketsphinxSpeechRecognitionEngine.m
PocketSphinx_RESOURCE_FILES = 

PocketSphinx_STANDARD_INSTALL = no

PocketSphinx_INCLUDE_DIRS += $(RECOGNIZER_BASE_CFLAGS) \
	-I../../ \
        -I../../../Headers \
        -I../../../Headers/Additions

PocketSphinx_LIB_DIRS += -L../../../Source/$(GNUSTEP_OBJ_DIR) \
        -L/usr/local/lib -lgnustep-gui \
        $(RECOGNIZER_BASE_LIBS)

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

