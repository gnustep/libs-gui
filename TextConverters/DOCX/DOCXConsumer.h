/* docxConsumer.h created by gcasa Feb-2025

   Copyright (C) 2025 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg.casamento@gmail.com>
   Date: Feb 2025

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

#ifndef _docxConsumer_h_INCLUDE
#define _docxConsumer_h_INCLUDE

#include <GNUstepGUI/GSTextConverter.h>

@class NSMutableDictionary;
@class NSMutableArray;
@class NSMutableAttributedString;

@interface DOCXConsumer: NSObject <GSTextConsumer>
{
@public
  NSStringEncoding encoding;
  NSMutableDictionary *documentAttributes;
  NSMutableDictionary *fonts;
  NSMutableArray *colours;
  NSMutableArray *attrs;
  NSMutableAttributedString *result;
  Class _class;
  int ignore;
}

@end

#endif
