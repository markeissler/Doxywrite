## Doxywrite

This script makes it easy to generate a DocSet from your Xcode project via Doxygen.

## Installation

Copy .doxrywrite.sh (script) and .doxywrite.cfg (config) files into the top-level of your Xcode project. Edit the config file parameters and PATH parameters in the script as needed.

**NOTE:** It is intended that you copy **both** of these files into your project so that you won't have to worry about future changes to this code.

### Config file
At a minimum, you should setup the following parameters in the configuration file:

	DOCSET_BUNDLE_ID="com.yourdomain.projectname"
	DOCSET_PUBLISHER_ID="com.yourdomain.projectname"
	DOCSET_PUBLISHER_NAME="Publisher"

You can also specify the target here so you won't have to supply it on the command line:

	TARGETNAME="MyProject"

### Info.plist path
Xcodebump will search the current directory for the appropriate Info.plist file based on the TARGETNAME using *find(1)*. Under some circumstances you may need to manually specify the path:

	>sh ../.xcodebump.sh -l MyTarget/Info.plist 2.5.1
	
### Script PATHs
Verify paths to grep, sed, doxygen:

	PATH_GREP="/usr/local/bin/ggrep"
	PATH_SED="/usr/local/bin/gsed"
	PATH_DOXYGEN="/usr/local/bin/doxygen"
	
It is unlikely you'll have to edit any remaining PATHs that are defined in the script as they point to system defaults.
	
The custom path to grep is absolutely necessary as it must point to a GNU grep, which is not installed on current distributions of OSX. As noted in the .xcodebump.cfg file, you can install that version of grep using [homebrew](http://brew.sh/):

	>brew tap homebrew/dupes
	>brew install homebrew/dupes/grep

The above commands will install the new grep as "ggrep" so you can avoid any potential conflicts with the BSD version of grep native to OSX.

You will also need to install GNU sed in the same way:

	>brew install gnu-sed
	
The above commands will install the new sed as "gsed" so you can avoid any potential conflicts with the BSD version of grep native to OSX.

To install doxygen, once again, use [homebrew](http://brew.sh/):

	>brew install doxygen
	
### Class Diagram Support
To support the generation of class diagrams, you will need to have dot installed. To get dot, just install graphiz using [homebrew](http://brew.sh/):

	>brew install graphviz
	
## Usage
**--TBD--**

## Xcode Run-Script
You can setup a run-script in Xcode to automate the process of generating updated documentation sets.

**--TBD--**

## Bugs and such

Submit bugs by opening an issue on this project's github page.

## License

Xcodebump is licensed under the MIT open source license.

## Appreciation
Like this script? Let me know! You can send some kudos my way courtesy of Flattr:

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=markeissler&url=https://github.com/markeissler/Doxywrite&title=Doxywrite&language=bash&tags=github&category=software)
