/* 
   NSDocumentController.h

   The document controller class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Carl Lindberg <Carl.Lindberg@hbo.com>
   Date: 1999
   
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
#ifndef _GNUstep_H_NSDocumentController
#define _GNUstep_H_NSDocumentController

#ifndef STRICT_OPENSTEP

#include <Foundation/Foundation.h>
#include <AppKit/NSNibDeclarations.h>
#include <AppKit/NSUserInterfaceValidation.h>

@class NSArray, NSMutableArray;
@class NSURL;
@class NSMenuItem, NSOpenPanel, NSWindow;
@class NSDocument;

@interface NSDocumentController : NSObject
{
  @private
    NSMutableArray 	*_documents;
    NSMutableArray 	*_recentDocuments;
    struct __controllerFlags {
        unsigned int shouldCreateUI:1;
        unsigned int RESERVED:31;
    } _controllerFlags;
    NSArray		*_types;		// from info.plist with key NSTypes
    void 		*_reserved1;
    void 		*_reserved2;
}

+ (id)sharedDocumentController;

/*" document creation "*/
// doesn't create the windowControllers
- (id)makeUntitledDocumentOfType:(NSString *)type;
- (id)makeDocumentWithContentsOfFile:(NSString *)fileName ofType:(NSString *)type;
// creates window controllers
- (id)openUntitledDocumentOfType:(NSString*)type display:(BOOL)display;
- (id)openDocumentWithContentsOfFile:(NSString *)fileName display:(BOOL)display;

- (id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)type;
- (id)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)display;

/*" With or without UI "*/
- (BOOL)shouldCreateUI;
- (void)setShouldCreateUI:(BOOL)flag;

/*" Actions "*/
- (IBAction)saveAllDocuments:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)newDocument:(id)sender;
- (IBAction)clearRecentDocuments:(id)sender;

/*" Recent Documents "*/
- (void)noteNewRecentDocument:(NSDocument *)aDocument;
- (void)noteNewRecentDocumentURL:(NSURL *)anURL;
- (NSArray *)recentDocumentURLs;

/*" Open panel "*/
- (NSArray *)URLsFromRunningOpenPanel;
- (NSArray *)fileNamesFromRunningOpenPanel;
- (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)openableFileExtensions;

/*" Document management "*/
- (void)addDocument:(NSDocument *)document;
- (void)removeDocument:(NSDocument *)document;
- (BOOL)closeAllDocuments;
- (void)closeAllDocumentsWithDelegate:(id)delegate 
		  didCloseAllSelector:(SEL)didAllCloseSelector 
			  contextInfo:(void *)contextInfo;
- (BOOL)reviewUnsavedDocumentsWithAlertTitle:(NSString *)title cancellable:(BOOL)cancellable;
- (void)reviewUnsavedDocumentsWithAlertTitle:(NSString *)title 
				 cancellable:(BOOL)cancellable 
				    delegate:(id)delegate
			didReviewAllSelector:(SEL)didReviewAllSelector 
				 contextInfo:(void *)contextInfo;
- (NSArray *)documents;
- (BOOL)hasEditedDocuments;
- (id)currentDocument;
- (NSString *)currentDirectory;
- (id)documentForWindow:(NSWindow *)window;
- (id)documentForFileName:(NSString *)fileName;


/*" Menu validation "*/
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;

/*" Types and extensions "*/
- (NSString *)displayNameForType:(NSString *)type;
- (NSString *)typeFromFileExtension:(NSString *)fileExtension;
- (NSArray *)fileExtensionsFromType:(NSString *)type;
- (Class)documentClassForType:(NSString *)type;

@end

#endif // STRICT_OPENSTEP

#endif // _GNUstep_H_NSDocumentController

