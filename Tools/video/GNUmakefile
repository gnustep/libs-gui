PACKAGE_NAME = gnustep-gui
include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = VideoFile VideoOutput
BUNDLE_EXTENSION = .nsmovie

# These are here in case GNUstep is not installed,
# otherwise compilation will fail.
VideoFile_INCLUDE_DIRS += -I../../Headers \
        -I../../Headers/Additions

VideoFile_LIB_DIRS += \
	-L../../Source/$(GNUSTEP_OBJ_DIR)

VideoOutput_INCLUDE_DIRS += -I../../Headers \
        -I../../Headers/Additions

VideoOutput_LIB_DIRS += \
	-L../../Source/$(GNUSTEP_OBJ_DIR)

# Build the bundles.
VideoFile_OBJC_FILES = VideoFileSource.m
VideoOutput_OBJC_FILES = VideoOutputSink.m
# ffplay.m
# VideoOutlet_C_FILES = cmdutils.c

VideoFile_PRINCIPAL_CLASS = VideoFileSource
VideoOutput_PRINCIPAL_CLASS = VidioOutputSink

VideoFile_BUNDLE_LIBS = 
VideoOutput_BUNDLE_LIBS = -lavformat -lavcodec -lSDL2

include $(GNUSTEP_MAKEFILES)/bundle.make
