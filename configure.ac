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
AC_CONFIG_AUX_DIR($GNUSTEP_MAKEFILES)

AC_CONFIG_HEADER(Headers/Additions/GNUstepGUI/config.h)

#--------------------------------------------------------------------
# Determine the host, build, and target systems
#--------------------------------------------------------------------
AC_CANONICAL_TARGET([])

#--------------------------------------------------------------------
# Add target OS directories as necessary
#--------------------------------------------------------------------
ADDITIONAL_INCLUDE_DIRS="$CPPFLAGS"
ADDITIONAL_LIB_DIRS="$LDFLAGS"
case "$target_os" in
  freebsd* | openbsd* )   
	      CPPFLAGS="$CPPFLAGS -I/usr/local/include"
              LDFLAGS="$LDFLAGS -L/usr/local/lib";;
  netbsd*)    CPPFLAGS="$CPPFLAGS -I/usr/pkg/include"
	      LDFLAGS="$LDFLAGS -Wl,-R/usr/pkg/lib -L/usr/pkg/lib";;
esac

#--------------------------------------------------------------------
# The following is so that headers and custom libraries
# in the GNUstep root are used before the standard ones
#--------------------------------------------------------------------
# Set location of GNUstep dirs for later use
GNUSTEP_HDIR=$GNUSTEP_SYSTEM_ROOT/Library/Headers
if test "$GNUSTEP_FLATTENED" = yes; then
  GNUSTEP_LDIR=$GNUSTEP_SYSTEM_ROOT/Library/Libraries
else
  clean_target_os=`$GNUSTEP_MAKEFILES/clean_os.sh $target_os`
  clean_target_cpu=`$GNUSTEP_MAKEFILES/clean_cpu.sh $target_cpu`
  obj_dir=$clean_target_cpu/$clean_target_os
  GNUSTEP_LDIR=$GNUSTEP_SYSTEM_ROOT/Library/Libraries/$obj_dir
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
# Find JPEG
#--------------------------------------------------------------------
GRAPHIC_CFLAGS=
GRAPHIC_LFLAGS=

AC_ARG_WITH(jpeg_library, 
           [  --with-jpeg-library=DIR JPEG library file are in DIR], ,
           with_jpeg_library=)
AC_ARG_WITH(jpeg_include,  
	[  --with-jpeg-include=DIR JPEG include files are in DIR], ,
        with_jpeg_include=)

if test -n "$with_jpeg_library"; then
  with_jpeg_library="-L$with_jpeg_library"
fi
if test -n "$with_jpeg_include"; then
  with_jpeg_include="-I$with_jpeg_include"
fi

CPPFLAGS="$with_jpeg_include ${CPPFLAGS}"
LDFLAGS="$with_jpeg_library ${LDFLAGS}"
AC_CHECK_HEADERS(jpeglib.h, have_jpeg=yes, have_jpeg=no)
if test "$have_jpeg" = yes; then
  AC_CHECK_LIB(jpeg, jpeg_destroy_decompress)
  if test "$ac_cv_lib_jpeg_jpeg_destroy_decompress" = yes; then
    GRAPHIC_LFLAGS="$with_jpeg_library $GRAPHIC_LFLAGS"
    GRAPHIC_CFLAGS="$with_jpeg_include $GRAPHIC_CFLAGS"
  fi
fi

#--------------------------------------------------------------------
# Find TIFF
#--------------------------------------------------------------------
AC_ARG_WITH(tiff_library, 
           [  --with-tiff-library=DIR TIFF library file are in DIR], ,
           with_tiff_library=)
AC_ARG_WITH(tiff_include,  
	[  --with-tiff-include=DIR TIFF include files are in DIR], ,
        with_tiff_include=)

if test -n "$with_tiff_library"; then
  with_tiff_library="-L$with_tiff_library"
fi
if test -n "$with_tiff_include"; then
  with_tiff_include="-I$with_tiff_include"
fi

CPPFLAGS="$with_tiff_include ${CPPFLAGS}"
LDFLAGS="$with_tiff_library ${LDFLAGS}"
AC_CHECK_LIB(z, main)
AC_CHECK_HEADER(tiffio.h, have_tiff=yes, have_tiff=no)
if test "$have_tiff" = yes; then
  AC_CHECK_LIB(tiff, TIFFReadScanline)
  if test "$ac_cv_lib_tiff_TIFFReadScanline" = yes; then
    GRAPHIC_LFLAGS="$with_tiff_library $GRAPHIC_LFLAGS"
    GRAPHIC_CFLAGS="$with_tiff_include $GRAPHIC_CFLAGS"
  else
    have_tiff=no
  fi
fi

if test "$have_tiff" = no; then
  AC_MSG_WARN(Cannot find libtiff header and/or library)
  echo "* The GUI library reqiures the TIFF library"
  echo "* Use --with-tiff-library to specify the tiff library"
  echo "* directory if it is not in the usual place(s)"
  echo "* You may also have to specify --with-jpeg-library if the jpeg"
  echo "* library is needed by tiff",
  AC_MSG_ERROR(gnustep-gui will not compile without tiff)
fi

ADDITIONAL_INCLUDE_DIRS="$ADDITIONAL_INCLUDE_DIRS $GRAPHIC_CFLAGS"
ADDITIONAL_LIB_DIRS="$ADDITIONAL_LIB_DIRS $GRAPHIC_LFLAGS"

#--------------------------------------------------------------------
# Find additional image libs
#--------------------------------------------------------------------
AC_CHECK_LIB(png, main)

#--------------------------------------------------------------------
# NSSound
#--------------------------------------------------------------------
AC_ARG_ENABLE(gsnd, 
  [  --disable-gsnd          Disable gsnd server],,
  enable_gsnd=yes)
audio_ok=no
BUILD_GSND=

AC_ARG_WITH(audiofile_library, 
           [  --with-audiofile-library=DIR AUDIOFILE library file are in DIR], ,
           with_audiofile_library=)
AC_ARG_WITH(audiofile_include,  
	[  --with-audiofile-include=DIR AUDIOFILE include files are in DIR], ,
        with_audiofile_include=)

if test -n "$with_audiofile_library"; then
  with_audiofile_library="-L$with_audiofile_library"
fi
if test -n "$with_audiofile_include"; then
  with_audiofile_include="-I$with_audiofile_include"
fi

CPPFLAGS="${with_audiofile_include} $CPPFLAGS"
LDFLAGS="${with_audiofile_library} $LDFLAGS"
AC_CHECK_LIB(audiofile, afGetVirtualFrameSize)

if test $ac_cv_lib_audiofile_afGetVirtualFrameSize = yes -a $enable_gsnd = yes; then
  AC_CHECK_HEADERS(audiofile.h)
  ADDITIONAL_INCLUDE_DIRS="$ADDITIONAL_INCLUDE_DIRS ${with_audiofile_include}"
  ADDITIONAL_LIB_DIRS="$ADDITIONAL_LIB_DIRS ${with_audiofile_library}"
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

AC_CONFIG_FILES([config.make gui.make Headers/Additions/GNUstepGUI/GSVersion.h])
AC_OUTPUT





