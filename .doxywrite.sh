#!/bin/bash
#
# STEmacsModelines:
# -*- Shell-Unix-Generic -*-
#

# Copyright (c) 2014 Mark Eissler, mark@mixtur.com

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#
# To setup an Aggregate Target, see:
#   http://www.simplicate.info/1/post/2013/07/using-appledoc-to-generate-xcode-help-part-1.html
#

PATH=/usr/local/bin:/usr/texbin:${PATH}

PATH_MKDIR="/bin/mkdir"
PATH_HEAD="/usr/bin/head"
PATH_FIND="/usr/bin/find"
PATH_MAKE="/usr/bin/make"
PATH_CP="/bin/cp"
PATH_RM="/bin/rm"
PATH_TOUCH="/usr/bin/touch"
PATH_BASENAME="/usr/bin/basename"
PATH_DIRNAME="/usr/bin/dirname"

# Install gnu grep via homebrew... (this will not symlink for you)
#
# >brew tap homebrew/dupes
# >brew install homebrew/dupes/grep
#
# This will install the new grep as "ggrep" to avoid any conflicts with the BSD
# version of grep native to OSX.
#
PATH_GREP="/usr/local/bin/ggrep"

# Install gnu sed via homebrew... (this will not symlink for you)
#
# >brew tap homebrew/dupes
# >brew install gnu-sed
#
# This will install the new sed as "gsed" to avoid any conflicts with the BSD
# version of sed native to OSX.
#
PATH_SED="/usr/local/bin/gsed"

# Install doxygen via homebrew...
#
# >brew install doxygen
#
PATH_DOXYGEN="/usr/local/bin/doxygen"

# Generate class diagrams with dot (part of graphviz)
#
# >brew install graphviz
#
PATH_GRAPHVIZ_DOT="/usr/local/bin/dot"


###### NO SERVICABLE PARTS BELOW ######
VERSION=1.1.3
PROGNAME=`basename $0`

# standard config file location
PATH_CONFIG=".doxywrite.cfg"
PATH_OSASCRIPT="/usr/bin/osascript"

# reset internal vars (do not touch these here)
DEBUG=0
FORCEEXEC=0
XCODEENV=0
GETOPT_OLD=0
TARGETNAME=""
PATH_ROOT=""
PATH_SEARCH=""
PATH_OUTPUT=""
PATH_WORK=""

# standard BSD sed is called by cleanString(); we will find this
PATH_STD_SED=""

# temp paths for files that will be cleaned up
TMP_PATH_DOXY_CONFIG=".doxyfile.cfg"

# doxygen config
DOCSET_PROJECT_NAME="MyProject"
DOCSET_BUNDLE_ID="com.yourdomain.projectname"
DOCSET_PUBLISHER_ID="com.yourdomain.projectname"
DOCSET_PUBLISHER_NAME="Publisher"
DOCSET_PAGE_MAIN="README.md"

#
# FUNCTIONS
#
function usage {
  if [ ${GETOPT_OLD} -eq 1 ]; then
    usage_old
  else
    usage_new
  fi
}

function usage_new {
cat << EOF
usage: ${PROGNAME} [options] targetName

Generate a docset for an xcode project identified by targetName.

OPTIONS:
   -d, --debug                  Turn debugging on (increases verbosity)
   -c, --path-config cFilePath  Path to config file (default: .doxywrite.cfg)
   -r, --path-root   rDirPath   Path to project root directory
   -s, --path-search sDirPath   Path to directory for files to search
   -o, --path-output oDirPath   Path to output directory (default: project root)
   -w, --path-temp   wDirPath   Path to temporary directory (default: /tmp)
   -x, --xcodeenv               Import Xcode environment variables
   -f, --force                  Execute updates without user prompt
   -h, --help                   Show this message
   -v, --version                Output version of this script

EOF
}

# support for old getopt (non-enhanced, only supports short param names)
#
function usage_old {
cat << EOF
usage: ${PROGNAME} [options] targetName

Generate a docset for the the xcode project.

OPTIONS:
   -d                           Turn debugging on (increases verbosity)
   -c cFilePath                 Path to config file (default: .doxywrite.cfg)
   -r rDirPath                  Path to project root directory
   -s sDirPath                  Path to directory for files to search
   -o oDirPath                  Path to output directory (default: project root)
   -w wDirPath                  Path to temporary directory (default: /tmp)
   -x                           Import Xcode environment variables
   -f                           Execute updates without user prompt
   -h                           Show this message
   -v                           Output version of this script

EOF
}

