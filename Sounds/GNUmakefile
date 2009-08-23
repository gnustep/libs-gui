#
#  Sounds makefile for GNUstep GUI Library
#  Copyright (C) 2009 Free Software Foundation, Inc.
#
#  Author:  Gregory Casamento <greg.casamento@gmail.com>,
#             Stefan Bidigaray <stefanbidi@gmail.com>
#  Date:  July 2009, August 2009
#
#  This file is part of the GNUstep GUI Library.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; see the file COPYING.LIB.
#  If not, see <http://www.gnu.org/licenses/> or write to the 
#  Free Software Foundation, 51 Franklin Street, Fifth Floor, 
#  Boston, MA 02110-1301, USA.

PACKAGE_NAME = gnustep-gui
GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

sounddir = $(GNUSTEP_LIBRARY)/Sounds

SOUND_FILES = \
Glass.wav \
Basso.wav \
Blow.wav \
Bottle.wav \
Glass.wav \
Hero.wav \
Ping.wav \
Pop.wav \
Sosumi.wav \
Tink.wav

BUNDLE_NAME = Sndfile AudioOutput
BUNDLE_EXTENSION = .nssound

OBJCFLAGS += -Wall -I../Headers/Additions

Sndfile_OBJC_FILES = SndfileSource.m
AudioOutput_OBJC_FILES = AudioOutputSink.m

Sndfile_PRINCIPAL_CLASS = SndfileSource
AudioOutput_PRINCIPAL_CLASS = AudioOutputSink

Sndfile_BUNDLE_LIBS = -lsndfile
AudioOutput_BUNDLE_LIBS = -lao

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/rules.make
include $(GNUSTEP_MAKEFILES)/bundle.make

include GNUmakefile.postamble
