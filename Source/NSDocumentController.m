

#import <AppKit/NSDocumentController.h>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSWorkspace.h>
#import <AppKit/NSDocumentFrameworkPrivate.h>


static NSString *NSTypesKey             = @"NSTypes";
static NSString *NSNameKey              = @"NSName";
static NSString *NSRoleKey              = @"NSRole";
static NSString *NSHumanReadableNameKey = @"NSHumanReadableName";
static NSString *NSUnixExtensionsKey    = @"NSUnixExtensions";
static NSString *NSDOSExtensionsKey     = @"NSDOSExtensions";
static NSString *NSMacOSTypesKey        = @"NSMacOSTypes";
static NSString *NSMIMETypesKey         = @"NSMIMETypes";
static NSString *NSDocumentClassKey     = @"NSDocumentClass";

#define TYPE_INFO(name) TypeInfoForName(_types, name)

static NSDictionary *TypeInfoForName(NSArray *types, NSString *typeName)
{
	int i, count = [types count];
	for (i=0; i<count;i++)
	{
		NSDictionary *dict = [types objectAtIndex:i];
		if ([[dict objectForKey:NSNameKey] isEqualToString:typeName])
			return dict;
	}
	
	return nil;
}

@implementation NSDocumentController

+ (void)initialize
{
}

+ (id)documentController //private
{
	return [self sharedDocumentController];
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedDocumentController];
}
+ (id)sharedDocumentController
{
	static id instance = nil;

	if (instance == nil) instance = [[super allocWithZone:NULL] init];
	return instance;
}

- init
{
    NSDictionary *customDict = [[NSBundle mainBundle] infoDictionary];
	
	_types = [[customDict objectForKey:NSTypesKey] retain];
	_documents = [[NSMutableArray alloc] init];
	[self setShouldCreateUI:YES];

	[[[NSWorkspace sharedWorkspace] notificationCenter]
		addObserver:self
		selector:@selector(_workspaceWillPowerOff:)
		name:NSWorkspaceWillPowerOffNotification
		object:nil];

	return self;
}

- (void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[_documents release];
	[_types release];
	[super dealloc];
}

- (BOOL)shouldCreateUI
{
	return _controllerFlags.shouldCreateUI;
}

- (void)setShouldCreateUI:(BOOL)flag
{
	_controllerFlags.shouldCreateUI = flag;
}

- (id)makeUntitledDocumentOfType:(NSString *)type
{
	Class documentClass = [self documentClassForType:type];
	return [[[documentClass alloc] init] autorelease];
}

- (id)makeDocumentWithContentsOfFile:(NSString *)fileName ofType:(NSString *)type
{
	Class documentClass = [self documentClassForType:type];
	return [[[documentClass alloc] initWithContentsOfFile:fileName ofType:type] autorelease];
}

- (id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)type
{
	Class documentClass = [self documentClassForType:type];
	return [[[documentClass alloc] initWithContentsOfURL:url ofType:type] autorelease];
}

- _defaultType
{
    if ([_types count] == 0) return nil; // raise exception?
	return [[_types objectAtIndex:0] objectForKey:NSNameKey];
}

/* These next two should really have been public. */
- (void)_addDocument:(NSDocument *)document
{
	[_documents addObject:document];
}

- (void)_removeDocument:(NSDocument *)document
{
	[_documents removeObject:document];
}

- (id)openUntitledDocumentOfType:(NSString*)type display:(BOOL)display
{
	NSDocument *document = [self makeUntitledDocumentOfType:type];
	
	if (document == nil) return nil;

    [self _addDocument:document];
    if ([self shouldCreateUI])
    {
        [document makeWindowControllers];
        if (display)
            [document showWindows];
    }

	return document;
}

- (id)openDocumentWithContentsOfFile:(NSString *)fileName display:(BOOL)display
{
	NSDocument *document = [self documentForFileName:fileName];

	if (document == nil)
    {
		NSString *type = [self typeFromFileExtension:[fileName pathExtension]];

		if ((document = [self makeDocumentWithContentsOfFile:fileName ofType:type]))
			[self _addDocument:document];
        if ([self shouldCreateUI])
			[document makeWindowControllers];
    }
	
	if (display && [self shouldCreateUI])
    {
		[document showWindows];
    }

	return document;
}

- (id)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)display
{
    // Should we only do this if [url isFileURL] is YES?
    NSDocument *document = [self documentForFileName:[url path]];

    if (document == nil)
    {
        NSString *type = [self typeFromFileExtension:[[url path] pathExtension]];
	
        document = [self makeDocumentWithContentsOfURL:url ofType:type];
		if (document == nil) return nil;

        [self _addDocument:document];
        if ([self shouldCreateUI])
        {
            [document makeWindowControllers];
        }
    }

    if (display && [self shouldCreateUI])
    {
        [document showWindows];
    }

	return document;
}

- _setupOpenPanel
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setDirectory:[self currentDirectory]];
	[openPanel setAllowsMultipleSelection:YES];
	return openPanel;
}

- (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)openableFileExtensions
{
	return [openPanel runModalForTypes:openableFileExtensions];
}

- (NSArray *)_openableFileExtensions
{
	int i, count = [_types count];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];

	for (i=0; i<count; i++)
	{
		NSDictionary *typeInfo = [_types objectAtIndex:i];
		[array addObjectsFromArray:[typeInfo objectForKey:NSUnixExtensionsKey]];
		[array addObjectsFromArray:[typeInfo objectForKey:NSDOSExtensionsKey]];
	}
	
	return array;
}

- (NSArray *)fileNamesFromRunningOpenPanel
{
	NSArray *types = [self _openableFileExtensions];
	NSOpenPanel *openPanel = [self _setupOpenPanel];
	
	if ([self runModalOpenPanel:openPanel forTypes:types])
	{
		return [openPanel filenames];
	}
	
	return nil;
}

- (NSArray *)URLsFromRunningOpenPanel
{
    NSArray *types = [self _openableFileExtensions];
    NSOpenPanel *openPanel = [self _setupOpenPanel];

    if ([self runModalOpenPanel:openPanel forTypes:types])
    {
        return [openPanel URLs];
    }

    return nil;
}


- (IBAction)saveAllDocuments:(id)sender
{
	NSDocument *document;
	NSEnumerator *docEnum = [_documents objectEnumerator];
	
	while ((document = [docEnum nextObject]))
	{
		if ([document isDocumentEdited])  //maybe we should save regardless...
		{
			[document saveDocument:sender];
		}
	}
}


- (IBAction)openDocument:(id)sender
{
	NSEnumerator *fileEnum = [[self fileNamesFromRunningOpenPanel] objectEnumerator];
	NSString *filename;
	
	while ((filename = [fileEnum nextObject]))
	{
		[self openDocumentWithContentsOfFile:filename display:YES];
	}
}
	
- (IBAction)newDocument:(id)sender
{
	[self openUntitledDocumentOfType:[self _defaultType] display:YES];
}


- (BOOL)closeAllDocuments
{
	NSDocument *document;
	NSEnumerator *docEnum = [_documents objectEnumerator];

	while ((document = [docEnum nextObject]))
	{
		if (![document canCloseDocument]) return NO;
		[document close];
		[self _removeDocument:document];
	}
	
	return YES;
}

- (BOOL)reviewUnsavedDocumentsWithAlertTitle:(NSString *)title cancellable:(BOOL)cancellable
{
    //FIXME -- localize.
	NSString *cancelString = (cancellable)? @"Cancel" : nil;
	int      result;

	if (![self hasEditedDocuments]) return YES;
	
	result = NSRunAlertPanel(title, @"You have unsaved documents.",
				@"Review Unsaved", cancelString, @"Quit Anyways");

#define ReviewUnsaved NSAlertDefaultReturn
#define Cancel        NSAlertAlternateReturn
#define QuitAnyways   NSAlertOtherReturn

	switch (result)
	{
		case ReviewUnsaved:	return [self closeAllDocuments];
		case QuitAnyways:	return YES;
		case Cancel:
		default:			return NO;
	}
}

#ifdef OPENSTEP_ONLY
/*
 * App delegate methods.  Apple doesn't have these, but they put code
 * into NSApplication to call the corresponding NSDocumentController
 * methods if the app delegate didn't implement a given delegate method.
 */
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    return [self openDocumentWithContentsOfFile:filename display:YES] ? YES : NO;
}

