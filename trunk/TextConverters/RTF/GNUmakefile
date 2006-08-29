#   GNUmakefile
#
#   Copyright (C) 2001 Free Software Foundation, Inc.
#
#   Author: Adam Fedor <fedor@gnu.org>
#
#   This file is part of GNUstep 
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

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME 		= RTFConverter
BUNDLE_INSTALL_DIR	=$(GNUSTEP_BUNDLES)/TextConverters

RTFConverter_OBJC_FILES = 		\
	RTFConsumer.m RTFProducer.m

RTFConverter_C_FILES =	 		\
	rtfGrammer.tab.c rtfScanner.c

RTFConverter_PRINCIPAL_CLASS = RTFConsumer

ifeq ($(GNUSTEP_TARGET_OS),mingw32)
RTFConverter_BUNDLE_LIBS += -lgnustep-gui $(FND_LIBS) $(OBJC_LIBS)
endif
ifeq ($(GNUSTEP_TARGET_OS),cygwin)
RTFConverter_BUNDLE_LIBS += -lgnustep-gui $(FND_LIBS) $(OBJC_LIBS)
endif

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

