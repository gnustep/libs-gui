#
#  Tools level makefile for gsnd
#
#  Copyright (C) 2002 Free Software Foundation, Inc.
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

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

# The applications to be compiled
TOOL_NAME = gnustep_sndd

# The source files to be compiled
gnustep_sndd_OBJC_FILES = gsnd.m

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  gnustep_sndd_C_FILES = portaudio/pa_common/pa_lib.c \
                 portaudio/pa_win_ds/dsound_wrapper.c \
                 portaudio/pa_win_ds/pa_dsound.c
else
  gnustep_sndd_C_FILES = portaudio/pa_common/pa_lib.c \
                 portaudio/pa_unix_oss/pa_unix_oss.c \
                 portaudio/pa_common/pa_trace.c
endif

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble
