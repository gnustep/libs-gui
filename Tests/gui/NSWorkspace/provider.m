/* Copyright (C) 2026 Free Software Foundation, Inc.
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3, or (at your option) any later version.
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See <https://www.gnu.org/licenses/> for the GNU General Public License.
 */

#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/NSWorkspace.h>

/* Deliberately partial: discovery must not require formal conformance. */
@interface Provider : NSObject

- (BOOL) selectFile: (NSString*)path inFileViewerRootedAtPath: (NSString*)root;
- (BOOL) performFileOperation: (NSString*)operation
                      source: (NSString*)source
                 destination: (NSString*)destination
                       files: (NSArray*)files
                         tag: (inout NSInteger*)tag;

@end

@implementation Provider

- (BOOL) selectFile: (NSString*)path inFileViewerRootedAtPath: (NSString*)root
{
  if ([path isEqual: @"recurse"])
    {
      return ![[NSWorkspace sharedWorkspace] selectFile: path
        inFileViewerRootedAtPath: root];
    }
  return [path isEqual: @"selected"] && [root isEqual: @"root"];
}

- (BOOL) performFileOperation: (NSString*)operation
                      source: (NSString*)source
                 destination: (NSString*)destination
                       files: (NSArray*)files
                         tag: (inout NSInteger*)tag
{
  *tag = 42;
  return [operation isEqual: @"test"] && [files count] == 1;
}

@end

static NSTask *
Start(NSString *mode, NSString *session, NSString *directory)
{
  NSTask *task = AUTORELEASE([[NSTask alloc] init]);
  NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:
    [[NSProcessInfo processInfo] environment]];
  NSString *executable = [[[NSProcessInfo processInfo] arguments] objectAtIndex: 0];

  if (![executable isAbsolutePath])
    {
      executable = [[[NSFileManager defaultManager] currentDirectoryPath]
        stringByAppendingPathComponent: executable];
    }
  [env setObject: session forKey: @"XDG_SESSION_ID"];
  [task setEnvironment: env];
  [task setLaunchPath: executable];
  [task setArguments: [NSArray arrayWithObjects: mode, directory, nil]];
  [task launch];
  return task;
}

static BOOL
WaitForFile(NSString *path)
{
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 15];

  while (![[NSFileManager defaultManager] fileExistsAtPath: path])
    {
      if ([deadline timeIntervalSinceNow] <= 0)
        {
          return NO;
        }
      [NSThread sleepForTimeInterval: 0.05];
    }
  return YES;
}

