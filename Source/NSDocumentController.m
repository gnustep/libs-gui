/** <title>NSDocumentController</title>

   <abstract>The document controller class</abstract>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Carl Lindberg <Carl.Lindberg@hbo.com>
   Date: 1999
   Modifications: Fred Kiefer <FredKiefer@gmx.de>
   Date: June 2000

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

#include <Foundation/NSArray.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSURL.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSTimer.h>

#include "AppKit/NSDocumentController.h"
#include "AppKit/NSOpenPanel.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSMenu.h"
#include "AppKit/NSMenuItem.h"
#include "AppKit/NSWorkspace.h"
#include "NSDocumentFrameworkPrivate.h"
#include "GSGuiPrivate.h"

static NSString *NSTypesKey             = @"NSTypes";
static NSString *NSNameKey              = @"NSName";
static NSString *NSRoleKey              = @"NSRole";
static NSString *NSHumanReadableNameKey = @"NSHumanReadableName";
static NSString *NSUnixExtensionsKey    = @"NSUnixExtensions";
static NSString *NSDOSExtensionsKey     = @"NSDOSExtensions";
//static NSString *NSMacOSTypesKey        = @"NSMacOSTypes";
//static NSString *NSMIMETypesKey         = @"NSMIMETypes";
static NSString *NSDocumentClassKey     = @"NSDocumentClass";

static NSString *CFBundleDocumentTypes  = @"CFBundleDocumentTypes";
static NSString *CFBundleTypeExtensions = @"CFBundleTypeExtensions";
static NSString *CFBundleTypeName       = @"CFBundleTypeName";
static NSString *CFBundleTypeRole       = @"CFBundleTypeRole";

// FIXME: Looks like this was changed to @"NSRecentDocumentRecords"
static NSString *NSRecentDocuments      = @"NSRecentDocuments";

static NSString *NSEditorRole = @"Editor";
static NSString *NSViewerRole = @"Viewer";
//static NSString *NSNoRole     = @"None";
//static NSString *NSShellRole	= @"Shell";

static NSDocumentController *sharedController = nil;

#define TYPE_INFO(name) TypeInfoForName(_types, name)
#define HR_TYPE_INFO(name) TypeInfoForHumanReadableName(_types, name)

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
      else if ([[dict objectForKey: CFBundleTypeName] isEqualToString: typeName])
        {
          return dict;
        }
    }  

  return nil;
}

static NSDictionary *TypeInfoForHumanReadableName (NSArray *types, NSString *typeName)
{
  int i, count = [types count];
  for (i = 0; i < count; i++)
    {
      NSDictionary *dict = [types objectAtIndex: i];

      if ([[dict objectForKey: NSHumanReadableNameKey] isEqualToString: typeName])
        {
          return dict;
        }
      else if ([[dict objectForKey: CFBundleTypeName] isEqualToString: typeName])
        {
          return dict;
        }
    }  

  return nil;
}


@interface NSDocumentController (RecentsMenu)
- (NSMenu *) _recentMenu;
- (void) _updateOpenRecentMenu;
- (IBAction) _openRecentDocument: (id)sender;
@end


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
      // -init sets sharedController
      [[self alloc] init];
    }

  return sharedController;
}

/* Private method for use by NSApplication to determine if it should
   instantiate an NSDocumentController.
*/
+ (BOOL) isDocumentBasedApplication
{
  return ([[[NSBundle mainBundle] infoDictionary] objectForKey: NSTypesKey] ||
          [[[NSBundle mainBundle] infoDictionary] objectForKey: CFBundleDocumentTypes]) 
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

  if(_types == nil)
    {
      ASSIGN(_types, [customDict objectForKey: CFBundleDocumentTypes]);
    }

  _documents = [[NSMutableArray alloc] init];
  
  /* Get list of recent documents */
  _recent_documents = [[NSUserDefaults standardUserDefaults] 
                       objectForKey: NSRecentDocuments];
  if (_recent_documents)
    {
      int i, count;

      _recent_documents = [_recent_documents mutableCopy];
      count = [_recent_documents count];
      for (i = 0; i < count; i++)
        {
          NSString *str;
          NSURL *url;

          str = [_recent_documents objectAtIndex: i];
          url = [NSURL URLWithString: str];
          if (url == nil)
            {
              NSLog(@"NSRecentItems value '%@' is not valid ... ignored", str);
              [_recent_documents removeObjectAtIndex: i];
              i--;
              count--;
            }
          else
            {
              [_recent_documents replaceObjectAtIndex: i withObject: url];
            }
        }
    } 
  else
    _recent_documents = RETAIN([NSMutableArray array]);
  [self setShouldCreateUI: YES];
  
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
  RELEASE (_recent_documents);
  RELEASE (_types);
  [super dealloc];
}

