# Message.subproj
# $Id: GNUmakefile,v 2.0 2002-08-16 18:24:18 erik Exp $


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
-I../HeaderFieldCoder.subproj


SUBPROJECT_NAME = Message.subproj


Message.subproj_HEADER_FILES = \
EDHeaderBearingObject.h EDMConstants.h \
EDInternetMessage.h     EDMessagePart.h


Message.subproj_OBJC_FILES = \
EDHeaderBearingObject.m EDMConstants.m \
EDInternetMessage.m     EDMessagePart.m


-include Makefile.preamble

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

-include Makefile.postamble

endif
