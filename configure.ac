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

AC_PATH_X	# Added for checking the existence of ungif.  Note that
                # -gui uses the API of the underlying window system ONLY IF
		# it is definitely necessary.  

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

AC_ARG_ENABLE(jpeg,
  [  --disable-jpeg          Disable JPEG support],,
  enable_jpeg=yes)

if test $enable_jpeg = yes; then
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
  else
    ac_cv_lib_jpeg_jpeg_destroy_decompress = no
  fi

  if test "$ac_cv_lib_jpeg_jpeg_destroy_decompress" = yes; then
    GRAPHIC_LFLAGS="$with_jpeg_library $GRAPHIC_LFLAGS"
    GRAPHIC_CFLAGS="$with_jpeg_include $GRAPHIC_CFLAGS"
  else
    echo "GNUstep requires libjpeg to support JPEG images, but this library"
    echo "can't be found. If you really want to compile GNUstep without"
    echo "JPEG support, pass the --disable-jpeg option to ./configure."
    echo "Note that this isn't recommended. For more information, see:"
    echo "http://gnustep.made-it.com/BuildGuide/index.html#JPEG"
    AC_MSG_ERROR([libjpeg not found.])
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
AC_ARG_ENABLE(png,
  [  --disable-png           Disable PNG support],,
  enable_png=yes)

if test $enable_png = yes; then
  AC_CHECK_LIB(png, png_sig_cmp)

  if test "$ac_cv_lib_png_png_sig_cmp" = no; then
    echo "GNUstep requires libpng to support PNG images, but this library"
    echo "can't be found. If you really want to compile GNUstep without"
    echo "PNG support, pass the --disable-png option to ./configure."
    echo "Note that this isn't recommended. For more information, see:"
    echo "http://gnustep.made-it.com/BuildGuide/index.html#PNG"
    AC_MSG_ERROR([libpng not found.])
  fi
fi


AC_ARG_ENABLE(ungif,
  [  --disable-ungif         Disable libungif-based GIF support],,
  enable_ungif=yes)

AC_ARG_WITH(ungif_library, 
           [  --with-ungif-library=DIR UNGIF library file are in DIR], ,
           with_ungif_library=)
AC_ARG_WITH(ungif_include,  
	[  --with-ungif-include=DIR UNGIF include files are in DIR], ,
        with_ungif_include=)

if test "${enable_ungif}" = yes; then
  orig_CPPFLAGS="${CPPFLAGS}"
  orig_LDFLAGS="${LDFLAGS}"
  orig_LIBS="${LIBS}"

  if test -n "${with_ungif_library}"; then
    with_ungif_library="-L$with_ungif_library"
  fi
  if test -n "${with_ungif_include}"; then
    with_ungif_include="-I$with_ungif_include"
  fi
  CPPFLAGS="${with_ungif_include} ${CPPFLAGS}"
  LDFLAGS="${with_ungif_library} ${LDFLAGS}"

  AC_CHECK_LIB(ungif, DGifOpen)

  if test "${with_x}" != no && test "${ac_cv_lib_ungif_DGifOpen}" = no; then
    AC_MSG_NOTICE([Checking if ungif is linked against -lX11])
    # This implies either that ungif is not installed at all, or that it
    # explicitly refers to the symbols defined in X11.  Now see if the latter
    # is the case.
    CPPFLAGS="${CPPFLAGS} -I${ac_x_includes}"
    LDFLAGS="${LDFLAGS} -L${ac_x_libraries}"
    LIBS="${LIBS} -lX11"

    AC_CHECK_LIB(ungif, DGifCloseFile)
    if test "${ac_cv_lib_ungif_DGifCloseFile}" = no; then
      # This indicates ungif is not installed at all.  The flags reverts to
      # the orignal value.
      CPPFLAGS="${orig_CPPFLAGS}"
      LDFLAGS="${orig_LDFLAGS}"
      LIBS="${orig_LIBS}"
    else
      # This indicates ungif actually refers to the X11's symbols.  We modify
      # the flags so that -gui gets linked against the X11 library to support
      # ungif.
      AC_MSG_NOTICE([-gui will be linked against -lX11 to support ungif images])
      ADDITIONAL_INCLUDE_DIRS="$ADDITIONAL_INCLUDE_DIRS $CPPFLAGS"
      ADDITIONAL_LIB_DIRS="$ADDITIONAL_LIB_DIRS $LDFLAGS -lX11"
    fi
  fi
fi


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





