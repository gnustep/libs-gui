/* Interface of class NSLayoutConstraint
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory Casamento <greg.casamento@gmail.com>
   Date: Sat May  9 16:30:22 EDT 2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#ifndef _NSLayoutConstraint_h_GNUSTEP_GUI_INCLUDE
#define _NSLayoutConstraint_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSLayoutAnchor.h>

@class NSControl, NSView, NSAnimation, NSArray, NSDictionary;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

// Priority
typedef float NSLayoutPriority;
static const NSLayoutPriority NSLayoutPriorityRequired = 1000;
static const NSLayoutPriority NSLayoutPriorityDefaultHigh = 750;
static const NSLayoutPriority NSLayoutPriorityDragThatCanResizeWindow = 510;
static const NSLayoutPriority NSLayoutPriorityWindowSizeStayPut = 500; 
static const NSLayoutPriority NSLayoutPriorityDragThatCannotResizeWindow = 490;
static const NSLayoutPriority NSLayoutPriorityDefaultLow = 250; 
static const NSLayoutPriority NSLayoutPriorityFittingSizeCompression = 50; 

// Orientation
enum {
    NSLayoutConstraintOrientationHorizontal = 0,
    NSLayoutConstraintOrientationVertical = 1
};
typedef NSInteger NSLayoutConstraintOrientation;


// Attributes
enum {
    NSLayoutAttributeLeft = 1,
    NSLayoutAttributeRight,
    NSLayoutAttributeTop,
    NSLayoutAttributeBottom,
    NSLayoutAttributeLeading,
    NSLayoutAttributeTrailing,
    NSLayoutAttributeWidth,
    NSLayoutAttributeHeight,
    NSLayoutAttributeCenterX,
    NSLayoutAttributeCenterY,
    NSLayoutAttributeLastBaseline,
    NSLayoutAttributeBaseline = NSLayoutAttributeLastBaseline,
    NSLayoutAttributeFirstBaseline, 
    NSLayoutAttributeNotAnAttribute = 0
};
typedef NSInteger NSLayoutAttribute;

// Relation
enum {
    NSLayoutRelationLessThanOrEqual = -1,
    NSLayoutRelationEqual = 0,
    NSLayoutRelationGreaterThanOrEqual = 1,
};
typedef NSInteger NSLayoutRelation;
  
// Options
enum {
    NSLayoutFormatAlignAllLeft = (1 << NSLayoutAttributeLeft),
    NSLayoutFormatAlignAllRight = (1 << NSLayoutAttributeRight),
    NSLayoutFormatAlignAllTop = (1 << NSLayoutAttributeTop),
    NSLayoutFormatAlignAllBottom = (1 << NSLayoutAttributeBottom),
    NSLayoutFormatAlignAllLeading = (1 << NSLayoutAttributeLeading),
    NSLayoutFormatAlignAllTrailing = (1 << NSLayoutAttributeTrailing),
    NSLayoutFormatAlignAllCenterX = (1 << NSLayoutAttributeCenterX),
    NSLayoutFormatAlignAllCenterY = (1 << NSLayoutAttributeCenterY),
    NSLayoutFormatAlignAllLastBaseline = (1 << NSLayoutAttributeLastBaseline),
    NSLayoutFormatAlignAllFirstBaseline = (1 << NSLayoutAttributeFirstBaseline),
    NSLayoutFormatAlignAllBaseline = NSLayoutFormatAlignAllLastBaseline,
    NSLayoutFormatAlignmentMask = 0xFFFF,
    NSLayoutFormatDirectionLeadingToTrailing = 0 << 16, // default
    NSLayoutFormatDirectionLeftToRight = 1 << 16,
    NSLayoutFormatDirectionRightToLeft = 2 << 16,    
    NSLayoutFormatDirectionMask = 0x3 << 16,
};
typedef NSUInteger NSLayoutFormatOptions;
  
@interface NSLayoutConstraint : NSObject

+ (NSArray *)constraintsWithVisualFormat: (NSString *)fmt 
                                 options: (NSLayoutFormatOptions)opt 
                                 metrics: (NSDictionary *)metrics 
                                   views: (NSDictionary *)views;

+ (instancetype) constraintWithItem: (id)view1 
                          attribute: (NSLayoutAttribute)attr1 
                          relatedBy: (NSLayoutRelation)relation 
                             toItem: (id)view2 
                          attribute: (NSLayoutAttribute)attr2 
                         multiplier: (CGFloat)mult 
                           constant: (CGFloat)c;


@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSLayoutConstraint_h_GNUSTEP_GUI_INCLUDE */

