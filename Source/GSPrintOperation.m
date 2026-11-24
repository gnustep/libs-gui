/* 
   GSPrintOperation.m

   Controls operations generating print jobs.

   Copyright (C) 1996,2004 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: November 2000
   Started implementation.
   Author: Chad Hardin <cehardin@mac.com>
   Date: June 2004
   Modified for printing backend support, split off from NSPrintOperation.m

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>
#import "AppKit/NSPrintPanel.h"
#import "AppKit/NSPrintInfo.h"
#import "AppKit/NSView.h"
#import "AppKit/NSWorkspace.h"
#import "GNUstepGUI/GSPrinting.h"
#import "GNUstepGUI/GSPrintOperation.h"
#import "GSGuiPrivate.h"



/**
  <unit>
  <heading>Class Description</heading>
  <p>
  GSPrintOperation is a generic class that should be subclasses
  by printing backend classes for the purpose of controlling and
  sending print jobs to a printing system.
  </p>
  </unit>
*/ 




/* A command-line previewer owns a lease independent of the print operation.
   The observation retain is released on termination or a failed launch. */
@interface GSPrintPreviewFile : NSObject
{
  NSString *path;
  NSTask *task;
  NSLock *lock;
  BOOL observing;
}

- (id) initWithTask: (NSTask *)aTask path: (NSString *)aPath;
- (void) startObserving;
- (void) invalidate;

@end

@implementation GSPrintPreviewFile

- (id) initWithTask: (NSTask *)aTask path: (NSString *)aPath
{
  self = [super init];
  if (self != nil)
    {
      ASSIGNCOPY(path, aPath);
      ASSIGN(task, aTask);
      lock = [[NSLock alloc] init];
    }
  return self;
}

/* The caller must start observation before launching the task. This retain
   keeps the lease alive after the caller releases its allocation ownership;
   invalidate balances it on termination or a failed launch. */
- (void) startObserving
{
  [lock lock];
  if (!observing)
    {
      observing = YES;
      RETAIN(self);
      [[NSNotificationCenter defaultCenter] addObserver: self
        selector: @selector(taskFinished:) name: NSTaskDidTerminateNotification object: task];
    }
  [lock unlock];
}

- (void) invalidate
{
  BOOL wasObserving;

  [lock lock];
  wasObserving = observing;
  observing = NO;
  [lock unlock];
  if (wasObserving)
    {
      [[NSNotificationCenter defaultCenter] removeObserver: self];
      RELEASE(self);
    }
}

- (void) taskFinished: (NSNotification *)notification
{
  RETAIN(self);
  NS_DURING
    {
      NSFileManager *manager = [NSFileManager defaultManager];
      if ([manager fileExistsAtPath: path]
          && ![manager removeFileAtPath: path handler: nil])
        NSLog(@"Could not remove print preview %@", path);
    }
  NS_HANDLER
    {
      NSLog(@"Could not remove print preview %@: %@", path, localException);
    }
  NS_ENDHANDLER
  [self invalidate];
  RELEASE(self);
}

- (void) dealloc
{
  RELEASE(path);
  RELEASE(task);
  RELEASE(lock);
  DEALLOC;
}

@end

@implementation GSPrintOperation

/** Load the appropriate bundle for the PrintInfo
    (eg: GSLPRPrintInfo, GSCUPSPrintInfo).
*/
+ (id) allocWithZone: (NSZone*) zone
{
  Class principalClass;

  principalClass = [[GSPrinting printingBundle] principalClass];

  if (principalClass == nil)
    return nil;
	
  return [[principalClass gsPrintOperationClass] allocWithZone: zone];
}



- (id)initWithView:(NSView *)aView
         printInfo:(NSPrintInfo *)aPrintInfo
{
      
  self = [self initWithView: aView
                 insideRect: [aView bounds]
                     toData: [NSMutableData data]
                  printInfo: aPrintInfo];
  if (self == nil)
    return nil;
  [self _setTemporaryOutputFileWithExtension: @"ps"];
  [self setShowPanels: YES];

  return self;
}

