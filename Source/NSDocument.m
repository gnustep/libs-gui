/** <title>NSDocument</title>

   <abstract>The abstract document class</abstract>

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <Foundation/NSData.h>
#include <AppKit/NSDocument.h>
#include <AppKit/NSFileWrapper.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPageLayout.h>
#include <AppKit/NSView.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSDocumentFrameworkPrivate.h>

#include <AppKit/GSGuiPrivate.h>

@implementation NSDocument

+ (NSArray *)readableTypes
{
  return [[NSDocumentController sharedDocumentController]
	   _editorAndViewerTypesForClass:self];
}

+ (NSArray *)writableTypes
{
  return [[NSDocumentController sharedDocumentController] 
	   _editorTypesForClass:self];
}

+ (BOOL)isNativeType:(NSString *)type
{
  return ([[self readableTypes] containsObject:type] &&
	  [[self writableTypes] containsObject:type]);
}


- (id)init
{
  static int untitledCount = 1;
  
  [super init];
  _documentIndex = untitledCount++;
  _windowControllers = [[NSMutableArray alloc] init];

  /* Set our default type */
  [self setFileType: [[[self class] writableTypes] objectAtIndex: 0]];
  return self;
}

- (id)initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)fileType
{
  [self init];
	
  if ([self readFromFile:fileName ofType:fileType])
    {
      [self setFileType:fileType];
      [self setFileName:fileName];
    }
  else
    {
      NSRunAlertPanel (_(@"Load failed"),
		       _(@"Could not load file %@."),
		       nil, nil, nil, fileName);
      RELEASE(self);
      return nil;
    }
	
  return self;
}

- (id)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)fileType
{
  [super init];

  if ([self readFromURL:url ofType:fileType])
    {
      [self setFileType:fileType];
      [self setFileName:[url path]];
    }
  else
    {
      NSRunAlertPanel(_(@"Load failed"),
		      _(@"Could not load URL %@."),
		      nil, nil, nil, [url absoluteString]);
      RELEASE(self);
      return nil;
    }
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  RELEASE(_undoManager);
  RELEASE(_fileName);
  RELEASE(_fileType);
  RELEASE(_windowControllers);
  RELEASE(_window);
  RELEASE(_printInfo);
  RELEASE(savePanelAccessory);
  RELEASE(spaButton);
  [super dealloc];
}

- (NSString *)fileName
{
  return _fileName;
}

- (void)setFileName:(NSString *)fileName
{
  ASSIGN(_fileName, fileName);
	
  [_windowControllers makeObjectsPerformSelector:
			@selector(synchronizeWindowTitleWithDocumentName)];
}

- (NSString *)fileType
{
  return _fileType;
}

- (void)setFileType:(NSString *)type
{
  ASSIGN(_fileType, type);
}

- (NSArray *)windowControllers
{
  return _windowControllers;
}

- (void)addWindowController:(NSWindowController *)windowController
{
  [_windowControllers addObject:windowController];
  if ([windowController document] != self)
    [windowController setDocument:self];
}

- (void)removeWindowController:(NSWindowController *)windowController
{
  if ([_windowControllers containsObject:windowController])
    {
	[windowController setDocument:nil];
	[_windowControllers removeObject:windowController];
    }
}

- (NSString *)windowNibName
{
  return nil;
}

// private; called during nib load.  
// we do not retain the window, since it should
// already have a retain from the nib.
- (void)setWindow:(NSWindow *)aWindow
{
  _window = aWindow;
}

//FIXME: In the later specification this method has a different return type!! 
- (void)makeWindowControllers
{
  NSString *name = [self windowNibName];

  if (name != nil && [name length] > 0)
    {
      NSWindowController *controller;
      controller = [[NSWindowController alloc] initWithWindowNibName:name owner:self];
      [self addWindowController:controller];
      RELEASE(controller);
    }
  else
    {
      [NSException raise:NSInternalInconsistencyException
		   format:@"%@ must override either -windowNibName or -makeWindowControllers",
		   NSStringFromClass([self class])];
    }
}

- (void)showWindows
{
  [_windowControllers makeObjectsPerformSelector:@selector(showWindow:) withObject:self];
}

- (BOOL)isDocumentEdited
{
  return _changeCount != 0;
}

