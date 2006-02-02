/** <title>NSDocumentController</title>

   <abstract>The document controller class</abstract>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Carl Lindberg <Carl.Lindberg@hbo.com>
   Date: 1999
   Modifications: Fred Kiefer <FredKiefer@gmx.de>
   Date: June 2000

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "AppKit/NSDocumentController.h"
#include "AppKit/NSOpenPanel.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSMenuItem.h"
#include "AppKit/NSWorkspace.h"
#include "AppKit/NSDocumentFrameworkPrivate.h"
#include "GSGuiPrivate.h"

#include <Foundation/NSUserDefaults.h>

static NSString *NSTypesKey             = @"NSTypes";
static NSString *NSNameKey              = @"NSName";
static NSString *NSRoleKey              = @"NSRole";
static NSString *NSHumanReadableNameKey = @"NSHumanReadableName";
static NSString *NSUnixExtensionsKey    = @"NSUnixExtensions";
static NSString *NSDOSExtensionsKey     = @"NSDOSExtensions";
//static NSString *NSMacOSTypesKey        = @"NSMacOSTypes";
//static NSString *NSMIMETypesKey         = @"NSMIMETypes";
static NSString *NSDocumentClassKey     = @"NSDocumentClass";

static NSString *NSRecentDocuments      = @"NSRecentDocuments";
static NSString *NSDefaultOpenDirectory = @"NSDefaultOpenDirectory";

static NSDocumentController *sharedController = nil;

#define TYPE_INFO(name) TypeInfoForName(_types, name)

static NSDictionary *TypeInfoForName (NSArray *types, NSString *typeName)
{
  int i, count = [types count];
  for (i = 0; i < count; i++)
    {
      NSDictionary *dict = [types objectAtIndex: i];

      if ([[dict objectForKey: NSNameKey] isEqualToString: typeName])
	{
	  return dict;
	}
    }  

  return nil;
}

/** <p>
    NSDocumentController is a class that controls a set of NSDocuments
    for an application. As an application delegate, it responds to the
    typical File Menu commands for opening and creating new documents,
    and making sure all documents have been saved when an application
    quits. It also registers itself for the
    NSWorkspaceWillPowerOffNotification.  Note that
    NSDocumentController isn't truly the application delegate, but it
    works in a similar way. You can still have your own application
    delegate - but beware, if it responds to the same methods as
    NSDocumentController, your delegate methods will get called, not
    the NSDocumentController's.
    </p>
    <p>
    NSDocumentController also manages document types and the related
    NSDocument subclasses that handle them. This information comes
    from the custom info property list ({ApplicationName}Info.plist)
    loaded when NSDocumentController is initialized. The property list
    contains an array of dictionarys with the key NSTypes. Each
    dictionary contains a set of keys:
    </p>
   <list>
     <item>NSDocumentClass - The name of the subclass</item>
     <item>NSName - Short name of the document type</item>
     <item>NSHumanReadableName - Longer document type name</item> 
     <item>NSUnixExtensions - Array of strings</item> 
     <item>NSDOSExtensions - Array of strings</item>
     <item>NSIcon - Icon name for these documents</item>
     <item>NSRole - Viewer or Editor</item>
   </list>
   <p>
   You can use NSDocumentController to get a list of all open
   documents, the current document (The one whose window is Key) and
   other information about these documents. It also remembers the most 
   recently opened documents (through the user default key
    NSRecentDocuments). .
   </p>
   <p>
   You can subclass NSDocumentController to customize the behavior of
   certain aspects of the class, but it is very rare that you would
   need to do this.
   </p>
*/
@implementation NSDocumentController

/** Returns the shared instance of the document controller class. You
    should always use this method to get the NSDocumentController. */
+ (id) sharedDocumentController
{
  if (sharedController == nil)
    {
      sharedController = [[self alloc] init];
    }

  return sharedController;
}

