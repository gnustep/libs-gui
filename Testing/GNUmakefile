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

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make

include $(GNUSTEP_MAKEFILES)/common.make

TEST_TOOL_NAME = testpb
testpb_OBJC_FILES = testpb.m Functions.m

include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/test-tool.make

include GNUmakefile.postamble
