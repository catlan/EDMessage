# HeaderCoder.subproj
# $Id: GNUmakefile,v 2.0 2002-08-16 18:24:15 erik Exp $


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
-I../Message.subproj


SUBPROJECT_NAME = HeaderCoder.subproj


HeaderCoder.subproj_HEADER_FILES = \
EDDateFieldCoder.h      EDFaceFieldCoder.h      EDIdListFieldCoder.h \
EDEntityFieldCoder.h    EDHeaderFieldCoder.h    EDTextFieldCoder.h


HeaderCoder.subproj_OBJC_FILES = \
EDDateFieldCoder.m      EDFaceFieldCoder.m      EDIdListFieldCoder.m \
EDEntityFieldCoder.m    EDHeaderFieldCoder.m    EDTextFieldCoder.m


HeaderCoder.subproj_C_FILES = parsedate.c


-include Makefile.preamble

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

-include Makefile.postamble

endif
