//---------------------------------------------------------------------------------------
//  EDMessageDefines.h created by erik on Wed 12-Apr-2000
//  $Id: EDMessageDefines.h,v 1.1.1.1 2002-08-16 18:21:51 erik Exp $
//
//  Copyright (c) 2000 by Erik Doernenburg. All rights reserved.
//
//  Permission to use, copy, modify and distribute this software and its documentation
//  is hereby granted, provided that both the copyright notice and this permission
//  notice appear in all copies of the software, derivative works or modified versions,
//  and any portions thereof, and that both notices appear in supporting documentation,
//  and that credit is given to Erik Doernenburg in all documents and publicity
//  pertaining to direct or indirect use of this code or its derivatives.
//
//  THIS IS EXPERIMENTAL SOFTWARE AND IT IS KNOWN TO HAVE BUGS, SOME OF WHICH MAY HAVE
//  SERIOUS CONSEQUENCES. THE COPYRIGHT HOLDER ALLOWS FREE USE OF THIS SOFTWARE IN ITS
//  "AS IS" CONDITION. THE COPYRIGHT HOLDER DISCLAIMS ANY LIABILITY OF ANY KIND FOR ANY
//  DAMAGES WHATSOEVER RESULTING DIRECTLY OR INDIRECTLY FROM THE USE OF THIS SOFTWARE
//  OR OF ANY DERIVATIVE WORK.
//---------------------------------------------------------------------------------------


#ifndef	__EDMessageDefines_h_INCLUDE
#define	__EDMessageDefines_h_INCLUDE

// Defines to handle extern declarations on different platforms

#if defined(__MACH__)

#ifdef __cplusplus
   // This isnt extern "C" because the compiler will not allow this if it has
   // seen an extern "Objective-C"
#  define EDMESSAGE_EXTERN		extern
#else
#  define EDMESSAGE_EXTERN		extern
#endif


#elif defined(WIN32)

#ifdef _BUILDING_EDMESSAGE_DLL
#  define EDMESSAGE_DLL_GOOP		__declspec(dllexport)
#else
#  define EDMESSAGE_DLL_GOOP		__declspec(dllimport)
#endif

#ifdef __cplusplus
#  define EDMESSAGE_EXTERN		extern "C" EDMESSAGE_DLL_GOOP
#else
#  define EDMESSAGE_EXTERN		EDMESSAGE_DLL_GOOP extern
#endif


#else

#ifdef __cplusplus
#  define EDMESSAGE_EXTERN		extern "C"
#else
#  define EDMESSAGE_EXTERN		extern
#endif


#endif


// Constants for EDLogMask. Note that codes should remain unique across all frameworks

#define EDLogCoder 0x010


#endif	/* __EDMessageDefines_h_INCLUDE */