function promptHelp {
cat << EOF
For help, run "${PROGNAME}" with the -h flag or without any options.

EOF
}

function version {
  echo ${PROGNAME} ${VERSION};
}

function cleanup {
  if [ -n "${PATH_WORK}" ] && [ -d "${PATH_WORK}" ]; then
    printf "Cleaning up... "
    if [[ $(isPathRoot "${PATH_ROOT}") -eq 0 ]]; then
      $PATH_RM -rf "${PATH_WORK}"
    fi
    echo "Done"
    echo
  fi
}

# cleanString
#
# Pass a variable name and this function will determine its current value, clean
# up the value, and then assign it back to the variable. This is tricky because
# we will dereference the var in order to access its value.
#
# Given a variable ${example} - or - $example, you will want to access this
# function like this:
#
#   cleanString example
#
# Not:
#
#   cleanString ${example} - or - cleanString $example
#
# Because the latter two will past the value and not the name of the variable.
# Which means we wouldn't be able to dereference it and assign a new value.
#
function cleanString {
  # remove quotes (leading or trailing, single or double)
  local t
  eval t=\$${1}
  if [ -n "${t}" ]; then
    # fetch name of variable passed in arg1
    _argVarName=\$${1}
    # get the current value of the variable
    _argVarValue=`eval "expr \"${_argVarName}\""`
    # clean up the value (1) - remove leading/trailing quotes (single or double)
    _argVarValue_Clean=$(echo ${_argVarValue} | ${PATH_STD_SED} "s/^[\'\"]//" |  ${PATH_STD_SED} "s/[\'\"]$//" );
    # clean up the value (2) - convert encoded values to unencoded
    _argVarValue_Clean=$(echo ${_argVarValue_Clean} |  ${PATH_STD_SED} 's@%3D@=@g' |  ${PATH_STD_SED} 's@%3A@:@g' | ${PATH_STD_SED} 's@%2F@\\/@g' );

    # assign the cleaned up value to the variable passed in arg1
    eval "${1}=\${_argVarValue_Clean}"
  fi
}

# Support for urlEncode and urlDecode string manipulation.
#
export LANG=C

# isGnuGrep()
#
# Checks for GNU Grep which supports PCRE (perl-type regex).
#
function isGnuGrep() {
  if [[ -z "${1}" ]]; then
    echo 0; return 1;
  fi

  RESP=$({ ${1} --version | ${PATH_HEAD} -n 1; } 2>&1 )
  RSLT=$?
  if [[ ! $RESP =~ "${1} (GNU grep)" ]]; then
    echo 0; return 1;
  fi

  echo 1; return 0;
}

# isGnuSed()
#
# Checks for GNU Sed which supports case insensitive match and replace.
#
function isGnuSed() {
  if [[ -z "${1}" ]]; then
    echo 0; return 1;
  fi

  RESP=$({ ${1} --version | ${PATH_HEAD} -n 1; } 2>&1 )
  RSLT=$?
  if [[ ! $RESP =~ "${1} (GNU sed)" ]]; then
    echo 0; return 1;
  fi

  echo 1; return 0;
}

# isPathRoot()
#
# Checks if a given string is at the root level of the volume.
#
# NOTE: The return pattern here is structured so that all of the following tests
# will work because we echo a value and set the return status...
#
# Using return value (function exit status captured in $?):
#  STAT=$(isNumber "${NUMBER}")
#  STAC=$?
#  if [[ ${STAC} -eq 0 ]]; then
#
# - or -
# Using echo value (captured in output from function):
#  if [[ $(isNumber "${NUMBER}") -eq 1 ]]; then
#
# - or -
# Using echo value (captured in output from function):
#  if [ $(isNumber "${NUMBER}") -eq 1 ]; then
#
function isPathRoot() {
  if [[ ${1} =~ ^\/[^\/.]*$ ]]; then
    # match
    echo 1; return 0
  else
    # no match
    echo 0; return 1
  fi
}

