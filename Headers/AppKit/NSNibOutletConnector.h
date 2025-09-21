/*
   NSNibOutletConnector.h

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@branstorm.co.uk>
   Date: 1999

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

#ifndef _GNUstep_H_NSNibOutletConnector
#define _GNUstep_H_NSNibOutletConnector

#import <AppKit/NSNibConnector.h>

APPKIT_EXPORT_CLASS
/**
 * NSNibOutletConnector is a specialized connector class that manages outlet
 * connections between objects in Interface Builder nib files. This class
 * inherits from NSNibConnector and provides the specific implementation for
 * establishing outlet connections during nib loading and object instantiation.
 * Outlet connections link instance variables or properties of objects to
 * other objects in the interface, enabling automatic wiring of user interface
 * components to controller objects. The connector maintains references to
 * the source object, destination object, and the outlet name that defines
 * the connection relationship. During nib loading, NSNibOutletConnector
 * instances are processed to establish the actual runtime connections between
 * objects, using key-value coding or direct instance variable assignment to
 * complete the outlet binding process. This enables the declarative interface
 * design paradigm where connections are defined visually and established
 * automatically at runtime.
 */
@interface NSNibOutletConnector : NSNibConnector
/**
 * Establishes the outlet connection between the source and destination objects
 * as specified by this connector. This method performs the actual runtime
 * connection process by setting the outlet property or instance variable of
 * the source object to reference the destination object. The connection is
 * typically established during nib loading after all objects have been
 * instantiated and are ready for interconnection. The method uses the outlet
 * name stored in the connector to identify which property or instance variable
 * should be set on the source object. The connection process may use key-value
 * coding mechanisms or direct instance variable access depending on the
 * implementation and object characteristics. This method completes the
 * declarative connection process defined in Interface Builder by creating
 * the actual runtime object references that enable proper user interface
 * functionality and object communication.
 */
- (void) establishConnection;
@end

#endif
