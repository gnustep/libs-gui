#  GNUmakefile
#
#  Copyright (C) 1996 Free Software Foundation, Inc.
#
#  Author: Ovidiu Predescu <ovidiu@net-community.com>
#  Date: November 1997
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
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libgmodel

ifeq ($(GUI_LIB), nx)
TOOL_NAME = nib2gmodel
endif

# APP_NAME = test

libgmodel_OBJC_FILES = IMCustomObject.m IMConnectors.m IMLoading.m GMAppKit.m
libgmodel_HEADER_FILES_DIR = .
libgmodel_HEADER_FILES_INSTALL_DIR = /gnustep/gui/AppKit
libgmodel_HEADER_FILES = IMConnectors.h IMCustomObject.h IMLoading.h GMAppKit.h

test_OBJC_FILES = test.m Controller.m
test_MAIN_MODEL_FILE = test.gmodel
test_RESOURCES = test.gmodel

nib2gmodel_OBJC_FILES = IBClasses.m Translator.m nib2gmodel.m

# Additional library directories the linker should search
ifeq ($(FOUNDATION_LIB), nx)
ADDITIONAL_LIB_DIRS += -framework AppKit
endif

# Additional flags to pass to the Objective-C compiler
ADDITIONAL_OBJCFLAGS = -Wall
ADDITIONAL_CPPFLAGS += $(RUNTIME_DEFINE) $(GUI_DEFINE) $(BACKEND_DEFINE)

ADDITIONAL_LIB_DIRS += -L$(GNUSTEP_OBJ_DIR)

ADDITIONAL_TOOL_LIBS += -lgmodel -lFoundationExt
ADDITIONAL_OBJC_FLAGS += $(BACKEND_DEFINE)

# Additional include directories the compiler should search
ADDITIONAL_INCLUDE_DIRS = -I../Headers -I../Headers/gnustep

# What are the libraries this library depends upon. This is needed for some
# systems where building a shared library requires to pass to the linker
# all the libraries the target library depends upon.

LIBRARIES_DEPEND_UPON = -lFoundationExt $(FND_LIBS) $(GUI_LIBS) \
		$(BACKEND_LIBS) $(SYSTEM_LIBS)

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/tool.make
include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
