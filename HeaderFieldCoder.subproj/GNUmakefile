# HeaderCoder.subproj
# $Id: GNUmakefile,v 2.3 2003-10-21 16:27:17 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

include $(GNUSTEP_MAKEFILES)/common.make

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


include ../GNUstepBuild


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

endif
