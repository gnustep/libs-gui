# This package is not relocatable
%define ver	0.6.5
%define date	20000217
%define prefix 	/usr
%define gsr 	%{prefix}/GNUstep
%define libcombo gnu-gnu-gnu-xgps
Name: 		gnustep-gui
Version: 	%{ver}
Release: 	1
Source: 	ftp://ftp.gnustep.org/pub/gnustep/core/gstep-gui-%{ver}.tar.gz
#Source: 	/cvs/gnustep-gui-%{ver}-%{date}.tar.gz
Copyright: 	GPL
Group: 		Development/Tools
Summary: 	GNUstep GUI library package
Packager:	Christopher Seawood <cls@seawood.org>
Distribution:	Seawood's Random RPMS (%{_buildsym})
Vendor:		The Seawood Project
URL:		http://www.gnustep.org/
BuildRoot: 	/var/tmp/build-%{name}
Conflicts:	gnustep-core
Requires:	gnustep-base

%description
   It is a library of graphical user interface classes written
completely in the Objective-C language; the classes are based upon the
OpenStep specification as release by NeXT Software, Inc.  The library
does not completely conform to the specification and has been enhanced
in a number of ways to take advantage of the GNU system.  These classes
include graphical objects such as buttons, text fields, popup lists,
browser lists, and windows; there are also many associated classes for
handling events, colors, fonts, pasteboards and images.

Library combo is %{libcombo}.
%{_buildblurb}

%package devel
Summary: GNUstep GUI headers and libs.
Group: Development/Libraries
Requires: %{name} = %{ver}, gnustep-base-devel
Conflicts: gnustep-core

%description devel
Header files required to build applications against the GNUstep GUI library.
Library combo is %{libcombo}.
%{_buildblurb}

%prep
%setup -q -n gstep-%{ver}/gui
%patch -p2 -b .headers

%build
if [ -z "$GNUSTEP_SYSTEM_ROOT" ]; then
   . %{gsr}/Makefiles/GNUstep.sh 
fi
CFLAGS="$RPM_OPT_FLAGS" ./configure --prefix=%{gsr} --with-library-combo=%{libcombo}
make

%install
rm -rf $RPM_BUILD_ROOT
if [ -z "$GNUSTEP_SYSTEM_ROOT" ]; then
   . %{gsr}/Makefiles/GNUstep.sh 
fi
mkdir -p ${RPM_BUILD_ROOT}%{gsr}/Library/Services

make install GNUSTEP_INSTALLATION_DIR=${RPM_BUILD_ROOT}%{gsr}

cat > filelist.rpm.in << EOF
%defattr (-, bin, bin)
%doc ANNOUNCE COPYING* ChangeLog INSTALL NEWS NOTES README SUPPORT Version

%dir %{gsr}/Library

%{gsr}/Libraries/GSARCH/GSOS/%{libcombo}/lib*.so.*
%{gsr}/Libraries/Resources
%{gsr}/Library/Model
%{gsr}/Library/Services/*
%{gsr}/Tools/make_services
%{gsr}/Tools/set_show_service
# gpbs is now provided by xgps
#%{gsr}/Tools/GSARCH/GSOS/%{libcombo}/gpbs
%{gsr}/Tools/GSARCH/GSOS/%{libcombo}/make_services
%{gsr}/Tools/GSARCH/GSOS/%{libcombo}/set_show_service

EOF

cat > filelist-devel.rpm.in  << EOF
%defattr(-, bin, bin)
%{gsr}/Headers/gnustep/gui
%{gsr}/Libraries/GSARCH/GSOS/%{libcombo}/lib*.so

EOF

sed -e "s|GSARCH|${GNUSTEP_HOST_CPU}|" -e "s|GSOS|${GNUSTEP_HOST_OS}|" < filelist.rpm.in > filelist.rpm
sed -e "s|GSARCH|${GNUSTEP_HOST_CPU}|" -e "s|GSOS|${GNUSTEP_HOST_OS}|" < filelist-devel.rpm.in > filelist-devel.rpm

# Don't worry about ld.so.conf on linux as gnustep-base should take care of it.

%ifos Linux
%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig
%endif

%clean
rm -rf $RPM_BUILD_ROOT

%files -f filelist.rpm
%files -f filelist-devel.rpm devel

%changelog
* Sat Sep 18 1999 Christopher Seawood <cls@seawood.org>
- Version 0.6.0
- Added headers patch

* Sat Aug 07 1999 Christopher Seawood <cls@seawood.org>
- Updated to cvs dawn_6 branch

* Sat Jun 26 1999 Christopher Seawood <cls@seawood.org>
- Split into separate rpm from gnustep-core
- Build from cvs snapshot
- Split into -devel, -libs & -zoneinfo packages

