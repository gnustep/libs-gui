# aclocal.m4 - configure macros for libobjects and projects that depend on it.
#
#   Copyright (C) 1995, 1996 Free Software Foundation, Inc.
#
#   Author:  Adam Fedor <fedor@boulder.colorado.edu>
#   Author:  Ovidiu Predescu <ovidiu@bx.logicnet.ro>
#
#   This file is part of the GNU Objective-C library.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Library General Public
#   License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#   
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Library General Public License for more details.
#
#   You should have received a copy of the GNU Library General Public
#   License along with this library; see the file COPYING.LIB.
#   If not, write to the Free Software Foundation,
#   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


AC_DEFUN(OBJC_SYS_AUTOLOAD,
[dnl
#--------------------------------------------------------------------
# Guess if we are using a object file format that supports automatic
# loading of constructor functions, et. al. (e.g. ELF format).
#
# Currently only looks for ELF format. NOTE: Checking for __ELF__ being
# defined doesnt work, since gcc on Solaris does not define this. I'm 
# assuming that machines that have elf.h use the ELF library format, what
# is really needed is to check if this is true directly.
#
# Makes the following substitutions:
#	Defines SYS_AUTOLOAD (whether initializer functions are autoloaded)
#	Defines CON_AUTOLOAD (whether constructor functions are autoloaded)
#--------------------------------------------------------------------
AC_CACHE_VAL(objc_cv_sys_autoload,
[AC_CHECK_HEADER(elf.h, [objc_cv_sys_autoload=yes], [objc_cv_sys_autoload=no])
])
if test $objc_cv_sys_autoload = yes; then
  AC_DEFINE(CON_AUTOLOAD)
fi
AC_CACHE_VAL(objc_subinit_worked,
[AC_MSG_CHECKING(loading of initializer functions)
AC_TRY_RUN([
static char *argv0 = 0;
static char *env0 = 0;
static void args_test (int argc, char *argv[], char *env[])
{
  argv0 = argv[0];
  env0 = env[0];
}
static void * __libobjects_subinit_args__
__attribute__ ((section ("__libc_subinit"))) = &(args_test);
int main(int argc, char *argv[])
{
  if (argv[0] == argv0 && env[0] == env0)
    exit (0);
  exit (1);
}
], objc_subinit_worked=yes, objc_subinit_worked=no, objc_subinit_worked=no)])
if test $objc_subinit_worked = yes; then
  AC_DEFINE(SYS_AUTOLOAD)
  AC_MSG_RESULT(yes)
else
  AC_MSG_RESULT(no)
fi
])

AC_DEFUN(OBJC_SYS_DYNAMIC_LINKER,
[dnl
#--------------------------------------------------------------------
# Guess the type of dynamic linker for the system
#
# Makes the following substitutions:
#	DYNAMIC_LINKER	- cooresponds to the interface that is included
#		in objc-load.c (i.e. #include "${DYNAMIC_LINKER}-load.h")
#	LIBS		- Updated to include the system library that 
#		performs dynamic linking. 
#--------------------------------------------------------------------
DYNAMIC_LINKER=null
AC_CHECK_LIB(dl, dlopen, [DYNAMIC_LINKER=simple LIBS="${LIBS} -ldl"])

if test $DYNAMIC_LINKER = null; then
    AC_CHECK_LIB(dld, main, [DYNAMIC_LINKER=dld LIBS="${LIBS} -ldld"])
    AC_CHECK_HEADER(dld/defs.h, objc_found_dld_defs=yes, objc_found_dld_defs=no)
    # Try to distinguish between GNU dld and HPUX dld 
    AC_CHECK_HEADER(dl.h, [DYNAMIC_LINKER=hpux])
    if test $ac_cv_lib_dld = yes && test $objc_found_dld_defs = no && test $ac_cv_header_dl_h = no; then
        AC_MSG_WARN(Could not find dld/defs.h header)
        echo
        echo "Currently, the dld/defs.h header is needed to get information"
        echo "about how to use GNU dld. Some files may not compile without"
        echo "this header."
        echo
    fi
fi
AC_SUBST(DYNAMIC_LINKER)dnl
AC_SUBST(DLD_INCLUDE)dnl
])