/* 
 * Private helper macro to check, if the method given via the selector sel 
 * has been overridden in the current subclass.
 */
#define OVERRIDDEN(sel) ([self methodForSelector: @selector(sel)] != [[NSDocumentController class] instanceMethodForSelector: @selector(sel)])

- (BOOL) shouldCreateUI
{
  return _controller_flags.should_create_ui;
}

- (void) setShouldCreateUI: (BOOL)flag
{
  _controller_flags.should_create_ui = flag;
}

- (NSTimeInterval) autosavingDelay
{
  return _autosavingDelay;
}

- (void) setAutosavingDelay: (NSTimeInterval)autosavingDelay
{
  static NSTimer *autosavingTimer = nil;

  if (autosavingTimer)
    {
      [autosavingTimer invalidate];
      DESTROY (autosavingTimer);
    }
  _autosavingDelay = autosavingDelay;
  if (autosavingDelay > 0)
    {
      autosavingTimer =
          [NSTimer scheduledTimerWithTimeInterval: autosavingDelay
                   target: self
                   selector: @selector(_autosaveDocuments:)
                   userInfo: nil
                   repeats: YES];
      RETAIN (autosavingTimer);
    }
}

- (id) makeUntitledDocumentOfType: (NSString *)type
{
  Class documentClass = [self documentClassForType: type];
  id document = AUTORELEASE ([[documentClass alloc] init]);

  [document setFileType: type];

  return document;
}

- (id) makeDocumentWithContentsOfFile: (NSString *)fileName 
                               ofType: (NSString *)type
{
  Class documentClass = [self documentClassForType:type];
  return AUTORELEASE ([[documentClass alloc] initWithContentsOfFile: fileName 
                                             ofType: type]);
}

- (id) makeDocumentWithContentsOfURL: (NSURL *)url ofType: (NSString *)type
{
  Class documentClass = [self documentClassForType: type];
  return AUTORELEASE ([[documentClass alloc] initWithContentsOfURL: url 
                                             ofType: type]);
}

- (id) makeDocumentForURL: (NSURL *)url
        withContentsOfURL: (NSURL *)contents
                   ofType: (NSString *)type
                    error: (NSError **)err
{
  Class documentClass = [self documentClassForType: type];

  if (documentClass == nil)
    {
      // FIXME: Set err
      return nil;
    }

  return AUTORELEASE([[documentClass alloc] initForURL: url
                                            withContentsOfURL: contents 
                                            ofType: type
                                            error: err]);
}

- (id) makeDocumentWithContentsOfURL: (NSURL *)url 
                              ofType: (NSString *)type 
                               error: (NSError **)err
{
  if (OVERRIDDEN(makeDocumentWithContentsOfFile:ofType:) && [url isFileURL])
    {
      return [self makeDocumentWithContentsOfFile: [url path] ofType: type];
    }
  else
    {
      Class documentClass = [self documentClassForType: type];

      if (documentClass == nil)
        {
          // FIXME: Set err
          return nil;
        }
      return AUTORELEASE([[documentClass alloc] initWithContentsOfURL: url 
                                                ofType: type
                                                error: err]);
    }
}

