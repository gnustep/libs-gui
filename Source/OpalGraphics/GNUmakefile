include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = opal
SUBPROJECT_NAME = OpalGraphics

$(SUBPROJECT_NAME)_OBJC_FILES = $(wildcard *.m)
$(SUBPROJECT_NAME)_OBJC_FILES += $(wildcard cairo/*.m)
$(SUBPROJECT_NAME)_OBJC_FILES += $(wildcard image/*.m)

$(SUBPROJECT_NAME)_HEADER_FILES_DIR = ../../Headers/CoreGraphics
$(SUBPROJECT_NAME)_INCLUDE_DIRS = -I../../Headers
$(SUBPROJECT_NAME)_HEADER_FILES_INSTALL_DIR = CoreGraphics
$(SUBPROJECT_NAME)_HEADER_FILES = \
	CGAffineTransform.h \
	CGBase.h \
	CGBitmapContext.h \
	CGColor.h \
	CGColorSpace.h \
	CGContext.h \
	CGDataConsumer.h \
	CGDataProvider.h \
	CGFont.h \
	CGFunction.h \
	CGGeometry.h \
	CGGradient.h \
	CGImage.h \
	CGImageDestination.h \
	CGImageSource.h \
	CGLayer.h \
	CGPath.h \
	CGPattern.h \
	CGPDFArray.h \
	CGPDFContentStream.h \
	CGPDFContext.h \
	CGPDFDictionary.h \
	CGPDFDocument.h \
	CGPDFObject.h \
	CGPDFOperatorTable.h \
	CGPDFPage.h \
	CGPDFScanner.h \
	CGPDFString.h \
	CGPDFStream.h \
	CGPSConverter.h \
	CGShading.h \
	CoreGraphics.h

ADDITIONAL_OBJCFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags lcms)

ifneq ($(GNUSTEP_TARGET_OS), mingw32)
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags freetype2)
else
ADDITIONAL_CPPFLAGS += -D__MINGW__
endif


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble
