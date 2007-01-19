/** <title>NSDocument</title>

   <abstract>The abstract document class</abstract>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Carl Lindberg <Carl.Lindberg@hbo.com>
   Date: 1999
   Modifications: Fred Kiefer <FredKiefer@gmx.de>
   Date: June 2000, Dec 2006

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

#include <Foundation/NSData.h>
#include "AppKit/NSBox.h"
#include "AppKit/NSDocument.h"
#include "AppKit/NSFileWrapper.h"
#include "AppKit/NSSavePanel.h"
#include "AppKit/NSPageLayout.h"
#include "AppKit/NSPrintInfo.h"
#include "AppKit/NSPrintOperation.h"
#include "AppKit/NSPopUpButton.h"
#include "AppKit/NSView.h"
#include "NSDocumentFrameworkPrivate.h"

#include "GSGuiPrivate.h"

@implementation NSDocument

+ (NSArray *)readableTypes
{
  return [[NSDocumentController sharedDocumentController]
	   _editorAndViewerTypesForClass: self];
}

+ (NSArray *)writableTypes
{
  return [[NSDocumentController sharedDocumentController] 
	   _editorTypesForClass: self];
}

+ (BOOL)isNativeType: (NSString *)type
{
  return ([[self readableTypes] containsObject: type] &&
	  [[self writableTypes] containsObject: type]);
}


- (id) init
{
  static int untitledCount = 1;
  NSArray *fileTypes;
  
  self = [super init];
  if (self != nil)
    {
      _document_index = untitledCount++;
      _window_controllers = [[NSMutableArray alloc] init];
      fileTypes = [[self class] readableTypes];
      _doc_flags.has_undo_manager = YES;

      /* Set our default type */
      if ([fileTypes count])
       { 
         [self setFileType: [fileTypes objectAtIndex: 0]];
	 ASSIGN(_save_type, [fileTypes objectAtIndex: 0]);
       }
    }
  return self;
}

/**
 * Initialises the receiver with the contents of the document at fileName
 * assuming that the type of data is as specified by fileType.<br />
 * Destroys the receiver and returns nil on failure.
 */
- (id) initWithContentsOfFile: (NSString*)fileName ofType: (NSString*)fileType
{
  self = [self init];
  if (self != nil)
    {
      if ([self readFromFile: fileName ofType: fileType])
        {
	  [self setFileType: fileType];
	  [self setFileName: fileName];
	}
      else
	{
	  NSRunAlertPanel (_(@"Load failed"),
			   _(@"Could not load file %@."),
			   nil, nil, nil, fileName);
	  DESTROY(self);
	}
    }
  return self;
}

/**
 * Initialises the receiver with the contents of the document at url
 * assuming that the type of data is as specified by fileType.<br />
 * Destroys the receiver and returns nil on failure.
 */
- (id) initWithContentsOfURL: (NSURL*)url ofType: (NSString*)fileType
{
  self = [self init];
  if (self != nil)
    {
      if ([self readFromURL: url ofType: fileType])
	{
	  [self setFileType: fileType];
	  [self setFileName: [url path]];
	}
      else
	{
	  NSRunAlertPanel(_(@"Load failed"),
			  _(@"Could not load URL %@."),
			  nil, nil, nil, [url absoluteString]);
	  DESTROY(self);
	}
    }  
  return self;
}

- (id)initForURL: (NSURL *)forUrl
withContentsOfURL: (NSURL *)url
          ofType: (NSString *)type
           error: (NSError **)error
{
  self = [self initWithType: type error: error];
  if (self != nil)
    {
      if ([self readFromURL: url
                     ofType: type
		      error: error])
        {
	  if (forUrl != nil)
	    {
	      [self setFileURL: forUrl];
	    }
	}
      else 
        {
	  DESTROY(self);
	}
    }
  return self;
}

- (id)initWithContentsOfURL: (NSURL *)url
                     ofType: (NSString *)type
                      error: (NSError **)error
{
  return [self initForURL: url
        withContentsOfURL: url
	           ofType: type
	            error: error];
}

- (id)initWithType:(NSString *)type
             error:(NSError **)error
{
  self = [self init];
  if (self != nil)
    {
      [self setFileType: type];
    }
  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(_undo_manager);
  RELEASE(_file_name);
  RELEASE(_file_url);
  RELEASE(_file_type);
  RELEASE(_last_component_file_name);
  RELEASE(_autosaved_file_url);
  RELEASE(_file_modification_date);
  RELEASE(_window_controllers);
  RELEASE(_window);
  RELEASE(_print_info);
  RELEASE(_save_panel_accessory);
  RELEASE(_spa_button);
  RELEASE(_save_type);
  [super dealloc];
}

/* 
 * Private helper method to check, if the method given via the selector sel 
 * has been overridden in the current subclass.
 */
- (BOOL)_hasOverridden: (SEL)sel
{
  // The actual signature is not important as we wont call the methods.
  IMP meth1;
  IMP meth2;

  meth1 = [self methodForSelector: sel];
  meth2 = [[NSDocument class] instanceMethodForSelector: sel];

  return (meth1 != meth2);
}

#define OVERRIDDEN(sel) [self _hasOverridden: @selector(sel)]

- (NSString *)fileName
{
  return _file_name;
}

- (void)setFileName: (NSString *)fileName
{
  // This check is to prevent super calls from recursing.
  if (!OVERRIDDEN(setFileName:))
    {
      [self setFileURL: [NSURL fileURLWithPath: fileName]];
    }
  ASSIGN(_file_name, fileName);
  [self setLastComponentOfFileName: [_file_name lastPathComponent]];
}

- (NSString *)fileType
{
  return _file_type;
}

- (void)setFileType: (NSString *)type
{
  ASSIGN(_file_type, type);
}

- (NSURL *)fileURL
{
  if (OVERRIDDEN(fileName))
    {
      return [NSURL fileURLWithPath: [self fileName]];
    }
  else
    {
      return _file_url;
    }
}

- (void)setFileURL: (NSURL *)url
{
  if (OVERRIDDEN(setFileName:) && 
      ((url == nil) || [url isFileURL]))
    {
      [self setFileName: [url path]];
    }
  else
    {
      ASSIGN(_file_url, url);
      [self setLastComponentOfFileName: [[_file_url path] lastPathComponent]];
    }
}

- (NSDate *)fileModificationDate
{
  return _file_modification_date;
}

- (void)setFileModificationDate: (NSDate *)date
{
  ASSIGN(_file_modification_date, date);
}

- (NSString *)lastComponentOfFileName
{
  return _last_component_file_name;
}

- (void)setLastComponentOfFileName: (NSString *)str
{
  ASSIGN(_last_component_file_name, str);

  [[self windowControllers] makeObjectsPerformSelector:
				@selector(synchronizeWindowTitleWithDocumentName)];
}

- (NSArray *)windowControllers
{
  return _window_controllers;
}

- (void)addWindowController: (NSWindowController *)windowController
{
  [_window_controllers addObject: windowController];
  if ([windowController document] != self)
    {
      [windowController setDocument: self];
    }
}

- (void)removeWindowController: (NSWindowController *)windowController
{
  if ([_window_controllers containsObject: windowController])
    {
      [windowController setDocument: nil];
      [_window_controllers removeObject: windowController];
    }
}

- (NSString *)windowNibName
{
  return nil;
}

// private; called during nib load.  
// we do not retain the window, since it should
// already have a retain from the nib.
- (void)setWindow: (NSWindow *)aWindow
{
  _window = aWindow;
}

- (NSWindow *)windowForSheet
{
  NSWindow *win;

  if (([_window_controllers count] > 0) &&
      ((win = [[_window_controllers objectAtIndex: 0] window]) != nil))
    {
      return win;
    }

  return [NSApp mainWindow];
}

/**
 * Creates the window controllers for the current document.  Calls
 * addWindowController: on the receiver to add them to the controller 
 * array.
 */
- (void) makeWindowControllers
{
  NSString *name = [self windowNibName];

  if (name != nil && [name length] > 0)
    {
      NSWindowController *controller;

      controller = [[NSWindowController alloc] initWithWindowNibName: name
							       owner: self];
      [self addWindowController: controller];
      RELEASE(controller);
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException
		  format: @"%@ must override either -windowNibName "
	@"or -makeWindowControllers", NSStringFromClass([self class])];
    }
}

/**
 * Makes all the documents windows visible by ordering them to the
 * front and making them main or key.<br />
 * If the document has no windows, this method has no effect.
 */
- (void) showWindows
{
  [_window_controllers makeObjectsPerformSelector: @selector(showWindow:)
				      withObject: self];
}

- (BOOL) isDocumentEdited
{
  return _change_count != 0;
}

- (void)updateChangeCount: (NSDocumentChangeType)change
{
  int i, count = [_window_controllers count];
  BOOL isEdited;
  
  switch (change)
    {
    case NSChangeDone:		_change_count++; 
	                        _autosave_change_count++; 
				break;
    case NSChangeUndone:	_change_count--; 
	                        _autosave_change_count--; 
				break;
    case NSChangeReadOtherContents:
    case NSChangeCleared:	_change_count = 0; 
                                _autosave_change_count = 0; 
				break;
    case NSChangeAutosaved:     _autosave_change_count = 0; 
	                        break;
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
      [[_window_controllers objectAtIndex: i] setDocumentEdited: isEdited];
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
	[self saveDocument: nil]; 
	return ![self isDocumentEdited];
      }
    case DontSave:	return YES;
    case Cancel:
    default:		return NO;
    }
}

- (void)canCloseDocumentWithDelegate: (id)delegate 
		 shouldCloseSelector: (SEL)shouldCloseSelector 
			 contextInfo: (void *)contextInfo
{
  BOOL result = [self canCloseDocument];

  if (delegate != nil && shouldCloseSelector != NULL)
    {
      void (*meth)(id, SEL, id, BOOL, void*);
      meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector: 
							       shouldCloseSelector];
      if (meth)
	meth(delegate, shouldCloseSelector, self, result, contextInfo);
    }
}

- (BOOL)shouldCloseWindowController: (NSWindowController *)windowController
{
  if (![_window_controllers containsObject: windowController]) return YES;

  /* If it's the last window controller, pop up a warning */
  /* maybe we should count only loaded window controllers (or visible windows). */
  if ([windowController shouldCloseDocument]
      || [_window_controllers count] == 1)
    {
      return [self canCloseDocument];
    }
	
  return YES;
}

- (void)shouldCloseWindowController: (NSWindowController *)windowController 
			   delegate: (id)delegate 
		shouldCloseSelector: (SEL)callback
			contextInfo: (void *)contextInfo
{
  BOOL result = [self shouldCloseWindowController: windowController];

  if (delegate != nil && callback != NULL)
    {
      void (*meth)(id, SEL, id, BOOL, void*);
      meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector: 
							       callback];
      
      if (meth)
	meth(delegate, callback, self, result, contextInfo);
    }
}

- (NSString *)displayName
{
  if ([self lastComponentOfFileName] != nil)
    {
      if ([self fileNameExtensionWasHiddenInLastRunSavePanel])
	{
	  return [[self lastComponentOfFileName] stringByDeletingPathExtension];
	}
      else
        {
	  return [self lastComponentOfFileName];
	}
    }
  else
    {
      return [NSString stringWithFormat: _(@"Untitled-%d"), _document_index];
    }
}

- (BOOL)keepBackupFile
{
  return NO;
}

- (NSData *)dataRepresentationOfType: (NSString *)type
{
  [NSException raise: NSInternalInconsistencyException format:@"%@ must implement %@",
	       NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  return nil;
}

- (NSData *)dataOfType: (NSString *)type
                 error: (NSError **)error
{
  if (OVERRIDDEN(dataRepresentationOfType:))
    {
      return [self dataRepresentationOfType: type];
    }

  [NSException raise: NSInternalInconsistencyException format:@"%@ must implement %@",
	       NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  return nil;
}

- (BOOL)loadDataRepresentation: (NSData *)data ofType: (NSString *)type
{
  [NSException raise: NSInternalInconsistencyException format:@"%@ must implement %@",
	       NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  return NO;
}

- (NSFileWrapper *)fileWrapperRepresentationOfType: (NSString *)type
{
  NSData *data = [self dataRepresentationOfType: type];
  
  if (data == nil) 
    return nil;

  return AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
}

- (NSFileWrapper *)fileWrapperOfType: (NSString *)type
                               error: (NSError **)error
{
  if (OVERRIDDEN(fileWrapperRepresentationOfType:))
    {
      return [self fileWrapperRepresentationOfType: type];
    }

  NSData *data = [self dataOfType: type error: error];
  
  if (data == nil) 
    return nil;

  return AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
}

- (BOOL)loadFileWrapperRepresentation: (NSFileWrapper *)wrapper ofType: (NSString *)type
{
  if ([wrapper isRegularFile])
    {
      return [self loadDataRepresentation:[wrapper regularFileContents] ofType: type];
    }
  
    /*
     * This even happens on a symlink.  May want to use
     * -stringByResolvingAllSymlinksInPath somewhere, but Apple doesn't.
     */
  NSLog(@"%@ must be overridden if your document deals with file packages.",
	NSStringFromSelector(_cmd));

  return NO;
}

- (BOOL)writeToFile: (NSString *)fileName ofType: (NSString *)type
{
  return [[self fileWrapperRepresentationOfType: type]
	   writeToFile: fileName atomically: YES updateFilenames: YES];
}

- (BOOL)readFromFile: (NSString *)fileName ofType: (NSString *)type
{
  NSFileWrapper *wrapper = AUTORELEASE([[NSFileWrapper alloc] initWithPath: fileName]);
  return [self loadFileWrapperRepresentation: wrapper ofType: type];
}

- (BOOL)revertToSavedFromFile: (NSString *)fileName ofType: (NSString *)type
{
  return [self readFromFile: fileName ofType: type];
}

- (BOOL)writeToURL: (NSURL *)url ofType: (NSString *)type
{
  NSData *data = [self dataRepresentationOfType: type];
  
  if (data == nil) 
    return NO;

  return [url setResourceData: data];
}

- (BOOL)readFromURL: (NSURL *)url ofType: (NSString *)type
{
  NSData *data = [url resourceDataUsingCache: YES];

  if (data == nil) 
    return NO;

  return [self loadDataRepresentation: data ofType: type];
}

- (BOOL)revertToSavedFromURL: (NSURL *)url ofType: (NSString *)type
{
  return [self readFromURL: url ofType: type];
}

- (BOOL)readFromData: (NSData *)data
              ofType: (NSString *)type
               error: (NSError **)error
{
  [NSException raise: NSInternalInconsistencyException format:@"%@ must implement %@",
	       NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  return NO;
}

- (BOOL)readFromFileWrapper: (NSFileWrapper *)wrapper
                     ofType: (NSString *)type
                      error: (NSError **)error
{
  if (OVERRIDDEN(loadFileWrapperRepresentation:ofType:))
    {
      return [self loadFileWrapperRepresentation: wrapper ofType: type];
    }

  if ([wrapper isRegularFile])
    {
      return [self readFromData: [wrapper regularFileContents]
                         ofType: type
                          error: error];
    }

  // FIXME: Set error
  return NO;
}

- (BOOL)readFromURL: (NSURL *)url
             ofType: (NSString *)type
              error: (NSError **)error
{
  if ([url isFileURL])
    {
      NSString *fileName = [url path];
      
      if (OVERRIDDEN(readFromFile:ofType:))
        {
	  return [self readFromFile: [url path] ofType: type];
	}
      else
        {
	  NSFileWrapper *wrapper = AUTORELEASE([[NSFileWrapper alloc] initWithPath: fileName]);
	  
	  return [self readFromFileWrapper: wrapper 
		       ofType: type
		       error: error];
	}
    }

  // FIXME: Set error
  return NO;
}

- (BOOL)revertToContentsOfURL: (NSURL *)url
                       ofType: (NSString *)type
                        error: (NSError **)error
{
  return [self readFromURL: url
                    ofType: type
	             error: error];
}

- (BOOL)writeToFile: (NSString *)fileName 
	     ofType: (NSString *)type 
       originalFile: (NSString *)origFileName
      saveOperation: (NSSaveOperationType)saveOp
{
  return [self writeToFile: fileName ofType: type];
}


- (NSString *)_backupFileNameFor: (NSString *)newFileName 
{
  NSString *extension = [newFileName pathExtension];
  NSString *backupFilename = [newFileName stringByDeletingPathExtension];
  backupFilename = [backupFilename stringByAppendingString:@"~"];
  return [backupFilename stringByAppendingPathExtension: extension];
}

- (BOOL)_writeBackupForFile: (NSString *)newFileName 
		      toFile: (NSString *)backupFilename
{
  NSFileManager *fileManager = [NSFileManager defaultManager];

  /* NSFileManager movePath: will fail if destination exists */
  /* Save panel has already asked if the user wants to replace it */
  if ([fileManager fileExistsAtPath: backupFilename])
    {
      [fileManager removeFileAtPath: backupFilename handler: nil];
    }
      
  // Move or copy?
  if (![fileManager movePath: newFileName toPath: backupFilename handler: nil] &&
      [self keepBackupFile])
    {
      int result = NSRunAlertPanel(_(@"File Error"),
				   _(@"Can't create backup file.  Save anyways?"),
				   _(@"Save"), _(@"Cancel"), nil);
      
      if (result != NSAlertDefaultReturn) return NO;
    }

  return YES;
}

- (BOOL)writeWithBackupToFile: (NSString *)fileName 
		       ofType: (NSString *)fileType 
		saveOperation: (NSSaveOperationType)saveOp
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *backupFilename = nil;
  BOOL isNativeType = [[self class] isNativeType: fileType];

  if (fileName && isNativeType)
    {
      NSArray  *extensions = [[NSDocumentController sharedDocumentController] 
			       fileExtensionsFromType: fileType];

      if ([extensions count] > 0)
	{
	  NSString *extension = [extensions objectAtIndex: 0];
	  NSString *newFileName = [[fileName stringByDeletingPathExtension] 
				    stringByAppendingPathExtension: extension];
	  
	  if ([fileManager fileExistsAtPath: newFileName])
	    {
	      backupFilename = [self _backupFileNameFor: newFileName];
	      
	      if (![self _writeBackupForFile: newFileName
			 toFile: backupFilename])
	        {
		  return NO;
		}
	    }

	  if ([self writeToFile: fileName 
		    ofType: fileType
		    originalFile: backupFilename
		    saveOperation: saveOp])
	    {
	      // FIXME: Should set the file attributes
	      
	      if (saveOp != NSSaveToOperation)
		{
		  [self setFileName: newFileName];
		  [self setFileType: fileType];
		  [self updateChangeCount: NSChangeCleared];
		}
	      
	      if (backupFilename && ![self keepBackupFile])
		{
		  [fileManager removeFileAtPath: backupFilename handler: nil];
		}
	      
	      return YES;
	    }
	}
    }

  return NO;
}

- (BOOL)writeSafelyToURL: (NSURL *)url
                  ofType: (NSString *)type
        forSaveOperation: (NSSaveOperationType)saveOp
                   error: (NSError **)error
{
  NSDictionary *attrs;
  NSURL *original = [self fileURL];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *backupFilename = nil;
  BOOL isNativeType = [[self class] isNativeType: type];
      
  if (OVERRIDDEN(writeWithBackupToFile:ofType:saveOperation:))
    {
      if (saveOp == NSAutosaveOperation)
	{
	  saveOp = NSSaveToOperation;
	}

      return [self writeWithBackupToFile: [url path] 
		   ofType: type 
		   saveOperation: saveOp];
    }

  if (!isNativeType || (url == nil))
    {
      return NO;
    }
  
  if (saveOp == NSSaveOperation)
    {
      if ([url isFileURL])
        {
	  NSString *newFileName;
	  
	  newFileName = [url path];
	  if ([fileManager fileExistsAtPath: newFileName])
	    {
	      backupFilename = [self _backupFileNameFor: newFileName];
	      
	      if (![self _writeBackupForFile: newFileName
			 toFile: backupFilename])
	        {
		  // FIXME: Set error.
		  return NO;
		}
	    }
	}
    }
      
  if (![self writeToURL: url 
	     ofType: type 
	     forSaveOperation: saveOp 
	     originalContentsURL: original
	     error: error])
    {
      return NO;
    }

  attrs = [self fileAttributesToWriteToURL: url
		ofType: type 
		forSaveOperation: saveOp 
		originalContentsURL: original
		error: error];
  // FIXME: Should set the file attributes

  if (saveOp != NSSaveToOperation)
    {
      [self setFileURL: url];
      [self setFileType: type];
      [self updateChangeCount: NSChangeCleared];
    }

  if (backupFilename && ![self keepBackupFile])
    {
      [fileManager removeFileAtPath: backupFilename handler: nil];
    }
	      
  return YES;
}

- (BOOL)writeToURL: (NSURL *)url 
            ofType: (NSString *)type 
             error: (NSError **)error
{
  NSFileWrapper *wrapper;

  if (OVERRIDDEN(writeToFile:ofType:))
    {
	return [self writeToFile: [url path] ofType: type];
    }

  wrapper = [self fileWrapperOfType: type
                              error: error];
  if (wrapper == nil)
    {
      return NO;
    }
   
  return [wrapper writeToFile: [url path] atomically: YES updateFilenames: YES];
}

- (BOOL)writeToURL: (NSURL *)url
            ofType: (NSString *)type
  forSaveOperation: (NSSaveOperationType)saveOp
originalContentsURL: (NSURL *)orig
             error: (NSError **)error
{
  if (OVERRIDDEN(writeToFile:ofType:originalFile:saveOperation:))
    {
      if (saveOp == NSAutosaveOperation)
	{
	  saveOp = NSSaveToOperation;
	}

      return [self writeToFile: [url path] 
		   ofType: type 
		   originalFile: [orig path] 
		   saveOperation: saveOp];
    }

  return [self writeToURL: url
	       ofType: type
	       error: error];
}

- (IBAction)changeSaveType: (id)sender
{ 
  NSDocumentController *controller = 
    [NSDocumentController sharedDocumentController];
  NSArray  *extensions = nil;

  ASSIGN(_save_type, [controller _nameForHumanReadableType: 
				  [sender titleOfSelectedItem]]);
  extensions = [controller fileExtensionsFromType: _save_type];
  if ([extensions count] > 0)
    {
      [(NSSavePanel *)[sender window] setRequiredFileType: [extensions objectAtIndex:0]];
    }
}

- (int)runModalSavePanel: (NSSavePanel *)savePanel 
       withAccessoryView: (NSView *)accessoryView
{
  [savePanel setAccessoryView: accessoryView];
  return [savePanel runModal];
}

- (void)runModalSavePanelForSaveOperation: (NSSaveOperationType)saveOperation 
				 delegate: (id)delegate
			  didSaveSelector: (SEL)didSaveSelector 
			      contextInfo: (void *)contextInfo
{
  NSString *fileName;

  // FIXME: Setting of the delegate of the save panel is missing
  fileName = [self fileNameFromRunningSavePanelForSaveOperation: saveOperation];
  [self saveToFile: fileName 
	saveOperation: saveOperation 
	delegate: delegate
	didSaveSelector: didSaveSelector 
	contextInfo: contextInfo];
}

- (BOOL)prepareSavePanel: (NSSavePanel *)savePanel
{
  return YES;
}

- (BOOL)shouldRunSavePanelWithAccessoryView
{
  return YES;
}

- (void) _createPanelAccessory
{
  if (_save_panel_accessory == nil)
    {
      NSRect accessoryFrame = NSMakeRect(0,0,380,70);
      NSRect spaFrame = NSMakeRect(115,14,150,22);

      _save_panel_accessory = [[NSBox alloc] initWithFrame: accessoryFrame];
      [(NSBox *)_save_panel_accessory setTitle: @"File Type"];
      [_save_panel_accessory setAutoresizingMask: 
			    NSViewWidthSizable | NSViewHeightSizable];
      _spa_button = [[NSPopUpButton alloc] initWithFrame: spaFrame];
      [_spa_button setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable | NSViewMinYMargin |
		 NSViewMaxYMargin | NSViewMinXMargin | NSViewMaxXMargin];
      [_spa_button setTarget: self];
      [_spa_button setAction: @selector(changeSaveType:)];
      [_save_panel_accessory addSubview: _spa_button];
    }
}
- (void) _addItemsToSpaButtonFromArray: (NSArray *)types
{
  NSEnumerator *en = [types objectEnumerator];
  NSString *title = nil;
  int i = 0;

  while ((title = [en nextObject]) != nil)
    {
      [_spa_button addItemWithTitle: title];
      i++;
    }

  // if it's more than one, then
  [_spa_button setEnabled: (i > 0)];
  
  // if we have some items, select the current filetype.
  if (i > 0)
    {
      NSString *title = [[NSDocumentController sharedDocumentController] 
			  displayNameForType: [self fileType]];
      if ([_spa_button itemWithTitle: title] != nil)
	{
	  [_spa_button selectItemWithTitle: title];
	}
      else
	{
	  [_spa_button selectItemAtIndex: 0];
	}
    }
}

- (NSString *)fileNameFromRunningSavePanelForSaveOperation: (NSSaveOperationType)saveOperation
{
  NSView *accessory = nil;
  NSString *title;
  NSString *directory;
  NSArray *displayNames;
  NSDocumentController *controller;
  NSSavePanel *savePanel = [NSSavePanel savePanel];

  controller = [NSDocumentController sharedDocumentController];
  displayNames = [controller _displayNamesForClass: [self class]];
  
  if ([self shouldRunSavePanelWithAccessoryView])
    {
      if (_save_panel_accessory == nil)
	[self _createPanelAccessory];
      
      [self _addItemsToSpaButtonFromArray: displayNames];
      
      accessory = _save_panel_accessory;
    }

  if ([displayNames count] > 0)
    {
      NSArray  *extensions = [[NSDocumentController sharedDocumentController] 
			       fileExtensionsFromType: [self fileTypeFromLastRunSavePanel]];
      if ([extensions count] > 0)
	{
	  [savePanel setRequiredFileType:[extensions objectAtIndex:0]];
	}
    }

  switch (saveOperation)
    {
    case NSSaveAsOperation: title = _(@"Save As"); break;
    case NSSaveToOperation: title = _(@"Save To"); break; 
    case NSSaveOperation: 
    default:
      title = _(@"Save");    
      break;
   }
  
  [savePanel setTitle: title];
  
  if ([self fileName])
    directory = [[self fileName] stringByDeletingLastPathComponent];
  else
    directory = [controller currentDirectory];
  [savePanel setDirectory: directory];
	
  if (![self prepareSavePanel: savePanel])
    {
      return nil;
    }

  if ([self runModalSavePanel: savePanel withAccessoryView: accessory])
    {
      return [savePanel filename];
    }
  
  return nil;
}

- (NSArray *)writableTypesForSaveOperation: (NSSaveOperationType)op
{
  NSArray *types = [isa writableTypes];
  NSMutableArray *muTypes;
  int i, len;

  if (op == NSSaveToOperation)
    {
      return types;
    }

  len = [types count];
  muTypes = [NSMutableArray arrayWithCapacity: len];
  for (i = 0; i < len; i++)
    {
      NSString *type;
	
      type = [types objectAtIndex: i];
      if ([[self class] isNativeType: type])
        {
	  [muTypes addObject: type];
	}
    }

  return muTypes;
}

- (BOOL)fileNameExtensionWasHiddenInLastRunSavePanel
{
  // FIXME
  return NO;
}

- (BOOL)shouldChangePrintInfo: (NSPrintInfo *)newPrintInfo
{
  return YES;
}

- (NSPrintInfo *)printInfo
{
  return _print_info? _print_info : [NSPrintInfo sharedPrintInfo];
}

- (void)setPrintInfo: (NSPrintInfo *)printInfo
{
  ASSIGN(_print_info, printInfo);
}


// Page layout panel (Page Setup)
- (BOOL)preparePageLayout:(NSPageLayout *)pageLayout
{
  return YES;
}

- (int)runModalPageLayoutWithPrintInfo: (NSPrintInfo *)printInfo
{
  NSPageLayout *pageLayout;

  pageLayout = [NSPageLayout pageLayout];
  if ([self preparePageLayout: pageLayout])
    {
      return [pageLayout runModalWithPrintInfo: printInfo];
    }
  else
    {
      return NSCancelButton;
    }
}

- (IBAction)runPageLayout: (id)sender
{
  NSPrintInfo *printInfo = [self printInfo];
  
  if ([self runModalPageLayoutWithPrintInfo: printInfo]
      && [self shouldChangePrintInfo: printInfo])
    {
      [self setPrintInfo: printInfo];
      [self updateChangeCount: NSChangeDone];
    }
}

- (void)runModalPageLayoutWithPrintInfo: (NSPrintInfo *)printInfo
                               delegate: (id)delegate
                         didRunSelector: (SEL)sel
                            contextInfo: (void *)context
{
  NSPageLayout *pageLayout;

  pageLayout = [NSPageLayout pageLayout];
  if ([self preparePageLayout: pageLayout])
    {
      NSWindow *win;

      win = [self windowForSheet];

      [pageLayout beginSheetWithPrintInfo: printInfo
		  modalForWindow: win
		  delegate: delegate
		  didEndSelector: sel
		  contextInfo: context];
    }
}

/* This is overridden by subclassers; the default implementation does nothing. */
- (void)printShowingPrintPanel: (BOOL)flag
{
}

- (IBAction)printDocument: (id)sender
{
  [self printShowingPrintPanel: YES];
}

- (void)printDocumentWithSettings: (NSDictionary *)settings
                   showPrintPanel: (BOOL)flag
                         delegate: (id)delegate
                 didPrintSelector: (SEL)sel
                      contextInfo: (void *)context
{
  NSPrintOperation *printOp;
  NSError *error;

  if (OVERRIDDEN(printShowingPrintPanel:))
    {
      // FIXME: More communication with the panel is needed.
      return [self printShowingPrintPanel: flag];
    }

  printOp = [self printOperationWithSettings: settings
		  error: &error];
  if (printOp != nil)
    {
      [printOp setShowsPrintPanel: flag];
      [self runModalPrintOperation: printOp
	    delegate: delegate
	    didRunSelector: sel
	    contextInfo: context];
    }
  else
    {
      [self presentError: error];

      if (delegate != nil && sel != NULL)
        {
	  void (*meth)(id, SEL, id, BOOL, void*);
	  meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector: sel];
	  if (meth)
	      meth(delegate, sel, self, NO, context);
	}
    }
}

- (NSPrintOperation *)printOperationWithSettings: (NSDictionary *)settings
                                           error: (NSError **)error
{
  return nil;
}

- (void)runModalPrintOperation: (NSPrintOperation *)op
                      delegate: (id)delegate
                didRunSelector: (SEL)sel
                   contextInfo: (void *)context
{
  [op runOperationModalForWindow: [self windowForSheet]
      delegate: delegate 
      didRunSelector: sel
      contextInfo: context];
}

- (BOOL)validateMenuItem: (NSMenuItem *)anItem
{
  BOOL result = YES;
  SEL  action = [anItem action];

  // FIXME should validate spa popup items; return YES if it's a native type.
  if (sel_eq(action, @selector(revertDocumentToSaved:)))
    {
      result = ([self fileName] != nil && [self isDocumentEdited]);
    }
  else if (sel_eq(action, @selector(undo:)))
    {
      if (_undo_manager == nil)
	{
	  result = NO;
	}
      else
	{
	  if ([_undo_manager canUndo])
	    {
	      [anItem setTitle: [_undo_manager undoMenuItemTitle]];
	      result = YES;
	    }
	  else
	    {
	      [anItem setTitle: [_undo_manager undoMenuTitleForUndoActionName: @""]];
	      result = NO;
	    }
	}
    }
  else if (sel_eq(action, @selector(redo:)))
    {
      if (_undo_manager == nil)
	{
	  result = NO;
	}
      else
	{
	  if ([_undo_manager canRedo])
	    {
	      [anItem setTitle: [_undo_manager redoMenuItemTitle]];
	      result = YES;
	    }
	  else
	    {
	      [anItem setTitle: [_undo_manager redoMenuTitleForUndoActionName: @""]];
	      result = NO;
	    }
	}
    }
    
  return result;
}

- (BOOL)validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)anItem
{
  if ([anItem action] == @selector(revertDocumentToSaved:))
    return ([self fileName] != nil);

  return YES;
}

- (NSString *)fileTypeFromLastRunSavePanel
{
  return _save_type;
}

- (NSDictionary *)fileAttributesToWriteToFile: (NSString *)fullDocumentPath 
				       ofType: (NSString *)docType 
				saveOperation: (NSSaveOperationType)saveOperationType
{
  // FIXME: Implement. Should set NSFileExtensionHidden
  return [NSDictionary dictionary];
}

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)url
                                      ofType:(NSString *)type
                            forSaveOperation:(NSSaveOperationType)op
                         originalContentsURL:(NSURL *)original
                                       error:(NSError **)error
{
  // FIXME: Implement. Should set NSFileExtensionHidden
  return [NSDictionary dictionary];
}

- (IBAction)saveDocument: (id)sender
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

- (IBAction)saveDocumentAs: (id)sender
{
  [self runModalSavePanelForSaveOperation: NSSaveAsOperation 
	delegate: nil
	didSaveSelector: NULL 
	contextInfo: NULL];
}

- (IBAction)saveDocumentTo: (id)sender
{
  [self runModalSavePanelForSaveOperation: NSSaveToOperation 
	delegate: nil
	didSaveSelector: NULL 
	contextInfo: NULL];
}

- (void)saveDocumentWithDelegate: (id)delegate 
		 didSaveSelector: (SEL)didSaveSelector 
		     contextInfo: (void *)contextInfo
{
  NSURL *fileURL = [self fileURL];
  NSString *type = [self fileType];

  if ((fileURL != nil) && (type != nil))
    {
      [self saveToURL: fileURL
	    ofType: type
	    forSaveOperation: NSSaveOperation
	    delegate: delegate
	    didSaveSelector: didSaveSelector 
	    contextInfo: contextInfo];
    }
  else
    {
      [self runModalSavePanelForSaveOperation: NSSaveOperation 
	    delegate: delegate
	    didSaveSelector: didSaveSelector 
	    contextInfo: contextInfo];
    }
}

- (void)saveToFile: (NSString *)fileName 
     saveOperation: (NSSaveOperationType)saveOperation 
	  delegate: (id)delegate
   didSaveSelector: (SEL)didSaveSelector 
       contextInfo: (void *)contextInfo
{
  BOOL saved = NO;
 
  if (fileName != nil)
  {
    saved = [self writeWithBackupToFile: fileName 
		  ofType: [self fileTypeFromLastRunSavePanel]
		  saveOperation: saveOperation];
  }

  if (delegate != nil && didSaveSelector != NULL)
    {
      void (*meth)(id, SEL, id, BOOL, void*);
      meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector: 
							       didSaveSelector];
      if (meth)
	meth(delegate, didSaveSelector, self, saved, contextInfo);
    }
}

- (BOOL)saveToURL: (NSURL *)url
           ofType: (NSString *)type
 forSaveOperation: (NSSaveOperationType)op
            error: (NSError **)error
{
  return [self writeSafelyToURL: url
	       ofType: type
	       forSaveOperation: op
	       error: error];
}

- (BOOL)saveToURL: (NSURL *)url
           ofType: (NSString *)type
 forSaveOperation: (NSSaveOperationType)op
         delegate: (id)delegate
  didSaveSelector: (SEL)didSaveSelector 
      contextInfo:(void *)contextInfo
{
  NSError *error;
  BOOL saved;

  saved = [self saveToURL: url
		ofType: type
		forSaveOperation: op
		error: &error];
  if (!saved)
    {
      [self presentError: error]; 
    }

  if (delegate != nil && didSaveSelector != NULL)
    {
      void (*meth)(id, SEL, id, BOOL, void*);
      meth = (void (*)(id, SEL, id, BOOL, void*))[delegate methodForSelector: 
							       didSaveSelector];
      if (meth)
	meth(delegate, didSaveSelector, self, saved, contextInfo);
    }

  return saved;
}

- (IBAction)revertDocumentToSaved: (id)sender
{
  int result;
  NSError *error;

  result = NSRunAlertPanel 
    (_(@"Revert"),
     _(@"%@ has been edited.  Are you sure you want to undo changes?"),
     _(@"Revert"), _(@"Cancel"), nil, 
     [self displayName]);
  
  if (result == NSAlertDefaultReturn)
  {
    if ([self revertToContentsOfURL: [self fileURL] 
	      ofType: [self fileType]
	      error: &error])
      {
	[self updateChangeCount: NSChangeCleared];
      }
    else
      {
	[self presentError: error];
      }
  }
}

/** Closes all the windows owned by the document, then removes itself
    from the list of documents known by the NSDocumentController. This
    method does not ask the user if they want to save the document before
    closing. It is closed without saving any information.
 */
- (void)close
{
  if (_doc_flags.in_close == NO)
    {
      int count = [_window_controllers count];
      /* Closing a windowController will also send us a close, so make
	 sure we don't go recursive */
      _doc_flags.in_close = YES;

      if (count > 0)
	{
	  NSWindowController *array[count];
	  [_window_controllers getObjects: array];
	  while (count-- > 0)
	    [array[count] close];
	}
      [[NSDocumentController sharedDocumentController] removeDocument: self];
    }
}

- (void)windowControllerWillLoadNib: (NSWindowController *)windowController {}
- (void)windowControllerDidLoadNib: (NSWindowController *)windowController  {}

- (NSUndoManager *)undoManager
{
  if (_undo_manager == nil && [self hasUndoManager])
    {
      [self setUndoManager: AUTORELEASE([[NSUndoManager alloc] init])];
    }
  
  return _undo_manager;
}

- (void)setUndoManager: (NSUndoManager *)undoManager
{
  if (undoManager != _undo_manager)
    {
      NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
      
      if (_undo_manager)
        {
	  [center removeObserver: self
		  name: NSUndoManagerWillCloseUndoGroupNotification
		  object:_undo_manager];
	  [center removeObserver: self
		  name: NSUndoManagerDidUndoChangeNotification
		  object:_undo_manager];
	  [center removeObserver: self
		  name: NSUndoManagerDidRedoChangeNotification
		  object:_undo_manager];
        }
      
      ASSIGN(_undo_manager, undoManager);
      
      if (_undo_manager == nil)
        {
	  [self setHasUndoManager: NO];
        }
      else
        {
	  [center addObserver: self
		  selector:@selector(_changeWasDone:)
		  name: NSUndoManagerWillCloseUndoGroupNotification
		  object:_undo_manager];
	  [center addObserver: self
		  selector:@selector(_changeWasUndone:)
		  name: NSUndoManagerDidUndoChangeNotification
		  object:_undo_manager];
	  [[NSNotificationCenter defaultCenter]
	    addObserver: self
	    selector:@selector(_changeWasRedone:)
	    name: NSUndoManagerDidRedoChangeNotification
	    object:_undo_manager];
        }
    }
}

- (BOOL)hasUndoManager
{
  return _doc_flags.has_undo_manager;
}

- (void)setHasUndoManager: (BOOL)flag
{
  if (_undo_manager && !flag)
    [self setUndoManager: nil];
  
  _doc_flags.has_undo_manager = flag;
}

- (BOOL)presentError: (NSError *)error
{
  error = [self willPresentError: error];
  return [[NSDocumentController sharedDocumentController] presentError: error];
}

- (void)presentError: (NSError *)error
      modalForWindow: (NSWindow *)window
            delegate: (id)delegate
  didPresentSelector: (SEL)sel
         contextInfo: (void *)context
{
  error = [self willPresentError: error];
  [[NSDocumentController sharedDocumentController] presentError: error
						   modalForWindow: window
						   delegate: delegate
						   didPresentSelector: sel
						   contextInfo: context];
}

- (NSError *)willPresentError:(NSError *)error
{
  return error;
}

- (NSURL *)autosavedContentsFileURL
{
  return _autosaved_file_url;
}

- (void)setAutosavedContentsFileURL: (NSURL *)url
{
  ASSIGN(_autosaved_file_url, url);
}

- (void)autosaveDocumentWithDelegate: (id)delegate
                 didAutosaveSelector: (SEL)didAutosaveSelector
                         contextInfo: (void *)context
{
  [self saveToURL: [self autosavedContentsFileURL]
	ofType: [self autosavingFileType]
	forSaveOperation: NSAutosaveOperation
	delegate: delegate
	didSaveSelector: didAutosaveSelector 
	contextInfo: context];
}

