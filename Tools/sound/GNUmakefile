PACKAGE_NAME = gnustep-gui
include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Sndfile AudioOutput
BUNDLE_EXTENSION = .nssound

Sndfile_OBJC_FILES = SndfileSource.m
AudioOutput_OBJC_FILES = AudioOutputSink.m

Sndfile_PRINCIPAL_CLASS = SndfileSource
AudioOutput_PRINCIPAL_CLASS = AudioOutputSink

Sndfile_BUNDLE_LIBS = -lsndfile
AudioOutput_BUNDLE_LIBS = -lao

include $(GNUSTEP_MAKEFILES)/bundle.make
