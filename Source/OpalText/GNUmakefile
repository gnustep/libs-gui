include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = opal
SUBPROJECT_NAME = OpalText

$(SUBPROJECT_NAME)_OBJC_FILES = $(wildcard *.m)

ifneq ($(GNUSTEP_TARGET_OS), mingw32)
$(SUBPROJECT_NAME)_OBJC_FILES += Fontconfig/NSFontconfigFontDescriptor.m
$(SUBPROJECT_NAME)_OBJC_FILES += FreeType/OPFreeTypeFont.m
endif

$(SUBPROJECT_NAME)_HEADER_FILES_DIR = ../../Headers/CoreText
$(SUBPROJECT_NAME)_INCLUDE_DIRS = -I../../Headers
$(SUBPROJECT_NAME)_HEADER_FILES_INSTALL_DIR = CoreText
$(SUBPROJECT_NAME)_HEADER_FILES = \
	CoreText.h\
	CTFont.h\
	CTFontCollection.h\
	CTFontDescriptor.h\
	CTFontManager.h\
	CTFontManagerErrors.h\
	CTFontTraits.h\
	CTFrame.h\
	CTFramesetter.h\
	CTGlyphInfo.h\
	CTLine.h\
	CTParagraphStyle.h\
	CTRun.h\
	CTStringAttributes.h\
	CTTextTab.h\
	CTTypesetter.h

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