/* Private method for use by NSApplication to determine if it should
   instantiate an NSDocumentController.
*/
+ (BOOL) isDocumentBasedApplication
{
  return ([[[NSBundle mainBundle] infoDictionary] objectForKey: NSTypesKey])
	? YES : NO;
}

/** </init>Initializes the document controller class. The first
    instance of a document controller class that gets initialized
    becomes the shared instance.
 */
- init
{
  NSDictionary *customDict = [[NSBundle mainBundle] infoDictionary];
	
  ASSIGN (_types, [customDict objectForKey: NSTypesKey]);
  _documents = [[NSMutableArray alloc] init];
  
  /* Get list of recent documents */
  _recentDocuments = [[NSUserDefaults standardUserDefaults] 
		       objectForKey: NSRecentDocuments];
  if (_recentDocuments)
    {
      int i, count;
      _recentDocuments = [_recentDocuments mutableCopy];
      count = [_recentDocuments count];
      for (i = 0; i < count; i++)
	{
	  NSURL *url;
	  url = [NSURL URLWithString: [_recentDocuments objectAtIndex: i]];
	  [_recentDocuments replaceObjectAtIndex: i withObject: url];
	}
    } 
  else
    _recentDocuments = RETAIN([NSMutableArray array]);
  [self setShouldCreateUI:YES];
  
  [[[NSWorkspace sharedWorkspace] notificationCenter]
    addObserver: self
    selector: @selector(_workspaceWillPowerOff:)
    name: NSWorkspaceWillPowerOffNotification
    object: nil];

  if (sharedController == nil)
    sharedController = self;
  return self;
}

- (void) dealloc
{
  [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];
  RELEASE (_documents);
  RELEASE (_recentDocuments);
  RELEASE (_types);
  [super dealloc];
}

- (BOOL) shouldCreateUI
{
  return (_controllerFlags.shouldCreateUI ? YES : NO);
}

- (void) setShouldCreateUI: (BOOL)flag
{
  _controllerFlags.shouldCreateUI = flag;
}

- (id) makeUntitledDocumentOfType: (NSString *)type
{
  Class documentClass = [self documentClassForType: type];
  return AUTORELEASE ([[documentClass alloc] init]);
}

- (id) makeDocumentWithContentsOfFile: (NSString *)fileName 
			       ofType: (NSString *)type
{
  Class documentClass = [self documentClassForType:type];
  return AUTORELEASE ([[documentClass alloc] initWithContentsOfFile: fileName 
					     ofType: type]);
}

- (id) makeDocumentWithContentsOfURL: (NSURL *)url  ofType: (NSString *)type
{
  Class documentClass = [self documentClassForType: type];
  return AUTORELEASE ([[documentClass alloc] initWithContentsOfURL: url 
					     ofType: type]);
}

- _defaultType
{
  if ([_types count] == 0) 
    {
      return nil; // raise exception?
    }
  
  return [(NSDictionary*)[_types objectAtIndex:0] objectForKey:NSNameKey];
}

- (void) addDocument: (NSDocument *)document
{
  [_documents addObject: document];
}

- (void) removeDocument: (NSDocument *)document
{
  [_documents removeObject: document];
}

- (id) openUntitledDocumentOfType: (NSString*)type  display: (BOOL)display
{
  NSDocument *document = [self makeUntitledDocumentOfType: type];
  
  if (document == nil) 
    {
      return nil;
    }

  [self addDocument: document];
  if ([self shouldCreateUI])
    {
      [document makeWindowControllers];
      if (display)
	{
	  [document showWindows];
	}
    }

  return document;
}

/**
 * Creates an [NSDocument] object from the data at the absolute path
 * given in fileName.  Causes the document to be displayed if display
 * is YES, unless the -shouldCreateUI method returns NO.
 */