# isPathWriteable()
#
# Checks if a given path (file or directory) is writeable by the current user.
#
function isPathWriteable() {
  if [ -z "${1}" ]; then
    echo 0; return 1
  fi

  # path is a directory...
  if [[ -d "${1}" ]]; then
    if [[ $({ ${PATH_TOUCH} "${1}.test"; } 2>&1) ]]; then
      # not writeable directory
      echo 0; return 1
    else
      # writeable directory
      ${PATH_RM} "${1}.test"
      echo 1; return 0
    fi
  fi

  # path is a file...
  if [ -w "${1}" ]; then
    # writeable file
    echo 1; return 0
  else
    # not writeable file
    echo 0; return 1
  fi

  # and if we fall through...
  echo 0; return 128
}

# promptConfirm()
#
# Confirm a user action. Input case insensitive.
#
# Returns "yes" or "no" (default).
#
function promptConfirm() {
  read -p "$1 ([y]es or [N]o): "
  case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
    y|yes) echo "yes" ;;
    *)     echo "no" ;;
  esac
}

# parse cli parameters
#
# Our options:
#   --path-config, c
#   --path-root, r
#   --path-search, s
#   --path-output, o
#   --path-work, w
#   --debug, d
#   --force, f
#   --help, h
#   --version, v
#
params=""
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  PROGNAME=`basename $0`
  params="$(getopt --name "$PROGNAME" --long path-config:,path-root:,path-search:,path-output:,path-work:,xcodeenv,force,help,version,debug --options c:r:s:o:w:xfhvd -- "$@")"
else
  # Original getopt is available
  GETOPT_OLD=1
  PROGNAME=`basename $0`
  params="$(getopt c:r:s:o:w:xfhvd "$@")"
fi

# check for invalid params passed; bail out if error is set.
if [ $? -ne 0 ]
then
  usage; exit 1;
fi

eval set -- "$params"
unset params

while [ $# -gt 0 ]; do
  case "$1" in
    -c | --path-config)     cli_CONFIGPATH="$2"; shift;;
    -r | --path-root)       cli_ROOTPATH="$2"; shift;;
    -s | --path-search)     cli_SEARCHPATH="$2"; shift;;
    -o | --path-output)     cli_OUTPUTPATH="$2"; shift;;
    -w | --path-work)       cli_WORKPATH="$2"; shift;;
    -x | --xcodeenv)        cli_XCODEENV=1; XCODEENV=${cli_XCODEENV};;
    -d | --debug)           cli_DEBUG=1; DEBUG=${cli_DEBUG};;
    -f | --force)           cli_FORCEEXEC=1;;
    -v | --version)         version; exit;;
    -h | --help)            usage; exit;;
    --)                     shift; break;;
  esac
  shift
done

# Grab final argument (the target name)
shift $((OPTIND-1))
if [ -z "${1}" ]; then
  echo "ABORTING. You must specify a targetName string."
  echo
  usage
  exit 1
else
  cli_TARGETNAME="${1}"
fi

# Configure std sed
#
if [[ -n "${PATH_SED}" ]] && [[ -x "${PATH_SED}" ]]; then
  PATH_STD_SED="${PATH_SED}"
elif [[ -x "/usr/bin/seds" ]]; then
  PATH_STD_SED="/usr/bin/sed"
else
  echo
  echo "FATAL. Something is wrong with this system. Unable to find standard sed."
  echo
  exit 1
fi

# Clean up and import Xcode environment variables
#
# PROJECT_NAME -> DOCSET_PROJECT_NAME
# SOURCE_ROOT -> PATH_ROOT
# TARGET_TEMP_DIR -> PATH_WORK
#
if [ "${XCODEENV}" -ne 0 ]; then
  if [ -n "${PROJECT_NAME}" ]; then
    env_PROJECT_NAME="${PROJECT_NAME}"
    cleanString env_PROJECT_NAME
    DOCSET_PROJECT_NAME="${env_PROJECT_NAME}"
  fi

  if [ -n "${SOURCE_ROOT}" ]; then
    env_SOURCE_ROOT="${SOURCE_ROOT}"
    cleanString env_SOURCE_ROOT
    PATH_ROOT="${env_SOURCE_ROOT}"
  fi

  if [ -n "${TARGET_TEMP_DIR}" ]; then
    env_TARGET_TEMP_DIR="${TARGET_TEMP_DIR}"
    cleanString env_TARGET_TEMP_DIR
    PATH_WORK="${env_TARGET_TEMP_DIR}"
  fi
fi

# Grab our config file path from the cli if provided
#
if [ -n "${cli_CONFIGPATH}" ]; then
  cleanString cli_CONFIGPATH;
  PATH_CONFIG=${cli_CONFIGPATH};
fi

# load config
echo
printf "Checking for a config file... "
if [ -s "${PATH_CONFIG}" ] && [ -r "${PATH_CONFIG}" ]; then
  source "${PATH_CONFIG}" &> /dev/null
else
  printf "!!"
  echo
  echo "ABORTING. The doxywrite config file ("${PATH_CONFIG}") is missing or empty!"
  echo
  _configDir=$(${PATH_DIRNAME} "${PATH_CONFIG}")
  _configExample="${_configDir}/.doxywrite-example.cfg"
  if [ -f "${_configExample}" ]; then
    echo "It looks like the example config file exists in the same location: "
    echo
    echo "     ${_configExample}"
    echo
    echo "Did you remember to customize and appropriately rename a copy of the example?"
    echo
  fi
  unset _configDir
  unset _configExample
  exit 1
fi
echo "Found: ${PATH_CONFIG}"
echo

# Verify grep version
printf "Checking for a compatible version of grep... "
if [[ $(isGnuGrep "${PATH_GREP}") -eq 0 ]]; then
  printf "!!"
  echo
  echo "ABORTING. Couldn't find a compatible version of grep. GNU grep is required."
  echo
  exit 1
fi
echo "Found: ${PATH_GREP}"
echo

# Verify sed version
printf "Checking for a compatible version of sed... "
if [[ $(isGnuSed "${PATH_SED}") -eq 0 ]]; then
  printf "!!"
  echo
  echo "ABORTING. Couldn't find a compatible version of sed. GNU sed is required."
  echo
  exit 1
fi
echo "Found: ${PATH_SED}"
echo
# Update standard sed to configured value (maybe have been overriden in cfg)
PATH_STD_SED="${PATH_SED}"

##
## SAFE TO CALL GNU GREP AND GNU SED FROM HERE ON IN!
##

# Clean up config file parameters
#
cleanString TARGETNAME
cleanString DOCSET_PROJECT_NAME
cleanString DOCSET_BUNDLE_ID
cleanString DOCSET_PUBLISHER_ID
cleanString DOCSET_PUBLISHER_NAME
cleanString DOCSET_PAGE_MAIN
cleanString PATH_ROOT
cleanString PATH_SEARCH
cleanString PATH_OUTPUT
cleanString PATH_WORK
cleanString PATH_DOXYGEN
cleanString PATH_GRAPHVIZ_DOT

# Rangle our vars
#
# The cli_VARS will override config file vars!!
#
if [ -n "${cli_FORCEEXEC}" ]; then
  FORCEEXEC=${cli_FORCEEXEC};
fi

if [ -n "${cli_TARGETNAME}" ]; then
  cleanString cli_TARGETNAME
  TARGETNAME=${cli_TARGETNAME};

  if [ "${DEBUG}" -ne 0 ]; then
    echo "TARGETNAME set from cli: ${TARGETNAME}"
  fi
fi

if [ -n "${cli_ROOTPATH}" ]; then
  cleanString cli_SEARCHPATH;
  PATH_ROOT=${cli_ROOTPATH};
fi
# If PATH_ROOT is still empty, configure to PWD
if [ -z "${PATH_ROOT}" ]; then
  PATH_ROOT="${PWD}"
fi
# If PATH_ROOT is on / (root), bail out
if [[ $(isPathRoot "${PATH_ROOT}") -eq 1 ]]; then
  echo
  echo "ABORTING. You have specified a rDirPath on the / (root) directory: ${PATH_ROOT}"
  echo "I don't want to work there."
  echo
  usage
  exit 1
fi

if [ -n "${cli_SEARCHPATH}" ]; then
  cleanString cli_SEARCHPATH;
  PATH_SEARCH=${cli_SEARCHPATH};
fi
# If PATH_SEARCH is still empty, configure to PATH_ROOT
if [ -z "${PATH_SEARCH}" ]; then
  PATH_SEARCH="${PATH_ROOT}"
fi
# If PATH_SEARCH is on / (root), bail out
if [[ $(isPathRoot "${PATH_SEARCH}") -eq 1 ]]; then
  echo
  echo "ABORTING. You have specified a sDirPath on the / (root) directory: ${PATH_SEARCH}"
  echo "I don't want to work there."
  echo
  promptHelp
  exit 1
fi

if [ -n "${cli_WORKPATH}" ]; then
  cleanString cli_WORKPATH;
  PATH_WORK="${cli_WORKPATH}";
