#import <AppKit/NSWindowController.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSDocumentFrameworkPrivate.h>

@implementation NSWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	return [self initWithWindowNibName:windowNibName owner:self];
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner
{
	[self initWithWindow:nil];
	_windowNibName = [windowNibName retain];
	_owner = owner;
	return self;
}

- (id)initWithWindow:(NSWindow *)window
{
	[super init];

	_window = [window retain];
	_windowFrameAutosaveName = @"";
	_wcFlags.shouldCascade = YES;
	_wcFlags.shouldCloseDocument = NO;

	if (_window)
	{
		[self _windowDidLoad];
	}

	return self;
}

- (id)init
{
	return [self initWithWindowNibName:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_windowNibName release];
	[_windowFrameAutosaveName release];
	[_topLevelObjects release];
	[_window autorelease];
	[super dealloc];
}

- (NSString *)windowNibName
{
	return _windowNibName;
}

- (id)owner
{
	return _owner;
}

- (void)setDocument:(NSDocument *)document
{
	_document = document;
	[self _synchronizeWindowTitleWithDocumentName];
}

- (id)document
{
	return _document;
}

- (void)setWindowFrameAutosaveName:(NSString *)name
{
	[name retain];
	[_windowFrameAutosaveName release];
	_windowFrameAutosaveName = name;
	
	if ([self isWindowLoaded])
	{
		[[self window] setFrameAutosaveName:name? name : @""];
	}
}

- (NSString *)windowFrameAutosaveName;
{
	return _windowFrameAutosaveName;
}

- (void)setShouldCloseDocument:(BOOL)flag
{
	_wcFlags.shouldCloseDocument = flag;
}

- (BOOL)shouldCloseDocument
{
	return _wcFlags.shouldCloseDocument;
}

- (void)setShouldCascadeWindows:(BOOL)flag
{
	_wcFlags.shouldCascade = flag;
}

- (BOOL)shouldCascadeWindows
{
	return _wcFlags.shouldCascade;
}

- (void)close
{
	[_window close];
}


- (void)_windowWillClose:(NSNotification *)notification
{
	if ([notification object] == _window)
    {
        if ([_window delegate] == self) [_window setDelegate:nil];
        if ([_window windowController] == self) [_window setWindowController:nil];

        /*
         * If the window is set to isReleasedWhenClosed, it will release
         * itself, so nil out our reference so we don't release it again.
         * We may want to unilaterally turn off the setting in the NSWindow
         * instance so it doesn't cause problems.
         * 
         * Apple's implementation doesn't seem to deal with this case, and
         * crashes if isReleaseWhenClosed is set.
         */
		if ([_window isReleasedWhenClosed])
        {
            _window = nil;
        }

        [_document _removeWindowController:self];
    }
}

- (NSWindow *)window
{
	if (_window == nil && ![self isWindowLoaded])
	{
		// Do all the notifications.  Yes, the docs say this should
		// be implemented here instead of in -loadWindow itself.
		[self windowWillLoad];
		if ([_document respondsToSelector:@selector(windowControllerWillLoadNib:)])
			[_document windowControllerWillLoadNib:self];

		[self loadWindow];
		
		[self _windowDidLoad];
		if ([_document respondsToSelector:@selector(windowControllerDidLoadNib:)])
			[_document windowControllerDidLoadNib:self];
	}

	return _window;
}

// Private method; the nib loading will call this.
- (void)setWindow:(NSWindow *)aWindow
{
	[_window autorelease];
    _window = [aWindow retain];
}

- (IBAction)showWindow:(id)sender
{
	NSWindow *window = [self window];

	if ([window isKindOfClass:[NSPanel class]] && [(NSPanel*)window becomesKeyOnlyIfNeeded])
		[window orderFront:sender];
	else
		[window makeKeyAndOrderFront:sender];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return displayName;
}

- (void)_synchronizeWindowTitleWithDocumentName
{
	if (_document)
    {
		NSString *filename = [_document fileName];
		NSString *displayName = [_document displayName];
		NSString *title = [self windowTitleForDocumentDisplayName:displayName];

		/* If they just want to display the filename, use the fancy method */
        if (filename != nil && [title isEqualToString:filename])
        {
			[_window setTitleWithRepresentedFilename:filename];
		}
		else
		{
            if (filename) [_window setRepresentedFilename:filename];
			[_window setTitle:title];
		}
	}
}

- (BOOL)isWindowLoaded
{
	return _wcFlags.nibIsLoaded;
}

- (void)windowDidLoad
{
}

- (void)windowWillLoad
{
}

- (void)_windowDidLoad
{
	_wcFlags.nibIsLoaded = YES;

	[_window setWindowController:self];

	[self _synchronizeWindowTitleWithDocumentName];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(_windowWillClose:)
		name:NSWindowWillCloseNotification
		object:_window];

	/* Make sure window sizes itself right */
	if ([_windowFrameAutosaveName length] > 0)
    {
		[_window setFrameUsingName:_windowFrameAutosaveName];
		[_window setFrameAutosaveName:_windowFrameAutosaveName];
    }

	if ([self shouldCascadeWindows])
    {
        static NSPoint nextWindowLocation  = { 0.0, 0.0 };
        static BOOL firstWindow = YES;

        if (firstWindow)
        {
            NSRect windowFrame = [_window frame];

            /* Start with the frame as set */
            nextWindowLocation = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
            firstWindow = NO;
        }
        else
        {
            /*
             * cascadeTopLeftFromPoint will "wrap" the point back to the
             * top left if the normal cascading will cause the window to go
             * off the screen. In Apple's implementation, this wraps to the
             * extreme top of the screen, and offset only a small amount
             * from the left.
             */
            nextWindowLocation = [_window cascadeTopLeftFromPoint:nextWindowLocation];
        }
    }

	[self windowDidLoad];
}

- (void)loadWindow
{
	if ([self isWindowLoaded]) return;

	if ([NSBundle loadNibNamed:_windowNibName owner:_owner])
	{
        _wcFlags.nibIsLoaded = YES;

        if (_window == nil && _document && _owner == _document)
			[self setWindow:[_document _transferWindowOwnership]];
	}
	else
    {
		NSLog(@"%@: could not load nib named %@.nib", [self class], _windowNibName);
    }
}

/*
 * There's no way I'll ever get these compatible if Apple's versions
 * actually encode anything, sigh
 */
- initWithCoder:(NSCoder *)coder
{
	return [self init];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    // What are we supposed to encode?  Window nib name?  Or should these
    // be empty, just to conform to NSCoding, so we do an -init on
    // unarchival.  ?
}

@end

