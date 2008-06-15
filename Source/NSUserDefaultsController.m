/** <title>NSUserDefaultsController</title>

   <abstract>Controller class for user defaults</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: September 2006

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include <Foundation/NSDictionary.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSUserDefaultsController.h>

static id shared = nil;

@implementation NSUserDefaultsController

+ (id) sharedUserDefaultsController
{
  if (shared == nil)
    {
	shared = [[NSUserDefaultsController alloc] 
		     initWithDefaults: nil
		     initialValues: nil];    
    }
  return shared;
}

- (id) initWithDefaults: (NSUserDefaults*)defaults
          initialValues: (NSDictionary*)initialValues
{
  if ((self = [super init]) != nil)
    {
      if (defaults == nil)
	{
	  defaults = [NSUserDefaults standardUserDefaults];
	}
	
      ASSIGN(_defaults, defaults);
      [self setInitialValues: initialValues];
    }

  return self;
}

- (NSUserDefaults*) defaults
{
  return _defaults;
}

- (id) values
{
  // TODO
  return nil;  
}

- (NSDictionary*) initialValues
{
  return _initial_values;
}

- (void) setInitialValues: (NSDictionary*)values
{
  ASSIGN(_initial_values, values);
}

- (BOOL) appliesImmediately
{
  return _applies_immediately;
}

- (void) setAppliesImmediately: (BOOL)flag
{
  _applies_immediately = flag; 
}

- (void) revert: (id)sender
{
  [self discardEditing];
  if (![self appliesImmediately])
    {
      // TODO
    } 
}

- (void) revertToInitialValues: (id)sender
{
  // TODO
}

- (void) save: (id)sender
{
  // TODO
}

@end
