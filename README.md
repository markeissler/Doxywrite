## Doxywrite

This script makes it easy to generate a DocSet from your Xcode project via Doxygen.

## Installation

Copy .doxrywrite.sh (script) and .doxywrite.cfg (config) files into the top-level of your Xcode project. Edit the config file parameters and PATH parameters in the script as needed.

**NOTE:** It is intended that you copy **both** of these files into your project so that you won't have to worry about future changes to this code.

### Config file
At a minimum, you should setup the following parameters in the configuration file:

	DOCSET_PROJECT_NAME="MyProject"
	DOCSET_BUNDLE_ID="com.yourdomain.projectname"
	DOCSET_PUBLISHER_ID="com.yourdomain.projectname"
	DOCSET_PUBLISHER_NAME="Publisher"

	
### Script PATHs
Verify paths to grep, sed, doxygen:

	PATH_GREP="/usr/local/bin/ggrep"
	PATH_SED="/usr/local/bin/gsed"
	PATH_DOXYGEN="/usr/local/bin/doxygen"
	
It is unlikely you'll have to edit any remaining PATHs that are defined in the script as they point to system defaults.
	
The custom path to grep is absolutely necessary as it must point to GNU grep), which is not installed on current distributions of OSX. As noted in the .doxywrite.cfg file, you can install GNU grep using [homebrew](http://brew.sh/):

	>brew tap homebrew/dupes
	>brew install grep

The above commands will install the GNU grep as "ggrep" (instead of just "grep") so you can avoid any potential conflicts with the BSD version of grep native to OSX.

You will also need to install GNU sed in the same way:

	>brew install gnu-sed
	
The above commands will install the new sed as "gsed" so you can avoid any potential conflicts with the BSD version of grep native to OSX.

To install doxygen, once again, use [homebrew](http://brew.sh/):

	>brew install doxygen
	
### Class Diagram Support
To support the generation of class diagrams, you will need to have dot installed. To get dot, just install graphiz using [homebrew](http://brew.sh/):

	>brew install graphviz
	
## Usage
Once you're ready to generate a DocSet just run Xcodebump from the top level of your project.

	>sh ./.doxywrite MyTarget
	
To get a list of supported command line flags and parameters:

	>sh ./.doxywrite -h

In general, options specified on the command line will override defaults and those found in the config file.

Doxywrite will look for a config file (.doxywrite.cfg) in the current directory. You can also specify a path on the command line:

	>sh ./.doxywrite.sh -c ./MyProject/MyTarget-doxywrite.cfg MyTarget
	
The ability to specify a config file path is how you can create different Doxwrite config files for each target in your project.

### Xcode Environment Var Import
With the -x (xcodeenv) flag specified, Doxywrite will import a few of the environment variables defined in Xcode and apply them accordingly:

Xcode Var          | Doxywrite Var        | Doxywrite Flag
---------          |
PROJECT_NAME       | DOCSET_PROJECT_NAME  | none
SOURCE_ROOT        | PATH_ROOT            | -r rDirPath
TARGET_TEMP_DIR    | PATH_WORK            | -w wDirPath

### Parameter Value Preference
Configured values are considered in this order of preference where each subsequent level is awarded a higher preference:

* Xcode Environment Vars
* .doxywrite.cfg (config file)
* command line options (flag and parameters)

As you can see, command line options are always given the highest preference.

### Documentation Output
Doxwrite will place a copy of the generated documentation into the root directory of your project or into the directory specified with the -o (path-output) flag.

**NOTE:** You may want to add the "Documentation" directory to your project's *.gitignore* file.

## Xcode Run-Script
You can setup a run-script in Xcode to automate the process of generating updated documentation sets.

The run-script shell should point to /bin/sh, and the script itself will just call the Doxywrite script with relevant flags and options specified. In general, a common configuration would look like this:

	/Users/USERNAME/MYPROJECT/.doxywrite.sh -f -x MyTarget

In this example above, the script is invoked with the -f (force) flag and the -x (xcodeenv) flag so enabled to override prompts (e.g. for creation of missing directories) and to import environment variables from Xcode. Doxywrite will end up using Xcode's project/target temp directory to set wDirPath (PATH_WORK).

The following example specifies an alternative temp directory:
	
	/Users/USERNAME/MYPROJECT/.doxywrite.sh -f -x -t /tmp/DOXYTEMP MyTarget

The temp directory will be removed once Doxywrite has finished.

### Xcode Aggregate Target Setup
**--TBD--**

## Bugs and such

Submit bugs by opening an issue on this project's github page.

## License

Xcodebump is licensed under the MIT open source license.

## Appreciation
Like this script? Let me know! You can send some kudos my way courtesy of Flattr:

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=markeissler&url=https://github.com/markeissler/Doxywrite&title=Doxywrite&language=bash&tags=github&category=software)
