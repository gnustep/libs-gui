/* GSWraps.h - Definitions of PostScript wraps for NSGraphicsContext

   Copyright (C) 1999 Free Software Foundation, Inc.
   Written by:  Adam Fedor <fedor@gnu.org>
   
   This file is part of the GNU Objective C User Interface library.
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111
   */

#ifndef _GSWraps_h_INCLUDE
#define _GSWraps_h_INCLUDE

#include <AppKit/NSGraphicsContext.h>

/* Context helper wraps */
extern unsigned int GSWDefineAsUserObj(NSGraphicsContext *ctxt);

extern void GSWViewIsFlipped(NSGraphicsContext *ctxt, BOOL flipped);

#endif
