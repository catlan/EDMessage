# FoundationExtensions.subproj
# $Id: GNUmakefile,v 2.1 2003-10-21 16:27:16 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

include $(GNUSTEP_MAKEFILES)/common.make

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


include ../GNUstepBuild


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

endif