- (void)updateChangeCount:(NSDocumentChangeType)change
{
  int i, count = [_windowControllers count];
  BOOL isEdited;
  
  switch (change)
    {
    case NSChangeDone:		_changeCount++; break;
    case NSChangeUndone:	_changeCount--; break;
    case NSChangeCleared:	_changeCount = 0; break;
    }
  
    /*
     * NOTE: Apple's implementation seems to not call -isDocumentEdited
     * here but directly checks to see if _changeCount == 0.  It seems it
     * would be better to call the method in case it's overridden by a
     * subclass, but we may want to keep Apple's behavior.
     */
  isEdited = [self isDocumentEdited];

  for (i=0; i<count; i++)
    {
      [[_windowControllers objectAtIndex: i] setDocumentEdited: isEdited];
    }
}

- (BOOL)canCloseDocument
{
  int result;

  if (![self isDocumentEdited])
    return YES;

  result = NSRunAlertPanel (_(@"Close"), 
			    _(@"%@ has changed.  Save?"),
			    _(@"Save"), _(@"Cancel"), _(@"Don't Save"), 
			    [self displayName]);
  
#define Save     NSAlertDefaultReturn
#define Cancel   NSAlertAlternateReturn
#define DontSave NSAlertOtherReturn

  switch (result)
    {
      // return NO if save failed
    case Save:
      {
	[self saveDocument:nil]; 
	return ![self isDocumentEdited];
      }
    case DontSave:	return YES;
    case Cancel:
    default:		return NO;
    }
}

- (void)canCloseDocumentWithDelegate:(id)delegate 
		 shouldCloseSelector:(SEL)shouldCloseSelector 
			 contextInfo:(void *)contextInfo
{
  BOOL result = [self canCloseDocument];

  if (delegate != nil && shouldCloseSelector != NULL)
    {
      // FIXME: This is the only way I know to call a callback with 
      // irregular arguments
      void (*meth)(id, SEL, id, BOOL, void*);
      meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector: 
							       shouldCloseSelector];
      if (meth)
	meth(delegate, shouldCloseSelector, self, result, contextInfo);
    }
}

- (BOOL)shouldCloseWindowController:(NSWindowController *)windowController
{
  if (![_windowControllers containsObject:windowController]) return YES;

  /* If it's the last window controller, pop up a warning */
  /* maybe we should count only loaded window controllers (or visible windows). */
  if ([windowController shouldCloseDocument]
      || [_windowControllers count] == 1)
    {
      return [self canCloseDocument];
    }
	
  return YES;
}

- (void)shouldCloseWindowController:(NSWindowController *)windowController 
			   delegate:(id)delegate 
		shouldCloseSelector:(SEL)callback
			contextInfo:(void *)contextInfo
{
  BOOL result = [self shouldCloseWindowController: windowController];

  if (delegate != nil && callback != NULL)
    {
      // FIXME: This is the only way I know to call a callback with 
      // irregular argumetns
      void (*meth)(id, SEL, id, BOOL, void*);
      meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector: 
							       callback];
      
      if (meth)
	meth(delegate, callback, self, result, contextInfo);
    }
}

- (NSString *)displayName
{
  if ([self fileName] != nil)
    {
      return [[[self fileName] lastPathComponent] stringByDeletingPathExtension];
    }
  else
    {
      return [NSString stringWithFormat: _(@"Untitled-%d"), _documentIndex];
    }
}

- (BOOL)keepBackupFile
{
  return NO;
}

