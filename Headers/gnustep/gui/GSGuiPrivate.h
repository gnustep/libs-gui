/* 
   GSGuiPrivate.h

   Define private functions for use in the GNUstep GUI Library

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Nicola Pero <nicola@brainstorm.co.uk>
   Date: 2001
   
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

#ifndef _GNUstep_H_GSGuiPrivate
#define _GNUstep_H_GSGuiPrivate

#include <Foundation/NSBundle.h>

/*
 * Return the gnustep-gui bundle used to load gnustep-gui resources.
 * Should be only used inside the gnustep-gui library.  Implemented
 * in Source/NSApplication.m
 */
NSBundle *GSGuiBundle ();

/*
 * Localize a message of the gnustep-gui library.  When we have a tool
 * generating the Localizable.strings file, we'll have it read strings
 * from any function/macro name of the form GSXXXLocalizedString (,),
 * and that should cover all invocations of GSGuiLocalizedString().
 * What a pain to type this long name for all strings.
 */
static inline NSString *GSGuiLocalizedString (NSString *key, NSString *comment)
{
  NSBundle *b = GSGuiBundle ();

  if (b != nil)
    {
      return [b localizedStringForKey: key  value: @""  table: nil];
    }
  else
    {
      return key;
    }
}

#endif /* _GNUstep_H_GSGuiPrivate */