- (id) openDocumentWithContentsOfFile: (NSString*)fileName 
			      display: (BOOL)display
{
  NSDocument *document = [self documentForFileName: fileName];
  
  if (document == nil)
    {
      NSString *type = [self typeFromFileExtension: [fileName pathExtension]];
      
      if ((document = [self makeDocumentWithContentsOfFile: fileName 
			    ofType: type]))
	{
	  [self addDocument: document];
	}

      if ([self shouldCreateUI])
	{
	  [document makeWindowControllers];
	}
    }
  
  // remember this document as opened
  [self noteNewRecentDocument: document];

  if (display && [self shouldCreateUI])
    {
      [document showWindows];
    }

  return document;
}

/**
 * Creates an [NSDocument] object from the data at the supplied url.<br />
 * Causes the document to be displayed if display
 * is YES, unless the -shouldCreateUI method returns NO.
 */
- (id) openDocumentWithContentsOfURL: (NSURL *)url  display: (BOOL)display
{
  // Should we only do this if [url isFileURL] is YES?
  NSDocument *document = [self documentForFileName: [url path]];
  
  if (document == nil)
    {
      NSString *type = [self typeFromFileExtension: 
			       [[url path] pathExtension]];
      
      document = [self makeDocumentWithContentsOfURL: url  ofType: type];
      
      if (document == nil)
	{
	  return nil;
	}
      
      [self addDocument: document];

      if ([self shouldCreateUI])
        {
	  [document makeWindowControllers];
        }
    }
  
  // remember this document as opened
  [self noteNewRecentDocumentURL: url];

  if (display && [self shouldCreateUI])
    {
      [document showWindows];
    }
  
  return document;
}

- (NSOpenPanel *) _setupOpenPanel
{
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setDirectory: [self currentDirectory]];
  [openPanel setAllowsMultipleSelection: YES];
  return openPanel;
}

/** Invokes [NSOpenPanel-runModalForTypes:] with the NSOpenPanel
    object openPanel, and passes the openableFileExtensions file types 
*/
- (int) runModalOpenPanel: (NSOpenPanel *)openPanel 
		forTypes: (NSArray *)openableFileExtensions
{
  return [openPanel runModalForTypes:openableFileExtensions];
}

- (NSArray *) _openableFileExtensions
{
  int i, count = [_types count];
  NSMutableArray *array = [NSMutableArray arrayWithCapacity: count];
  
  for (i = 0; i < count; i++)
    {
      NSDictionary *typeInfo = [_types objectAtIndex: i];
      [array addObjectsFromArray: [typeInfo objectForKey: NSUnixExtensionsKey]];
      [array addObjectsFromArray: [typeInfo objectForKey: NSDOSExtensionsKey]];
    }
  
  return array;
}

/** Uses -runModalOpenPanel:forTypes: to allow the user to select
    files to open (after initializing the NSOpenPanel). Returns the
    list of files that the user has selected.
*/
- (NSArray *) fileNamesFromRunningOpenPanel
{
  NSArray *types = [self _openableFileExtensions];
  NSOpenPanel *openPanel = [self _setupOpenPanel];
	
  if ([self runModalOpenPanel: openPanel  forTypes: types])
    {
      return [openPanel filenames];
    }
	
  return nil;
}

/** Uses -runModalOpenPanel:forTypes: to allow the user to select
    files to open (after initializing the NSOpenPanel). Returns the
    list of files as URLs that the user has selected.
*/
- (NSArray *) URLsFromRunningOpenPanel
{
  NSArray *types = [self _openableFileExtensions];
  NSOpenPanel *openPanel = [self _setupOpenPanel];
  
  if ([self runModalOpenPanel: openPanel  forTypes: types])
    {
      return [openPanel URLs];
    }
  
  return nil;
}


- (IBAction) saveAllDocuments: (id)sender
{
  NSDocument *document;
  NSEnumerator *docEnum = [_documents objectEnumerator];
	
  while ((document = [docEnum nextObject]))
    {
      if ([document isDocumentEdited])  //maybe we should save regardless...
	{
	  [document saveDocument: sender];
	}
    }
}


