#import <AppKit/NSDocument.h>
#import <Foundation/NSData.h>
#import <AppKit/NSFileWrapper.h>
#import <AppKit/NSSavePanel.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPageLayout.h>
#import <AppKit/NSView.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSDocumentFrameworkPrivate.h>


@implementation NSDocument

+ (void)initialize
{
}

+ (NSArray *)readableTypes
{
	return [[NSDocumentController sharedDocumentController]
				_editorAndViewerTypesForClass:self];
}

+ (NSArray *)writableTypes
{
	return [[NSDocumentController sharedDocumentController] _editorTypesForClass:self];
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
	return self;
}

- (id)initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)fileType
{
	[super init];
	
	if ([self readFromFile:fileName ofType:fileType])
	{
		[self setFileType:fileType];
		[self setFileName:fileName];
	}
	else
	{
		[self release];
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
		[self release];
		return nil;
	}
	
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[(NSObject*)_undoManager release];
	[_fileName release];
	[_fileType release];
	[_windowControllers release];
	[_window release];
	[_printInfo release];
	[savePanelAccessory release];
	[spaButton release];
	[super dealloc];
}

- (NSString *)fileName
{
	return _fileName;
}

- (void)setFileName:(NSString *)fileName
{
    [fileName retain];
    [_fileName release];
    _fileName = fileName;
	
	[_windowControllers makeObjectsPerformSelector:
		@selector(_synchronizeWindowTitleWithDocumentName)];
}

- (NSString *)fileType
{
	return _fileType;
}

- (void)setFileType:(NSString *)type
{
	[type retain];
	[_fileType release];
	_fileType = type;
}

- (NSArray *)windowControllers
{
	return _windowControllers;
}

- (void)addWindowController:(NSWindowController *)windowController
{
	if (_windowControllers == nil) _windowControllers = [[NSMutableArray alloc] init];

	[_windowControllers addObject:windowController];
	if ([windowController document] != self)
		[windowController setDocument:self];
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

- (NSString *)windowNibName
{
	return nil;
}

// private; called during nib load.  // we do not retain the window, since it should
// already have a retain from the nib.
- (void)setWindow:(NSWindow *)window
{
	_window = window;
}

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
	return [window autorelease];
}

- (void)makeWindowControllers
{
	NSString *name = [self windowNibName];

    if ([name length] > 0)
	{
		NSWindowController *controller;
		controller = [[NSWindowController alloc] initWithWindowNibName:name owner:self];
		[self addWindowController:controller];
		[controller release];
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
        [[[_windowControllers objectAtIndex:i] window] setDocumentEdited:isEdited];
	}
}

- (BOOL)canCloseDocument
{
	int result;

	if (![self isDocumentEdited]) return YES;

    //FIXME -- localize.
	result = NSRunAlertPanel(@"Close", @"%@ has changed.  Save?",
				@"Save", @"Cancel", @"Don't Save", [self displayName]);

#define Save     NSAlertDefaultReturn
#define Cancel   NSAlertAlternateReturn
#define DontSave NSAlertOtherReturn

	switch (result)
	{
		// return NO if save failed
		case Save:		[self saveDocument:nil]; return ![self isDocumentEdited];
		case DontSave:	return YES;
		case Cancel:
		default:		return NO;
	}
}

- (BOOL)shouldCloseWindowController:(NSWindowController *)windowController
{
	if (![_windowControllers containsObject:windowController]) return YES;

	/* If it's the last window controller, pop up a warning */
    /* maybe we should count only loaded window controllers (or visible windows). */
	if ([windowController shouldCloseDocument] || [_windowControllers count] == 1)
	{
		return [self canCloseDocument];
	}
	
	return YES;
}


- (NSString *)displayName
{
	if ([self fileName] != nil)
	{
		return [[[self fileName] lastPathComponent] stringByDeletingPathExtension];
	}
	else
	{
        //FIXME -- localize.
		return [NSString stringWithFormat:@"Untitled-%d", _documentIndex];
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
	
	if (data == nil) return nil;
	
	return [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
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
	NSFileWrapper *wrapper = [[[NSFileWrapper alloc] initWithPath:fileName] autorelease];
	return [self loadFileWrapperRepresentation:wrapper ofType:type];
}

- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type
{
	return [self readFromFile:fileName ofType:type];
}

- (IBAction)changeSaveType:(id)sender
{ //FIXME if we have accessory -- store the desired save type somewhere.
}

- (int)runModalSavePanel:(NSSavePanel *)savePanel withAccessoryView:(NSView *)accessoryView
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
	NSString *title = @"save";
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSArray *extensions = [[NSDocumentController sharedDocumentController]
											fileExtensionsFromType:[self fileType]];
	
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
        // FIXME -- localize.
		case NSSaveOperation:	title = @"Save"; break;
		case NSSaveAsOperation:	title = @"Save As"; break;
		case NSSaveToOperation: title = @"Save To"; break;
	}

	[savePanel setTitle:title];
	if ([self fileName])
        [savePanel setDirectory:[[self fileName] stringByDeletingLastPathComponent]];
	
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
	[printInfo retain];
	[_printInfo release];
	_printInfo = printInfo;
}


    // Page layout panel (Page Setup)

