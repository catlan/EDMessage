# ContentCoder.subproj
# $Id: GNUmakefile,v 2.1 2003-05-03 17:17:38 znek Exp $


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


-include Makefile.preamble

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

-include Makefile.postamble

endif
