# configure.in for GNUstep GUI library
# Process this file with autoconf to produce a configure script.
#
# Copyright (C) 1996 Free Software Foundation, Inc.
#
# Author:  Adam Fedor <fedor@gnu.org>
#
# This file is part of the GNUstep GUI frontend (AppKit).
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; see the file COPYING.LIB.
# If not, write to the Free Software Foundation,
# 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
AC_INIT
AC_CONFIG_SRCDIR([Source/NSApplication.m])

if test -z "$GNUSTEP_SYSTEM_ROOT"; then
  AC_MSG_ERROR([You must run the GNUstep initialization script first!])
fi

#--------------------------------------------------------------------
# Use config.guess, config.sub and install-sh provided by gnustep-make
#--------------------------------------------------------------------
AC_CONFIG_AUX_DIR($GNUSTEP_SYSTEM_ROOT/Makefiles)

AC_CONFIG_HEADER(Headers/gnustep/gui/config.h)

#--------------------------------------------------------------------
# Determine the host, build, and target systems
#--------------------------------------------------------------------
AC_CANONICAL_TARGET([])

#--------------------------------------------------------------------
# The following is so that headers and custom libraries
# in the GNUstep root are used before the standard ones
#--------------------------------------------------------------------
# Set location of GNUstep dirs for later use
GNUSTEP_HDIR=$GNUSTEP_SYSTEM_ROOT/Headers
if test "$GNUSTEP_FLATTENED" = yes; then
  GNUSTEP_LDIR=$GNUSTEP_SYSTEM_ROOT/Libraries
else
  clean_target_os=`$GNUSTEP_SYSTEM_ROOT/Makefiles/clean_os.sh $target_os`
  clean_target_cpu=`$GNUSTEP_SYSTEM_ROOT/Makefiles/clean_cpu.sh $target_cpu`
  obj_dir=$clean_target_cpu/$clean_target_os
  GNUSTEP_LDIR=$GNUSTEP_SYSTEM_ROOT/Libraries/$obj_dir
fi
CPPFLAGS="$CPPFLAGS -I$GNUSTEP_HDIR"
LDFLAGS="$LDFLAGS -L$GNUSTEP_LDIR/$LIBRARY_COMBO -L$GNUSTEP_LDIR"

#--------------------------------------------------------------------
# Find the compiler
#--------------------------------------------------------------------
AC_PROG_CC
AC_PROG_CPP

AC_CHECK_LIB(m, main)
AC_CHECK_FUNCS(rint rintf)

#--------------------------------------------------------------------
# Find for JPEG
#--------------------------------------------------------------------
GRAPHIC_LIBS=
GRAPHIC_CFLAGS=
GRAPHIC_LFLAGS=

AC_ARG_WITH(jpeg_library, 
           [  --with-jpeg-library=DIR JPEG library file are in DIR], ,
           with_jpeg_library=)
AC_ARG_WITH(jpeg_include,  
	[  --with-jpeg-include=DIR JPEG include files are in DIR], ,
        with_jpeg_include=)

if test "$with_jpeg_library" = ""; then
  case "$target_os" in
    freebsd*)	with_jpeg_include="/usr/local/include"
		with_jpeg_library="/usr/local/lib";;
  esac
fi

if test -n "$with_jpeg_library"; then
  with_jpeg_library="-L$with_jpeg_library"
fi
if test -n "$with_jpeg_include"; then
  with_jpeg_include="-I$with_jpeg_include"
fi

AC_DEFUN(AC_CHECK_JPEGLIB,
[jpeg_check_lib_save_header=${CPPFLAGS}
CPPFLAGS="$1 $2 ${CPPFLAGS}"

AC_CHECK_LIB(jpeg, jpeg_destroy_decompress,
      jpeg_ok=yes,
      jpeg_ok=no)
if test "$jpeg_ok" = yes; then
  AC_MSG_CHECKING([for jpeglib.h])
  AC_TRY_CPP([#include <stdio.h>
              #undef PACKAGE
	      #undef VERSION
	      #undef HAVE_STDLIB_H
              #include <jpeglib.h>],
 	      jpeg_ok=yes,
	      jpeg_ok=no)
  AC_MSG_RESULT($jpeg_ok)

  if test "$jpeg_ok" = yes; then
    GRAPHIC_LFLAGS="$1 $GRAPHIC_LFLAGS"
    GRAPHIC_CFLAGS="$2 $GRAPHIC_CFLAGS"
  fi
fi
CPPFLAGS="${jpeg_check_lib_save_header}"])

AC_CHECK_JPEGLIB(${with_jpeg_library}, ${with_jpeg_include})

#--------------------------------------------------------------------
# Find for TIFF
#--------------------------------------------------------------------
AC_ARG_WITH(tiff_library, 
           [  --with-tiff-library=DIR TIFF library file are in DIR], ,
           with_tiff_library=)
AC_ARG_WITH(tiff_include,  
	[  --with-tiff-include=DIR TIFF include files are in DIR], ,
        with_tiff_include=)

if test "$with_tiff_library" = ""; then
  case "$target_os" in
    freebsd*)	with_tiff_include="/usr/local/include"
		with_tiff_library="/usr/local/lib";;
  esac
fi

if test -n "$with_tiff_library"; then
  with_tiff_library="-L$with_tiff_library"