AC_DEFUN(OBJC_SYS_DYNAMIC_FLAGS,
[AC_REQUIRE([OBJC_SYS_DYNAMIC_LINKER])dnl
AC_REQUIRE([OBJC_SYS_AUTOLOAD])dnl
#--------------------------------------------------------------------
# Set the flags for compiling dynamically loadable objects
#
# Makes the following substitutions:
#	DYNAMIC_BUNDLER_LINKER - The command to link the object files into
#		a dynamically loadable module.
#	DYNAMIC_LDFLAGS - Flags required when compiling the main program
#		that will do the dynamic linking
#	DYNAMIC_CFLAGS - Flags required when compiling the object files that
#		will be included in the loaded module.
#--------------------------------------------------------------------
if test $DYNAMIC_LINKER = dld; then
    DYNAMIC_BUNDLER_LINKER="ld -r"
    DYNAMIC_LDFLAGS="-static"
    DYNAMIC_CFLAGS=""
elif test $DYNAMIC_LINKER = simple; then
    if test $objc_cv_sys_autoload = yes; then 
      DYNAMIC_BUNDLER_LINKER='$(CC) -Xlinker -r'
    else
      DYNAMIC_BUNDLER_LINKER='$(CC) -nostdlib'
    fi
    DYNAMIC_LDFLAGS=""
    DYNAMIC_CFLAGS="-fPIC"
elif test $DYNAMIC_LINKER = hpux; then
    DYNAMIC_BUNDLER_LINKER='$(CC) -nostdlib -Xlinker -b'
    DYNAMIC_LDFLAGS="-Xlinker -E"
    DYNAMIC_CFLAGS="-fPIC"
elif test $DYNAMIC_LINKER = null; then
    DYNAMIC_BUNDLER_LINKER='$(CC) -nostdlib -Xlinker -r'
    DYNAMIC_LDFLAGS=""
    DYNAMIC_CFLAGS=""
else
    DYNAMIC_BUNDLER_LINKER='$(CC) -nostdlib -Xlinker -r'
    DYNAMIC_LDFLAGS=""
    DYNAMIC_CFLAGS=""
fi
AC_SUBST(DYNAMIC_BUNDLER_LINKER)dnl
AC_SUBST(DYNAMIC_LDFLAGS)dnl
AC_SUBST(DYNAMIC_CFLAGS)dnl
])

AC_DEFUN(AC_LANG_OBJECTIVE_C,
[AC_REQUIRE([AC_PROG_CC])dnl
define([AC_LANG], [AC_LANG_OBJECTIVE_C])dnl
ac_ext=m
# CFLAGS is not in ac_cpp because -g, -O, etc. are not valid cpp options.
ac_cpp='$CPP $OBJC_RUNTIME_FLAG'
ac_compile='${CC-cc} -c $OBJC_RUNTIME_FLAG $CFLAGS conftest.$ac_ext 1>&AC_FD_CC 2>&AC_FD_CC'
ac_link='${CC-cc} -o conftest $OBJC_RUNTIME_FLAG $CFLAGS $LDFLAGS conftest.$ac_ext $LIBS $OBJC_LIBS 1>&AC_FD_CC 2>&AC_FD_CC'
])dnl

AC_DEFUN(AC_FIND_FOUNDATION,
[dnl
AC_SUBST(FOUNDATION_LIBRARY)dnl
dnl
AC_REQUIRE([AC_PROG_CC])dnl
AC_REQUIRE([AC_C_CROSS])dnl
AC_MSG_CHECKING(for the Foundation library)
OBJC_LIBS=
AC_CACHE_VAL(ac_cv_foundation_library,
[AC_LANG_SAVE[]dnl
AC_LANG_OBJECTIVE_C[]
AC_TRY_COMPILE(
#include <Foundation/preface.h>
,
, ac_cv_foundation_library="$ac_cv_foundation_library gnustep-base")
AC_TRY_COMPILE(
#include <Foundation/exceptions/FoundationException.h>
,
, ac_cv_foundation_library="$ac_cv_foundation_library libFoundation")
AC_TRY_COMPILE(
#include <objects/stdobjects.h>
,
, ac_cv_foundation_library="$ac_cv_foundation_library libobjects")
AC_LANG_RESTORE[]dnl
if test "$FOUNDATION" = ""; then
AC_TRY_CPP(
#include <foundation/NSObject.h>
, ac_cv_foundation_library=foundation)
else
    ac_cv_foundation_library=$FOUNDATION
fi
])dnl
libs_found=`echo ${ac_cv_foundation_library} | awk '{print NF}' -`
if test $libs_found -gt 1; then
    echo "" 1>&2
    AC_MSG_ERROR([More than one Foundation library installed on your system. In the FOUNDATION variable you must specify exactly one of the following libraries: ${ac_cv_foundation_library}])
fi
FOUNDATION_LIBRARY=`echo ${ac_cv_foundation_library} | awk '{print $1}'`
case "$FOUNDATION_LIBRARY" in
    foundation)
	OBJC_RUNTIME=next

	# save the prefix
	old_prefix=$prefix
	prefix=$ac_default_prefix
	CFLAGS="-I`eval \"echo $includedir\"`/next $CFLAGS"
	# restore the value of prefix
	prefix=$old_prefix

	OBJC_LIBS="-lFoundation_s"; 
	AC_DEFINE(NeXT_foundation_LIBRARY);;
    libobjects)
	OBJC_LIBS="-lobjects"
	AC_DEFINE(GNUSTEP_BASE_LIBRARY);;
    gnustep-base)
	OBJC_LIBS="-lgnustep-base"
	AC_DEFINE(GNUSTEP_BASE_LIBRARY);;
    libFoundation)
	if test "$FOUNDATION_LIB" = ""; then
	    FOUNDATION_LIB=Foundation
	fi
	OBJC_LIBS="-l${FOUNDATION_LIB}"
	AC_DEFINE(LIB_FOUNDATION_LIBRARY);;
    *)
	AC_MSG_ERROR(Unknown $FOUNDATION_LIBRARY library!);;
