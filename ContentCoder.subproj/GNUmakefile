# ContentCoder.subproj
# $Id: GNUmakefile,v 2.2 2003-10-21 16:27:15 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_INCLUDE_DIRS = \
-I.. \
-I../FoundationExtensions.subproj \
-I../Message.subproj \
-I../HeaderFieldCoder.subproj


SUBPROJECT_NAME = ContentCoder.subproj


ContentCoder.subproj_HEADER_FILES = \
EDCompositeContentCoder.h       EDPlainTextContentCoder.h \
EDContentCoder.h                EDTextContentCoder.h \
EDMultimediaContentCoder.h      EDHTMLTextContentCoder.h

ContentCoder.subproj_OBJC_FILES = \
EDCompositeContentCoder.m       EDPlainTextContentCoder.m \
EDContentCoder.m                EDTextContentCoder.m \
EDMultimediaContentCoder.m      EDHTMLTextContentCoder.m


include ../GNUstepBuild


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

endif
