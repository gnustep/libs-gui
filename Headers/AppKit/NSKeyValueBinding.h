/** <title>NSKeyValueBinding</title>

   <abstract>Interfae declaration for key value binding</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: June 2006

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

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

#ifndef _GNUstep_H_NSKeyValueBinding
#define _GNUstep_H_NSKeyValueBinding

#include <Foundation/NSObject.h>

#if OS_API_VERSION(100300,GS_API_LATEST)

@class NSString;
@class NSArray;
@class NSDictionary;


@interface NSObject (NSKeyValueBindingCreation)

+ (void) exposeBinding: (NSString *)key;

- (NSArray *) exposedBindings;
- (Class) valueClassForBinding: (NSString *)binding;
- (void) bind: (NSString *)binding 
     toObject: (id)controller 
  withKeyPath: (NSString *)keyPath 
      options: (NSDictionary *)options;
- (void) unbind: (NSString *)binding;
- (void) commitEditingWithDelegate: (id)delegate
                 didCommitSelector: (SEL)didCommitSelector 
                       contextInfo: (void *)contextInfo;
- (NSDictionary *) infoForBinding: (NSString *)binding;

@end

@interface NSObject (NSPlaceholder)

+ (id) defaultPlaceholderForMarker: (id)marker 
                       withBinding: (NSString *)binding;
+ (void) setDefaultPlaceholder: (id)placeholder 
                     forMarker: (id)marker 
                   withBinding: (NSString *)binding;

@end


@interface NSObject (NSEditor)

- (BOOL) commitEditing;
- (void) discardEditing;

@end

@interface NSObject (NSEditorRegistration)

- (void) objectDidBeginEditing: (id)editor;
- (void) objectDidEndEditing: (id)editor;

@end

// Keys in options dictionary

// binding values

// Keys in dictionary returned by infoForBinding
APPKIT_EXPORT NSString *NSObservedObjectKey;
APPKIT_EXPORT NSString *NSObservedKeyPath;
APPKIT_EXPORT NSString *NSOptionsKey;

// special markers
APPKIT_EXPORT id NSMultipleValuesMarker;
APPKIT_EXPORT id NSNoSelectionMarker;
APPKIT_EXPORT id NSNotApplicableMarker;

#endif // OS_API_VERSION

#endif // _GNUstep_H_NSKeyValueBinding
