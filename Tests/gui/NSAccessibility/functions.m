/*
 * NSAccessibility function tests
 *
 * Tests for NSAccessibility functions including 
 * notifications, unignored ancestor/descendant handling,
 * role descriptions, and action descriptions.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSAccessibility.h>
#include <AppKit/NSAccessibilityConstants.h>
#include <AppKit/NSAccessibilityProtocols.h>

int main(int argc, char **argv)
{
    CREATE_AUTORELEASE_POOL(arp);
    
    int passed = 1;
    NSWindow *window;
    NSView *view;
    NSButton *button;
    
    START_SET("NSAccessibility functions")
    
    NS_DURING
    {
        [NSApplication sharedApplication];
    }
    NS_HANDLER
    {
        if ([[localException name] isEqualToString: NSInternalInconsistencyException])
            SKIP("It looks like GNUstep backend is not yet installed")
    }
    NS_ENDHANDLER
    
    // Create test objects
    window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100,100,200,200)
                                         styleMask: NSClosableWindowMask
                                           backing: NSBackingStoreRetained
                                             defer: YES];
    view = [[NSView alloc] initWithFrame: NSMakeRect(20,20,100,100)];
    button = [[NSButton alloc] initWithFrame: NSMakeRect(10,10,50,30)];
    
    [[window contentView] addSubview: view];
    [view addSubview: button];
    
    // Test NSAccessibilityRoleDescription
    NSString *roleDesc = NSAccessibilityRoleDescription(NSAccessibilityButtonRole, nil);
    pass(roleDesc != nil && [roleDesc length] > 0, 
         "NSAccessibilityRoleDescription returns valid description for button");
    
    // Test NSAccessibilityRoleDescriptionForUIElement  
    NSString *elementRoleDesc = NSAccessibilityRoleDescriptionForUIElement(button);
    pass(elementRoleDesc != nil && [elementRoleDesc length] > 0,
         "NSAccessibilityRoleDescriptionForUIElement returns valid description");
    
    // Test NSAccessibilityActionDescription
    NSString *actionDesc = NSAccessibilityActionDescription(NSAccessibilityPressAction);
    pass(actionDesc != nil && [actionDesc length] > 0,
         "NSAccessibilityActionDescription returns valid description for press action");
    
    // Test NSAccessibilityUnignoredAncestor
    id ancestor = NSAccessibilityUnignoredAncestor(button);
    pass(ancestor != nil, "NSAccessibilityUnignoredAncestor returns non-nil ancestor");
    
    // Test NSAccessibilityUnignoredDescendant
    id descendant = NSAccessibilityUnignoredDescendant(view);
    pass(descendant != nil, "NSAccessibilityUnignoredDescendant returns non-nil descendant");
    
    // Test NSAccessibilityUnignoredChildren
    NSArray *children = [NSArray arrayWithObject: button];
    NSArray *unignoredChildren = NSAccessibilityUnignoredChildren(children);
    pass(unignoredChildren != nil && [unignoredChildren count] > 0,
         "NSAccessibilityUnignoredChildren filters array correctly");
    
    // Test NSAccessibilityUnignoredChildrenForOnlyChild
    NSArray *singleChildArray = NSAccessibilityUnignoredChildrenForOnlyChild(button);
    pass(singleChildArray != nil, 
         "NSAccessibilityUnignoredChildrenForOnlyChild handles single child");
    
    // Test NSAccessibilityPostNotification (should not crash)
    NS_DURING
    {
        NSAccessibilityPostNotification(button, NSAccessibilityValueChangedNotification);
        pass(YES, "NSAccessibilityPostNotification executes without exception");
    }
    NS_HANDLER
    {
        pass(NO, "NSAccessibilityPostNotification should not throw exception");
    }
    NS_ENDHANDLER
    
    END_SET("NSAccessibility functions")
    
    DESTROY(arp);
    return 0;
}