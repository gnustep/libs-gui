/** <title>NSInputManager</title>                              -*-objc-*-

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 2001

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

#include <AppKit/NSEvent.h>
#include <AppKit/NSInputManager.h>
#include <AppKit/NSInputServer.h>
#include <AppKit/NSText.h>

/* A table mapping character names to characters, used to interpret
   the character names found in KeyBindings dictionary files.  */
#define CHARACTER_TABLE_SIZE 77

static struct 
{
  NSString *name;
  unichar character;
} 
character_table[CHARACTER_TABLE_SIZE] =
{
  /* Function keys.  */
  { @"UpArrow", NSUpArrowFunctionKey },
  { @"DownArrow", NSDownArrowFunctionKey },
  { @"LeftArrow", NSLeftArrowFunctionKey },
  { @"RightArrow", NSRightArrowFunctionKey },
  { @"F1", NSF1FunctionKey },
  { @"F2", NSF2FunctionKey },
  { @"F3", NSF3FunctionKey },
  { @"F4", NSF4FunctionKey },
  { @"F5", NSF5FunctionKey },
  { @"F6", NSF6FunctionKey },
  { @"F7", NSF7FunctionKey },
  { @"F8", NSF8FunctionKey },
  { @"F9", NSF9FunctionKey },
  { @"F10", NSF10FunctionKey },
  { @"F11", NSF11FunctionKey },
  { @"F12", NSF12FunctionKey },
  { @"F13", NSF13FunctionKey },
  { @"F14", NSF14FunctionKey },
  { @"F15", NSF15FunctionKey },
  { @"F16", NSF16FunctionKey },
  { @"F17", NSF17FunctionKey },
  { @"F18", NSF18FunctionKey },
  { @"F19", NSF19FunctionKey },
  { @"F20", NSF20FunctionKey },
  { @"F21", NSF21FunctionKey },
  { @"F22", NSF22FunctionKey },
  { @"F23", NSF23FunctionKey },
  { @"F24", NSF24FunctionKey },
  { @"F25", NSF25FunctionKey },
  { @"F26", NSF26FunctionKey },
  { @"F27", NSF27FunctionKey },
  { @"F28", NSF28FunctionKey },
  { @"F29", NSF29FunctionKey },
  { @"F30", NSF30FunctionKey },
  { @"F31", NSF31FunctionKey },
  { @"F32", NSF32FunctionKey },
  { @"F33", NSF33FunctionKey },
  { @"F34", NSF34FunctionKey },
  { @"F35", NSF35FunctionKey },
  { @"Insert", NSInsertFunctionKey },
  { @"Delete", NSDeleteFunctionKey },
  { @"Home", NSHomeFunctionKey },
  { @"Begin", NSBeginFunctionKey },
  { @"End", NSEndFunctionKey },
  { @"PageUp", NSPageUpFunctionKey },
  { @"PageDown", NSPageDownFunctionKey },
  { @"PrintScreen", NSPrintScreenFunctionKey },
  { @"ScrollLock", NSScrollLockFunctionKey },
  { @"Pause", NSPauseFunctionKey },
  { @"SysReq", NSSysReqFunctionKey },
  { @"Break", NSBreakFunctionKey },
  { @"Reset", NSResetFunctionKey },
  { @"Stop", NSStopFunctionKey },
  { @"Menu", NSMenuFunctionKey },
  { @"User", NSUserFunctionKey },
  { @"System", NSSystemFunctionKey },
  { @"Print", NSPrintFunctionKey },
  { @"ClearLine", NSClearLineFunctionKey },
  { @"ClearDisplay", NSClearDisplayFunctionKey },
  { @"InsertLine", NSInsertLineFunctionKey },
  { @"DeleteLine", NSDeleteLineFunctionKey },
  { @"InsertChar", NSInsertCharFunctionKey },
  { @"DeleteChar", NSDeleteCharFunctionKey },
  { @"Prev", NSPrevFunctionKey },
  { @"Next", NSNextFunctionKey },
  { @"Select", NSSelectFunctionKey },
  { @"Execute", NSExecuteFunctionKey },
  { @"Undo", NSUndoFunctionKey },
  { @"Redo", NSRedoFunctionKey },
  { @"Find", NSFindFunctionKey },
  { @"Help", NSHelpFunctionKey },
  { @"ModeSwitch", NSModeSwitchFunctionKey },

  /* Special characters by name.  Useful if you want, for example,
     to associate some special action to C-Tab or similar evils.  */
  { @"Backspace", NSBackspaceCharacter },
  { @"Tab", NSTabCharacter },
  { @"Enter", NSEnterCharacter },
  { @"FormFeed", NSFormFeedCharacter },
  { @"CarriageReturn", NSCarriageReturnCharacter }
};

