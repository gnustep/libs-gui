@echo off
rem
rem Configure.bat
rem 
rem Configuration program for GNUstep GUI Library
rem
rem 2/27/95	Initially created
rem

rem
rem Top level makefile
rem
echo "Top level makefile"
sed -f Makefile.sed.nt Makefile.in >Makefile

rem
rem Source makefile
rem
cd Source
echo "Source makefile"
sed -f Makefile.sed.nt Makefile.in >Makefile
cd ..

rem
rem Configuration files
rem
echo "Creating header configuration files"
cd Headers
cd AppKit
rm -f config.h
sed -f config.sed.nt config.h.in >>config.h
cd ..
cd ..

