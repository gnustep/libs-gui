/** <title>CGPDFArray</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: June 2010
  
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

#import <Foundation/NSObject.h>
#include "CoreGraphics/CGPDFArray.h"

bool CGPDFArrayGetArray(CGPDFArrayRef array, size_t index, CGPDFArrayRef *value)
{
  return false;
}

bool CGPDFArrayGetBoolean(CGPDFArrayRef array, size_t index, CGPDFBoolean *value)
{
  return false;
}

size_t CGPDFArrayGetCount(CGPDFArrayRef array)
{
  return 0;
}

bool CGPDFArrayGetDictionary(CGPDFArrayRef array, size_t index, CGPDFDictionaryRef *value)
{
  return false;
}

bool CGPDFArrayGetInteger(CGPDFArrayRef array, size_t index, CGPDFInteger *value)
{
  return false;
}

bool CGPDFArrayGetName(CGPDFArrayRef array, size_t index, const char **value)
{
  return false;
}

bool CGPDFArrayGetNull(CGPDFArrayRef array, size_t index)
{
  return false;
}

bool CGPDFArrayGetNumber(CGPDFArrayRef array, size_t index, CGPDFReal *value)
{
  return false;
}

bool CGPDFArrayGetObject(CGPDFArrayRef array, size_t index, CGPDFObjectRef *value)
{
  return false;
}

bool CGPDFArrayGetStream(CGPDFArrayRef array, size_t index, CGPDFStreamRef *value)
{
  return false;
}

bool CGPDFArrayGetString(CGPDFArrayRef array, size_t index, CGPDFStringRef *value)
{
  return false;
}