static NSInputManager *currentInputManager = nil;


@implementation NSInputManager

+ (NSInputManager *) currentInputManager
{
  if (currentInputManager == nil)
    {
      currentInputManager = [[self alloc] initWithName: nil  host: nil];
    }
  
  return currentInputManager;
}

- (void) bindKey: (NSString *)key  toAction: (NSString *)action
{
  /* First we try to parse the key into a character/flags couple  */
  unichar character = 0;
  unsigned flags = 0;
  BOOL isFunctionKey = NO;
  /* Then we parse the action into a selector  */
  SEL selector;

  NSString *c;

  /* Parse the key: first break it into segments separated by - */
  NSArray *components = [key componentsSeparatedByString: @"-"];

  /* Then, parse the modifiers.  The modifiers are the components 
     - all of them except the last one!  */
  int i, count = [components count];
  int index;

  for (i = 0; i < count - 1; i++)
    {
      NSString *modifier = [components objectAtIndex: i];
      
      if ([modifier isEqualToString: @"Control"] 
	  || [modifier isEqualToString: @"Ctrl"] 
	  || [modifier isEqualToString: @"C"])
	{
	  flags |= NSControlKeyMask;
	}
      else if ([modifier isEqualToString: @"Alternate"] 
	       || [modifier isEqualToString: @"Alt"] 
	       || [modifier isEqualToString: @"A"]
	       || [modifier isEqualToString: @"Meta"]
	       || [modifier isEqualToString: @"M"])
	{
	  flags |= NSAlternateKeyMask;
	}
      else if ([modifier isEqualToString: @"Shift"] 
	       || [modifier isEqualToString: @"S"])
	{
	  flags |= NSShiftKeyMask;
	}
      else
	{
	  NSLog (@"NSInputManager - unknown modifier '%@' ignored", modifier);
	}
    }

  /* The actual index in the little SEL table is the following one.  */
  index = flags / 2;
  
  /* Now, parse the actual key.  */
  c = [components objectAtIndex: (count - 1)];
  
  if ([c isEqualToString: @""])
    {
      /* This happens if '-' was the character.  */
      character = '-';
    }
  else if ([c length] == 1)
    {
      /* A single character, such as 'a'.  */
      character = [c characterAtIndex: 0];
    }
  else
    {
      /* A descriptive string, such as Tab or Home.  */
      for (i = 0; i < CHARACTER_TABLE_SIZE; i++)
	{
	  if ([c isEqualToString: (character_table[i]).name])
	    {
	      character = (character_table[i]).character;
	      isFunctionKey = YES;
	      break;
	    }
	}
      if (i == CHARACTER_TABLE_SIZE)
	{
	  NSLog (@"NSInputManager - unknown character '%@' ignored", c);
	  return;
	}
    }  

  /* "" as action means disable the keybinding.  It can be used to override
     a previous keybinding.  */
  if ([action isEqualToString: @""])
    {
      selector = NULL;
    }
  else
    {
      selector = NSSelectorFromString (action);
      if (selector == NULL)
       {
         NSLog (@"NSInputManager: unknown selector '%@' ignored", action);
         return;
       }
    }
    
  /* Check if there are already some bindings for this character.  */
  for (i = 0; i < _bindingsCount; i++)
    {
      if (_bindings[i].character == character)
	{
	  (_bindings[i]).selector[index] = selector;
	  if (!isFunctionKey)
	    {
	      /* Not a function key - set the selector for the character
		 with shift as well - we don't actually know if the character
		 is typed with shift or not ! */
	      flags |= NSShiftKeyMask;
	      index = flags / 2;
	      
	      (_bindings[i]).selector[index] = selector;
	    }
	  return;
	}
    }

  /* Ok - allocate memory for the new binding.  */
  if (_bindingsCount == 0)
    {
      _bindingsCount = 1;
      _bindings = objc_malloc (sizeof (struct _GSInputManagerBinding));
    }
  else
    {
      _bindingsCount++;
      _bindings = objc_realloc (_bindings, 
				sizeof (struct _GSInputManagerBinding) 
				* _bindingsCount);
    }
  _bindings[_bindingsCount - 1].character = character;

  /* Set to NULL all selectors.  */
  for (i = 0; i < 8; i++)
    {
      (_bindings[_bindingsCount - 1]).selector[i] = NULL;
    }

  /* Now save the selector.  */
  (_bindings[_bindingsCount - 1]).selector[index] = selector;
  if (!isFunctionKey)
    {
      /* Not a function key - set the selector for the character
	 with shift as well - we don't actually know if the character
	 is typed with shift or not ! */
      flags |= NSShiftKeyMask;
      index = flags / 2;
      
      (_bindings[_bindingsCount - 1]).selector[index] = selector;
    }
}