fi
# If PATH_WORK is still empty, configure to /tmp
if [ -z "${PATH_WORK}" ]; then
  PATH_WORK="/tmp"
fi
# If PATH_WORK is on / (root), bail out
if [[ $(isPathRoot "${PATH_WORK}") -eq 1 ]]; then
  echo
  echo "ABORTING. You have specified a wDirPath on the / (root) directory: ${PATH_WORK}"
  echo "I don't want to work there."
  echo
  promptHelp
  exit 1
fi

if [ -n "${cli_OUTPUTPATH}" ]; then
  cleanString cli_OUTPUTPATH;
  PATH_OUTPUT="${cli_OUTPUTPATH}";
fi
# If PATH_OUTPUT is still empty, configure to PATH_ROOT/Documentation
if [ -z "${PATH_OUTPUT}" ]; then
  PATH_OUTPUT="${PATH_ROOT}/Documentation"
fi
# If PATH_OUTPUT is on / (root), bail out
if [[ $(isPathRoot "${PATH_OUTPUT}") -eq 1 ]]; then
  echo
  echo "ABORTING. You have specified a oDirPath on the / (root) directory: ${PATH_OUTPUT}"
  echo "I don't want to work there."
  echo
  promptHelp
  exit 1
fi

#
# NONE OF THE FOLLOWING CAN BE SET FROM CLI AS OF YET but we can adjust defaults
#
# DOCSET_PROJECT_NAME
# DOCSET_PUBLISHER_ID
# DOCSET_PUBLISHER_NAME
# DOCSET_PAGE_MAIN
# PATH_DOXYGEN
# PATH_GRAPHVIZ_DOT
#

if [ -z "${DOCSET_PROJECT_NAME}" ]; then
  DOCSET_PROJECT_NAME="${TARGETNAME}"
fi

# bail out if minimum config isn't available
#
# @TODO: need to complete minimum config requirements
#
if [ -z "${TARGETNAME}" ] || [ -z "${PATH_WORK}" ] || [ -z "${PATH_ROOT}" ]; then
  echo; usage;
  exit 1
fi

#
# Let's GO!
#

# Make sure PATH_WORK exists, create it if it doesn't
printf "Checking for ${PATH_WORK} working directory... "
if [[ -d "${PATH_WORK}" ]] && [[ $(isPathWriteable "${PATH_WORK}") -ne 1 ]]; then
  echo "Found: ${PATH_WORK}"
  echo
  echo "ABORTING. Unable to access Doxywrite working directory: ${PATH_WORK}"
  echo "Must be a write permissions error."
  echo
  exit 1
elif [[ ! -d "${PATH_WORK}" ]]; then
  printf "!!"
  echo
  echo "Doxywrite working directory appears to be missing. "
  echo
  if [[ "${FORCEEXEC}" -eq 0 ]]; then
    echo "Ready to create Doxywrite working directory with configured path: ${PATH_WORK}"
    # prompt user for confirmation
    if [[ "no" == $(promptConfirm "Create working directory?") ]]
    then
      echo "Aborting."
      exit 1
    fi
  fi

  echo "Creating Doxywrite working directory with configured path: ${PATH_WORK}"

  RESP=$({ $PATH_MKDIR -p "${PATH_WORK}"; } 2>&1 )
  RSLT=$?
  if [[ ${RSLT} -ne 0 ]]; then
    echo
    echo "ABORTING. Unable to create Doxywrite working diretory: ${PATH_WORK}"
    echo "Not sure what the problem is."
    echo
    exit 1
  fi

  echo
else
  echo "Found: ${PATH_WORK}"
  echo
fi

# Make sure PATH_OUTPUT exists, create it if it doesn't
printf "Checking for ${PATH_OUTPUT} output directory... "
if [[ -d "${PATH_OUTPUT}" ]] && [[ $(isPathWriteable "${PATH_OUTPUT}") -ne 1 ]]; then
  echo "Found: ${PATH_OUTPUT}"
  echo
  echo "ABORTING. Unable to access Doxywrite output directory: ${PATH_OUTPUT}"
  echo "Must be a write permissions error."
  echo
  cleanup
  exit 1