- (IBAction) openDocument: (id)sender
{
  NSEnumerator *fileEnum;
  NSString *filename;

  fileEnum = [[self fileNamesFromRunningOpenPanel] objectEnumerator];
	
  while ((filename = [fileEnum nextObject]))
    {
      [self openDocumentWithContentsOfFile: filename  display: YES];
    }
}
	
- (IBAction) newDocument: (id)sender
{
  [self openUntitledDocumentOfType: [self _defaultType]  display: YES];
}


/** Iterates through all the open documents and asks each one in turn
    if it can close using [NSDocument-canCloseDocument]. If the
    document returns YES, then it is closed.
*/
- (BOOL) closeAllDocuments
{
  int count;
  count = [_documents count];
  if (count > 0)
    {
      NSDocument *array[count];
      [_documents getObjects: array];
      while (count-- > 0)
	{
	  NSDocument *document = array[count];
	  if (![document canCloseDocument]) 
	    {
	      return NO;
	    }
	  [document close];
	}
    }

  return YES;
}

- (void)closeAllDocumentsWithDelegate:(id)delegate 
		  didCloseAllSelector:(SEL)didAllCloseSelector 
			  contextInfo:(void *)contextInfo
{
  //FIXME
}

/** If there are any unsaved documents, this method displays an alert
    panel asking if the user wants to review the unsaved documents. If
    the user agrees to review the documents, this method calls
    -closeAllDocuments to close each document (prompting to save a
    document if it is dirty). If cancellable is YES, then the user is
    not allowed to cancel this request, otherwise this method will
    return NO if the user presses the Cancel button. Otherwise returns
    YES after all documents have been closed (or if there are no
    unsaved documents.)
*/
- (BOOL) reviewUnsavedDocumentsWithAlertTitle: (NSString *)title 
				  cancellable: (BOOL)cancellable
{
  NSString *cancelString = (cancellable)? _(@"Cancel") : nil;
  int      result;
  
  /* Probably as good a place as any to do this */
  [[NSUserDefaults standardUserDefaults] 
    setObject: [self currentDirectory] forKey: NSDefaultOpenDirectory];

  if (![self hasEditedDocuments]) 
    {
      return YES;
    }
  
  result = NSRunAlertPanel(title, _(@"You have unsaved documents"),
			   _(@"Review Unsaved"), 
			   cancelString, 
			   _(@"Quit Anyways"));
  
#define ReviewUnsaved NSAlertDefaultReturn
#define Cancel        NSAlertAlternateReturn
#define QuitAnyways   NSAlertOtherReturn

  switch (result)
    {
    case ReviewUnsaved:	return [self closeAllDocuments];
    case QuitAnyways:	return YES;
    case Cancel:
    default:		return NO;
    }
}

- (void)reviewUnsavedDocumentsWithAlertTitle:(NSString *)title 
				 cancellable:(BOOL)cancellable 
				    delegate:(id)delegate
			didReviewAllSelector:(SEL)didReviewAllSelector 
				 contextInfo:(void *)contextInfo
{
// FIXME
}


#ifdef OPENSTEP_ONLY
/*
 * App delegate methods.  Apple doesn't have these, but they put code
 * into NSApplication to call the corresponding NSDocumentController
 * methods if the app delegate didn't implement a given delegate method.
 */
- (BOOL) application:(NSApplication *)sender  openFile: (NSString *)filename
{
  return [self openDocumentWithContentsOfFile:filename display:YES] ? YES : NO;
}

- (BOOL) application:(NSApplication *)sender  
	openTempFile: (NSString *)filename
{
  return [self openDocumentWithContentsOfFile:filename display:YES] ? YES : NO;
}

- (BOOL) applicationOpenUntitledFile: (NSApplication *)sender
{
  return [self openUntitledDocumentOfType: [self _defaultType]
	       display: YES] ? YES : NO;
}

- (BOOL) application:(id)sender openFileWithoutUI:(NSString *)filename
{
  return [self openDocumentWithContentsOfFile: filename  display: NO] ? 
    YES : NO;
}