- (void) dealloc
{
  objc_free (_bindings);
  return;
}

- (void) loadBindingsFromFile: (NSString *)fullPath
{
  NS_DURING
    {
      NSDictionary *bindings;
      NSEnumerator *e;
      NSString *key;
      
      bindings = [NSDictionary dictionaryWithContentsOfFile: fullPath];
      if (bindings == nil)
	{
	  [NSException raise];
	}
      
      e = [bindings keyEnumerator];
      while ((key = [e nextObject]) != nil)
	{
	  [self bindKey: key  
		toAction: [bindings objectForKey: key]];
	}
    }
  NS_HANDLER
    {
      NSLog (@"Unable to load KeyBindings from file %@", fullPath);
    }
  NS_ENDHANDLER 
}

- (void) loadBindingsWithName: (NSString *)fileName
{
  NSArray *paths;
  NSEnumerator *enumerator;
  NSString *bundlePath;
  
  paths = NSSearchPathForDirectoriesInDomains (GSLibrariesDirectory,
					       NSAllDomainsMask, YES);
  /* paths are in the order - user, network, local, root. Instead we
     want to load keybindings in the order root, local, network, user
     - so that user can override root - for this reason we use a
     reverseObjectEnumerator.  */
  enumerator = [paths reverseObjectEnumerator];
  while ((bundlePath = [enumerator nextObject]) != nil)
    {
      NSBundle *bundle = [NSBundle bundleWithPath: bundlePath];
      NSString *fullPath = [bundle pathForResource: fileName
				   ofType: @"dict"
				   inDirectory: @"KeyBindings"];
      if (fullPath != nil)
	{
	  [self loadBindingsFromFile: fullPath];
	}
    }
}

- (NSInputManager *) initWithName: (NSString *)inputServerName
			     host: (NSString *)hostName
{
  NSString *defaultKeyBindings;
  NSArray *customKeyBindings;
  NSUserDefaults *defaults;
  CREATE_AUTORELEASE_POOL (pool);

  defaults = [NSUserDefaults standardUserDefaults];

  self = [super init];

  /* Normally, when we start up, we load all the keybindings we find
     in the following files, in this order:
     
     $GNUSTEP_SYSTEM_ROOT/Libraries/Resources/KeyBindings/DefaultKeyBindings.dict
     $GNUSTEP_LOCAL_ROOT/Libraries/Resources/KeyBindings/DefaultKeyBindings.dict
     $GNUSTEP_NETWORK_ROOT/Libraries/Resources/KeyBindings/DefaultKeyBindings.dict
     $GNUSTEP_USER_ROOT/Libraries/Resources/KeyBindings/DefaultKeyBindings.dict
     
     This gives you a first way of adding your customized keybindings
     - adding a DefaultKeyBindings.dict to your GNUSTEP_USER_ROOT, and
     putting additional keybindings in there.  This allows you to add
     new keybindings to the standard ones, or override standard ones
     with your own.  These keybindings are normally used by all your
     applications (this is why they are in 'DefaultKeyBindings').

     In addition, you can specify a list of additional key bindings
     files to be loaded by setting the GSCustomKeyBindings default to
     an array of file names.  We will attempt to load all those
     keybindings in a way similar to what we do with the
     DefaultKeyBindings.  We load them after the default ones, in the
     order you specify.  This allows you to have application-specific
     keybindings, where you put different keybindings in different
     files, and run different applications with different
     GSCustomKeyBindings, telling them to use different keybindings
     files.

     Last, in special cases you might want to have the
     DefaultKeybindings totally ignored.  In this case, you set the
     GSDefaultKeyBindings variable to a different filename (different
     from 'DefaultKeybindings').  We attempt to load all keybindings
     stored in the files with that name where we normally would load
     DefaultKeybindings.  */

  /* First, load the DefaultKeyBindings.  */
  defaultKeyBindings = [defaults stringForKey: @"GSDefaultKeyBindings"];
  
  if (defaultKeyBindings == nil)
    {
      defaultKeyBindings = @"DefaultKeyBindings";
    }
  
  [self loadBindingsWithName: defaultKeyBindings];
  
  /* Then, if any, the CustomKeyBindings, in the specified order.  */
  customKeyBindings = [defaults arrayForKey: @"GSCustomKeyBindings"];
  
  if (customKeyBindings != nil)
    {
      int i, count = [customKeyBindings count];
      Class string = [NSString class];

      for (i = 0; i < count; i++)
	{
	  NSString *filename = [customKeyBindings objectAtIndex: i];
	  
	  if ([filename isKindOfClass: string])
	    {
	      [self loadBindingsWithName: filename];
	    }
	}
    }

  RELEASE (pool);
  
  return self;
}

