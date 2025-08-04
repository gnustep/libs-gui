/**
 * Example demonstrating NSDataLink delegate callbacks
 * 
 * This example shows how to implement the NSDataLinkManager delegate methods
 * to handle link tracking, updates, and outline drawing.
 */

#import <Foundation/Foundation.h>
#import "AppKit/NSDataLinkManager.h"
#import "AppKit/NSDataLink.h"
#import "AppKit/NSSelection.h"
#import "AppKit/NSPasteboard.h"

@interface DataLinkDelegate : NSObject
{
  NSMutableArray *_trackedLinks;
}
@end

@implementation DataLinkDelegate

- (id) init
{
  if ((self = [super init]))
    {
      _trackedLinks = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  [_trackedLinks release];
  [super dealloc];
}

// Required delegate methods for link management
- (void)dataLinkManager: (NSDataLinkManager *)sender 
       startTrackingLink: (NSDataLink *)link
{
  NSLog(@"Started tracking link #%d", [link linkNumber]);
  [_trackedLinks addObject: link];
}

- (void)dataLinkManager: (NSDataLinkManager *)sender 
        stopTrackingLink: (NSDataLink *)link
{
  NSLog(@"Stopped tracking link #%d", [link linkNumber]);
  [_trackedLinks removeObject: link];
}

- (void)dataLinkManager: (NSDataLinkManager *)sender 
           didBreakLink: (NSDataLink *)link
{
  NSLog(@"Link #%d was broken", [link linkNumber]);
  [_trackedLinks removeObject: link];
}

- (BOOL)dataLinkManager: (NSDataLinkManager *)sender 
  isUpdateNeededForLink: (NSDataLink *)link
{
  // Check if the source has been modified since last update
  NSDate *lastUpdate = [link lastUpdateTime];
  NSString *sourceFile = [link sourceFilename];
  
  if (sourceFile)
    {
      NSDictionary *attrs = [[NSFileManager defaultManager] 
                             attributesOfItemAtPath: sourceFile error: nil];
      NSDate *modDate = [attrs objectForKey: NSFileModificationDate];
      
      if (modDate && lastUpdate && [modDate compare: lastUpdate] == NSOrderedDescending)
        {
          NSLog(@"Update needed for link #%d - source modified", [link linkNumber]);
          return YES;
        }
    }
  
  return NO;
}

- (void)dataLinkManagerDidEditLinks: (NSDataLinkManager *)sender
{
  NSLog(@"Document links were edited");
}

- (void)dataLinkManagerRedrawLinkOutlines: (NSDataLinkManager *)sender
{
  NSLog(@"Should redraw link outlines (visibility: %s)", 
        [sender areLinkOutlinesVisible] ? "visible" : "hidden");
}

- (BOOL)dataLinkManagerTracksLinksIndividually: (NSDataLinkManager *)sender
{
  NSLog(@"Using individual link tracking");
  return YES; // Enable individual tracking
}

- (void)dataLinkManagerCloseDocument: (NSDataLinkManager *)sender
{
  NSLog(@"Document is closing, cleaning up %lu tracked links", 
        (unsigned long)[_trackedLinks count]);
}

// Optional selection management methods
- (BOOL)copyToPasteboard: (NSPasteboard *)pasteboard 
                     at: (NSSelection *)selection
        cheapCopyAllowed: (BOOL)flag
{
  NSLog(@"Copy to pasteboard requested for selection");
  return YES;
}

- (BOOL)showSelection: (NSSelection *)selection
{
  NSLog(@"Show selection requested");
  return YES;
}

@end

// Example usage
int main(int argc, char *argv[])
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  DataLinkDelegate *delegate = [[DataLinkDelegate alloc] init];
  NSDataLinkManager *manager = [[NSDataLinkManager alloc] 
                                initWithDelegate: delegate];
  
  // Create a test link
  NSDataLink *link = [[NSDataLink alloc] initLinkedToFile: @"/tmp/test.txt"];
  
  // Add the link - this will trigger startTrackingLink delegate callback
  NSLog(@"Adding link...");
  [manager addSourceLink: link];
  
  // Test update checking
  NSLog(@"Checking for updates...");
  [manager checkForLinkUpdates];
  
  // Test outline visibility changes
  NSLog(@"Setting outline visibility...");
  [manager setLinkOutlinesVisible: YES];
  [manager setLinkOutlinesVisible: NO];
  
  // Test manual redraw
  NSLog(@"Manual redraw...");
  [manager redrawLinkOutlines];
  
  // Test tracking mode
  NSLog(@"Individual tracking: %s", 
        [manager tracksLinksIndividually] ? "YES" : "NO");
  
  // Remove the link - this will trigger stopTrackingLink delegate callback
  NSLog(@"Removing link...");
  [manager removeLink: link];
  
  // Cleanup
  [link release];
  [manager release];
  [delegate release];
  [pool release];
  
  return 0;
}
