#
#  Copyright (C) 2001 Free Software Foundation, Inc.
#
#  Author: Nicola Pero <n.pero@mi.flashnet.it>
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

include $(GNUSTEP_MAKEFILES)/common.make

include $(GNUSTEP_MAKEFILES)/rules.make

$(GNUSTEP_LIBRARY)/KeyBindings:
	$(MKINSTALLDIRS) $@

after-install:: $(GNUSTEP_LIBRARY)/KeyBindings
	$(INSTALL_DATA) DefaultKeyBindings.dict \
	                $(GNUSTEP_LIBRARY)/KeyBindings/

after-uninstall::
	rm -f $(GNUSTEP_LIBRARY)/KeyBindings/DefaultKeyBindings.dict