- (void) handleKeyboardEvents: (NSArray *)eventArray
		       client: (id)client
{
  NSEvent *theEvent;
  NSEnumerator *eventEnum = [eventArray objectEnumerator];

  _currentClient = client;

  while ((theEvent = [eventEnum nextObject]) != nil)
    {
      NSString *characters = [theEvent characters];
      NSString *unmodifiedCharacters = [theEvent charactersIgnoringModifiers];
      unichar character = 0;
      unsigned flags = [theEvent modifierFlags] & (NSShiftKeyMask 
						   | NSAlternateKeyMask 
						   | NSControlKeyMask);
      BOOL done = NO;
      int i;
      
      if ([unmodifiedCharacters length] > 0)
	{
	  character = [unmodifiedCharacters characterAtIndex: 0];
	}

      
      /* Look up the character in the keybindings dictionary.  */
      for (i = 0; i < _bindingsCount; i++)
	{
	  if (_bindings[i].character == character)
	    {
	      SEL selector  = (_bindings[i]).selector[flags / 2];
	      
	      if (selector == NULL)
		{
		  /* Get out of loop with done = NO - we found the
		     keybinding, but it was bound to the default
		     action, so we stop searching and fall back on the
		     default action.  */
		  break;
		}
	      else
		{
		  [self doCommandBySelector: selector];
		  done = YES;
		  break;
		}
	    }
	}

      /* If not yet found, perform the default action.  */
      if (!done)
	{
	  switch (character)
	    {
	    case NSBackspaceCharacter:
	      [self doCommandBySelector: @selector (deleteBackward:)];
	      break;

	    case NSTabCharacter:
	      if (flags & NSShiftKeyMask)
		{
		  [self doCommandBySelector: @selector (insertBacktab:)];
		}
	      else
		{
		  [self doCommandBySelector: @selector (insertTab:)];
		}
	      break;

	    case NSEnterCharacter:
	    case NSFormFeedCharacter:
	    case NSCarriageReturnCharacter:
	      [self doCommandBySelector: @selector (insertNewline:)];
	      break;

	    default:
	      [self insertText: characters];
	      break;
	    }
	}
    }
}


- (BOOL) handleMouseEvent: (NSEvent *)theMouseEvent
{
  return NO;
}

- (NSString *) language
{
  return @"English";
}


- (NSString *) localizedInputManagerName
{
  return nil;
}

- (void) markedTextAbandoned: (id)client
{}

- (void) markedTextSelectionChanged: (NSRange)newSel
			     client: (id)client
{}

- (BOOL) wantsToDelayTextChangeNotifications
{
  return NO;
}

- (BOOL) wantsToHandleMouseEvents
{
  return NO;
}

- (BOOL) wantsToInterpretAllKeystrokes
{
  return NO;
}

- (void) setMarkedText: (id)aString 
	 selectedRange: (NSRange)selRange
{}

- (BOOL) hasMarkedText
{
  return NO;
}

- (NSRange) markedRange
{
  return NSMakeRange (NSNotFound, 0);
}

- (NSRange) selectedRange
{
  return NSMakeRange (NSNotFound, 0);
}

- (void) unmarkText
{}

- (NSArray*) validAttributesForMarkedText
{
  return nil;
}

- (NSAttributedString *) attributedSubstringFromRange: (NSRange)theRange
{
  return nil;
}

- (unsigned int) characterIndexForPoint: (NSPoint)thePoint
{
  return 0;
}

- (long) conversationIdentifier
{
  return 0;
}

- (void) doCommandBySelector: (SEL)aSelector
{
  [_currentClient doCommandBySelector: aSelector];
}

- (NSRect) firstRectForCharacterRange: (NSRange)theRange
{
  return NSZeroRect;
}

- (void) insertText: (id)aString
{
  [_currentClient insertText: aString];
}

@end
