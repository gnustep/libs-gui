#
#  GSLPR Printing Backend Bundle makefile for GNUstep GUI Library
#
#  Copyright (C) 2004 Free Software Foundation, Inc.
#
#  Author: Chad Hardin <cehardin@mac.com
#
#  Date: June 2004
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
#  License along with this library; see the file COPYING.LIB.
#  If not, write to the Free Software Foundation,
#  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../../gui.make

include $(GNUSTEP_MAKEFILES)/common.make
include ../../config.make
include ../../Version

GNUSTEP_INSTALLATION_DIR=$(GNUSTEP_SYSTEM_ROOT)




BUNDLE_NAME=GSLPR
BUNDLE_INSTALL_DIR=	$(GNUSTEP_BUNDLES)/GSPrinting
GSLPR_PRINCIPAL_CLASS=GSLPRPrincipalClass



ifeq ($(GNUSTEP_TARGET_OS),mingw32)
GSLPR_BUNDLE_LIBS += -lgnustep-gui $(FND_LIBS) $(OBJC_LIBS)
endif
ifeq ($(GNUSTEP_TARGET_OS),cygwin)
GSLPR_BUNDLE_LIBS += -lgnustep-gui $(FND_LIBS) $(OBJC_LIBS)
endif



#
# Libraries
#
#GSLPR_LIBRARIES_DEPEND_UPON += 


#
# Resource files
#
#GSLPR_RESOURCE_FILES = 


#
# Header files
#
GSLPR_HEADERS= \
 GSLPRPrincipalClass.m \
 GSLPRPageLayout.m \
 GSLPRPrintInfo.m \
 GSLPRPrintOperation \
 GSLPRPrintPanel.m \
 GSLPRPrinter.m


#
# Class files
#
GSLPR_OBJC_FILES=	\
 GSLPRPrincipalClass.m \
 GSLPRPageLayout.m \
 GSLPRPrintInfo.m \
 GSLPRPrintOperation.m \
 GSLPRPrintPanel.m \
 GSLPRPrinter.m


#
# C files
#
#GSLPR_C_FILES = 


#
# Languages
#
#GSLPR_LANGUAGES= \
# English


#
# Localized Resource Files
#
#GSLPR_LOCALIZED_RESOURCE_FILES= \
# GSLPRPrintPanel.gorm \
# GSLPRPageLayout.gorm







#
# Makefiles
#
-include GNUmakefile.preamble
#include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
