# Mail.subproj
# $Id: GNUmakefile,v 2.1 2003-10-21 16:27:17 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_INCLUDE_DIRS = \
-I.. \
-I../FoundationExtensions.subproj \
-I../Message.subproj \
-I../HeaderFieldCoder.subproj \
-I../ContentCoder.subproj


SUBPROJECT_NAME = Mail.subproj


Mail.subproj_HEADER_FILES = \
EDMailAgent.h   EDSMTPStream.h


Mail.subproj_OBJC_FILES = \
EDMailAgent.m   EDSMTPStream.m


include ../GNUstepBuild


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble


endif
