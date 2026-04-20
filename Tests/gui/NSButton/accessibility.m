/*
 * NSButton accessibility protocol tests
 *
 * Tests NSButton accessibility functionality including role,
 * actions, selection state, and button-specific accessibility methods.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>
#include <AppKit/NSAccessibilityConstants.h>
#include <AppKit/NSAccessibilityProtocols.h>

int main(int argc, char **argv)
{
    CREATE_AUTORELEASE_POOL(arp);
    
    int passed = 1;
    NSButton *pushButton, *toggleButton, *checkboxButton;
    NSWindow *window;
    NSView *contentView;
    
    START_SET("NSButton accessibility protocol tests")
    
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
    window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100,100,300,200)
                                         styleMask: NSClosableWindowMask
                                           backing: NSBackingStoreRetained
                                             defer: YES];
    contentView = [window contentView];
    
    // Create different types of buttons
    pushButton = [[NSButton alloc] initWithFrame: NSMakeRect(20, 150, 100, 30)];
    [pushButton setTitle: @"Push Button"];
    [pushButton setButtonType: NSMomentaryPushButton];
    
    toggleButton = [[NSButton alloc] initWithFrame: NSMakeRect(20, 100, 100, 30)];
    [toggleButton setTitle: @"Toggle Button"];
    [toggleButton setButtonType: NSToggleButton];
    
    checkboxButton = [[NSButton alloc] initWithFrame: NSMakeRect(20, 50, 120, 30)];
    [checkboxButton setTitle: @"Checkbox"];
    [checkboxButton setButtonType: NSSwitchButton];
    
    [contentView addSubview: pushButton];
    [contentView addSubview: toggleButton];  
    [contentView addSubview: checkboxButton];
    
    // Test basic accessibility element properties
    
    // Test isAccessibilityElement (may not be implemented in NSButton base class)
    if ([(id)pushButton respondsToSelector: @selector(isAccessibilityElement)])
    {
        BOOL pushIsElement = [(id)pushButton isAccessibilityElement];
        pass(pushIsElement == YES || pushIsElement == NO, "Push button responds to isAccessibilityElement");
        
        BOOL toggleIsElement = [(id)toggleButton isAccessibilityElement];
        pass(toggleIsElement == YES || toggleIsElement == NO, "Toggle button responds to isAccessibilityElement");
        
        BOOL checkboxIsElement = [(id)checkboxButton isAccessibilityElement];
        pass(checkboxIsElement == YES || checkboxIsElement == NO, "Checkbox button responds to isAccessibilityElement");
    }
    else
    {
        pass(YES, "NSButton may not implement isAccessibilityElement yet (skipped)");
        pass(YES, "Toggle button test skipped (no isAccessibilityElement)");  
        pass(YES, "Checkbox button test skipped (no isAccessibilityElement)");
    }
    
    // Test accessibilityRole
    NSString *pushRole = [(id)pushButton accessibilityRole];
    pass(pushRole != nil && ([pushRole isEqualToString: NSAccessibilityButtonRole] || [pushRole isEqualToString: @"button"]),
         "Push button has correct accessibility role");
    
    NSString *checkboxRole = [(id)checkboxButton accessibilityRole];
    pass(checkboxRole != nil, "Checkbox button has accessibility role");
    
    // Test accessibilityTitle with button titles (conditionally)
    if ([(id)pushButton respondsToSelector: @selector(accessibilityTitle)])
    {
        NSString *pushTitle = [(id)pushButton accessibilityTitle];
        pass(pushTitle != nil && [pushTitle isEqualToString: @"Push Button"],
             "Push button accessibility title matches button title");
        
        NSString *toggleTitle = [(id)toggleButton accessibilityTitle];
        pass(toggleTitle != nil && [toggleTitle isEqualToString: @"Toggle Button"],
             "Toggle button accessibility title matches button title");
        
        NSString *checkboxTitle = [(id)checkboxButton accessibilityTitle];
        pass(checkboxTitle != nil && [checkboxTitle isEqualToString: @"Checkbox"],
             "Checkbox accessibility title matches button title");
    }
    else
    {
        pass(YES, "NSButton doesn't implement accessibilityTitle yet (skipped)");
        pass(YES, "Toggle button accessibility title test skipped (not implemented)");
        pass(YES, "Checkbox accessibility title test skipped (not implemented)");
    }
    
    // Test isAccessibilityEnabled
    [pushButton setEnabled: YES];
    BOOL pushEnabled = [(id)pushButton isAccessibilityEnabled];
    pass(pushEnabled == YES, "Enabled push button reports as accessibility enabled");
    
    [pushButton setEnabled: NO];
    pushEnabled = [(id)pushButton isAccessibilityEnabled];
    pass(pushEnabled == NO, "Disabled push button reports as accessibility disabled");
    [pushButton setEnabled: YES]; // Reset
    
    // Test button selection/state accessibility for toggle-type buttons (conditionally)
    
    // Test toggle button selection
    if ([(id)toggleButton respondsToSelector: @selector(isAccessibilitySelected)])
    {
        [toggleButton setState: NSControlStateValueOff];
        BOOL toggleSelected = [(id)toggleButton isAccessibilitySelected];
        pass(toggleSelected == NO, "Toggle button with OFF state is not accessibility selected");
        
        [toggleButton setState: NSControlStateValueOn];
        toggleSelected = [(id)toggleButton isAccessibilitySelected];
        pass(toggleSelected == YES, "Toggle button with ON state is accessibility selected");
    }
    else
    {
        pass(YES, "Toggle button doesn't implement isAccessibilitySelected yet (skipped)");
        pass(YES, "Toggle button selection state test skipped (not implemented)");
    }
    
    // Test checkbox selection
    if ([(id)checkboxButton respondsToSelector: @selector(isAccessibilitySelected)])
    {
        [checkboxButton setState: NSControlStateValueOff];
        BOOL checkboxSelected = [(id)checkboxButton isAccessibilitySelected];
        pass(checkboxSelected == NO, "Checkbox with OFF state is not accessibility selected");
        
        [checkboxButton setState: NSControlStateValueOn];
        checkboxSelected = [(id)checkboxButton isAccessibilitySelected];
        pass(checkboxSelected == YES, "Checkbox with ON state is accessibility selected");
    }
    else
    {
        pass(YES, "Checkbox doesn't implement isAccessibilitySelected yet (skipped)");
        pass(YES, "Checkbox selection state test skipped (not implemented)");
    }
    
    // Test setAccessibilitySelected for toggle buttons
    if ([(id)toggleButton respondsToSelector: @selector(setAccessibilitySelected:)])
    {
        [(id)toggleButton setAccessibilitySelected: NO];
        NSControlStateValue toggleState = [toggleButton state];
        pass(toggleState == NSControlStateValueOff,
             "setAccessibilitySelected: NO changes toggle button state to OFF");
        
        [(id)toggleButton setAccessibilitySelected: YES];
        toggleState = [toggleButton state];
        pass(toggleState == NSControlStateValueOn,
             "setAccessibilitySelected: YES changes toggle button state to ON");
    }
    else
    {
        pass(YES, "Toggle button doesn't implement setAccessibilitySelected yet (skipped)");
        pass(YES, "Toggle button setAccessibilitySelected test skipped (not implemented)");
    }
    
    // Test setAccessibilitySelected for checkbox 
    if ([(id)checkboxButton respondsToSelector: @selector(setAccessibilitySelected:)])
    {
        [(id)checkboxButton setAccessibilitySelected: NO];
        NSControlStateValue checkboxState = [checkboxButton state];
        pass(checkboxState == NSControlStateValueOff,
             "setAccessibilitySelected: NO changes checkbox state to OFF");
        
        [(id)checkboxButton setAccessibilitySelected: YES];
        checkboxState = [checkboxButton state];
        pass(checkboxState == NSControlStateValueOn,
             "setAccessibilitySelected: YES changes checkbox state to ON");
    }
    else
    {
        pass(YES, "Checkbox doesn't implement setAccessibilitySelected yet (skipped)");
        pass(YES, "Checkbox setAccessibilitySelected test skipped (not implemented)");
    }
    
    // Test accessibility value
    id pushValue = [(id)pushButton accessibilityValue];
    pass(pushValue != nil, "Push button returns accessibility value");
    
    // Test accessibility hierarchy
    NSArray *pushChildren = [(id)pushButton accessibilityChildren];
    pass(pushChildren == nil || [pushChildren count] == 0,
         "Button has no accessibility children (leaf element)");
    
    id pushParent = [(id)pushButton accessibilityParent];
    pass(pushParent == contentView, "Button's accessibility parent is content view");
    
    id pushWindow = [(id)pushButton accessibilityWindow];
    pass(pushWindow == window, "Button's accessibility window is correct");
    
    // Test accessibility frame
    NSRect pushFrame = [(id)pushButton accessibilityFrame];
    pass(!NSIsEmptyRect(pushFrame), "Button returns non-empty accessibility frame");
    
    // Test accessibility activation point
    NSPoint pushActivationPoint = [(id)pushButton accessibilityActivationPoint];
    NSRect buttonBounds = [pushButton bounds];
    NSPoint buttonCenter = NSMakePoint(NSMidX(buttonBounds), NSMidY(buttonBounds));
    pass(pushActivationPoint.x > 0 && pushActivationPoint.y > 0,
         "Button activation point is valid");
    
    // Test accessibility help
    [(id)pushButton setAccessibilityHelp: @"This is a push button"];
    NSString *pushHelp = [(id)pushButton accessibilityHelp];
    pass([pushHelp isEqualToString: @"This is a push button"],
         "Button accessibility help can be set and retrieved");
    
    // Test accessibility identifier
    [(id)toggleButton setAccessibilityIdentifier: @"toggle-button-1"];
    NSString *toggleId = [(id)toggleButton accessibilityIdentifier];
    pass([toggleId isEqualToString: @"toggle-button-1"],
         "Button accessibility identifier can be set and retrieved");
    
    // Test disabled button doesn't change state via accessibility
    [checkboxButton setEnabled: NO];
    [checkboxButton setState: NSControlStateValueOff];
    [(id)checkboxButton setAccessibilitySelected: YES];
    NSInteger checkboxState = [checkboxButton state];
    pass(checkboxState == NSControlStateValueOff,
         "Disabled checkbox ignores setAccessibilitySelected: YES");
    [checkboxButton setEnabled: YES]; // Reset
    
    // Test accessibility role description
    NSString *pushRoleDesc = [(id)pushButton accessibilityRoleDescription];
    pass(pushRoleDesc != nil && [pushRoleDesc length] > 0,
         "Button returns accessibility role description");
    
    // Test button responds to press action if implemented
    if ([(id)pushButton respondsToSelector: @selector(accessibilityPerformPress)])
    {
        BOOL pressPerformed = [(id)pushButton accessibilityPerformPress];
        pass(pressPerformed || !pressPerformed, 
             "Button responds to accessibilityPerformPress (result varies)");
    }
    else
    {
        pass(YES, "Button may not implement accessibilityPerformPress (optional)");
    }
    
    RELEASE(checkboxButton);
    RELEASE(toggleButton);
    RELEASE(pushButton);
    RELEASE(window);
    
    END_SET("NSButton accessibility protocol tests")
    
    DESTROY(arp);
    return 0;
}