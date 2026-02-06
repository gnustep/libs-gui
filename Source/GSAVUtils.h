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

#ifndef _GNUstep_H_GSAVUtils
#define _GNUstep_H_GSAVUtils

/* FFmpeg headers */
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>

NSDictionary *NSDictionaryFromAVPacket(AVPacket *packet);
AVPacket AVPacketFromNSDictionary(NSDictionary *dict);

#endif // GSAVUtils...