- (int)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo
{
	return [[NSPageLayout pageLayout] runModalWithPrintInfo:printInfo];
}

- (IBAction)runPageLayout:(id)sender
{
	NSPrintInfo *printInfo = [self printInfo];

	if ([self runModalPageLayoutWithPrintInfo:printInfo] &&
		[self shouldChangePrintInfo:printInfo])
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

- (NSString *)saveFileType
{
	// FIXME this should return type picked on save accessory
	// return [spaPopupButton title];
	return [self fileType];
}

- (void)_doSaveAs:(NSSaveOperationType)saveOperation
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filename = [self fileName];
	NSString *backupFilename = nil;

	if (filename == nil || saveOperation != NSSaveOperation)
	{
		filename = [self fileNameFromRunningSavePanelForSaveOperation:saveOperation];
		if (saveOperation == NSSaveOperation) saveOperation = NSSaveAsOperation;
	}
	
	if (filename)
	{
		if ([fileManager fileExistsAtPath:filename])
		{
			NSString *extension  = [filename pathExtension];

			backupFilename = [filename stringByDeletingPathExtension];
			backupFilename = [backupFilename stringByAppendingString:@"~"];
			backupFilename = [backupFilename stringByAppendingPathExtension:extension];

			/* Save panel has already asked if the user wants to replace it */

			/* NSFileManager movePath: will fail if destination exists */
			if ([fileManager fileExistsAtPath:backupFilename])
				[fileManager removeFileAtPath:backupFilename handler:nil];

			// Move or copy?
			if (![fileManager movePath:filename toPath:backupFilename handler:nil] &&
				[self keepBackupFile])
            {
                //FIXME -- localize.
                int result = NSRunAlertPanel(@"File Error",
								@"Can't create backup file.  Save anyways?",
								@"Save", @"Cancel", nil);

				if (result != NSAlertDefaultReturn) return;
            }
		}
		if ([self writeToFile:filename ofType:[self saveFileType]])
		{
			if (saveOperation != NSSaveToOperation)
			{
				[self setFileName:filename];
				[self setFileType:[self saveFileType]];
				[self updateChangeCount:NSChangeCleared];
			}

			if (backupFilename && ![self keepBackupFile])
			{
				[fileManager removeFileAtPath:backupFilename handler:nil];
			}
		}
	}
}

- (IBAction)saveDocument:(id)sender
{
	[self _doSaveAs:NSSaveOperation];
}

- (IBAction)saveDocumentAs:(id)sender
{
	[self _doSaveAs:NSSaveAsOperation];
}

- (IBAction)saveDocumentTo:(id)sender
{
	[self _doSaveAs:NSSaveToOperation];
}

- (IBAction)revertDocumentToSaved:(id)sender
{
	int result;

    //FIXME -- localize.
	result = NSRunAlertPanel(@"Revert",
				@"%@ has been edited.  Are you sure you want to undo changes?",
				@"Revert", @"Cancel", nil, [self displayName]);
	
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
	[[NSDocumentController sharedDocumentController] _removeDocument:self];
}

- (void)windowControllerWillLoadNib:(NSWindowController *)windowController {}
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController  {}

- (NSUndoManager *)undoManager
{
	if (_undoManager == nil && [self hasUndoManager])
	{
		[self setUndoManager:[[[NSUndoManager alloc] init] autorelease]];
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

        [(NSObject*)undoManager retain];
		[(NSObject*)_undoManager release];
		_undoManager = undoManager;
	
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

- (void)_changeWasDone:(NSNotification *)notification
{	[self updateChangeCount:NSChangeDone];
}
- (void)_changeWasUndone:(NSNotification *)notification
{	[self updateChangeCount:NSChangeUndone];
}
- (void)_changeWasRedone:(NSNotification *)notification
{	[self updateChangeCount:NSChangeDone];
}

@end