elif [[ ! -d "${PATH_OUTPUT}" ]]; then
  printf "!!"
  echo
  echo "Doxywrite output directory appears to be missing. "
  echo
  if [[ "${FORCEEXEC}" -eq 0 ]]; then
    echo "Ready to create Doxywrite output directory with configured path: ${PATH_OUTPUT}"
    # prompt user for confirmation
    if [[ "no" == $(promptConfirm "Create output directory?") ]]
    then
      echo "Aborting."
      cleanup; exit 1
    fi
  fi

  echo "Creating Doxywrite output directory with configured path: ${PATH_OUTPUT}"

  RESP=$({ $PATH_MKDIR -p "${PATH_OUTPUT}"; } 2>&1 )
  RSLT=$?
  if [[ ${RSLT} -ne 0 ]]; then
    echo
    echo "ABORTING. Unable to create Doxywrite output diretory: ${PATH_OUTPUT}"
    echo "Not sure what the problem is."
    echo
    cleanup; exit 1
  fi

  echo
else
  echo "Found: ${PATH_OUTPUT}"
  echo
fi

# Find doxygen config file (aka "Doxyfile")
TMP_PATH_DOXY_CONFIG="${PATH_WORK}/${TARGETNAME}-Doxyfile.cfg"
printf "Checking for ${TMP_PATH_DOXY_CONFIG} file... "
if [[ -f "${TMP_PATH_DOXY_CONFIG}" ]] && [[ ! -w "${TMP_PATH_DOXY_CONFIG}" ]]; then
  echo "Found: ${TMP_PATH_DOXY_CONFIG}"
  echo
  echo "ABORTING. Unable to access Doxygen config file: ${TMP_PATH_DOXY_CONFIG}"
  echo "Must be a write permissions error."
  echo
  cleanup; exit 1
elif [[ ! -f "${TMP_PATH_DOXY_CONFIG}" ]]; then
  printf "!!"
  echo
  echo "Doxygen config file appears to be missing. "
  echo
  if [[ "${FORCEEXEC}" -eq 0 ]]; then
    echo "Ready to create Doxygen config file with configured path: ${TMP_PATH_DOXY_CONFIG}"
    # prompt user for confirmation
    if [[ "no" == $(promptConfirm "Create config file?") ]]
    then
      echo "Aborting."
      cleanup; exit 1
    fi
  fi

  echo "Creating Doxygen config file with configured path: ${TMP_PATH_DOXY_CONFIG}"

  RESP=$({ $PATH_DOXYGEN -g "${TMP_PATH_DOXY_CONFIG}"; } 2>&1 )
  RSLT=$?
  if [[ ${RSLT} -ne 0 ]]; then
    echo
    echo "ABORTING. Unable to create Doxygen config file: ${TMP_PATH_DOXY_CONFIG}"
    echo "Not sure what the problem is."
    echo
    cleanup; exit 1
  fi

  echo
else
  echo "Found: ${TMP_PATH_DOXY_CONFIG}"
  echo
fi

# Doxygen will complain if the output directory doesn't exist. The warning will
# trigger an error in Xcode and result in a failed build...even though Doxygen
# goes and creates the directory. Redirecting errors does not seem to help, but
# it would be heavyhanded to do so. Let's just proactively create the directory.

# Find doxygen docset directory
TMP_PATH_DOXY_DOCSET="${PATH_WORK}/${TARGETNAME}-Documentation.docset"
printf "Checking for ${TMP_PATH_DOXY_DOCSET} Doxygen temp output directory... "
if [[ -d "${TMP_PATH_DOXY_DOCSET}" ]] && [[ $(isPathWriteable "${TMP_PATH_DOXY_DOCSET}") -ne 1 ]]; then
  echo "Found: ${TMP_PATH_DOXY_DOCSET}"
  echo
  echo "ABORTING. Unable to access Doxygen temp output directory: ${TMP_PATH_DOXY_DOCSET}"
  echo "Must be a write permissions error."
  echo
  cleanup; exit 1
elif [[ ! -d "${TMP_PATH_DOXY_DOCSET}" ]]; then
  printf "!!"
  echo
  echo "Doxygen temp output directory appears to be missing. "
  echo
  if [[ "${FORCEEXEC}" -eq 0 ]]; then
    echo "Ready to create Doxygen temp output directory with configured path: ${TMP_PATH_DOXY_DOCSET}"
    # prompt user for confirmation
    if [[ "no" == $(promptConfirm "Create Doxygen temp output directory?") ]]
    then
      echo "Aborting."
      cleanup; exit 1
    fi
  fi

  echo "Creating Doxygen temp output directory with configured path: ${TMP_PATH_DOXY_DOCSET}"

  RESP=$({ $PATH_MKDIR -p "${TMP_PATH_DOXY_DOCSET}"; } 2>&1 )
  RSLT=$?
  if [[ ${RSLT} -ne 0 ]]; then
    echo
    echo "ABORTING. Unable to create Doxygen temp output diretory: ${TMP_PATH_DOXY_DOCSET}"
    echo "Not sure what the problem is."
    echo
    cleanup; exit 1
  fi