- (id) makeUntitledDocumentOfType: (NSString *)type 
                            error: (NSError **)err
{
  if (OVERRIDDEN(makeUntitledDocumentOfType:))
    {
      return [self makeUntitledDocumentOfType: type];
    }
  else
    {
      Class documentClass = [self documentClassForType: type];
      return AUTORELEASE([[documentClass alloc] initWithType: type
                                                error: err]);
    }
}

- (BOOL) presentError: (NSError *)error
{
  error = [self willPresentError: error];
  return [NSApp presentError: error];
}

- (void) presentError: (NSError *)error
       modalForWindow: (NSWindow *)window
             delegate: (id)delegate 
   didPresentSelector: (SEL)sel
          contextInfo: (void *)context
{
  error = [self willPresentError: error];
  [NSApp presentError: error
         modalForWindow: window
         delegate: delegate
         didPresentSelector: sel
         contextInfo: context];
}

- (NSError *) willPresentError: (NSError *)error
{
  return error;
}

- (NSString*) defaultType
{
  NSString *defaultName = nil;
	int i, count = [_types count];

	for (i = 0; i < count; i++)
		{
      NSDictionary *typeInfo = (NSDictionary*)[_types objectAtIndex: i];		
      NSString *role;

      role = [typeInfo objectForKey: NSRoleKey];
      if (role == nil)
        role = [typeInfo objectForKey: CFBundleTypeRole];

      if ([role isEqual: NSEditorRole])
        {
          defaultName = [typeInfo objectForKey: NSNameKey];
          if (defaultName == nil)
            {
              defaultName = [typeInfo objectForKey: CFBundleTypeName];
            }

          return defaultName;
        }
		}

	// none found
	return nil;
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
      
      document = [self makeDocumentWithContentsOfFile: fileName ofType: type];

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
- (id) openDocumentWithContentsOfURL: (NSURL *)url display: (BOOL)display
{
  NSDocument *document = [self documentForURL: url];
  
  if (document == nil)
    {
      NSString *type = [self typeForContentsOfURL: url error: NULL];
      
      document = [self makeDocumentWithContentsOfURL: url ofType: type];
      
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

- (id) openUntitledDocumentAndDisplay: (BOOL)display 
                                error: (NSError **)err
{
  NSString *type;
  
  type = [self defaultType];

  if (OVERRIDDEN(openUntitledDocumentOfType:display:))
    {
      return [self openUntitledDocumentOfType: type display: display];
    }
  else
    {
      NSDocument *document = [self makeUntitledDocumentOfType: type
                                   error: err];
  
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
}

- (id) openDocumentWithContentsOfURL: (NSURL *)url
                             display: (BOOL)display
                               error: (NSError **)err
{
  if (OVERRIDDEN(openDocumentWithContentsOfFile:display:) && [url isFileURL])
    {
      return [self openDocumentWithContentsOfFile: [url path] 
                   display: display];
    }
  else
    {
      NSDocument *document = [self documentForURL: url];
  
      if (document == nil)
        {
          NSString *type = [self typeForContentsOfURL: url error: err];
      
          if (type == nil)
            {
              return nil;
            }

          document = [self makeDocumentWithContentsOfURL: url  
                           ofType: type 
                           error: err];
      
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
}

- (BOOL) reopenDocumentForURL: (NSURL *)url
            withContentsOfURL: (NSURL *)contents
                        error: (NSError **)err
{
  NSString *type = [self typeForContentsOfURL: contents error: err];
  id document;

  if (type == nil)
    {
      return NO;
    }

  document = [self makeDocumentForURL: url
                   withContentsOfURL: contents
                   ofType: type
                   error: err];
  if (document)
    {
      [self addDocument:document];
      if ([self shouldCreateUI])
        {
          [document makeWindowControllers];
          [document showWindows];
        }  
      return YES;
    }

  return NO;
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
- (NSInteger) runModalOpenPanel: (NSOpenPanel *)openPanel 
                       forTypes: (NSArray *)openableFileExtensions
{
  return [openPanel runModalForTypes: openableFileExtensions];
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
      [array addObjectsFromArray: [typeInfo objectForKey: CFBundleTypeExtensions]];
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
        
  if ([self runModalOpenPanel: openPanel forTypes: types])
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
  
  if ([self runModalOpenPanel: openPanel forTypes: types])
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
  NSError *err = nil;
  NSEnumerator *urlEnum;
  NSURL *url;

  urlEnum = [[self URLsFromRunningOpenPanel] objectEnumerator];
  while ((url = [urlEnum nextObject]))
    {
      [self openDocumentWithContentsOfURL: url display: YES error: &err];
      if (err && ![self presentError: err])
        {
          break;
        }
    }
}
        
- (IBAction) newDocument: (id)sender
{
  NSError *err = nil;

  [self openUntitledDocumentAndDisplay: YES error: &err];
  if (err)
    [self presentError: err];
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


// FIXME
static BOOL _shouldClose = YES;

- (void) _document: (NSDocument *)doc
       shouldClose: (BOOL)shouldClose
       contextInfo: (void *)contextInfo
{
  _shouldClose = shouldClose;
}

- (void)closeAllDocumentsWithDelegate:(id)delegate 
                  didCloseAllSelector:(SEL)didAllCloseSelector 
                          contextInfo:(void *)contextInfo
{
  int count;
  BOOL closeAll = YES;

  count = [_documents count];
  if (count > 0)
    {
      NSDocument *array[count];

      [_documents getObjects: array];
      while (count-- > 0)
        {
          NSDocument *document = array[count];

          // Initialize to known state
          _shouldClose = YES;
          [document canCloseDocumentWithDelegate: self
                    shouldCloseSelector: 
                        @selector(_document:shouldClose:contextInfo:)
                    contextInfo: contextInfo];
          if (_shouldClose)
            {
              [document close];
            }
          else
            {
              closeAll = NO;
            }
        }
    }

  if (delegate != nil && didAllCloseSelector != NULL)
    {
      void (*meth)(id, SEL, id, BOOL, void*);
      meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector: 
                                                               didAllCloseSelector];
      if (meth)
        meth(delegate, didAllCloseSelector, self, closeAll, contextInfo);
    }
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
  NSString *cancelString = (cancellable)? ((NSString *)_(@"Cancel")) : ((NSString *)nil);
  int      result;
  
  if (![self hasEditedDocuments]) 
    {
      return YES;
    }
  
  result = NSRunAlertPanel(title, _(@"You have unsaved documents"),
                           _(@"Review Unsaved"), 
                           cancelString, 
                           _(@"Quit Anyway"));
  
#define ReviewUnsaved NSAlertDefaultReturn
#define Cancel        NSAlertAlternateReturn
#define QuitAnyways   NSAlertOtherReturn

  switch (result)
    {
    case ReviewUnsaved:        return [self closeAllDocuments];
    case QuitAnyways:        return YES;
    case Cancel:
    default:                return NO;
    }
}

- (void) reviewUnsavedDocumentsWithAlertTitle: (NSString *)title 
                                  cancellable: (BOOL)cancellable 
                                     delegate: (id)delegate
                         didReviewAllSelector: (SEL)didReviewAllSelector 
                                  contextInfo: (void *)contextInfo
{
  NSString *cancelString = (cancellable)? ((NSString *)_(@"Cancel")) : ((NSString *)nil);
  int result = YES;
  
  if (![self hasEditedDocuments]) 
    {
      if (delegate != nil && didReviewAllSelector != NULL)
        {
          void (*meth)(id, SEL, id, BOOL, void*);
          meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector: 
                                                                   didReviewAllSelector];
          if (meth)
            meth(delegate, didReviewAllSelector, self, result, contextInfo);
        }

      return;
    }
  
  // FIXME
  NSBeginAlertSheet(title, 
                    _(@"Review Unsaved"), 
                    cancelString, 
                    _(@"Quit Anyway"),
                    nil,
                    delegate, 
                    didReviewAllSelector, 
                    contextInfo, 
                    _(@"You have unsaved documents"),
                    nil);
}


#ifdef OPENSTEP_ONLY
/*
 * App delegate methods.  Apple doesn't have these, but they put code
 * into NSApplication to call the corresponding NSDocumentController
 * methods if the app delegate didn't implement a given delegate method.
 */
- (BOOL) application: (NSApplication *)sender openFile: (NSString *)filename
{
  return [self openDocumentWithContentsOfFile: filename display: YES] ? YES : NO;
}

- (BOOL) application: (NSApplication *)sender  
        openTempFile: (NSString *)filename
{
  return [self openDocumentWithContentsOfFile: filename display: YES] ? YES : NO;
}

- (BOOL) applicationOpenUntitledFile: (NSApplication *)sender
{
  return [self openUntitledDocumentOfType: [self defaultType]
               display: YES] ? YES : NO;
}

- (BOOL) application: (id)sender openFileWithoutUI: (NSString *)filename
{
  return [self openDocumentWithContentsOfFile: filename display: NO] ? 
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

/** 
 * Returns the current directory. This method first checks if there
 * is a current document using the -currentDocument method. If this
 * returns a document and the document has a filename, this method
 * returns the directory this file is located in. Otherwise it
 * returns the directory of the most recently opened document or
 * the user's home directory if no document has been opened before.
 */
- (NSString *) currentDirectory
{
  NSFileManager *manager = [NSFileManager defaultManager];
  NSDocument *document = [self currentDocument];
  NSString *directory = nil;
  BOOL isDir = NO;

  if (document)
    {
      directory = [[document fileName] stringByDeletingLastPathComponent];
    }
  if (directory == nil || [directory isEqual: @""]
      || [manager fileExistsAtPath: directory  isDirectory: &isDir] == NO
      || isDir == NO)
    {
      directory = [[NSOpenPanel openPanel] directory];
    }
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

  if (![document isKindOfClass: [NSDocument class]])
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

- (id) documentForURL: (NSURL *)url
{
  if (OVERRIDDEN(documentForFileName:) && [url isFileURL])
    {
      return [self documentForFileName: [url path]];
    }
  else
    {
      int i, count = [_documents count];
        
      for (i = 0; i < count; i++)
        {
          NSDocument *document = [_documents objectAtIndex: i];
      
          if ([[document fileURL] isEqual: url])
            {
              return document;
            }
        }
        
      return nil;
    }
}

- (BOOL) validateMenuItem: (NSMenuItem *)anItem
{
  return [self validateUserInterfaceItem: anItem];
}

- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)anItem
{
  if (sel_eq([anItem action], @selector(saveAllDocuments:)))
    {
      return [self hasEditedDocuments];
    }
  if (sel_eq([anItem action], @selector(newDocument:)))
    {
      return ([self defaultType] != nil); 
    }
  return YES;
}

- (NSString *) displayNameForType: (NSString *)type
{
  // FIXME: Is this needed?
  NSString *name = [TYPE_INFO(type) objectForKey: NSHumanReadableNameKey];

  if (!name)
    {
      name = [[NSBundle mainBundle] localizedStringForKey: type
                                    value: type
                                    table: @"InfoPlist"];
    }

  return name ? name : type;
}

- (NSString *) typeFromFileExtension: (NSString *)fileExtension
{
  int i, count = [_types count];
        
  for (i = 0; i < count; i++)
    {
      NSDictionary *typeInfo = [_types objectAtIndex: i];
      
      if ([[typeInfo objectForKey: NSUnixExtensionsKey] 
            containsObject: fileExtension] ||
          [[typeInfo objectForKey: NSDOSExtensionsKey]  
            containsObject: fileExtension] ||
          [[typeInfo objectForKey: CFBundleTypeExtensions]
            containsObject: fileExtension])
        {
          NSString *type = [typeInfo objectForKey: NSNameKey];

          if(type == nil)
            {
              type = [typeInfo objectForKey: CFBundleTypeName];
            }
          return type;
        }
    }
        
  return nil;
}

- (NSString *) typeForContentsOfURL: (NSURL *)url error: (NSError **)err
{
  // FIXME: open connection and get response to determine mine/type
  // Should we only do this if [url isFileURL] is YES?
  return [self typeFromFileExtension: [[url path] pathExtension]];
}

- (NSArray *) fileExtensionsFromType: (NSString *)type
{
  NSDictionary *typeInfo = TYPE_INFO(type);
	NSMutableArray *array = [NSMutableArray arrayWithCapacity: 3];

  [array addObjectsFromArray: [typeInfo objectForKey: NSUnixExtensionsKey]];
  [array addObjectsFromArray: [typeInfo objectForKey: NSDOSExtensionsKey]];
  [array addObjectsFromArray: [typeInfo objectForKey: CFBundleTypeExtensions]];

  return array;
}

- (Class) documentClassForType: (NSString *)type
{
  NSString *className = [TYPE_INFO(type) objectForKey: NSDocumentClassKey];
        
  return className ? NSClassFromString(className) : Nil;
}

- (NSArray *)documentClassNames
{
  int i, count = [_types count];
  NSMutableArray *classNames;

  classNames = [[NSMutableArray alloc] initWithCapacity: count];
        
  for (i = 0; i < count; i++)
    {
      NSDictionary *typeInfo = [_types objectAtIndex: i];
      NSString *className = [typeInfo objectForKey: NSDocumentClassKey];

      if(className != nil)
        {
          [classNames addObject: className];
        }
      else
        {
          NSLog(@"WARN: The entry does not have an NSDocumentClass name defined: %@",
                typeInfo);
        }
    }
 
  return AUTORELEASE(classNames);
}


- (IBAction) clearRecentDocuments: (id)sender
{
  [_recent_documents removeAllObjects];
  [[NSUserDefaults standardUserDefaults] 
    setObject: _recent_documents forKey: NSRecentDocuments];
	[self _updateOpenRecentMenu];
}

// The number of remembered recent documents
- (NSUInteger) maximumRecentDocumentCount
{
  // FIXME: Should come from user defaults
  return 5;
}

- (void) noteNewRecentDocument: (NSDocument *)aDocument
{
  NSURL *anURL = [aDocument fileURL];

  if (anURL != nil)
    [self noteNewRecentDocumentURL: anURL];
}

- (void) noteNewRecentDocumentURL: (NSURL *)anURL
{
  unsigned index = [_recent_documents indexOfObject: anURL];
  NSMutableArray *a;

  if (index != NSNotFound)
    {
      // Always keep the current object at the end of the list
      [_recent_documents removeObjectAtIndex: index];
    }
  else if ([_recent_documents count] > [self maximumRecentDocumentCount])
    {
      [_recent_documents removeObjectAtIndex: 0];
    }

  [_recent_documents addObject: anURL];

  // Save the changed list
  a = [_recent_documents mutableCopy];
  index = [a count];
  while (index-- > 0)
    {
      [a replaceObjectAtIndex: index withObject:
        [[a objectAtIndex: index] absoluteString]];
    }
  [[NSUserDefaults standardUserDefaults] 
    setObject: a forKey: NSRecentDocuments];
  RELEASE(a);
	[self _updateOpenRecentMenu];
}

- (NSArray *) recentDocumentURLs
{
  return _recent_documents;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // FIXME
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  // FIXME
  return self;
}

@end

@implementation NSDocumentController (Private)

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
      
      // if the standard one isn't filled... check the CF key.
      if (role == nil)
        {
          role = [typeInfo objectForKey: CFBundleTypeRole];
        }

      if ([docClassName isEqualToString: className] 
          && (role == nil 
              || [role isEqual: NSEditorRole] 
              || [role isEqual: NSViewerRole]))
        {
          NSString *name = [typeInfo objectForKey: NSNameKey];

          if(name == nil)
            {
              name = [typeInfo objectForKey: CFBundleTypeName];
            }
          [types addObject: name];
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
      
      // if the standard one isn't filled... check the CF key.
      if (role == nil)
        {
          role = [typeInfo objectForKey: CFBundleTypeRole];
        }

      if ([docClassName isEqualToString: className] &&
          (role == nil || [role isEqual: NSEditorRole]))
        {
          NSString *name = [typeInfo objectForKey: NSNameKey];

          if(name == nil)
            {
              name = [typeInfo objectForKey: CFBundleTypeName];
            }
          [types addObject: name];
        }
    }
  
  return types;
}

- (NSArray *) _exportableTypesForClass: (Class)documentClass
{
  // Dunno what this method is for; maybe looks for filter types
  return [self _editorTypesForClass: documentClass];
}

- (NSString *) _nameForHumanReadableType: (NSString *)type
{
  return [HR_TYPE_INFO(type) objectForKey: NSNameKey];
}

- (NSArray *) _displayNamesForTypes: (NSArray *)types
{
  NSEnumerator *en = [types objectEnumerator];
  NSString *type = nil;
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: 10];
  while ((type = (NSString *)[en nextObject]) != nil)
    {
      NSString *name = [self displayNameForType: type];
      [result addObject: name];
    }
  return result;
}

- (NSArray *) _displayNamesForClass: (Class)documentClass
{
  return [self _displayNamesForTypes: 
                 [self _editorTypesForClass: documentClass]];
}

static NSMapTable *autosavedDocuments = NULL;
static NSString *processName = nil;

- (NSString *) _autosaveDirectory: (BOOL)create
{
  NSArray *paths =
      NSSearchPathForDirectoriesInDomains (NSLibraryDirectory,
                                           NSUserDomainMask,
                                           YES);
  NSString *path = [paths objectAtIndex:0];
  path = [path stringByAppendingPathComponent: @"Autosave"];

  if (create)
    {
      BOOL isDir;
      NSFileManager *fm = [NSFileManager defaultManager];

      if ([fm fileExistsAtPath: path isDirectory: &isDir] == NO)
        {
          if (![fm createDirectoryAtPath: path attributes: nil])
            return nil;
        }
      else if (isDir == NO)
        {
          if (![fm removeFileAtPath: path handler: nil] ||
              ![fm createDirectoryAtPath: path attributes: nil])
            return nil;
        }
    }

  return path;
}

- (void) _autosaveDocuments: (NSTimer *)timer
{
  id document;
  int i, n = [_documents count];

  for (i = 0; i < n; i++)
    {
      document = [_documents objectAtIndex: i];
      if ([document autosavingFileType] && [document hasUnautosavedChanges])
        {
          [document autosaveDocumentWithDelegate: nil
                    didAutosaveSelector: NULL
                    contextInfo: NULL];
        }
    }
}

- (BOOL) _reopenAutosavedDocuments
{
  BOOL didOpen = NO;

  if (!autosavedDocuments)
    {
      NSArray *autosaved;
      NSString *path;

      autosavedDocuments =
          NSCreateMapTable (NSObjectMapKeyCallBacks,
                            NSObjectMapValueCallBacks,
                            1);
      if (!processName)
        processName = [[[NSProcessInfo processInfo] processName] copy];

      path = [self _autosaveDirectory: NO];
      path = [path stringByAppendingPathComponent: processName];
      path = [path stringByAppendingPathExtension: @"plist"];
      autosaved = [NSArray arrayWithContentsOfFile: path];
      if (autosaved)
        {
          int i, n = [autosaved count];
          NSFileManager *fm = [NSFileManager defaultManager];

          for (i = 0; i < n; i++)
            {
              NSDictionary *dict = [autosaved objectAtIndex: i];
              NSString *location = [dict objectForKey: @"Location"];
              NSString *autosavedLoc = [dict objectForKey: @"AutosavedLocation"];
              NSURL *url = location ? [NSURL URLWithString: location] : nil;
              NSURL *autosavedURL =
                  autosavedLoc ? [NSURL URLWithString: autosavedLoc] : nil;

              if (autosavedURL && [fm fileExistsAtPath: [autosavedURL path]])
                {
                  NSError *err;
                  if ([self reopenDocumentForURL: url
                            withContentsOfURL: autosavedURL
                            error: &err])
                    didOpen = YES;
                }
            }
        }
    }

  return didOpen;
}

- (void) _recordAutosavedDocument: (NSDocument *)document
{
  BOOL changed = NO;
  NSURL *url = [document autosavedContentsFileURL];

  if (!autosavedDocuments)
    autosavedDocuments =
        NSCreateMapTable (NSObjectMapKeyCallBacks,
                          NSObjectMapValueCallBacks,
                          1);
  if (url)
    {
      NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
      if ([document fileURL])
        [dict setObject: [document fileURL] forKey: @"Location"];
      [dict setObject: url forKey: @"AutosavedLocation"];
      NSMapInsert (autosavedDocuments, document, dict);
      [dict release];
      changed = YES;
    }
  else if (NSMapGet (autosavedDocuments, document))
    {
      NSMapRemove (autosavedDocuments, document);
      changed = YES;
    }

  if (changed)
    {
      NSString *path = [self _autosaveDirectory: YES];
      NSArray *autosaved = NSAllMapTableValues (autosavedDocuments);
      NSFileManager *fm = [NSFileManager defaultManager];

      if (!processName)
        processName = [[[NSProcessInfo processInfo] processName] copy];

      path = [path stringByAppendingPathComponent: processName];
      path = [path stringByAppendingPathExtension: @"plist"];
      if ([autosaved count] == 0)
        {
          [fm removeFileAtPath: path handler: nil];
        }
      else
        {
          [autosaved writeToFile: path atomically:YES];
        }
    }
}
@end


@implementation NSDocumentController (RecentsMenu)

- (NSMenu *) _recentMenu
{
  // FIXME
  return nil;
}

// should be handled by making us the delegate of the recent's menu
- (void) _updateOpenRecentMenu
{
	NSMenu *recentMenu;
	int i;

	recentMenu = [self _recentMenu];
	if (!recentMenu)
		{
      return;
		}

	// don't update (to keep Clear List status consistent)
	[recentMenu setAutoenablesItems: NO];
	[recentMenu setMenuChangedMessagesEnabled: NO];

	while ([recentMenu numberOfItems] > 0)
		[recentMenu removeItemAtIndex: 0];	// remove them all

	for (i = [_recent_documents count]; i >= -2; i--)
		{
      // add all items incl. a Clear List item if needed
      NSMenuItem *item;

      if (i == -1)
			  {
          if ([_recent_documents count] == 0)
            continue;	// skip if menu is empty
          item = (NSMenuItem *) [NSMenuItem separatorItem];
          // will release...
          RETAIN(item);
        }
      else if (i == -2)
			  {
          item = [[NSMenuItem alloc] initWithTitle: _(@"Clear List")
                                     action: @selector(clearRecentDocuments:) 
                                     keyEquivalent: nil];
          // disable for empty list
          [item setEnabled: [_recent_documents count] > 0];
        }
      else
			  {
          // standard item
          NSURL *u = [_recent_documents objectAtIndex: i];	// get URL
          if ([u isFileURL])
            item = [[NSMenuItem alloc] initWithTitle: [[u path] lastPathComponent] 
                                       action: @selector(_openRecentDocument:)
                                       keyEquivalent:nil];
          else
              item = [[NSMenuItem alloc] initWithTitle: [u relativeString]
                                         action: @selector(_openRecentDocument:)
                                         keyEquivalent:nil];
          [item setTag: i];
        }
      [item setTarget: self];
      [recentMenu addItem: item];
      RELEASE(item);
		}

	[recentMenu setMenuChangedMessagesEnabled: YES];
}

- (IBAction) _openRecentDocument: (id)sender
{
  // action to open recent document by tag index
	NSURL *url;
	int idx = [sender tag];

	if (idx < 0 || idx >= [_recent_documents count])
		{
      // something went wrong, ignore
      [self _updateOpenRecentMenu];
      return;
		}
	url = (NSURL *)[_recent_documents objectAtIndex: idx];
  [self openDocumentWithContentsOfURL: url display: YES];
}

@end
