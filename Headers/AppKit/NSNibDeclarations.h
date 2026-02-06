/** <title>NSNibDeclarations</title>

    <abstract>Interface Builder annotation macros and declarations</abstract>

    This header provides macro definitions and declarations used by Interface
    Builder and other visual development tools to annotate Objective-C code
    for automatic user interface construction and connection.

    The primary macros defined here are:
    * IBOutlet - Marks instance variables as outlets for interface connections
    * IBAction - Marks methods as actions that can be connected to UI controls

    These macros serve as annotations that are recognized by Interface Builder
    when parsing header files to identify properties and methods that should
    be available for visual connection in the interface design process.

    While these macros expand to empty declarations at compile time (except
    for IBAction which expands to void), they provide crucial metadata for
    development tools that generate and maintain user interface connections.

    Copyright (C) 1999 Free Software Foundation, Inc.

    Author:  Michael Giddings <giddings@genetics.utah.edu>
    Date: Feb. 1999

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

#ifndef _NSNibDeclarations_H_
#define _NSNibDeclarations_H_
#import <AppKit/AppKitDefines.h>

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/* IBOutlet and IBAction are now built-in macros in recent Clang */
#if !defined(IBOutlet)
#define IBOutlet
#endif
#if !defined(IBAction)
#define IBAction void
#endif
#if !defined(IBOutletCollection)
#define IBOutletCollection(ClassName)
#endif
#endif

#endif