- (NSGraphicsContext*)createContext
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (BOOL) _prepareOutputFile
{
  if ([[[self printInfo] jobDisposition] isEqual: NSPrintSaveJob])
    {
      id output = [[[self printInfo] dictionary] objectForKey: NSPrintSavePath];

      if (![output isKindOfClass: [NSString class]] || [output length] == 0)
        return NO;
      [self _setOutputFile: output temporary: NO];
    }
  else if (!_flags.owns_output_file || _path == nil)
    [self _setTemporaryOutputFileWithExtension: @"ps"];
  return YES;
}


/**
/ !!!Here is the method that will be overridden in the printer bundle
*/
- (BOOL) _deliverSpooledResult
{
  [self subclassResponsibility: _cmd];
  return NO;
}


- (BOOL) deliverResult
{
  BOOL success;
  NSString *job;
  
  success = NO;
  job = [[self printInfo] jobDisposition];
  if ([job isEqual: NSPrintPreviewJob] && ![NSThread isMainThread])
    {
      NSMutableDictionary *result = [NSMutableDictionary dictionary];
      [self performSelectorOnMainThread: @selector(_deliverPreviewOnMainThread:)
                             withObject: result waitUntilDone: YES];
      return [[result objectForKey: @"success"] boolValue];
    }
  if ([job isEqual: NSPrintPreviewJob])
    {
      /* Check to see if there is a GNUstep app that can preview PS files.
	       It's not likely at this point, so also check for a standards
	       previewer, like gv.
      */
      NSTask *task;
      NSString *preview;
      NSWorkspace *ws = [NSWorkspace sharedWorkspace];
      [[self printPanel] _setStatusStringValue: @"Opening in previewer..."];
      
      preview = [ws getBestAppInRole: @"Viewer" 
                        forExtension: [_path pathExtension]];
      if (preview)
        {
          /* openTempFile: deletes the source as soon as the receiving
             application's open-file handler returns. Viewers such as GSPdf
             still need it for asynchronous rendering and subsequent pages.
             Workspace provides no document-close notification, so leave a
             successful preview in the temporary directory for the viewer. */
          success = [ws openFile: _path withApplication: preview];
          if (success)
            _flags.owns_output_file = NO;
          if (success == NO)
            {
              NSString *status = [NSString stringWithFormat:
                _(@"Could not open the print preview with %@."), preview];
              [[self printPanel] _setStatusStringValue: status];
              NSLog(@"%@", status);
            }
        }
      else
        {
          NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
          GSPrintPreviewFile *lease = nil;
          preview = [def objectForKey: @"NSPreviewApp"];
          
	  if (preview == nil || [preview length] == 0)
	    preview = @"gv";
            
          task = AUTORELEASE([[NSTask alloc] init]);
          [task setLaunchPath: preview];
          [task setArguments: [NSArray arrayWithObject: _path]];
          if (_flags.owns_output_file)
            lease = [[GSPrintPreviewFile alloc] initWithTask: task path: _path];
	  NS_DURING
	    {
              [lease startObserving];
	      [task launch];
              /* Previewers run asynchronously; success means launched. */
              success = YES;
              if (lease != nil)
                _flags.owns_output_file = NO;
	    }
	  NS_HANDLER
	    {
              success = NO;
              [lease invalidate];
	      NSRunAlertPanel(_(@"Preview"),
_(@"Problem running the preview application '%@' perhaps you need to set your NSPreviewApp user default"),
		_(@"Dismiss"), nil, nil, preview);
	    }
	  NS_ENDHANDLER
          RELEASE(lease);
        }
    }
  else if ([job isEqual: NSPrintSpoolJob])
    {
      success = [self _deliverSpooledResult];
    }
  else if ([job isEqual: NSPrintSaveJob])
    {
      /* The graphics context has already written the output file. */
      success = YES;
    }
  else if ([job isEqual: NSPrintCancelJob] == NO)
    {
      NSString *status = [NSString stringWithFormat:
        _(@"Unsupported print job disposition: %@."), job];
      [[self printPanel] _setStatusStringValue: status];
      NSLog(@"%@", status);
    }

  /* Synchronous spoolers have consumed the file when they return. Successful
     previews have transferred ownership; explicit save paths are never ours. */
  [self _removeTemporaryOutputFile];
  return success;
}

- (void) _deliverPreviewOnMainThread: (NSMutableDictionary *)result
{
  [result setObject: [NSNumber numberWithBool: [self deliverResult]]
            forKey: @"success"];
}

@end