- (NSData *)dataRepresentationOfType:(NSString *)type
{
  [NSException raise:NSInternalInconsistencyException format:@"%@ must implement %@",
	       NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type
{
  [NSException raise:NSInternalInconsistencyException format:@"%@ must implement %@",
	       NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  return NO;
}

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type
{
  NSData *data = [self dataRepresentationOfType:type];
  
  if (data == nil) 
    return nil;

  return AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents:data]);
}

- (BOOL)loadFileWrapperRepresentation:(NSFileWrapper *)wrapper ofType:(NSString *)type
{
  if ([wrapper isRegularFile])
    {
      return [self loadDataRepresentation:[wrapper regularFileContents] ofType:type];
    }
  
    /*
     * This even happens on a symlink.  May want to use
     * -stringByResolvingAllSymlinksInPath somewhere, but Apple doesn't.
     */
  NSLog(@"%@ must be overridden if your document deals with file packages.",
	NSStringFromSelector(_cmd));

  return NO;
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type
{
  return [[self fileWrapperRepresentationOfType:type]
	   writeToFile:fileName atomically:YES updateFilenames:YES];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type
{
  NSFileWrapper *wrapper = AUTORELEASE([[NSFileWrapper alloc] initWithPath:fileName]);
  return [self loadFileWrapperRepresentation:wrapper ofType:type];
}

- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type
{
  return [self readFromFile:fileName ofType:type];
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)type
{
  NSData *data = [self dataRepresentationOfType:type];
  
  if (data == nil) 
    return NO;

  return [url setResourceData: data];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type
{
  NSData *data = [url resourceDataUsingCache: YES];

  if (data == nil) 
    return NO;

  return [self loadDataRepresentation: data ofType: type];
}

- (BOOL)revertToSavedFromURL:(NSURL *)url ofType:(NSString *)type
{
  return [self readFromURL: url ofType: type];
}

- (IBAction)changeSaveType:(id)sender
{ 
//FIXME if we have accessory -- store the desired save type somewhere.
}

- (int)runModalSavePanel:(NSSavePanel *)savePanel 
       withAccessoryView:(NSView *)accessoryView
{
  [savePanel setAccessoryView:accessoryView];
  return [savePanel runModal];
}

- (BOOL)shouldRunSavePanelWithAccessoryView
{
  return YES;
}

- (void)_loadPanelAccessoryNib
{
// FIXME.  We need to load the pop-up button
}
- (void)_addItemsToSpaButtonFromArray:(NSArray *)types
{
// FIXME.  Add types to popup.
}

- (NSString *)fileNameFromRunningSavePanelForSaveOperation:(NSSaveOperationType)saveOperation
{
  NSView *accessory = nil;
  NSString *title;
  NSString *directory;
  NSArray *extensions;
  NSDocumentController *controller;
  NSSavePanel *savePanel = [NSSavePanel savePanel];

  controller = [NSDocumentController sharedDocumentController];
  extensions = [controller fileExtensionsFromType:[self fileType]];
  
  if ([self shouldRunSavePanelWithAccessoryView])
    {
      if (savePanelAccessory == nil)
	[self _loadPanelAccessoryNib];
      
      [self _addItemsToSpaButtonFromArray:extensions];
      
      accessory = savePanelAccessory;
    }

  if ([extensions count] > 0)
    [savePanel setRequiredFileType:[extensions objectAtIndex:0]];

  switch (saveOperation)
    {
    case NSSaveAsOperation: title = _(@"Save As"); break;
    case NSSaveToOperation: title = _(@"Save To"); break; 
    case NSSaveOperation: 
    default:
      title = _(@"Save");    
      break;
   }
  
  [savePanel setTitle:title];

  
  if ([self fileName])
    directory = [[self fileName] stringByDeletingLastPathComponent];
  else
    directory = [controller currentDirectory];
  [savePanel setDirectory: directory];
	
  if ([self runModalSavePanel:savePanel withAccessoryView:accessory])
    {
      return [savePanel filename];
    }
  
  return nil;
}

- (BOOL)shouldChangePrintInfo:(NSPrintInfo *)newPrintInfo
{
  return YES;
}

- (NSPrintInfo *)printInfo
{
  return _printInfo? _printInfo : [NSPrintInfo sharedPrintInfo];
}

- (void)setPrintInfo:(NSPrintInfo *)printInfo
{
  ASSIGN(_printInfo, printInfo);
}


// Page layout panel (Page Setup)

- (int)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo
{
  return [[NSPageLayout pageLayout] runModalWithPrintInfo:printInfo];
}

- (IBAction)runPageLayout:(id)sender
{
  NSPrintInfo *printInfo = [self printInfo];
  
  if ([self runModalPageLayoutWithPrintInfo:printInfo]
      && [self shouldChangePrintInfo:printInfo])
    {
      [self setPrintInfo:printInfo];
      [self updateChangeCount:NSChangeDone];
    }
}

/* This is overridden by subclassers; the default implementation does nothing. */
- (void)printShowingPrintPanel:(BOOL)flag
{
}

- (IBAction)printDocument:(id)sender
{
  [self printShowingPrintPanel:YES];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
  if ([anItem action] == @selector(revertDocumentToSaved:))
    return ([self fileName] != nil && [self isDocumentEdited]);

  // FIXME should validate spa popup items; return YES if it's a native type.
    
  return YES;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
  if ([anItem action] == @selector(revertDocumentToSaved:))
    return ([self fileName] != nil);

  return YES;
}

- (NSString *)fileTypeFromLastRunSavePanel
{
  // FIXME this should return type picked on save accessory
  // return [spaPopupButton title];
  return [self fileType];
}

- (NSDictionary *)fileAttributesToWriteToFile: (NSString *)fullDocumentPath 
				       ofType: (NSString *)docType 
				saveOperation: (NSSaveOperationType)saveOperationType
{
  // FIXME: Implement.
  return [NSDictionary dictionary];
}

- (BOOL)writeToFile:(NSString *)fileName 
	     ofType:(NSString *)type 
       originalFile:(NSString *)origFileName
      saveOperation:(NSSaveOperationType)saveOp
{
  return [self writeToFile: fileName ofType: type];
}

- (BOOL)writeWithBackupToFile:(NSString *)fileName 
		       ofType:(NSString *)fileType 
		saveOperation:(NSSaveOperationType)saveOp
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *backupFilename = nil;

  if (fileName)
    {
      if ([fileManager fileExistsAtPath:fileName])
	{
	  NSString *extension  = [fileName pathExtension];
	  
	  backupFilename = [fileName stringByDeletingPathExtension];
	  backupFilename = [backupFilename stringByAppendingString:@"~"];
	  backupFilename = [backupFilename stringByAppendingPathExtension:extension];

	  /* Save panel has already asked if the user wants to replace it */

	  /* NSFileManager movePath: will fail if destination exists */
	  if ([fileManager fileExistsAtPath:backupFilename])
	    [fileManager removeFileAtPath:backupFilename handler:nil];

	  // Move or copy?
	  if (![fileManager movePath:fileName toPath:backupFilename handler:nil] &&
	      [self keepBackupFile])
            {
	      int result = NSRunAlertPanel(_(@"File Error"),
					   _(@"Can't create backup file.  Save anyways?"),
					   _(@"Save"), _(@"Cancel"), nil);
	      
	      if (result != NSAlertDefaultReturn) return NO;
            }
	}
      if ([self writeToFile: fileName 
		ofType: fileType
		originalFile: backupFilename
		saveOperation: saveOp])
	{
	  if (saveOp != NSSaveToOperation)
	    {
	      [self setFileName:fileName];
	      [self setFileType: fileType];
	      [self updateChangeCount:NSChangeCleared];
	    }
	  
	  if (backupFilename && ![self keepBackupFile])
	    {
	      [fileManager removeFileAtPath:backupFilename handler:nil];
	    }

	  return YES;
	}
    }

  return NO;
}

- (IBAction)saveDocument:(id)sender
{
  NSString *filename = [self fileName];

  if (filename == nil)
    {
      [self saveDocumentAs: sender];
      return;
    }

  [self writeWithBackupToFile: filename 
	ofType: [self fileType]
	saveOperation: NSSaveOperation];
}

- (IBAction)saveDocumentAs:(id)sender
{
  NSString *filename = 
      [self fileNameFromRunningSavePanelForSaveOperation: 
		NSSaveAsOperation];

  [self writeWithBackupToFile: filename 
	ofType: [self fileTypeFromLastRunSavePanel]
	saveOperation: NSSaveAsOperation];
}

- (IBAction)saveDocumentTo:(id)sender
{
  NSString *filename = 
      [self fileNameFromRunningSavePanelForSaveOperation: 
		NSSaveToOperation];

  [self writeWithBackupToFile: filename 
	ofType: [self fileTypeFromLastRunSavePanel]
	saveOperation: NSSaveToOperation];
}

- (void)saveDocumentWithDelegate:(id)delegate 
		 didSaveSelector:(SEL)didSaveSelector 
		     contextInfo:(void *)contextInfo
{
  // FIXME
}

- (void)saveToFile:(NSString *)fileName 
     saveOperation:(NSSaveOperationType)saveOperation 
	  delegate:(id)delegate
   didSaveSelector:(SEL)didSaveSelector 
       contextInfo:(void *)contextInfo
{
  // FIXME
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
  return YES;
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation 
				 delegate:(id)delegate
			  didSaveSelector:(SEL)didSaveSelector 
			      contextInfo:(void *)contextInfo
{
  // FIXME
}

- (IBAction)revertDocumentToSaved:(id)sender
{
  int result;

  result = NSRunAlertPanel 
    (_(@"Revert"),
     _(@"%@ has been edited.  Are you sure you want to undo changes?"),
     _(@"Revert"), _(@"Cancel"), nil, 
     [self displayName]);
  
  if (result == NSAlertDefaultReturn &&
      [self revertToSavedFromFile:[self fileName] ofType:[self fileType]])
    {
      [self updateChangeCount:NSChangeCleared];
    }
}

- (void)close
{
  // We have an _docFlags.inClose flag, but I don't think we need to use it.
  [_windowControllers makeObjectsPerformSelector:@selector(close)];
  [[NSDocumentController sharedDocumentController] removeDocument:self];
}

- (void)windowControllerWillLoadNib:(NSWindowController *)windowController {}
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController  {}

- (NSUndoManager *)undoManager
{
  if (_undoManager == nil && [self hasUndoManager])
    {
      [self setUndoManager: AUTORELEASE([[NSUndoManager alloc] init])];
    }
  
  return _undoManager;
}

- (void)setUndoManager:(NSUndoManager *)undoManager
{
  if (undoManager != _undoManager)
    {
      NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
      
      if (_undoManager)
        {
	  [center removeObserver:self
		  name:NSUndoManagerWillCloseUndoGroupNotification
		  object:_undoManager];
	  [center removeObserver:self
		  name:NSUndoManagerDidUndoChangeNotification
		  object:_undoManager];
	  [center removeObserver:self
		  name:NSUndoManagerDidRedoChangeNotification
		  object:_undoManager];
        }
      
      ASSIGN(_undoManager, undoManager);
      
      if (_undoManager == nil)
        {
	  [self setHasUndoManager:NO];
        }
      else
        {
	  [center addObserver:self
		  selector:@selector(_changeWasDone:)
		  name:NSUndoManagerWillCloseUndoGroupNotification
		  object:_undoManager];
	  [center addObserver:self
		  selector:@selector(_changeWasUndone:)
		  name:NSUndoManagerDidUndoChangeNotification
		  object:_undoManager];
	  [[NSNotificationCenter defaultCenter]
	    addObserver:self
	    selector:@selector(_changeWasRedone:)
	    name:NSUndoManagerDidRedoChangeNotification
	    object:_undoManager];
        }
    }
}

- (BOOL)hasUndoManager
{
  return _docFlags.hasUndoManager;
}

- (void)setHasUndoManager:(BOOL)flag
{
  if (_undoManager && !flag)
    [self setUndoManager:nil];
  
  _docFlags.hasUndoManager = flag;
}
@end

@implementation NSDocument(Private)

/*
 * This private method is used to transfer window ownership to the
 * NSWindowController in situations (such as the default) where the
 * document is set to the nib owner, and thus owns the window immediately
 * following the loading of the nib.
 */
- (NSWindow *)_transferWindowOwnership
{
  NSWindow *window = _window;
  _window = nil;
  return AUTORELEASE(window);
}

- (void)_removeWindowController:(NSWindowController *)windowController
{
  if ([_windowControllers containsObject:windowController])
    {
      BOOL autoClose = [windowController shouldCloseDocument];
      
      [windowController setDocument:nil];
      [_windowControllers removeObject:windowController];
      
      if (autoClose || [_windowControllers count] == 0)
        {
	  [self close];
	}
    }
}

- (void)_changeWasDone:(NSNotification *)notification
{
  [self updateChangeCount:NSChangeDone];
}

- (void)_changeWasUndone:(NSNotification *)notification
{
  [self updateChangeCount:NSChangeUndone];
}

- (void)_changeWasRedone:(NSNotification *)notification
{
  [self updateChangeCount:NSChangeDone];
}

@end