static BOOL
Run(NSString *mode, NSString *session, NSString *directory)
{
  NSTask *task = Start(mode, session, directory);
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 20];

  while ([task isRunning] && [deadline timeIntervalSinceNow] > 0)
    {
      [NSThread sleepForTimeInterval: 0.05];
    }
  if ([task isRunning])
    {
      [task terminate];
      [task waitUntilExit];
      return NO;
    }
  return [task terminationStatus] == 0;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSArray *args = [[NSProcessInfo processInfo] arguments];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *mode = argc > 1 ? [args objectAtIndex: 1] : nil;

  [[NSUserDefaults standardUserDefaults] setVolatileDomain:
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"YES", @"GSLogWorkspaceTimeout",
      @"NonexistentWorkspace", @"GSWorkspaceApplication", nil]
    forName: NSArgumentDomain];
  if (mode != nil)
    {
      NSString *directory = [args objectAtIndex: 2];
      Provider *provider = AUTORELEASE([[Provider alloc] init]);
      NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
      BOOL ok = YES;

      if ([mode isEqual: @"server"])
        {
          NSObject *other = AUTORELEASE([[NSObject alloc] init]);
          ok = ![NSWorkspace registerWorkspaceProvider: nil]
            && [NSWorkspace registerWorkspaceProvider: provider]
            && ![NSWorkspace registerWorkspaceProvider: provider]
            && ![NSWorkspace unregisterWorkspaceProvider: other]
            && ![workspace selectFile: @"selected" inFileViewerRootedAtPath: @"root"];
          if (!ok)
            {
              return 1;
            }
          [@"ready" writeToFile: [directory stringByAppendingPathComponent: @"ready"]
            atomically: YES];
          while (![fm fileExistsAtPath: [directory stringByAppendingPathComponent: @"stop"]])
            {
              [[NSRunLoop currentRunLoop] runUntilDate:
                [NSDate dateWithTimeIntervalSinceNow: 0.05]];
            }
          ok = [NSWorkspace unregisterWorkspaceProvider: provider]
            && ![NSWorkspace unregisterWorkspaceProvider: provider]
            && [NSWorkspace registerWorkspaceProvider: provider]
            && [NSWorkspace unregisterWorkspaceProvider: provider];
        }
      else if ([mode isEqual: @"client"])
        {
          NSInteger tag = 0;
#define CHECK(expression) do { BOOL result = (expression); \
  if (!result) fprintf(stderr, "Failed client check: %s\n", #expression); \
  ok = ok && result; } while (0)
          CHECK(![NSWorkspace registerWorkspaceProvider: provider]);
          CHECK(![NSWorkspace unregisterWorkspaceProvider: provider]);
          CHECK([workspace selectFile: @"selected" inFileViewerRootedAtPath: @"root"]);
          CHECK([workspace selectFile: @"recurse" inFileViewerRootedAtPath: @"root"]);
          CHECK([workspace extendPowerOffBy: 100] == 0);
          CHECK([workspace performFileOperation: @"test" source: @"source"
            destination: @"destination" files: [NSArray arrayWithObject: @"file"]
            tag: &tag]);
          CHECK(tag == 42);
#undef CHECK
        }
      else if ([mode isEqual: @"reconnect"])
        {
          NSString *session = [[[NSProcessInfo processInfo] environment]
            objectForKey: @"XDG_SESSION_ID"];
          NSString *ready = [directory stringByAppendingPathComponent: @"ready"];
          NSTask *server;

          [fm removeItemAtPath: ready error: NULL];
          server = Start(@"server", session, directory);
          ok = WaitForFile(ready)
            && [workspace selectFile: @"selected" inFileViewerRootedAtPath: @"root"];
          [server terminate];
          [server waitUntilExit];
          ok = ![workspace selectFile: @"selected" inFileViewerRootedAtPath: @"root"] && ok;
          [fm removeItemAtPath: ready error: NULL];
          server = Start(@"server", session, directory);
          ok = WaitForFile(ready) && ok;
          ok = [workspace selectFile: @"selected" inFileViewerRootedAtPath: @"root"] && ok;
          [server terminate];
          [server waitUntilExit];
        }
      else if ([mode isEqual: @"absent"])
        {
          ok = ![workspace selectFile: @"selected" inFileViewerRootedAtPath: @"root"]
            && [NSWorkspace registerWorkspaceProvider: provider]
            && [NSWorkspace unregisterWorkspaceProvider: provider];
        }
      RELEASE(pool);
      return ok ? 0 : 1;
    }

  {
    NSString *session = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent: session];
    NSString *ready = [directory stringByAppendingPathComponent: @"ready"];
    NSString *stop = [directory stringByAppendingPathComponent: @"stop"];
    NSTask *server;

    [fm createDirectoryAtPath: directory withIntermediateDirectories: YES
      attributes: nil error: NULL];
    PASS(Run(@"absent", session, directory), "no provider uses fallback and permits registration");
    server = Start(@"server", session, directory);
    PASS(WaitForFile(ready), "provider registers exclusively and avoids local recursion");
    PASS(Run(@"client", session, directory), "DO discovery, arguments, output tag, capabilities and ownership work");
    PASS(Run(@"absent", [session stringByAppendingString: @"-other"], directory),
      "another desktop session has an independent role");
    [@"stop" writeToFile: stop atomically: YES];
    [server waitUntilExit];
    PASS([server terminationStatus] == 0, "owner can relinquish and reacquire the role");
    PASS(Run(@"absent", session, directory), "released role is available to another process");
    [fm removeItemAtPath: ready error: NULL];
    [fm removeItemAtPath: stop error: NULL];
    server = Start(@"server", session, directory);
    PASS(WaitForFile(ready), "replacement provider starts");
    [server terminate];
    [server waitUntilExit];
    PASS(Run(@"absent", session, directory), "provider death permits fallback and replacement");
    PASS(Run(@"reconnect", session, directory),
      "an existing client reconnects after provider death and replacement");
    [fm removeItemAtPath: directory error: NULL];
  }
  RELEASE(pool);
  return 0;
}