else
  echo "Found: ${TMP_PATH_DOXY_DOCSET}"
  echo
fi

#
# Customize Doxygen config file
#
${PATH_SED} -i -r "s#^PROJECT_NAME\ *=.*#PROJECT_NAME = \"${DOCSET_PROJECT_NAME}\"#g" "${TMP_PATH_DOXY_CONFIG}"
${PATH_SED} -i -r "s#^INPUT\ *=.*#INPUT = \"${PATH_SEARCH}\"#g" "${TMP_PATH_DOXY_CONFIG}"
${PATH_SED} -i -r "s#^OUTPUT_DIRECTORY\ *=.*#OUTPUT_DIRECTORY = \"${TMP_PATH_DOXY_DOCSET}\"#g" "${TMP_PATH_DOXY_CONFIG}"
${PATH_SED} -i -r "s#^DOCSET_BUNDLE_ID\ *=.*#DOCSET_BUNDLE_ID = \"${DOCSET_BUNDLE_ID}\"#g" "${TMP_PATH_DOXY_CONFIG}"
${PATH_SED} -i -r "s#^DOCSET_PUBLISHER\ *=.*#DOCSET_PUBLISHER = \"${DOCSET_PUBLISHER_NAME}\"#g" "${TMP_PATH_DOXY_CONFIG}"
${PATH_SED} -i -r "s#^DOCSET_PUBLISHER_ID\ *=.*#DOCSET_PUBLISHER_ID = \"${DOCSET_PUBLISHER_ID}\"#g" "${TMP_PATH_DOXY_CONFIG}"

# Exclude Cocoapods
${PATH_SED} -i -r "s#^EXCLUDE_PATTERNS\ *=.*#EXCLUDE_PATTERNS = */Pods/*#g" "${TMP_PATH_DOXY_CONFIG}"

# Use the README.md file as the main page (index.html)
${PATH_SED} -i -r "s#^USE_MDFILE_AS_MAINPAGE\ *=.*#USE_MDFILE_AS_MAINPAGE = ${DOCSET_PAGE_MAIN}#g" "${TMP_PATH_DOXY_CONFIG}"

# Follow directory trees recursively
${PATH_SED} -i -r "s#^RECURSIVE\ *=.*#RECURSIVE = YES#g" "${TMP_PATH_DOXY_CONFIG}"

# Tell doxygen to generate a docset.
${PATH_SED} -i -r "s#^GENERATE_DOCSET\ *=.*#GENERATE_DOCSET = YES#g" "${TMP_PATH_DOXY_CONFIG}"

# Don't generate LATEX output.
${PATH_SED} -i -r "s#^GENERATE_LATEX\ *=.*#GENERATE_LATEX = NO#g" "${TMP_PATH_DOXY_CONFIG}"

# Don't repeat the @brief description in the extended class and method descriptions.
${PATH_SED} -i -r "s#^REPEAT_BRIEF\ *=.*#REPEAT_BRIEF = NO#g" "${TMP_PATH_DOXY_CONFIG}"

# Javadoc style list of links at the top of the page.
#${PATH_SED} -e "s#^JAVADOC_AUTOBRIEF\ *=.*#JAVADOC_AUTOBRIEF = YES#g" "${TMP_PATH_DOXY_CONFIG}"

# Insert the @brief description into the class member list at the top of each class reference page.
${PATH_SED} -i -r "s#^INLINE_INHERITED_MEMB\ *=.*#INLINE_INHERITED_MEMB = YES#g" "${TMP_PATH_DOXY_CONFIG}"

# Extracts documentation for **everything**, including stuff you might not want the user to know about.
# You can still cause doxygen to skip stuff using special commands. If that's what you prefer uncomment
# this and comment out the two lines below this one.
${PATH_SED} -i -r "s#^EXTRACT_ALL\ *=.*#EXTRACT_ALL = YES#g" "${TMP_PATH_DOXY_CONFIG}"