- (BOOL) applicationShouldTerminate: (NSApplication *)sender
{
  return [self reviewUnsavedDocumentsWithAlertTitle: _(@"Quit")
	       cancellable: YES];
}
#endif

- (void) _workspaceWillPowerOff: (NSNotification *)notification
{
  [self reviewUnsavedDocumentsWithAlertTitle: _(@"Power Off") cancellable: NO];
}


/** Returns an array of all open documents */
- (NSArray *) documents
{
  return _documents;
}

/** Returns YES if any documents are "dirty", e.g. changes have been
    made to the document that have not been saved to the disk 
*/
- (BOOL) hasEditedDocuments
{
  int i, count = [_documents count];
  
  for (i = 0; i < count; i++)
    {
      if ([[_documents objectAtIndex: i] isDocumentEdited])
	{
	  return YES;
	}
    }
	
  return NO;
}

/** Returns the document whose window is the main window */
- (id) currentDocument
{
  return [self documentForWindow: 
		 [[NSApplication sharedApplication] mainWindow]];
}

/** Returns the current directory. This method first checks if there
    is a current document using the -currentDocument method. If this
    returns a document and the document has a filename, this method
    returns the directory this file is located in. Otherwise it
    returns the directory of the most recently opened document or
    the user's home directory if no document has been opened before.
*/
- (NSString *) currentDirectory
{
  NSFileManager *manager = [NSFileManager defaultManager];
  NSDocument *document = [self currentDocument];
  NSString *directory;
  BOOL isDir = NO;

  if (document)
    directory = [[document fileName] stringByDeletingLastPathComponent];
  else
    directory = [[NSOpenPanel openPanel] directory];
  if (directory == nil || [directory isEqual: @""]
      || [manager fileExistsAtPath: directory  isDirectory: &isDir] == NO
      || isDir == NO)
    {
      directory = NSHomeDirectory ();
    }
  return directory;
}

/** Returns the NSDocument class that controls window */
- (id) documentForWindow: (NSWindow *)window
{
  id document;

  if (window == nil)
    {
      return nil;
    }

  if (![[window windowController] isKindOfClass: [NSWindowController class]])
    {
      return nil;
    }

  document = [[window windowController] document];

  if (![document isKindOfClass:[NSDocument class]])
    {
      return nil;
    }

  return document;
}

/** Returns the NSDocument class that controls the document with the
    name fileName.
*/
- (id) documentForFileName: (NSString *)fileName
{
  int i, count = [_documents count];
	
  for (i = 0; i < count; i++)
    {
      NSDocument *document = [_documents objectAtIndex: i];
      
      if ([[document fileName] isEqualToString: fileName])
	{
	  return document;
	}
    }
	
  return nil;
}

- (BOOL) validateMenuItem: (NSMenuItem *)anItem
{
  if ([anItem action] == @selector(saveAllDocuments:))
    {
      return [self hasEditedDocuments];
    }
  return YES;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
  // FIXME
  return YES;
}

- (NSString *) displayNameForType: (NSString *)type
{
  NSString *name = [TYPE_INFO(type) objectForKey: NSHumanReadableNameKey];
  
  return name? name : type;
}

- (NSString *) typeFromFileExtension: (NSString *)fileExtension
{
  int i, count = [_types count];
	
  for (i = 0; i < count;i++)
    {
      NSDictionary *typeInfo = [_types objectAtIndex: i];
      
      if ([[typeInfo objectForKey:NSUnixExtensionsKey] 
	    containsObject: fileExtension] ||
	  [[typeInfo objectForKey:NSDOSExtensionsKey]  
	    containsObject: fileExtension])
	{
	  return [typeInfo objectForKey: NSNameKey];
	}
    }
	
  return nil;
}

- (NSArray *) fileExtensionsFromType: (NSString *)type
{
  NSDictionary *typeInfo = TYPE_INFO(type);
  NSArray *unixExtensions = [typeInfo objectForKey: NSUnixExtensionsKey];
  NSArray *dosExtensions  = [typeInfo objectForKey: NSDOSExtensionsKey];
  
  if (!dosExtensions)  return unixExtensions;
  if (!unixExtensions) return dosExtensions;
  return [unixExtensions arrayByAddingObjectsFromArray: dosExtensions];
}

