/** <title>CGBase</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Jan 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#ifndef OPAL_CGBase_h
#define OPAL_CGBase_h

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

// for off_t
#include <sys/types.h>

// Note: GNUstep Foundation defines CGFloat

#import <Foundation/Foundation.h>

#ifndef MAX
#define MAX(a,b) ((a)>(b)?(a):(b))
#endif

#ifndef MIN
#define MIN(a,b) ((a)<(b)?(a):(b))
#endif
 
/* Typedefs for CoreFoundation types */

typedef signed long CFIndex;
typedef unsigned long CFTypeID;
typedef NSRange CFRange;
typedef NSComparisonResult CFComparisonResult;

#ifdef __OBJC__
@class NSObject;
typedef NSObject *CFTypeRef;
#else
typedef struct NSObject * CFTypeRef;
#endif

#ifdef __OBJC__
@class NSString;
@class NSMutableString;
typedef NSString* CFStringRef;
typedef NSMutableString* CFMutableStringRef;
#else
typedef const struct __CFString * CFStringRef;
typedef struct __CFString * CFMutableStringRef;
#endif

#ifdef __OBJC__
@class NSAttributedString;
@class NSMutableAttributedString;
typedef NSAttributedString* CFAttributedStringRef;
typedef NSMutableAttributedString* CFMutableAttributedStringRef;
#else
typedef struct CFAttributedString * CFAttributedStringRef;
typedef struct CFMutableAttributedString * CFMutableAttributedStringRef;
#endif

#ifdef __OBJC__
@class NSArray;
@class NSMutableArray;
typedef NSArray* CFArrayRef;
typedef NSMutableArray* CFMutableArrayRef;
#else
typedef struct CFArray *CFArrayRef;
typedef struct CFArray *CFMutableArrayRef;
#endif

#ifdef __OBJC__
@class NSCharacterSet;
typedef NSCharacterSet* CFCharacterSetRef;
#else
typedef struct CFCharacterSet * CFCharacterSetRef;
#endif

#ifdef __OBJC__
@class NSData;
@class NSMutableData;
typedef NSData* CFDataRef;
typedef NSMutableData* CFMutableDataRef;
#else
typedef struct CFData *CFDataRef;
typedef struct CFMutableData *CFMutableDataRef;
#endif

#ifdef __OBJC__
@class NSDate;
@class NSTimeZone;
typedef NSDate* CFDateRef;
typedef NSTimeZone* CFTimeZoneRef;
#else
typedef struct CFDate *CFDateRef;
typedef struct CFTimeZone *CFTimeZoneRef;
#endif

#ifdef __OBJC__
@class NSDictionary;
@class NSMutableDictionary;
typedef NSDictionary* CFDictionaryRef;
typedef NSMutableDictionary* CFMutableDictionaryRef;
#else
typedef struct CFDictionary * CFDictionaryRef;
typedef struct CFMutableDictionary * CFMutableDictionaryRef;
#endif

#ifdef __OBJC__
@class NSError;
typedef NSError* CFErrorRef;
#else
typedef struct CFError *CFErrorRef;
#endif

#ifdef __OBJC__
@class NSNumber;
typedef NSNumber* CFNumberRef;
#else
typedef struct NSNumber * CFNumberRef;
#endif

#ifdef __OBJC__
@class NSSet;
@class NSMutableSet;
typedef NSSet* CFSetRef;
typedef NSMutableSet* CFMutableSetRef;
#else
typedef struct CFSet * CFSetRef;
typedef struct CFMutableSet * CFMutableSetRef;
#endif

#ifdef __OBJC__
@class NSURL;
typedef NSURL *CFURLRef;
#else
typedef struct CFURL *CFURLRef;
#endif

#endif /* OPAL_CGBase_h */