# Hide undocumented members and classes.
${PATH_SED} -i -r "s#^HIDE_UNDOC_MEMBERS\ *=.*#HIDE_UNDOC_MEMBERS = YES#g" "${TMP_PATH_DOXY_CONFIG}"
${PATH_SED} -i -r "s#^HIDE_UNDOC_CLASSES\ *=.*#HIDE_UNDOC_CLASSES = YES#g" "${TMP_PATH_DOXY_CONFIG}"

# Enable class diagrams if you have dot installed...
if [[ -x "${PATH_GRAPHVIZ_DOT}" ]]; then
  ${PATH_SED} -i -r "s#^HAVE_DOT\ *=.*#HAVE_DOT = YES#g" "${TMP_PATH_DOXY_CONFIG}"
  ${PATH_SED} -i -r "s#^DOT_PATH\ *=.*#DOT_PATH = \"${PATH_GRAPHVIZ_DOT}#g" "${TMP_PATH_DOXY_CONFIG}"
fi

# Additional diagram generation tweaks..
#
#${PATH_SED} -i -r "s#^TEMPLATE_RELATIONS\ *=.*#TEMPLATE_RELATIONS = YES#g" "${TMP_PATH_DOXY_CONFIG}"

# Copy the updated config file to project directory
echo "Copying Doxygen config file to project directory: ${PATH_ROOT}"
RESP=$({ $PATH_CP "${TMP_PATH_DOXY_CONFIG}" "${PATH_ROOT}"; } 2>&1 )
RSLT=$?
if [[ ${RSLT} -ne 0 ]]; then
  echo
  echo "WARNING. Unable to copy Doxygen config file to directory: ${PATH_ROOT}"
  echo "Not sure what the problem is."
  echo
  exit 1
else
  echo "Finished!"
  echo
fi

# Run doxygen on the updated config file.
printf "Generating documentation docset..."
RESP=$({ $PATH_DOXYGEN "${TMP_PATH_DOXY_CONFIG}"; } 2>&1 )
RSLT=$?
if [[ ${RSLT} -ne 0 ]]; then
  echo
  echo "ABORTING. Unable to generate documentation."
  echo "Not sure what the problem is."
  echo
  cleanup; exit 1
else
  echo "Finished!"
  echo
fi

# Copy the generated documentation to output directory
echo "Copying Documentation to output directory: ${PATH_OUTPUT}"
RESP=$({ $PATH_CP -R "${TMP_PATH_DOXY_DOCSET}" "${PATH_OUTPUT}"; } 2>&1 )
RSLT=$?
if [[ ${RSLT} -ne 0 ]]; then
  echo
  echo "WARNING. Unable to copy Documentation to output directory: ${PATH_OUTPUT}"
  echo "Not sure what the problem is. Continuing..."
  echo
else
  echo "Finished!"
  echo
fi

# Install docset via docsetutil.
echo "Installing docset..."
RESP=$({ ${PATH_MAKE} -C "${TMP_PATH_DOXY_DOCSET}/html" install; } 2>&1 )
RSLT=$?
if [[ ${RSLT} -ne 0 ]]; then
  echo
  echo "WARNING. Unable to generate Docset loader script."
  echo "Not sure what the problem is."
  echo
else
  printf "Docset installed. "

  #  Construct a temporary applescript file to tell Xcode to load a docset.
  printf "Generating Xcode Docset loader... "
  ${PATH_RM} -f "${PATH_WORK}/loadDocSet.scpt"
  echo "tell application \"Xcode\"" >> "${PATH_WORK}/loadDocSet.scpt"
  echo "load documentation set with path \"/Users/$USER/Library/Developer/Shared/Documentation/DocSets/$DOCSET_BUNDLE_ID.docset\"" >> "${PATH_WORK}/loadDocSet.scpt"
  echo "end tell" >> "${PATH_WORK}/loadDocSet.scpt"
  echo "Finished!"
  echo

  #  Run the load-docset applescript command.
  echo "Docset: /Users/$USER/Library/Developer/Shared/Documentation/DocSets/$DOCSET_BUNDLE_ID.docset"

  printf "Loading Docset into Xcode... "
  RESP=$({ ${PATH_OSASCRIPT} "${PATH_WORK}/loadDocSet.scpt"; } 2>&1 )
  RSLT=$?
  if [[ ${RSLT} -ne 0 ]]; then
    echo
    echo "WARNING. Unable to copy load Docset into Xcode."
    echo "Not sure what the problem is."
    echo
  fi
  echo "Finished!"
  echo
fi

cleanup; exit 0