- (Class) documentClassForType: (NSString *)type
{
  NSString *className = [TYPE_INFO(type) objectForKey: NSDocumentClassKey];
	
  return className? NSClassFromString(className) : Nil;
}

- (IBAction) clearRecentDocuments: (id)sender
{
  [_recentDocuments removeAllObjects];
  [[NSUserDefaults standardUserDefaults] 
    setObject: _recentDocuments forKey: NSRecentDocuments];
}

// The number of remembered recent documents
#define MAX_DOCS 5

- (void) noteNewRecentDocument: (NSDocument *)aDocument
{
  NSString *fileName = [aDocument fileName];
  NSURL *anURL = [NSURL fileURLWithPath: fileName];

  if (anURL != nil)
    [self noteNewRecentDocumentURL: anURL];
}

- (void) noteNewRecentDocumentURL: (NSURL *)anURL
{
  unsigned index = [_recentDocuments indexOfObject: anURL];
  NSMutableArray *a;

  if (index != NSNotFound)
    {
      // Always keep the current object at the end of the list
      [_recentDocuments removeObjectAtIndex: index];
    }
  else if ([_recentDocuments count] > MAX_DOCS)
    {
      [_recentDocuments removeObjectAtIndex: 0];
    }

  [_recentDocuments addObject: anURL];
  
  a = [_recentDocuments mutableCopy];
  index = [a count];
  while (index-- > 0)
    {
      [a replaceObjectAtIndex: index withObject:
	[[a objectAtIndex: index] absoluteString]];
    }
  [[NSUserDefaults standardUserDefaults] 
    setObject: a forKey: NSRecentDocuments];
  RELEASE(a);
}

- (NSArray *) recentDocumentURLs
{
  return _recentDocuments;
}

@end

@implementation NSDocumentController (Private)
static NSString *NSEditorRole = @"Editor";
static NSString *NSViewerRole = @"Viewer";
//static NSString *NSNoRole     = @"None";

- (NSArray *) _editorAndViewerTypesForClass: (Class)documentClass
{
  int i, count = [_types count];
  NSMutableArray *types = [NSMutableArray arrayWithCapacity: count];
  NSString *docClassName = NSStringFromClass (documentClass);
	
  for (i = 0; i < count; i++)
    {
      NSDictionary *typeInfo = [_types objectAtIndex: i];
      NSString     *className = [typeInfo objectForKey: NSDocumentClassKey];
      NSString     *role      = [typeInfo objectForKey: NSRoleKey];
      
      if ([docClassName isEqualToString: className] 
	  && (role == nil 
	      || [role isEqual: NSEditorRole] 
	      || [role isEqual: NSViewerRole]))
	{
	  [types addObject: [typeInfo objectForKey: NSNameKey]];
	}
    }
  
  return types;
}

- (NSArray *) _editorTypesForClass: (Class)documentClass
{
  int i, count = [_types count];
  NSMutableArray *types = [NSMutableArray arrayWithCapacity: count];
  NSString *docClassName = NSStringFromClass (documentClass);
  
  for (i = 0; i < count; i++)
    {
      NSDictionary *typeInfo = [_types objectAtIndex: i];
      NSString     *className = [typeInfo objectForKey: NSDocumentClassKey];
      NSString     *role      = [typeInfo objectForKey: NSRoleKey];
      
      if ([docClassName isEqualToString: className] &&
	  (role == nil || [role isEqual: NSEditorRole]))
	{
	  [types addObject: [typeInfo objectForKey: NSNameKey]];
	}
    }
  
  return types;
}

- (NSArray *) _exportableTypesForClass: (Class)documentClass
{
  // Dunno what this method is for; maybe looks for filter types
  return [self _editorTypesForClass: documentClass];
}

@end

