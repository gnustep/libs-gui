/*
   AppKitExceptions.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: February 1997
   
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
#ifndef __AppKit_AppKitExceptions_h__
#define __AppKit_AppKitExceptions_h__

@class NSString;

extern NSString *NSAbortModalException;
extern NSString *NSAbortPrintingException;
extern NSString *NSAppKitIgnoredException;
extern NSString *NSAppKitVirtualMemoryException;
extern NSString *NSBadBitmapParametersException;
extern NSString *NSBadComparisonException;
extern NSString *NSBadRTFColorTableException;
extern NSString *NSBadRTFDirectiveException;
extern NSString *NSBadRTFFontTableException;
extern NSString *NSBadRTFStyleSheetException;
extern NSString *NSBrowserIllegalDelegateException;
extern NSString *NSColorListIOException;
extern NSString *NSColorListNotEditableException;
extern NSString *NSDraggingException;
extern NSString *NSFontUnavailableException;
extern NSString *NSIllegalSelectorException;
extern NSString *NSImageCacheException;
extern NSString *NSNibLoadingException;
extern NSString *NSPPDIncludeNotFoundException;
extern NSString *NSPPDIncludeStackOverflowException;
extern NSString *NSPPDIncludeStackUnderflowException;
extern NSString *NSPPDParseException;
extern NSString *NSPasteboardCommunicationException;
extern NSString *NSPrintOperationExistsException;
extern NSString *NSPrintPackageException;
extern NSString *NSPrintingCommunicationException;
extern NSString *NSRTFPropertyStackOverflowException;
extern NSString *NSTIFFException;
extern NSString *NSTextLineTooLongException;
extern NSString *NSTextNoSelectionException;
extern NSString *NSTextReadException;
extern NSString *NSTextWriteException;
extern NSString *NSTypedStreamVersionException;
extern NSString *NSWindowServerCommunicationException;
extern NSString *NSWordTablesReadException;
extern NSString *NSWordTablesWriteException;

#endif /* __AppKit_AppKitExceptions_h__ */
