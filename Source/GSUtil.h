/*
   GSUtil.h

   Some utility functions that are shared by several classes.


   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Pascal J. Bourguignon <pjb@imaginet.fr>
   Date: 2000-03-10
   Modifications: 
   Date: 

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
#ifndef GSUtil_h
#define GSUtil_h

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>


    extern NSSize GSUtil_sizeOfMultilineStringWithFont(NSString* string,
                                                       NSFont* font);
        /*
            RETURN:   the width of the longest line in string as written 
                      with font and the number of lines * the font height.
        */


#endif // GSUtil_h

/*** GSUtil.h                         -- 2000-03-10 06:39:50 -- PJB ***/
