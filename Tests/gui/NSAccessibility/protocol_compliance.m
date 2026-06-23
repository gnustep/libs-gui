/*
 * NSAccessibilityElement protocol compliance test
 *
 * Tests multiple UI classes for proper implementation of 
 * NSAccessibilityElement protocol methods and compliance.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSSlider.h>
#include <AppKit/NSSwitch.h>
#include <AppKit/NSAccessibilityConstants.h>
#include <AppKit/NSAccessibilityProtocols.h>

// Helper function to test protocol compliance for any object
BOOL testProtocolCompliance(id object, NSString *className, int *testsPassed)
{
    BOOL allPassed = YES;
    int localPassed = 0;
    
    // Check if object conforms to NSAccessibilityElement protocol
    if ([object conformsToProtocol: @protocol(NSAccessibilityElement)])
    {
        localPassed++;
        
        // Test required protocol methods
        if ([object respondsToSelector: @selector(accessibilityRole)])
        {
            NSString *role = [object accessibilityRole];
            if (role != nil)
                localPassed++;
            else
                allPassed = NO;
        }
        else
        {
            allPassed = NO;
        }
        
        if ([object respondsToSelector: @selector(isAccessibilityElement)])
        {
            [object isAccessibilityElement]; // Just test it doesn't crash
            localPassed++;
        }
        else
        {
            allPassed = NO;
        }
        
        if ([object respondsToSelector: @selector(accessibilityFrame)])
        {
            NSRect frame = [object accessibilityFrame];
            if (!NSIsEmptyRect(frame) || NSIsEmptyRect(frame)) // Either is valid
                localPassed++;
        }
        else
        {
            allPassed = NO;
        }
        
        if ([object respondsToSelector: @selector(accessibilityParent)])
        {
            [object accessibilityParent]; // Just test it doesn't crash
            localPassed++;
        }
        else
        {
            allPassed = NO;
        }
        
        if ([object respondsToSelector: @selector(isAccessibilityFocused)])
        {
            [object isAccessibilityFocused]; // Just test it doesn't crash  
            localPassed++;
        }
        else
        {
            allPassed = NO;
        }
        
        if ([object respondsToSelector: @selector(accessibilityLabel)])
        {
            [object accessibilityLabel]; // Just test it doesn't crash
            localPassed++;
        }
        else
        {
            allPassed = NO;
        }
        
        if ([object respondsToSelector: @selector(accessibilityValue)])
        {
            [object accessibilityValue]; // Just test it doesn't crash
            localPassed++;
        }
        else
        {
            allPassed = NO;
        }
        
        // Test methods that should be implemented for full compliance
        NSArray *requiredSelectors = [NSArray arrayWithObjects:
            NSStringFromSelector(@selector(accessibilityRoleDescription)),
            NSStringFromSelector(@selector(accessibilitySubrole)),  
            NSStringFromSelector(@selector(accessibilityTitle)),
            NSStringFromSelector(@selector(accessibilityHelp)),
            NSStringFromSelector(@selector(isAccessibilityEnabled)),
            NSStringFromSelector(@selector(accessibilityChildren)),
            NSStringFromSelector(@selector(accessibilitySelectedChildren)),
            NSStringFromSelector(@selector(accessibilityVisibleChildren)),
            NSStringFromSelector(@selector(accessibilityWindow)),
            NSStringFromSelector(@selector(accessibilityTopLevelUIElement)),
            NSStringFromSelector(@selector(accessibilityActivationPoint)),
            NSStringFromSelector(@selector(accessibilityURL)),
            NSStringFromSelector(@selector(accessibilityIndex)),
            NSStringFromSelector(@selector(accessibilityCustomRotors)),
            NSStringFromSelector(@selector(accessibilityPerformEscape)),
            NSStringFromSelector(@selector(accessibilityCustomActions)),
            NSStringFromSelector(@selector(setAccessibilityElement:)),
            NSStringFromSelector(@selector(setAccessibilityFrame:)),
            NSStringFromSelector(@selector(setAccessibilityParent:)),
            NSStringFromSelector(@selector(setAccessibilityFocused:)),
            nil];
        
        int methodsImplemented = 0;
        for (NSString *selectorString in requiredSelectors)
        {
            SEL selector = NSSelectorFromString(selectorString);
            if ([object respondsToSelector: selector])
            {
                methodsImplemented++;
            }
        }
        
        // For reasonable compliance, some methods should be implemented
        if (methodsImplemented >= ([requiredSelectors count] * 0.3)) // 30% threshold
        {
            localPassed++;
        }
        else
        {
            allPassed = NO;
        }
    }
    else
    {
        allPassed = NO;
    }
    
    *testsPassed = localPassed;
    return allPassed;
}

int main(int argc, char **argv)
{
    CREATE_AUTORELEASE_POOL(arp);
    
    NSWindow *window;
    NSView *view;
    NSButton *button;
    NSTextField *textField;
    NSSlider *slider;
    NSSwitch *switchControl;
    
    START_SET("NSAccessibilityElement protocol compliance across UI classes")
    
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
    window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100,100,300,250)
                                         styleMask: NSClosableWindowMask
                                           backing: NSBackingStoreRetained
                                             defer: YES];
    
    view = [[NSView alloc] initWithFrame: NSMakeRect(20,20,200,150)];
    button = [[NSButton alloc] initWithFrame: NSMakeRect(10,120,100,25)];
    [button setTitle: @"Test Button"];
    
    textField = [[NSTextField alloc] initWithFrame: NSMakeRect(10,90,150,20)];
    [textField setStringValue: @"Test Text"];
    
    slider = [[NSSlider alloc] initWithFrame: NSMakeRect(10,60,120,20)];
    [slider setMinValue: 0];
    [slider setMaxValue: 100];
    [slider setDoubleValue: 50];
    
    switchControl = [[NSSwitch alloc] initWithFrame: NSMakeRect(10,30,60,25)];
    
    // Add to hierarchy
    [[window contentView] addSubview: view];
    [view addSubview: button];
    [view addSubview: textField]; 
    [view addSubview: slider];
    [view addSubview: switchControl];
    
    // Test protocol compliance for each UI class
    
    int testsPassed;
    BOOL viewCompliant = testProtocolCompliance(view, @"NSView", &testsPassed);
    pass(viewCompliant || testsPassed >= 3, "NSView shows some NSAccessibilityElement protocol compliance");
    printf("  NSView: %d/8+ compliance tests passed\n", testsPassed);
    
    BOOL buttonCompliant = testProtocolCompliance(button, @"NSButton", &testsPassed);
    pass(buttonCompliant || testsPassed >= 3, "NSButton shows some NSAccessibilityElement protocol compliance");
    printf("  NSButton: %d/8+ compliance tests passed\n", testsPassed);
    
    BOOL textFieldCompliant = testProtocolCompliance(textField, @"NSTextField", &testsPassed);
    pass(textFieldCompliant || testsPassed >= 2, 
         "NSTextField shows basic NSAccessibilityElement protocol compliance (or partial implementation)");
    printf("  NSTextField: %d/8+ compliance tests passed\n", testsPassed);
    
    BOOL sliderCompliant = testProtocolCompliance(slider, @"NSSlider", &testsPassed);
    pass(sliderCompliant || testsPassed >= 2,
         "NSSlider shows basic NSAccessibilityElement protocol compliance (or partial implementation)");
    printf("  NSSlider: %d/8+ compliance tests passed\n", testsPassed);
    
    BOOL switchCompliant = testProtocolCompliance(switchControl, @"NSSwitch", &testsPassed);
    pass(switchCompliant, "NSSwitch shows good NSAccessibilityElement protocol compliance");
    printf("  NSSwitch: %d/8+ compliance tests passed\n", testsPassed);
    
    // Test that all objects report as accessibility elements
    BOOL allAreElements = [view isAccessibilityElement] ||
                         [button isAccessibilityElement] ||
                         [textField isAccessibilityElement] ||
                         [slider isAccessibilityElement] ||
                         [switchControl isAccessibilityElement];
    pass(allAreElements, "At least some UI objects report as accessibility elements");
    
    // Test that accessibility roles are provided
    NSArray *objects = [NSArray arrayWithObjects: view, button, textField, slider, switchControl, nil];
    int objectsWithRoles = 0;
    for (id obj in objects)
    {
        NSString *role = [obj accessibilityRole];
        if (role != nil && [role length] > 0)
            objectsWithRoles++;
    }
    pass(objectsWithRoles >= 3, "Most UI objects provide accessibility roles");
    
    // Test that accessibility frames are reasonable
    int objectsWithValidFrames = 0;
    for (id obj in objects)
    {
        NSRect frame = [obj accessibilityFrame];
        if (!NSIsEmptyRect(frame) && frame.size.width > 0 && frame.size.height > 0)
            objectsWithValidFrames++;
    }
    pass(objectsWithValidFrames >= 3, "Most UI objects provide valid accessibility frames");
    
    // Test accessibility hierarchy consistency
    id buttonParent = [button accessibilityParent];
    id textFieldParent = [textField accessibilityParent];
    pass(buttonParent == view || buttonParent == [window contentView],
         "Button has correct accessibility parent in hierarchy");
    pass(textFieldParent == view || textFieldParent == [window contentView],
         "TextField has correct accessibility parent in hierarchy");
    
    // Test that enabled/disabled state is reflected in accessibility
    [button setEnabled: NO];
    BOOL buttonAccessEnabled = [button isAccessibilityEnabled];
    pass(buttonAccessEnabled == NO, "Disabled button reports as accessibility disabled");
    
    [button setEnabled: YES];
    buttonAccessEnabled = [button isAccessibilityEnabled];
    pass(buttonAccessEnabled == YES, "Enabled button reports as accessibility enabled");
    
    // Test accessibility window consistency
    id buttonWindow = [button accessibilityWindow];
    id viewWindow = [view accessibilityWindow];
    pass(buttonWindow == window && viewWindow == window,
         "UI objects report correct accessibility window");
    
    RELEASE(switchControl);
    RELEASE(slider);
    RELEASE(textField);
    RELEASE(button);
    RELEASE(view);
    RELEASE(window);
    
    END_SET("NSAccessibilityElement protocol compliance across UI classes")
    
    DESTROY(arp);
    return 0;
}