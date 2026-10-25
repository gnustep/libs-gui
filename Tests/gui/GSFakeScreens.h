#ifndef GSFakeScreens_h
#define GSFakeScreens_h

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>

@interface GSFakeScreens : NSProxy
{
  id _server;
  NSArray *_frames;
  NSArray *_resolutions;
}
+ (GSFakeScreens *) installWithFrames: (NSArray *)frames
                          resolutions: (NSArray *)resolutions;
- (void) uninstall;
@end

@implementation GSFakeScreens

+ (GSFakeScreens *) installWithFrames: (NSArray *)frames
                          resolutions: (NSArray *)resolutions
{
  GSFakeScreens *fake = [GSFakeScreens alloc];

  fake->_server = [GSCurrentServer() retain];
  fake->_frames = [frames retain];
  fake->_resolutions = [resolutions retain];
  [GSDisplayServer setCurrentServer: (GSDisplayServer *)fake];
  [NSScreen resetScreens];
  return [fake autorelease];
}

- (void) uninstall
{
  [GSDisplayServer setCurrentServer: _server];
  [NSScreen resetScreens];
}

- (void) dealloc
{
  [_server release];
  [_frames release];
  [_resolutions release];
  [super dealloc];
}

- (NSArray *) screenList
{
  NSMutableArray *list = [NSMutableArray array];
  NSUInteger i;

  for (i = 0; i < [_frames count]; i++)
    {
      [list addObject: [NSNumber numberWithInt: (int)i]];
    }
  return list;
}

- (NSRect) boundsForScreen: (int)screen
{
  return [[_frames objectAtIndex: screen] rectValue];
}

- (NSSize) resolutionForScreen: (int)screen
{
  CGFloat dpi = [[_resolutions objectAtIndex: screen] doubleValue];

  return NSMakeSize(dpi, dpi);
}

- (NSWindowDepth) windowDepthForScreen: (int)screen
{
  return [_server windowDepthForScreen: 0];
}

- (const NSWindowDepth *) availableDepthsForScreen: (int)screen
{
  return [_server availableDepthsForScreen: 0];
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)aSelector
{
  return [_server methodSignatureForSelector: aSelector];
}

- (void) forwardInvocation: (NSInvocation *)anInvocation
{
  [anInvocation invokeWithTarget: _server];
}

@end

static inline void
GSSetScaleFactorArgument(NSString *value)
{
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary *args = [[[defs volatileDomainForName: NSArgumentDomain]
                                 mutableCopy] autorelease];

  if (args == nil)
    {
      args = [NSMutableDictionary dictionary];
    }
  if (value == nil)
    {
      [args removeObjectForKey: @"GSScaleFactor"];
    }
  else
    {
      [args setObject: value forKey: @"GSScaleFactor"];
    }
  [defs removeVolatileDomainForName: NSArgumentDomain];
  [defs setVolatileDomain: args forName: NSArgumentDomain];
}

#endif
