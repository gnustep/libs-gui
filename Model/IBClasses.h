/*
   IBClasses.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: November 1997
   
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

/* This is a list of classes used internally by the NeXT's NIB stuff. These
   classes were generated using the class-dump utility. */

#ifndef _GNUstep_H_IBClasses
#define _GNUstep_H_IBClasses

#import <Foundation/NSObject.h>

@class NSString;

@interface NSCustomObject : NSObject
{
    NSString *className;
    id realObject;
    id extension;
}
@end


@interface NSIBConnector : NSObject
{
    id source;
    id destination;
    NSString *label;
}
@end

@interface NSIBOutletConnector : NSIBConnector
@end

@interface NSIBControlConnector : NSIBConnector
@end

#endif /* _GNUstep_H_IBClasses */