- (BOOL)application:(NSApplication *)sender openTempFile:(NSString *)filename;
{
    return [self openDocumentWithContentsOfFile:filename display:YES] ? YES : NO;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender
{
    return [self openUntitledDocumentOfType:[self _defaultType] display:YES] ? YES : NO;
}

- (BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename
{
    return [self openDocumentWithContentsOfFile:filename display:NO] ? YES : NO;
}

- (BOOL)applicationShouldTerminate:(NSApplication *)sender
{
    return [self reviewUnsavedDocumentsWithAlertTitle:@"Quit" cancellable:YES];
}
#endif

- (void)_workspaceWillPowerOff:(NSNotification *)notification
{
    // FIXME -- localize.
    [self reviewUnsavedDocumentsWithAlertTitle:@"Power" cancellable:NO];
}


- (NSArray *)documents
{
	return _documents;
}

- (BOOL)hasEditedDocuments;
{
	int i, count = [_documents count];
	
	for (i=0; i<count; i++)
	{
		if ([[_documents objectAtIndex:i] isDocumentEdited]) return YES;
	}
	
	return NO;
}

- (id)currentDocument
{
	return [self documentForWindow:[[NSApplication sharedApplication] mainWindow]];
}

- (NSString *)currentDirectory
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSDocument *currentDocument = [self currentDocument];
	NSString *directory = [[currentDocument fileName] stringByDeletingLastPathComponent];
	BOOL isDir = NO;

	if (directory &&
		[manager fileExistsAtPath:directory isDirectory:&isDir] && isDir) return directory;
	//FIXME -- need to remember last saved directory, and return that here.
    //Only return NSHomeDirectory if nothing's been saved yet.
	return NSHomeDirectory();
}

- (id)documentForWindow:(NSWindow *)window
{
	id document;

	if (window == nil) return nil;
	if (![[window windowController] isKindOfClass:[NSWindowController class]]) return nil;
	
    document = [[window windowController] document];
	if (![document isKindOfClass:[NSDocument class]]) return nil;
	return document;
}

- (id)documentForFileName:(NSString *)fileName
{
	int i, count = [_documents count];
	
	for (i=0; i<count; i++)
	{
		NSDocument *document = [_documents objectAtIndex:i];

		if ([[document fileName] isEqualToString:fileName])
			return document;
	}
	
	return nil;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([anItem action] == @selector(saveAllDocuments:))
		return [self hasEditedDocuments];
	return YES;
}

- (NSString *)displayNameForType:(NSString *)type
{
	NSString *name = [TYPE_INFO(type) objectForKey:NSHumanReadableNameKey];

	return name? name : type;
}

- (NSString *)typeFromFileExtension:(NSString *)fileExtension
{
	int i, count = [_types count];
	
	for (i=0; i<count;i++)
	{
		NSDictionary *typeInfo = [_types objectAtIndex:i];
		
		if ([[typeInfo objectForKey:NSUnixExtensionsKey] containsObject:fileExtension] ||
		    [[typeInfo objectForKey:NSDOSExtensionsKey]  containsObject:fileExtension])
		{
			return [typeInfo objectForKey:NSNameKey];
		}
	}
	
	return nil;
}

- (NSArray *)fileExtensionsFromType:(NSString *)type
{
	NSDictionary *typeInfo = TYPE_INFO(type);
	NSArray *unixExtensions = [typeInfo objectForKey:NSUnixExtensionsKey];
	NSArray *dosExtensions  = [typeInfo objectForKey:NSDOSExtensionsKey];
	
	if (!dosExtensions)  return unixExtensions;
	if (!unixExtensions) return dosExtensions;
	return [unixExtensions arrayByAddingObjectsFromArray:dosExtensions];
}

- (Class)documentClassForType:(NSString *)type
{
	NSString *className = [TYPE_INFO(type) objectForKey:NSDocumentClassKey];
	
	return className? NSClassFromString(className) : Nil;
}

static NSString *NSEditorRole = @"Editor";
static NSString *NSViewerRole = @"Viewer";
static NSString *NSNoRole     = @"None";

- (NSArray *)_editorAndViewerTypesForClass:(Class)documentClass
{
	int i, count = [_types count];
	NSMutableArray *types = [NSMutableArray arrayWithCapacity:count];
	NSString *docClassName = NSStringFromClass(documentClass);
	
	for (i=0; i<count; i++)
	{
		NSDictionary *typeInfo = [_types objectAtIndex:i];
		NSString     *className = [typeInfo objectForKey:NSDocumentClassKey];
		NSString     *role      = [typeInfo objectForKey:NSRoleKey];
		
		if ([docClassName isEqualToString:className] &&
			(role == nil || [role isEqual:NSEditorRole] || [role isEqual:NSViewerRole]))
		{
			[types addObject:[typeInfo objectForKey:NSNameKey]];
		}
	}
	
	return types;
}

- (NSArray *)_editorTypesForClass:(Class)documentClass
{
	int i, count = [_types count];
	NSMutableArray *types = [NSMutableArray arrayWithCapacity:count];
	NSString *docClassName = NSStringFromClass(documentClass);
	
	for (i=0; i<count; i++)
	{
		NSDictionary *typeInfo = [_types objectAtIndex:i];
		NSString     *className = [typeInfo objectForKey:NSDocumentClassKey];
		NSString     *role      = [typeInfo objectForKey:NSRoleKey];
		
		if ([docClassName isEqualToString:className] &&
			(role == nil || [role isEqual:NSEditorRole]))
		{
			[types addObject:[typeInfo objectForKey:NSNameKey]];
		}
	}
	
	return types;
}

- (NSArray *)_exportableTypesForClass:(Class)documentClass
{
	// Dunno what this method is for; maybe looks for filter types
	return [self _editorTypesForClass:documentClass];
}

@end

