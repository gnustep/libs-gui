/** <title>GSAVUtils</title>

   <abstract>Utilities to handle AVPacket structs</abstract>

   Copyright <copy>(C) 2025 Free Software Foundation, Inc.</copy>

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: May 2025

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
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>

#import "GSAVUtils.h"

NSDictionary *NSDictionaryFromAVPacket(AVPacket *packet)
{
  NSData *data = [NSData dataWithBytes: packet->data length: packet->size];
  NSNumber *pts = [NSNumber numberWithLongLong: packet->pts];
  NSNumber *duration = [NSNumber numberWithInt: packet->duration];
  NSNumber *flags = [NSNumber numberWithInt: packet->flags];

  return [NSDictionary dictionaryWithObjectsAndKeys:
			 data, @"data",
		       pts, @"pts",
		       duration, @"duration",
		       flags, @"flags",
		       nil];
}

AVPacket AVPacketFromNSDictionary(NSDictionary *dict)
{
  NSData *data = [dict objectForKey: @"data"];
  NSNumber *pts = [dict objectForKey: @"pts"];
  NSNumber *duration = [dict objectForKey: @"duration"];
  NSNumber *flags = [dict objectForKey: @"flags"];

  AVPacket packet;
  packet.data = (uint8_t *)[data bytes];
  packet.size = (int)[data length];
  packet.pts = [pts longLongValue];
  packet.duration = [duration intValue];
  packet.flags = [flags intValue];

  return packet;
}
