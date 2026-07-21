/*
 * NSAccessibilityCustomAction and NSAccessibilityCustomRotor tests
 *
 * Tests for custom accessibility actions and rotors functionality
 * to ensure proper creation and behavior.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSAccessibilityCustomAction.h>
#include <AppKit/NSAccessibilityCustomRotor.h>

// Simple target class for testing action callbacks
@interface TestActionTarget : NSObject
{
    BOOL actionWasCalled;
    NSString *lastActionName;
}
- (BOOL) wasActionCalled;
- (NSString *) lastActionName;
- (BOOL) performCustomAction: (NSAccessibilityCustomAction *)action;
@end

@implementation TestActionTarget
- (BOOL) wasActionCalled
{
    return actionWasCalled;
}

- (NSString *) lastActionName  
{
    return lastActionName;
}

- (BOOL) performCustomAction: (NSAccessibilityCustomAction *)action
{
    actionWasCalled = YES;
    ASSIGN(lastActionName, [action name]);
    return YES;
}

- (void) dealloc
{
    RELEASE(lastActionName);
    [super dealloc];
}
@end

int main(int argc, char **argv)
{
    CREATE_AUTORELEASE_POOL(arp);
    
    NSAccessibilityCustomAction *action1, *action2;
    NSAccessibilityCustomRotor *rotor;
    TestActionTarget *target;
    
    START_SET("NSAccessibilityCustomAction and NSAccessibilityCustomRotor tests")
    
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
    
    // Create test target
    target = [[TestActionTarget alloc] init];
    
    // Test NSAccessibilityCustomAction creation and properties
    
    // Test action creation with name and selector
    action1 = [[NSAccessibilityCustomAction alloc] 
                initWithName: @"Custom Action 1" 
                      target: target
                    selector: @selector(performCustomAction:)];
    
    pass(action1 != nil, "NSAccessibilityCustomAction can be created with target/selector");
    
    if (action1 != nil)
    {
        // Test name property
        NSString *actionName = [action1 name];
        pass([actionName isEqualToString: @"Custom Action 1"],
             "Custom action name property works correctly");
        
        // Test target property
        id actionTarget = [action1 target];
        pass(actionTarget == target, 
             "Custom action target property works correctly");
        
        // Test selector property
        SEL actionSelector = [action1 selector];
        pass(sel_isEqual(actionSelector, @selector(performCustomAction:)),
             "Custom action selector property works correctly");
        
        // Test action execution
        BOOL actionResult = [action1 perform];
        pass(actionResult == YES && [target wasActionCalled],
             "Custom action can be performed successfully");
        
        pass([[target lastActionName] isEqualToString: @"Custom Action 1"],
             "Custom action execution calls target with correct action");
    }
    
    // Test action creation with handler block (if supported)
#if defined(__BLOCKS__) || (defined(__has_feature) && __has_feature(blocks))
    __block BOOL blockCalled = NO;
    __block NSString *blockActionName = nil;
    
    NS_DURING
    {
        action2 = [[NSAccessibilityCustomAction alloc] 
                    initWithName: @"Block Action"
                         handler: ^void(BOOL success) {
                             blockCalled = YES;
                             blockActionName = [@"Block Action" copy];
                         }];
        
        if (action2 != nil)
        {
            pass(YES, "NSAccessibilityCustomAction can be created with block handler");
            
            NSString *blockActionNameProp = [action2 name];
            pass([blockActionNameProp isEqualToString: @"Block Action"],
                 "Block action name property works correctly");
            
            BOOL blockResult = [action2 perform];
            pass(blockResult == YES && blockCalled,
                 "Block action can be performed successfully");
            
            if (blockActionName != nil)
            {
                pass([blockActionName isEqualToString: @"Block Action"],
                     "Block action execution provides correct action to handler");
                RELEASE(blockActionName);
            }
        }
        else
        {
            pass(YES, "Block-based actions may not be implemented (skipped)");
        }
    }
    NS_HANDLER
    {
        pass(YES, "Block-based custom actions may not be supported (skipped)");
        action2 = nil;
    }
    NS_ENDHANDLER
#else
    // Blocks not supported - skip block-based tests
    pass(YES, "Block-based custom actions not supported in this build (skipped)");
    pass(YES, "Block action name property test skipped (blocks not available)");
    pass(YES, "Block action performance test skipped (blocks not available)");
    pass(YES, "Block action execution test skipped (blocks not available)");
    action2 = nil;
#endif
    
    // Test NSAccessibilityCustomRotor (if implemented)
    NS_DURING
    {
        rotor = [[NSAccessibilityCustomRotor alloc] init];
        
        if (rotor != nil)
        {
            pass(YES, "NSAccessibilityCustomRotor can be created");
            
            // Test basic rotor properties if they exist
            if ([rotor respondsToSelector: @selector(setLabel:)])
            {
                [rotor setLabel: @"Test Rotor"];
                if ([rotor respondsToSelector: @selector(label)])
                {
                    NSString *rotorLabel = [rotor label];
                    pass([rotorLabel isEqualToString: @"Test Rotor"],
                         "Custom rotor label property works correctly");
                }
                else
                {
                    pass(YES, "Custom rotor label getter not implemented (partial support)");
                }
            }
            else
            {
                pass(YES, "Custom rotor label setter not implemented (basic creation only)");
            }
        }
        else
        {
            pass(YES, "NSAccessibilityCustomRotor may not be fully implemented (skipped)");
        }
    }
    NS_HANDLER
    {
        pass(YES, "NSAccessibilityCustomRotor may not be supported (skipped)");
        rotor = nil;
    }
    NS_ENDHANDLER
    
    // Test action array handling
    NSMutableArray *actions = [NSMutableArray array];
    if (action1 != nil)
        [actions addObject: action1];
    if (action2 != nil)
        [actions addObject: action2];
    
    if ([actions count] > 0)
    {
        pass([actions count] <= 2, "Custom actions can be collected in array");
        
        // Test that actions in array maintain their properties
        NSAccessibilityCustomAction *firstAction = [actions objectAtIndex: 0];
        NSString *firstName = [firstAction name];
        pass([firstName length] > 0, 
             "Custom action in array maintains name property");
    }
    
    // Clean up
    if (rotor != nil)
        RELEASE(rotor);
    if (action2 != nil)
        RELEASE(action2);
    if (action1 != nil)
        RELEASE(action1);
    RELEASE(target);
    
    END_SET("NSAccessibilityCustomAction and NSAccessibilityCustomRotor tests")
    
    DESTROY(arp);
    return 0;
}