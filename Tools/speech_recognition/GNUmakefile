include $(GNUSTEP_MAKEFILES)/common.make

# Set the default.  Eventually this should be conditional.
GSSPEECHRECOGNITIONENGINE = Pocketsphinx

VERSION = 0.1

# This is an app not a tool because, eventually, it will present the user
# interface for the GUI part of the speech engine.
APP_NAME = GSSpeechRecognitionServer

GSSpeechRecognitionServer_LANGUAGES = English

GSSpeechRecognitionServer_OBJC_FILES = \
	GSSpeechRecognitionEngine.m \
	GSSpeechRecognitionServer.m \
	GSSpeechRecognizer.m \
	main.m


ifeq ($(GSSPEECHRECOGNITIONENGINE), Pocketsphinx)
POCKETSPHINX_BASE_LIBS = -lpocketsphinx

GSSpeechRecognitionServer_OBJC_FILES += PocketsphinxSpeechRecognitionEngine.m
GSSpeechRecognitionServer_INCLUDE_DIRS += -I/usr/local/include/pocketsphinx -I../../Headers \
	-I../../Headers/Additions
GSSpeechRecognitionServer_LIB_DIRS += -L../../Source/$(GNUSTEP_OBJ_DIR) \
	-L/usr/local/lib -lgnustep-gui \
	$(POCKETSPHINX_BASE_LIBS)
endif

include $(GNUSTEP_MAKEFILES)/application.make
