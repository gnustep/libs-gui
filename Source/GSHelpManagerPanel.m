#import <AppKit/AppKit.h>
#import <AppKit/GSHelpManagerPanel.h>

@implementation GSHelpManagerPanel
{
  id textView;
}

static GSHelpManagerPanel* _GSsharedGSHelpPanel;

+ (id) sharedHelpManagerPanel
{
  if(!_GSsharedGSHelpPanel)
    _GSsharedGSHelpPanel = [[GSHelpManagerPanel alloc] init];
  return _GSsharedGSHelpPanel;
}

/* This window should not be destroyed... So we don't allow it to! */
- (id) retain
{
  return self;
}

- (void) release
{
}

- (id) autorelease
{
  return self;
}

- (id) init
{
  NSScrollView	*scrollView;
  NSRect	scrollViewRect = {{0, 0}, {470, 150}};
  NSRect	winRect = {{100, 100}, {470, 150}};
  NSColor	*backColor;
  unsigned int	style = NSTitledWindowMask | NSClosableWindowMask
    | NSMiniaturizableWindowMask | NSResizableWindowMask;
  
  [self initWithContentRect: winRect
		  styleMask: style
		    backing: NSBackingStoreRetained
		      defer: NO];
  [self setRepresentedFilename: @"Help"];
  [self setDocumentEdited: NO];
  
  scrollView = [[NSScrollView alloc] initWithFrame: scrollViewRect];
  [scrollView setHasHorizontalScroller: NO];
  [scrollView setHasVerticalScroller: YES]; 
  [scrollView setAutoresizingMask: NSViewHeightSizable];
  
  textView = [NSText new];
  [textView setEditable: NO];
  [textView setRichText: YES];
  [textView setSelectable: YES];
  [textView setFrame: [[scrollView contentView] frame]];
  backColor = [NSColor colorWithCalibratedWhite: 0.85 alpha: 1.0]; // off white
  [textView setBackgroundColor: backColor];					
  [scrollView setDocumentView: textView];
  [[self contentView] addSubview: scrollView];
  
  [self setTitle: @"Help"];
  
  return self;
}

- (void) setHelpText: (NSAttributedString*) helpText
{
  [textView setText: [helpText string]];
}

- (BOOL) isFloatingPanel
{
  return YES;
}

- (void) close
{
  [NSApp stopModal];
  [super close];
}
@end
