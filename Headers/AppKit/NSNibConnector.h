/*
   NSNibConnector.h

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

#ifndef _GNUstep_H_NSNibConnector
#define _GNUstep_H_NSNibConnector
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>

@class NSString;

APPKIT_EXPORT_CLASS
/**
 * NSNibConnector is the abstract base class for objects that represent
 * connections between user interface elements and their controllers in
 * Interface Builder nib files. This class provides the fundamental
 * infrastructure for establishing relationships between objects during
 * nib loading and instantiation. Connectors maintain references to source
 * and destination objects along with identifying labels that specify the
 * nature of the connection. The class supports the declarative interface
 * paradigm by storing connection metadata that is processed at runtime
 * to establish actual object relationships. Subclasses like NSNibOutletConnector
 * and NSNibControlConnector provide specific implementations for different
 * types of connections such as outlet bindings and action-target relationships.
 * The connector system enables visual interface design tools to create
 * complex object interconnections that are automatically established when
 * nib files are loaded, bridging the gap between design-time declarations
 * and runtime object behavior.
 */
@interface NSNibConnector : NSObject <NSCoding>
{
  id		_src;
  id		_dst;
  NSString	*_tag;
}

/**
 * Returns the destination object of this connector. The destination object
 * represents the target end of the connection relationship, typically the
 * object that will receive messages or be assigned to properties during
 * connection establishment. For outlet connections, the destination is
 * usually a user interface element that will be referenced by the source
 * object. For action connections, the destination is the object that will
 * receive action messages from user interface controls. The destination
 * object is established during nib loading when objects are instantiated
 * and their relationships are resolved. This method provides access to
 * the destination for connection processing and relationship management.
 */
- (id) destination;
/**
 * Establishes the actual connection between the source and destination
 * objects according to the connector's configuration. This abstract method
 * must be overridden by subclasses to provide specific connection behavior
 * appropriate for their connection type. The connection establishment process
 * typically occurs during nib loading after all objects have been instantiated
 * and are ready for interconnection. For outlet connectors, this might involve
 * setting instance variables or properties using key-value coding. For action
 * connectors, this might involve configuring target-action relationships on
 * user interface controls. The method coordinates the final step in the
 * declarative connection process defined in Interface Builder.
 */
- (void) establishConnection;
/**
 * Returns the label string that identifies this connector's connection type
 * or target property. The label typically corresponds to the name of an
 * outlet, action, or other connection identifier that was specified in
 * Interface Builder during the visual connection process. For outlet
 * connections, the label usually matches the name of an instance variable
 * or property on the source object. For action connections, the label
 * typically corresponds to an action method name. This identifier is used
 * during connection establishment to determine the specific connection
 * behavior and target location for the relationship. The label provides
 * the semantic meaning that transforms generic source-destination relationships
 * into specific functional connections.
 */
- (NSString*) label;
/**
 * Replaces references to one object with another object within this connector's
 * configuration. This method is used during nib loading when object references
 * need to be updated, typically when placeholder objects are replaced with
 * actual instances or when object identity changes during the instantiation
 * process. The anObject parameter specifies the object to be replaced, while
 * anotherObject specifies the replacement object. The connector updates its
 * internal references to maintain correct connection relationships even when
 * object identities change during nib loading. This mechanism ensures that
 * connections remain valid throughout the complex object instantiation and
 * replacement processes that occur during nib file processing.
 */
- (void) replaceObject: (id)anObject withObject: (id)anotherObject;
/**
 * Returns the source object of this connector. The source object represents
 * the originating end of the connection relationship, typically the object
 * that will contain references to other objects or initiate communication.
 * For outlet connections, the source is usually a controller object that
 * will maintain references to user interface elements. For action connections,
 * the source is typically a user interface control that will send action
 * messages to target objects. The source object is established during nib
 * loading when objects are instantiated and their relationships are resolved.
 * This method provides access to the source object for connection processing
 * and relationship management during the nib loading process.
 */
- (id) source;
/**
 * Sets the destination object for this connector. The anObject parameter
 * specifies the target object that will serve as the destination end of
 * the connection relationship. This method is typically called during nib
 * loading when objects are being instantiated and connections are being
 * configured. The destination object represents the target of the connection,
 * which might be a user interface element for outlet connections or a
 * controller object for action connections. Setting the destination establishes
 * one half of the connection relationship that will be completed when the
 * connection is established. The destination must be compatible with the
 * connection type and the requirements of the source object.
 */
- (void) setDestination: (id)anObject;
/**
 * Sets the label string that identifies this connector's connection type
 * or target property. The label parameter specifies the connection identifier
 * that corresponds to outlet names, action method names, or other connection
 * semantics defined in Interface Builder. This label is used during connection
 * establishment to determine the specific behavior and target for the
 * relationship. For outlet connections, the label typically matches an
 * instance variable or property name on the source object. For action
 * connections, the label usually corresponds to an action method signature.
 * Setting the appropriate label ensures that the connector can establish
 * the correct type of connection with the proper semantic meaning during
 * nib loading.
 */
- (void) setLabel: (NSString*)label;
/**
 * Sets the source object for this connector. The anObject parameter specifies
 * the originating object that will serve as the source end of the connection
 * relationship. This method is typically called during nib loading when
 * objects are being instantiated and connections are being configured. The
 * source object represents the origin of the connection, which might be a
 * controller object for outlet connections or a user interface control for
 * action connections. Setting the source establishes one half of the connection
 * relationship that will be completed when the connection is established.
 * The source must be compatible with the connection type and capable of
 * participating in the intended relationship with the destination object.
 */
- (void) setSource: (id)anObject;
@end

#import <AppKit/NSNibControlConnector.h>
#import <AppKit/NSNibOutletConnector.h>

#endif

