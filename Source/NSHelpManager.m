/* 
   NSHelpManager.m

   NSHelpManager is the class responsible for managing context help
   for the application, and its mapping to the graphic elements.

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Pedro Ivo Andrade Tavares <ptavares@iname.com>
   Date: September 1999
   
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

#include <gnustep/gui/config.h>
#include <AppKit/NSHelpManager.h>
#include <Foundation/NSNotification.h>

#include <Foundation/NSFileManager.h>
#include <Foundation/NSString.h>
#include <Foundation/NSBundle.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSWorkspace.h>
#include <AppKit/GSHelpManagerPanel.h>

@implementation NSBundle (NSHelpManager)

- (NSAttributedString*) contextHelpForKey: (NSString*) key
{
  id helpFile = nil;
  NSDictionary *contextHelp = 
    [[NSDictionary dictionaryWithContentsOfFile: 
		    [self pathForResource: @"Help" ofType: @"plist"]] retain];

  if(contextHelp)
    {
      helpFile = [contextHelp objectForKey: key];
    }

  if(helpFile)
    {
      return [NSUnarchiver unarchiveObjectWithData:
			     [helpFile objectForKey: @"NSHelpRTFContents"]];
    }
  else
    {
      helpFile = [self 
		   pathForResource: key 
		   ofType: @"rtf" 
		   inDirectory: @"Help"];
      return [[[NSAttributedString alloc] initWithPath: (NSString *)helpFile 
				 documentAttributes: nil] autorelease];
    }

  return nil;
}

@end

@implementation NSApplication (NSHelpManager)

- (void) showHelp: (id)sender
{
  NSBundle *mb = [NSBundle mainBundle];
  NSDictionary *info = [mb infoDictionary];
  NSString *help;

  help = [info objectForKey: @"GSHelpContentsFile"];

  if(!help)
    {
      help = [info objectForKey: @"NSExecutable"];
      // If there's no specification, we look for a file named "appname.rtf"
      [[NSWorkspace sharedWorkspace] 
	openFile: [mb pathForResource: help ofType: @"rtf"]];
    }
}

- (void) activateContextHelpMode: (id)sender
{
  [NSHelpManager setContextHelpModeActive: YES];
}

@end

@implementation NSHelpManager
{
@private
  NSMapTable* contextHelpTopics;
}

static NSHelpManager *_gnu_sharedHelpManager = nil;
static BOOL _gnu_contextHelpActive = NO;


//
// Class methods
//
+ (NSHelpManager*)sharedHelpManager
{
  if (!_gnu_sharedHelpManager)
    {
      _gnu_sharedHelpManager = [NSHelpManager alloc];
      [_gnu_sharedHelpManager init];
    }
  return _gnu_sharedHelpManager;
}

+ (BOOL)isContextHelpModeActive
{
  return _gnu_contextHelpActive;
}

+ (void)setContextHelpModeActive: (BOOL) flag
{
  _gnu_contextHelpActive = flag;
  if (flag)
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: NSContextHelpModeDidActivateNotification 
	object: [self sharedHelpManager]];
    }
  else
    {
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: NSContextHelpModeDidDeactivateNotification 
	object: [self sharedHelpManager]];
    }
}

//
// Instance methods
//
- (id) init
{
  contextHelpTopics = NSCreateMapTable(NSObjectMapKeyCallBacks,
				       NSObjectMapValueCallBacks,
				       64);
  return self;
}

- (NSAttributedString*) contextHelpForObject: (id)object
{
  /* Help is kept on the contextHelpTopics NSMapTable, with
     the object for it as the key. 
     
     Help is loaded on demand:
     If it's an NSAttributedString which is stored, then it's already 
     loaded. 
     If it's nil, there's no help for this object, and that's what we return.
     If it's an NSString, it's the path for the help, and we ask NSBundle
     for it. */
  // FIXME: Check this implementation when NSResponders finally store what
  // their context help is.
     
  id hc = NSMapGet(contextHelpTopics, object);
  if(hc)
    {
      if(![hc isKindOfClass: [NSAttributedString class]])
	{
	  hc = [[NSBundle mainBundle] contextHelpForKey: hc];
	  /* We store the retrieved value, or remove the key from
	     the table if nil returns (note that it's OK if the key
	     does not exist already. */
	  if (hc)
	    NSMapInsert(contextHelpTopics, object, hc);
	  else 	    
	    NSMapRemove(contextHelpTopics, object);
	}
    }
  return hc;
}

- (void) removeContextHelpForObject: (id)object
{
  NSMapRemove(contextHelpTopics, object);
}

- (void) setContextHelp: (NSAttributedString*) help withObject: (id) object
{
  NSMapInsert(contextHelpTopics, object, help);
}

- (BOOL) showContextHelpForObject: (id)object locationHint: (NSPoint) point
{
  id contextHelp = [self contextHelpForObject: object];
  if (contextHelp)
    {
      [[GSHelpManagerPanel sharedHelpManagerPanel] setHelpText: contextHelp];
      [NSApp runModalForWindow: [GSHelpManagerPanel sharedHelpManagerPanel]];
      return YES;
    }
  else return NO;
}

@end
