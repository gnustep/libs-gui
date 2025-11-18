/** <title>TouchBarExample</title>

    <abstract>Example application demonstrating NSTouchBar with NSScrubber fallback</abstract>

    This example shows how to create a touch bar with an NSScrubber control
    and display it in a fallback window on systems without touch bar hardware.

    Copyright (C) 2025 Free Software Foundation, Inc.

    By: GNUstep Contributors
    Date: Sep 30 2025
*/

#import <AppKit/AppKit.h>

@interface TouchBarExampleDelegate : NSObject
{
    NSWindow *_mainWindow;
    NSTouchBar *_touchBar;
    NSArray *_scrubberItems;
}

@end

@implementation TouchBarExampleDelegate

- (id) init
{
    self = [super init];
    if (self)
    {
        ASSIGN(_scrubberItems, [NSArray arrayWithObjects: 
                          @"Item 1", @"Item 2", @"Item 3", @"Item 4", @"Item 5",
                          @"Item 6", @"Item 7", @"Item 8", @"Item 9", @"Item 10", 
                          nil]);
    }
    return self;
}

- (void) dealloc
{
    RELEASE(_scrubberItems);
    RELEASE(_touchBar);
    RELEASE(_mainWindow);
    [super dealloc];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notification
{
    // Create main window
    NSRect frame = NSMakeRect(100, 100, 400, 300);
    _mainWindow = [[NSWindow alloc] 
                   initWithContentRect: frame
                             styleMask: NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | 
                                       NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                               backing: NSBackingStoreBuffered
                                 defer: NO];
    
    [_mainWindow setTitle: @"Touch Bar Example"];
    [_mainWindow makeKeyAndOrderFront: nil];
    
    // Create touch bar
    [self _createTouchBar];
    
    // Show fallback window (since we don't have hardware touch bar)
    [_touchBar showFallbackWindow];
}

- (void) _createTouchBar
{
    _touchBar = [[NSTouchBar alloc] init];
    [_touchBar setDelegate: self];
    [_touchBar setCustomizationIdentifier: @"com.example.touchbar"];
    [_touchBar setDefaultItemIdentifiers: [NSArray arrayWithObjects: 
                                          @"scrubber.example", 
                                          NSTouchBarItemIdentifierFlexibleSpace,
                                          @"button.example", nil]];
    [_touchBar setItemIdentifiers: [_touchBar defaultItemIdentifiers]];
}

/*
 * NSTouchBar delegate methods
 */

- (NSTouchBarItem *) touchBar: (NSTouchBar *)touchBar makeItemForIdentifier: (NSString *)identifier
{
    if ([identifier isEqualToString: @"scrubber.example"])
    {
        NSScrubberTouchBarItem *scrubberItem = 
            [[NSScrubberTouchBarItem alloc] initWithIdentifier: identifier];
        
        NSScrubber *scrubber = [scrubberItem scrubber];
        [scrubber setDataSource: self];
        [scrubber setDelegate: self];
        
        // Configure scrubber appearance
        [scrubber setItemAlignment: NSScrubberAlignmentCenter];
        [scrubber setShowsArrowButtons: YES];
        
        [scrubberItem setCustomizationLabel: @"Example Scrubber"];
        return AUTORELEASE(scrubberItem);
    }
    else if ([identifier isEqualToString: @"button.example"])
    {
        NSTouchBarItem *buttonItem = [[NSTouchBarItem alloc] initWithIdentifier: identifier];
        
        NSButton *button = [[NSButton alloc] init];
        [button setTitle: @"Example"];
        [button setTarget: self];
        [button setAction: @selector(buttonPressed:)];
        [button sizeToFit];
        
        [buttonItem setView: button];
        [buttonItem setCustomizationLabel: @"Example Button"];
        
        RELEASE(button);
        return AUTORELEASE(buttonItem);
    }
    
    return nil;
}

/*
 * NSScrubber data source methods
 */

- (NSInteger) numberOfItemsForScrubber: (NSScrubber *)scrubber
{
    return [_scrubberItems count];
}

- (NSScrubberItemView *) scrubber: (NSScrubber *)scrubber 
                     viewForItemAtIndex: (NSInteger)index
{
    NSString *identifier = @"TextItem";
    NSScrubberTextItemView *itemView = 
        (NSScrubberTextItemView *)[scrubber makeItemWithIdentifier: identifier owner: nil];
    
    if (!itemView)
    {
        itemView = AUTORELEASE([[NSScrubberTextItemView alloc] init]);
    }
    
    [itemView setTitle: [_scrubberItems objectAtIndex: index]];
    return itemView;
}

/*
 * NSScrubber delegate methods
 */

- (void) scrubber: (NSScrubber *)scrubber didSelectItemAtIndex: (NSInteger)selectedIndex
{
    NSString *item = [_scrubberItems objectAtIndex: selectedIndex];
    NSLog(@"Selected scrubber item: %@", item);
}

/*
 * Action methods
 */

- (void) buttonPressed: (id)sender
{
    NSLog(@"Touch Bar button pressed!");
}

@end

// Main function
int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSApplication *app = [NSApplication sharedApplication];
    TouchBarExampleDelegate *delegate = [[TouchBarExampleDelegate alloc] init];
    [app setDelegate: delegate];
    
    [app run];
    
    RELEASE(delegate);
    RELEASE(pool);
    return 0;
}