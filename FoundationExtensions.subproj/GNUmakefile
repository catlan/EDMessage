# FoundationExtensions.subproj
# $Id: GNUmakefile,v 1.1.1.1 2002-08-16 18:21:51 erik Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

include $(GNUSTEP_MAKEFILES)/common.make

ifeq "$(OBJC_RUNTIME_LIB)" "gnu"
ADDITIONAL_OBJCFLAGS += -DGNU_RUNTIME
endif

# leave certain stuff out if we're building without UI
ifeq "$(GUI_LIB)" "nil"
ADDITIONAL_OBJCFLAGS += -DEDMESSAGE_WOBUILD
endif

ADDITIONAL_INCLUDE_DIRS = -I..


SUBPROJECT_NAME = FoundationExtensions.subproj


FoundationExtensions.subproj_HEADER_FILES = \
NSCalendarDate+NetExt.h                 NSImage+XFace.h \
NSCharacterSet+MIME.h                   NSString+MessageUtils.h \
NSData+MIME.h                           NSString+PlainTextFlowedExtensions.h


FoundationExtensions.subproj_OBJC_FILES = \
NSCalendarDate+NetExt.m                 NSImage+XFace.m \
NSCharacterSet+MIME.m                   NSString+MessageUtils.m \
NSData+MIME.m                           NSString+PlainTextFlowedExtensions.m


-include Makefile.preamble

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

-include Makefile.postamble

endif
