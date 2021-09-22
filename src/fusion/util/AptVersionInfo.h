////////////////////////////////////////////////////////////////
//
// Copyright (C) 2010 Affymetrix, Inc.
//
// This library is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License 
// (version 2.1) as published by the Free Software Foundation.
// 
// This library is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
// for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this library; if not, write to the Free Software Foundation, Inc.,
// 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
//
////////////////////////////////////////////////////////////////

#ifndef _APTVERSIONINFO_H_
#define _APTVERSIONINFO_H_

#include <string>
#include "util/Convert.h"

// After including this file, all these will be defined.
// They will problably be "unknown" unless AptVersionInfoGenerated.h
// is around or they have been defined with "-D" on the command line.
// In any event, they will be safe to use as strings.

// "util/AptVersionInfoGenerated.h" should be generated by a shell script.
// but we dont at the moment.
// if APT_HAVE_APTVERSIONINFOGENERATED is set then we will pick it up.

// The problem with generating the file is we dont want to
// generate it each time we do a edit/compile cycle.
// But in a Bamboo build, the data will be static.

#ifdef APT_HAVE_APTVERSIONINFOGENERATED
#include "util/AptVersionInfoGenerated.h"
#endif

// These are the backstops to make sure everything is defined
// and to document the formats you can expect.

// "APTHEADCI-HEADCIAMD64PCLINUX-397"
#ifndef APT_VER_BAMBOO_BUILD
#define APT_VER_BAMBOO_BUILD "na"
#endif

// "4.3.2 20081105 (Red Hat 4.3.2-7)"
#ifndef APT_VER_COMPILE_CC_VERSION
// ansi says this should be defined, but check anyways
#ifdef __VERSION__
#define APT_VER_COMPILE_CC_VERSION __VERSION__
#else
#define APT_VER_COMPILE_CC_VERSION "unknown"
#endif
#endif

// "20091210-1501"
#ifndef APT_VER_COMPILE_DATE
#define APT_VER_COMPILE_DATE "unknown"
#endif

// "ostia", "parama"
#ifndef APT_VER_COMPILE_HOST
#define APT_VER_COMPILE_HOST "unknown"
#endif

// output from "uname"
// "Linux", "Darwin" 
#ifndef APT_VER_COMPILE_OS
#define APT_VER_COMPILE_OS "unknown"
#endif

// output from "id"
// "rsatin", "harley" 
#ifndef APT_VER_COMPILE_USER
#define APT_VER_COMPILE_USER "unknown"
#endif

// output from "uname -a"
// Linux leno.ev.affymetrix.com 2.6.27.25-170.2.72.fc10.x86_64 #1 SMP Sun Jun 21 18:39:34
#ifndef APT_VER_COMPILE_OS_VERSION
#define APT_VER_COMPILE_OS_VERSION "unknown"
#endif

// "1.10.2" "1.12.0"
#ifndef APT_VER_RELEASE
#define APT_VER_RELEASE "unknown"
#endif

// the output from "svnversion"
// See "svnversion --help" for how to interpret this number.
// "r12140M"
#ifndef APT_VER_SVN_VERSION
#define APT_VER_SVN_VERSION "unknown"
#endif

// where the checkout is rooted.
// from "svn info" but not currently captured.
// "svn://svn.ev.affymetrix.com/projects/apt/trunk/affy/sdk"
#ifndef APT_VER_SVN_URL
#define APT_VER_SVN_URL "unknown"
#endif

class AptVersionInfo {
    public:
        static std::string version() { 
            return ToStr(APT_VER_RELEASE); 
        }

        static std::string cvsId() { 
            return (ToStr(APT_VER_SVN_URL) + " " + ToStr(APT_VER_SVN_VERSION)); 
        }

        static std::string versionToReport() { 
            return version() + " " + cvsId() + " " + ToStr(APT_VER_BAMBOO_BUILD); 
        }

        static std::string reportBambooBuild() { 
            return ToStr(APT_VER_BAMBOO_BUILD); 
        }
        static std::string reportCompileCCVersion() { 
            return ToStr(APT_VER_COMPILE_CC_VERSION); 
        }
        static std::string reportCompileDate() { 
            return ToStr(APT_VER_COMPILE_DATE); 
        }
        static std::string reportCompileHost() { 
            return ToStr(APT_VER_COMPILE_HOST); 
        }
        static std::string reportCompileOS() { 
            return ToStr(APT_VER_COMPILE_OS);
        }
        static std::string reportRelease() { 
            return ToStr(APT_VER_RELEASE); 
        }
        static std::string reportSVNVersion() { 
            return ToStr(APT_VER_SVN_VERSION); 
        }
        static std::string reportSVNURL() { 
            return ToStr(APT_VER_SVN_URL); 
        }
};

#endif // _APTVERSIONINFO_H_