- (NSString *)autosavingFileType
{
  return [self fileType];
}

- (BOOL)hasUnautosavedChanges
{
  return _autosave_change_count != 0;
}

@end

@implementation NSDocument(Private)

/*
 * This private method is used to transfer window ownership to the
 * NSWindowController in situations (such as the default) where the
 * document is set to the nib owner, and thus owns the window immediately
 * following the loading of the nib.
 */
- (NSWindow *) _transferWindowOwnership
{
  NSWindow *window = _window;
  _window = nil;
  return AUTORELEASE(window);
}

- (void) _removeWindowController: (NSWindowController *)windowController
{
  if ([_window_controllers containsObject: windowController])
    {
      BOOL autoClose = [windowController shouldCloseDocument];
      
      [windowController setDocument: nil];
      [_window_controllers removeObject: windowController];
      
      if (autoClose || [_window_controllers count] == 0)
        {
	  [self close];
	}
    }
}

- (void) _changeWasDone: (NSNotification *)notification
{
  [self updateChangeCount: NSChangeDone];
}

- (void) _changeWasUndone: (NSNotification *)notification
{
  [self updateChangeCount: NSChangeUndone];
}

- (void) _changeWasRedone: (NSNotification *)notification
{
  [self updateChangeCount: NSChangeDone];
}

- (void) undo: (id)sender
{
  [[self undoManager] undo];
}

- (void) redo: (id)sender
{
  [[self undoManager] redo];
}

@end
