/** <title>CGPDFScanner</title>
 
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
#include "CoreGraphics/CGPDFScanner.h"

CGPDFScannerRef CGPDFScannerCreate(
  CGPDFContentStreamRef cs,
  CGPDFOperatorTableRef table,
  void *info)
{
  return nil;
}

bool CGPDFScannerScan(CGPDFScannerRef scanner)
{
  return false;
}

CGPDFContentStreamRef CGPDFScannerGetContentStream(CGPDFScannerRef scanner)
{
  return nil;
}

bool CGPDFScannerPopArray(CGPDFScannerRef scanner, CGPDFArrayRef *value)
{
  return false;
}

bool CGPDFScannerPopBoolean(CGPDFScannerRef scanner, CGPDFBoolean *value)
{
  return false;
}

bool CGPDFScannerPopDictionary(CGPDFScannerRef scanner, CGPDFDictionaryRef *value)
{
  return false;
}

bool CGPDFScannerPopInteger(CGPDFScannerRef scanner, CGPDFInteger *value)
{
  return false;
}

bool CGPDFScannerPopName(CGPDFScannerRef scanner, const char **value)
{
  return false;
}

bool CGPDFScannerPopNumber(CGPDFScannerRef scanner, CGPDFReal *value)
{
  return false;
}

bool CGPDFScannerPopObject(CGPDFScannerRef scanner, CGPDFObjectRef *value)
{
  return false;
}

bool CGPDFScannerPopStream(CGPDFScannerRef scanner, CGPDFStreamRef *value)
{
  return false;
}

bool CGPDFScannerPopString(CGPDFScannerRef scanner, CGPDFStringRef *value)
{
  return false;
}

CGPDFScannerRef CGPDFScannerRetain(CGPDFScannerRef scanner)
{
  return nil;
}

void CGPDFScannerRelease(CGPDFScannerRef scanner)
{
  
}