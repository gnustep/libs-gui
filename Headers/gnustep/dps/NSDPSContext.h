/* 
   NSDPSContext.h

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
   If not, write to the Free Software Foundation, Inc.,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSDPSContext
#define _GNUstep_H_NSDPSContext

#include <DPSClient/TypesandConstants.h>
#include <DPSClient/DPSOperators.h>
#include <Foundation/NSObject.h>

@class NSData;
@class NSMutableData;

//
// NSDPSContextNotification
// Circular dependency between protocol and class
//
@class NSDPSContext;
@protocol NSDPSContextNotification

//
// Synchronizing Application and Display Postscript Server Execution
//
- (void)contextFinishedExecuting:(NSDPSContext *)context;

@end

//
// NSDPSContext class interface
//
@interface NSDPSContext : NSObject
{
  // Attributes
  NSMutableData *context_data;
  BOOL is_screen_context;
  DPSErrorProc error_proc;
  DPSTextProc text_proc;
  NSDPSContext *chained_parent;
  NSDPSContext *chained_child;
  BOOL is_output_traced;
  BOOL is_synchronized;

  // Reserverd for back-end use
  void *be_context_reserved;
}

//
// Initializing a Context
//
- initWithMutableData:(NSMutableData *)data
	 forDebugging:(BOOL)debug
     languageEncoding:(DPSProgramEncoding)langEnc
	 nameEncoding:(DPSNameEncoding)nameEnc
	     textProc:(DPSTextProc)tProc
	    errorProc:(DPSErrorProc)errorProc;

//
// Testing the Drawing Destination
//
- (BOOL)isDrawingToScreen;

//
// Accessing Context Data
//
- (NSMutableData *)mutableData;

//
// Setting and Identifying the Current Context
//
+ (NSDPSContext *)currentContext;
+ (void)setCurrentContext:(NSDPSContext *)context;
- (NSDPSContext *)DPSContext;

//
// Controlling the Context
//
- (void)flush;
- (void)interruptExecution;
- (void)notifyObjectWhenFinishedExecuting:(id <NSDPSContextNotification>)obj;
- (void)resetCommunication;
- (void)wait;

//
// Managing Returned Text and Errors
//
+ (NSString *)stringForDPSError:(const DPSBinObjSeqRec *)error;
- (DPSErrorProc)errorProc;
- (void)setErrorProc:(DPSErrorProc)proc;
- (void)setTextProc:(DPSTextProc)proc;
- (DPSTextProc)textProc;

//
// Sending Raw Data
//
- (void)printFormat:(NSString *)format,...;
- (void)printFormat:(NSString *)format arguments:(va_list)argList;
- (void)writeData:(NSData *)buf;
- (void)writePostScriptWithLanguageEncodingConversion:(NSData *)buf;

//
// Managing Binary Object Sequences
//
- (void)awaitReturnValues;
- (void)writeBOSArray:(const void *)data
		count:(unsigned int)items
	       ofType:(DPSDefinedType)type;
- (void)writeBOSNumString:(const void *)data
		   length:(unsigned int)count
		   ofType:(DPSDefinedType)type
		    scale:(int)scale;
- (void)writeBOSString:(const void *)data
		length:(unsigned int)bytes;
- (void)writeBinaryObjectSequence:(const void *)data
			   length:(unsigned int)bytes;
- (void)updateNameMap;

//
// Managing Chained Contexts
//
- (void)chainChildContext:(NSDPSContext *)child;
- (NSDPSContext *)childContext;
- (NSDPSContext *)parentContext;
- (void)unchainContext;

//
// Debugging Aids
//
+ (BOOL)areAllContextsOutputTraced;
+ (BOOL)areAllContextsSynchronized;
+ (void)setAllContextsOutputTraced:(BOOL)flag;
+ (void)setAllContextsSynchronized:(BOOL)flag;
- (BOOL)isOutputTraced;
- (BOOL)isSynchronized;
- (void)setOutputTraced:(BOOL)flag;
- (void)setSynchronized:(BOOL)flag;

@end

#endif /* _GNUstep_H_NSDPSContext */
