/* 
   NSDPSContext.m

   Encapsulation of Display Postscript contexts

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <Foundation/NSThread.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <gnustep/dps/NSDPSContext.h>

//
// DPS exceptions
//
NSString *DPSPostscriptErrorException = @"DPSPostscriptErrorException";
NSString *DPSNameTooLongException = @"DPSNameTooLongException";
NSString *DPSResultTagCheckException = @"DPSResultTagCheckException";
NSString *DPSResultTypeCheckException = @"DPSResultTypeCheckException";
NSString *DPSInvalidContextException = @"DPSInvalidContextException";
NSString *DPSSelectException = @"DPSSelectException";
NSString *DPSConnectionClosedException = @"DPSConnectionClosedException";
NSString *DPSReadException = @"DPSReadException";
NSString *DPSWriteException = @"DPSWriteException";
NSString *DPSInvalidFDException = @"DPSInvalidFDException";
NSString *DPSInvalidTEException = @"DPSInvalidTEException";
NSString *DPSInvalidPortException = @"DPSInvalidPortException";
NSString *DPSOutOfMemoryException = @"DPSOutOfMemoryException";
NSString *DPSCantConnectException = @"DPSCantConnectException";

//
// Class variables
//
static NSMutableDictionary *GNU_CONTEXT_THREAD_DICT = nil;
static NSRecursiveLock *GNU_CONTEXT_LOCK = nil;
static BOOL GNU_CONTEXT_TRACED = NO;
static BOOL GNU_CONTEXT_SYNCHRONIZED = NO;

@implementation NSDPSContext

+ (void)initialize
{
  if (self == [NSDPSContext class])
    {
      // Set initial version
      [self setVersion: 1];

      // Allocate dictionary for maintaining
      // mapping of threads to contexts
     GNU_CONTEXT_THREAD_DICT = [NSMutableDictionary dictionary];
     // Create lock for serializing access to dictionary
     GNU_CONTEXT_LOCK = [[NSRecursiveLock alloc] init];

     GNU_CONTEXT_TRACED = NO;
     GNU_CONTEXT_SYNCHRONIZED = NO;
    }
}

//
// Initializing a Context
//
- init
{
  NSMutableData *data = [NSMutableData data];

  return [self initWithMutableData: data
	       forDebugging: NO
	       languageEncoding: dps_ascii
	       nameEncoding: dps_strings
	       textProc: NULL
	       errorProc: NULL];
}

// Default initializer
- initWithMutableData:(NSMutableData *)data
	 forDebugging:(BOOL)debug
     languageEncoding:(DPSProgramEncoding)langEnc
	 nameEncoding:(DPSNameEncoding)nameEnc
	     textProc:(DPSTextProc)tProc
	    errorProc:(DPSErrorProc)errorProc
{
  [super init];
  context_data = data;
  is_screen_context = YES;
  error_proc = errorProc;
  text_proc = tProc;
  chained_parent = nil;
  chained_child = nil;

  return self;
}

//
// Testing the Drawing Destination
//
- (BOOL)isDrawingToScreen
{
  return is_screen_context;
}

//
// Accessing Context Data
//
- (NSMutableData *)mutableData
{
  return context_data;
}

//
// Setting and Identifying the Current Context
//
+ (NSDPSContext *)currentContext
{
  NSThread *current_thread;
  NSDPSContext *current_context = nil;

  current_thread = [NSThread currentThread];

  // Get current context for current thread
  [GNU_CONTEXT_LOCK lock];

  current_context = [GNU_CONTEXT_THREAD_DICT objectForKey: current_thread];

  // If not in dictionary then create one
  if (!current_context)
    {
      current_context = [[NSDPSContext alloc] init];
      [self setCurrentContext: current_context];
    }
  [GNU_CONTEXT_LOCK unlock];

  return current_context;
}

+ (void)setCurrentContext:(NSDPSContext *)context
{
  NSThread *current_thread = [NSThread currentThread];

  [GNU_CONTEXT_LOCK lock];

  // If no context then remove from dictionary
  if (!context)
    {
      [GNU_CONTEXT_THREAD_DICT removeObjectForKey: current_thread];
    }
  else
    {
      [GNU_CONTEXT_THREAD_DICT setObject: context 
			       forKey: current_thread];
    }

  [GNU_CONTEXT_LOCK unlock];
}

- (NSDPSContext *)DPSContext
{
  return self;
}

//
// Controlling the Context
//
- (void)flush
{}

- (void)interruptExecution
{}

- (void)notifyObjectWhenFinishedExecuting:(id <NSDPSContextNotification>)obj
{}

- (void)resetCommunication
{}

- (void)wait
{}

//
// Managing Returned Text and Errors
//
+ (NSString *)stringForDPSError:(const DPSBinObjSeqRec *)error
{
  return nil;
}

- (DPSErrorProc)errorProc
{
  return error_proc;
}

- (void)setErrorProc:(DPSErrorProc)proc
{
  error_proc = proc;
}

- (void)setTextProc:(DPSTextProc)proc
{
  text_proc = proc;
}

- (DPSTextProc)textProc
{
  return text_proc;
}

//
// Sending Raw Data
//
- (void)printFormat:(NSString *)format,...
{}

- (void)printFormat:(NSString *)format arguments:(va_list)argList
{}

- (void)writeData:(NSData *)buf
{}

- (void)writePostScriptWithLanguageEncodingConversion:(NSData *)buf
{}

//
// Managing Binary Object Sequences
//
- (void)awaitReturnValues
{}

- (void)writeBOSArray:(const void *)data
		count:(unsigned int)items
	       ofType:(DPSDefinedType)type
{}

- (void)writeBOSNumString:(const void *)data
		   length:(unsigned int)count
		   ofType:(DPSDefinedType)type
		    scale:(int)scale
{}

- (void)writeBOSString:(const void *)data
		length:(unsigned int)bytes
{}

- (void)writeBinaryObjectSequence:(const void *)data
			   length:(unsigned int)bytes
{}

- (void)updateNameMap
{}

//
// Managing Chained Contexts
//
- (void)setParentContext:(NSDPSContext *)parent
{
  chained_parent = parent;
}

- (void)chainChildContext:(NSDPSContext *)child
{
  if (child)
    {
      chained_child = child;
      [child setParentContext: self];
    }
}

- (NSDPSContext *)childContext
{
  return chained_child;
}

- (NSDPSContext *)parentContext
{
  return chained_parent;
}

- (void)unchainContext
{
  if (chained_child)
    {
      [chained_child setParentContext: nil];
      chained_child = nil;
    }
}

//
// Debugging Aids
//
+ (BOOL)areAllContextsOutputTraced
{
  return GNU_CONTEXT_TRACED;
}

+ (BOOL)areAllContextsSynchronized
{
  return GNU_CONTEXT_SYNCHRONIZED;
}

+ (void)setAllContextsOutputTraced:(BOOL)flag
{
  GNU_CONTEXT_TRACED = flag;
}

+ (void)setAllContextsSynchronized:(BOOL)flag
{
  GNU_CONTEXT_SYNCHRONIZED = flag;
}

- (BOOL)isOutputTraced
{
  return is_output_traced;
}

- (BOOL)isSynchronized
{
  return is_synchronized;
}

- (void)setOutputTraced:(BOOL)flag
{
  is_output_traced = flag;
}

- (void)setSynchronized:(BOOL)flag
{
  is_synchronized = flag;
}

@end