esac
AC_MSG_RESULT(${ac_cv_foundation_library})
AC_DETERMINE_FOUNDATION_RUNTIME
])dnl

AC_DEFUN(AC_DETERMINE_FOUNDATION_RUNTIME,
[dnl
AC_SUBST(OBJC_RUNTIME)dnl
AC_SUBST(OBJC_RUNTIME_FLAG)dnl
dnl
AC_REQUIRE([AC_PROG_CC])dnl
AC_REQUIRE([AC_C_CROSS])dnl
AC_MSG_CHECKING(for the Objective-C runtime)
AC_CACHE_VAL(ac_cv_objc_runtime,
[if test "$OBJC_RUNTIME" = ""; then
  AC_LANG_SAVE[]dnl
  AC_LANG_OBJECTIVE_C[]
  AC_TRY_LINK([#include <Foundation/NSString.h>],
  [extern id objc_lookUpClass(char*);
  id class = objc_lookUpClass("NSObject");
  id obj = [class alloc];
  puts([[obj description] cString]);
  ], ac_cv_objc_runtime=NeXT, ac_cv_objc_runtime=unknown)
  if test $ac_cv_objc_runtime = unknown; then
    OBJC_RUNTIME_FLAG=-fgnu-runtime
    saved_LIBS=$LIBS
    LIBS="$OBJC_LIBS -lobjc $LIBS"
    AC_TRY_LINK([#include <Foundation/NSString.h>
    #include <objc/objc-api.h>],
    [id class = objc_lookup_class("NSObject");
    id obj = [class alloc];
    puts([[obj description] cString]);
    ], ac_cv_objc_runtime=GNU, ac_cv_objc_runtime=unknown)
    LIBS=$saved_LIBS
  fi
  AC_LANG_RESTORE[]
fi
])dnl
OBJC_RUNTIME=$ac_cv_objc_runtime
if test "`echo ${OBJC_RUNTIME} | tr a-z A-Z`" = "GNU"; then
  OBJC_RUNTIME=GNU
  OBJC_RUNTIME_FLAG=-fgnu-runtime
  ac_cv_objc_runtime=GNU
  OBJC_LIBS="$OBJC_LIBS -lobjc"
  AC_DEFINE(GNU_RUNTIME)
elif test "`echo ${OBJC_RUNTIME} | tr a-z A-Z`" = "NEXT"; then
  OBJC_RUNTIME=NeXT
  OBJC_RUNTIME_FLAG=-fnext-runtime
  ac_cv_objc_runtime=NeXT
  AC_DEFINE(NeXT_RUNTIME)
else
  OBJC_RUNTIME=unknown
fi
if test ${OBJC_RUNTIME} = unknown; then
  echo
  rm -f conftest* confdefs* core core.* *.core
  AC_MSG_ERROR([Cannot determine the Objective-C runtime! Probably you have
to specify some additional libraries needed to link an ObjC program, so please
take a look in the config.log file to see the reason and try again.])
fi
AC_MSG_RESULT(${ac_cv_objc_runtime})
LIBS="$OBJC_LIBS $LIBS"
])dnl
