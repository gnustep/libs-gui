/*
   libgnustep.m

   Main initialization routine for the GNUstep GUI Library

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/AppKit.h>

id NSApp;

char **NSArgv;

//
// The main entry point for X Windows
//
int
GNUstepMain(int argc, char **argv)
{
	NSFontManager *fm;

	// Create the global application object
	NSApp = [[NSApplication alloc] init];

	// Set the application default fonts
	fm = [NSFontManager sharedFontManager];
	[NSFont setUserFixedPitchFont: [fm fontWithFamily:@"Arial"
		traits:0 weight:0 size:10]];
	[NSFont setUserFont: [fm fontWithFamily:@"Times New Roman"
		traits:0 weight:0 size:12]];

	// Call the user's main
	//user_main(0, NULL);

	// Release the application
	[NSApp release];
}
