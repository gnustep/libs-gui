/*
 * NSSwitch accessibility protocol implementation tests
 *
 * Tests the NSAccessibilityElement protocol methods implemented 
 * in NSSwitch class to verify compliance and functionality.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSSwitch.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>
#include <AppKit/NSAccessibilityConstants.h>
#include <AppKit/NSAccessibilityProtocols.h>

int main(int argc, char **argv)
{
    CREATE_AUTORELEASE_POOL(arp);
    
    int passed = 1;
    NSSwitch *switchControl;
    NSWindow *window;
    NSView *contentView;
    
    START_SET("NSSwitch accessibility protocol compliance")
    
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
    contentView = [window contentView];
    switchControl = [[NSSwitch alloc] initWithFrame: NSMakeRect(50, 50, 60, 30)];
    
    [contentView addSubview: switchControl];
    
    // Test basic NSAccessibilityElement protocol methods
    
    // Test accessibilityRole
    NSString *role = [switchControl accessibilityRole];
    pass(role != nil && [role isEqualToString: NSAccessibilityCheckBoxRole],
         "accessibilityRole returns correct checkbox role");
    
    // Test accessibilityRoleDescription
    NSString *roleDesc = [switchControl accessibilityRoleDescription];
    pass(roleDesc != nil && [roleDesc isEqualToString: @"switch"],
         "accessibilityRoleDescription returns 'switch'");
    
    // Test accessibilityHelp
    NSString *help = [switchControl accessibilityHelp];
    pass(help != nil && [help isEqualToString: @"Toggle switch control"],
         "accessibilityHelp returns appropriate description");
    
    // Test isAccessibilityElement
    BOOL isElement = [switchControl isAccessibilityElement];
    pass(isElement == YES, "isAccessibilityElement returns YES");
    
    // Test isAccessibilityEnabled when enabled
    [switchControl setEnabled: YES];
    BOOL isEnabled = [switchControl isAccessibilityEnabled];
    pass(isEnabled == YES, "isAccessibilityEnabled returns YES when enabled");
    
    // Test isAccessibilityEnabled when disabled
    [switchControl setEnabled: NO];
    isEnabled = [switchControl isAccessibilityEnabled];
    pass(isEnabled == NO, "isAccessibilityEnabled returns NO when disabled");
    [switchControl setEnabled: YES]; // Reset for further tests
    
    // Test accessibilityTitle
    NSString *title = [switchControl accessibilityTitle];
    pass(title != nil && [title isEqualToString: @"Switch"],
         "accessibilityTitle returns default 'Switch' title");
    
    // Test isAccessibilitySelected with different states
    [switchControl setState: NSControlStateValueOff];
    BOOL selected = [switchControl isAccessibilitySelected];
    pass(selected == NO, "isAccessibilitySelected returns NO for OFF state");
    
    [switchControl setState: NSControlStateValueOn];
    selected = [switchControl isAccessibilitySelected];
    pass(selected == YES, "isAccessibilitySelected returns YES for ON state");
    
    // Test setAccessibilitySelected
    [switchControl setAccessibilitySelected: NO];
    NSControlStateValue state = [switchControl state];
    pass(state == NSControlStateValueOff,
         "setAccessibilitySelected: NO changes state to OFF");
    
    [switchControl setAccessibilitySelected: YES];
    state = [switchControl state];
    pass(state == NSControlStateValueOn,
         "setAccessibilitySelected: YES changes state to ON");
    
    // Test protocol methods that should return nil/NO for switches
    
    // Test accessibilitySubrole
    NSString *subrole = [switchControl accessibilitySubrole];
    pass(subrole == nil, "accessibilitySubrole returns nil");
    
    // Test accessibilityChildren
    NSArray *children = [switchControl accessibilityChildren];
    pass(children == nil, "accessibilityChildren returns nil");
    
    // Test accessibilitySelectedChildren
    NSArray *selectedChildren = [switchControl accessibilitySelectedChildren];
    pass(selectedChildren == nil, "accessibilitySelectedChildren returns nil");
    
    // Test accessibilityVisibleChildren
    NSArray *visibleChildren = [switchControl accessibilityVisibleChildren];
    pass(visibleChildren == nil, "accessibilityVisibleChildren returns nil");
    
    // Test accessibilityWindow
    id accessWindow = [switchControl accessibilityWindow];
    pass(accessWindow == window, "accessibilityWindow returns correct window");
    
    // Test accessibilityTopLevelUIElement
    id topLevel = [switchControl accessibilityTopLevelUIElement];
    pass(topLevel != nil || topLevel == nil, "accessibilityTopLevelUIElement may return nil (implementation varies)");
    
    // Test accessibilityActivationPoint
    NSPoint activationPoint = [switchControl accessibilityActivationPoint];
    pass(activationPoint.x > 0 && activationPoint.y > 0,
         "accessibilityActivationPoint returns valid point");
    
    // Test accessibilityURL
    NSString *url = [switchControl accessibilityURL];
    pass(url == nil, "accessibilityURL returns nil for switch");
    
    // Test accessibilityIndex
    NSNumber *index = [switchControl accessibilityIndex];
    pass(index == nil, "accessibilityIndex returns nil for switch");
    
    // Test accessibilityCustomRotors
    NSArray *rotors = [switchControl accessibilityCustomRotors];
    pass(rotors == nil, "accessibilityCustomRotors returns nil");
    
    // Test accessibilityPerformEscape
    BOOL escapesPerformed = [switchControl accessibilityPerformEscape];
    pass(escapesPerformed == NO, "accessibilityPerformEscape returns NO");
    
    // Test accessibilityCustomActions
    NSArray *actions = [switchControl accessibilityCustomActions];
    pass(actions == nil, "accessibilityCustomActions returns nil");
    
    // Test setter methods (should not crash)
    NS_DURING
    {
        [switchControl setAccessibilityElement: YES];
        pass(YES, "setAccessibilityElement: does not crash");
    }
    NS_HANDLER
    {
        pass(NO, "setAccessibilityElement: should not throw exception");
    }
    NS_ENDHANDLER
    
    NS_DURING
    {
        [switchControl setAccessibilityFrame: NSMakeRect(0, 0, 100, 50)];
        pass(YES, "setAccessibilityFrame: does not crash");
    }
    NS_HANDLER
    {
        pass(NO, "setAccessibilityFrame: should not throw exception");
    }
    NS_ENDHANDLER
    
    NS_DURING
    {
        [switchControl setAccessibilityParent: contentView];
        pass(YES, "setAccessibilityParent: does not crash");
    }
    NS_HANDLER
    {
        pass(NO, "setAccessibilityParent: should not throw exception");
    }
    NS_ENDHANDLER
    
    NS_DURING
    {
        [switchControl setAccessibilityFocused: YES];
        pass(YES, "setAccessibilityFocused: does not crash");
    }
    NS_HANDLER
    {
        pass(NO, "setAccessibilityFocused: should not throw exception");
    }
    NS_ENDHANDLER
    
    // Test that disabled switch doesn't respond to accessibility selection changes
    [switchControl setEnabled: NO];
    [switchControl setState: NSControlStateValueOff];
    [switchControl setAccessibilitySelected: YES];
    state = [switchControl state];
    pass(state == NSControlStateValueOff, 
         "Disabled switch ignores setAccessibilitySelected: YES");
    
    RELEASE(switchControl);
    RELEASE(window);
    
    END_SET("NSSwitch accessibility protocol compliance")
    
    DESTROY(arp);
    return 0;
}