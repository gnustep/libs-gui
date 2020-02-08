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
	main.m


ifeq ($(GSSPEECHRECOGNITIONENGINE), Pocketsphinx)
POCKETSPHINX_BASE_LIBS = -lpocketsphinx -lsphinxbase -lsphinxad

# Add includes and link dirs.... need to replace triplet.
GSSpeechRecognitionServer_OBJC_FILES += PocketsphinxSpeechRecognitionEngine.m
GSSpeechRecognitionServer_INCLUDE_DIRS += -I/usr/local/include/pocketsphinx \
	-I/usr/include/pocketsphinx \
	-I/usr/include/x86_64-linux-gnu/sphinxbase \
	-I../../Headers \
	-I../../Headers/Additions
GSSpeechRecognitionServer_LIB_DIRS += -L../../Source/$(GNUSTEP_OBJ_DIR) \
	-L/usr/local/lib -lgnustep-gui \
	$(POCKETSPHINX_BASE_LIBS)
endif

include $(GNUSTEP_MAKEFILES)/application.make