fi
if test -n "$with_tiff_include"; then
  with_tiff_include="-I$with_tiff_include"
fi

AC_DEFUN(AC_CHECK_TIFFLIB,
[tiff_check_lib_save_header=${CPPFLAGS}
tiff_check_lib_save_libs=${LIBS}
CPPFLAGS="$1 ${JPEG_LIB} $2 ${JPEG_INCLUDE} ${CPPFLAGS}"
AC_CHECK_LIB(z, main, HAVE_LIBZ=1, HAVE_LIBZ=0)

AC_MSG_CHECKING(for -ltiff without -ljpeg nor -lz)
LIBS="-ltiff -lm $LIBS"
AC_TRY_LINK([char TIFFReadScanline();], [TIFFReadScanline()],
    jpeg_notneeded=yes,
    jpeg_notneeded=no)
AC_MSG_RESULT($jpeg_notneeded)
LIBS=${tiff_check_lib_save_libs}
JPEG=
if test "$jpeg_notneeded" = no; then
  JPEG=-ljpeg
fi

if test $HAVE_LIBZ = 1; then
  AC_MSG_CHECKING(for -ltiff without -lz)
  LIBS="-ltiff $JPEG -lm $LIBS"
  AC_TRY_LINK([char TIFFReadScanline();], [TIFFReadScanline()],
      libz_notneeded=yes,
      libz_notneeded=no)
  AC_MSG_RESULT($libz_notneeded)
  LIBS=${tiff_check_lib_save_libs}
  if test "$libz_notneeded" = no; then
    JPEG="$JPEG -lz"
  fi
fi

AC_CHECK_LIB(tiff, TIFFReadScanline, tiff_ok=yes, tiff_ok=no, $JPEG -lm)
if test "$tiff_ok" = yes; then
  AC_CHECK_HEADER(tiffio.h, tiff_ok=yes, tiff_ok=no)
  if test "$tiff_ok" = yes; then
    GRAPHIC_LFLAGS="$1 $GRAPHIC_LFLAGS"
    GRAPHIC_CFLAGS="$2 $GRAPHIC_CFLAGS"
    GRAPHIC_LIBS="-ltiff $JPEG $GRAPHIC_LIBS"
  else
    AC_MSG_WARN(Cannot find libtiff header tiffio)
    echo "* The GUI library requres the TIFF library"
    echo "* Use --with-tiff-include to specify the tiff header directory"
    echo "* and --with-tiff-library to specify the tiff library directory"
    echo "* if it is not in the usual place(s)"
    AC_MSG_ERROR(gnustep-gui will not compile without tiff includes)
  fi
else
  AC_MSG_WARN(Cannot find libtiff)
  echo "* The GUI library reqiures the TIFF library"
  echo "* Use --with-tiff-library to specify the tiff library"
  echo "* directory if it is not in the usual place(s)"
  echo "* You may also have to specify --with-jpeg-library if the jpeg"
  echo "* library is needed by tiff",
  AC_MSG_ERROR(gnustep-gui will not compile without tiff)
fi
CPPFLAGS="${tiff_check_lib_save_header}"])

AC_CHECK_TIFFLIB(${with_tiff_library}, ${with_tiff_include})

ADDITIONAL_INCLUDE_DIRS="$GRAPHIC_CFLAGS"
ADDITIONAL_LIB_DIRS="$GRAPHIC_LFLAGS"
ADDITIONAL_DEPENDS="$GRAPHIC_LIBS"

#--------------------------------------------------------------------
# NSSound
#--------------------------------------------------------------------
audio_ok=no
BUILD_GSND=
AC_CHECK_LIB(audiofile, afGetVirtualFrameSize, audio_ok=yes, audio_ok=no)
if test $audio_ok = yes; then
  AC_CHECK_HEADERS(audiofile.h)
  ADDITIONAL_DEPENDS="$ADDITIONAL_DEPENDS -laudiofile"
  BUILD_GSND=gsnd
fi
AC_SUBST(BUILD_GSND)

#--------------------------------------------------------------------
# Record the version
#--------------------------------------------------------------------
AC_MSG_CHECKING(for the version of gnustep-gui we are compiling)
if test -f "Version"; then
  . ./Version
fi
AC_MSG_RESULT($GNUSTEP_GUI_VERSION)
AC_SUBST(GNUSTEP_GUI_VERSION)
AC_SUBST(GNUSTEP_GUI_MAJOR_VERSION)
AC_SUBST(GNUSTEP_GUI_MINOR_VERSION)
AC_SUBST(GNUSTEP_GUI_SUBMINOR_VERSION)

AC_SUBST(ADDITIONAL_LIB_DIRS)
AC_SUBST(ADDITIONAL_INCLUDE_DIRS)
AC_SUBST(ADDITIONAL_DEPENDS)

#--------------------------------------------------------------------
# Configure
#--------------------------------------------------------------------
AH_BOTTOM([
/* Define for those who don't have rintf and/or rint */
#ifndef HAVE_RINTF
#define rintf rint
#endif
#ifndef HAVE_RINT
#define DEFINE_RINT_IF_MISSING   \
static double rint(double a)     \
{                                \
  return (floor(a+0.5));         \
}
#else
#define DEFINE_RINT_IF_MISSING
#endif
])

AC_CONFIG_FILES([config.make gui.make Headers/gnustep/gui/GSVersion.h])
AC_OUTPUT





