## Doxywrite

This script makes it easy to generate a Docset from your Xcode project via Doxygen. As an option, you can also install the generated Docset.

## Installation

The suggested installation involves copying the Doxywrite files into your home directory, followed by the creation of an alias pointing to the script.

1 - Create the Doxywrite directory in your home directory:

```
	>mkdir ~/.doxywrite
```

2 - Copy script and templates:

```
	>cp doxywrite.sh ~/.doxywrite
	>cp doxywrite-example.cfg ~/.doxywrite
	>cp -R DoxywriteTemplate ~/.doxywrite
```


3 - Add an alias to your `.bashrc` file:

```
	# doxywrite support
	alias doxywrite="sh ~/.doxywrite/doxywrite.sh"
```

**NOTE:** These instructions assume `bash` is your default shell.

### Cocoapods
>Due to technical and mission changes in the cocoapods project, it is no longer possible to install Doxywrite via cocoapods.


### Config file
Copy the provided "doxywrite-example.cfg" file to ".doxywrite.cfg" at the root of your project directory. At a minimum, you should setup the following parameters in the configuration file:

	DOCSET_PROJECT_NAME="MyProject"
	DOCSET_BUNDLE_ID="com.yourdomain.MyProject"
	DOCSET_PUBLISHER_ID="com.yourdomain.MyProject"
	DOCSET_PUBLISHER_NAME="Publisher"

**NOTE:** The leading dot is optional. If both ".doxywrite.cfg" and "doxywrite.cfg" exist, the file without the dot will take precedence.

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
Once you're ready to generate a Docset just run Doxywrite from the top level of your project.

	>cd /User/JOEUSER/dev/MyProject
	>doxywrite MyTarget

**NOTE:** These instructions assume the `doxywrite` script is in your path or has been aliased as described above.

To get a list of supported command line flags and parameters:

	>doxywrite -h

In general, options specified on the command line will override defaults and those found in the config file.

Doxywrite will look for a config file in the current directory. You can also specify a path on the command line:

	>doxywrite -c ./MyProject/MyTarget-doxywrite.cfg MyTarget

The ability to specify a config file path is how you can create different Doxwrite config files for each target in your project.

### Xcode Environment Var Import
With the -x (xcodeenv) flag specified, Doxywrite will import a few of the environment variables defined in Xcode and apply them accordingly:

Xcode Var          | Doxywrite Var        | Doxywrite Flag
---------          | -------------        | --------------
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

### Docset Installation
As of Doxywrite 1.1.8, installation of the generated Docset is optional. To install a Docset on your system, specify the -a (add-docset) flag.

## Xcode Run-Script
You can setup a run-script in Xcode to automate the process of generating updated documentation sets.

The run-script shell should point to /bin/sh, and the script itself will just call the Doxywrite script with relevant flags and options specified. In general, a common configuration would look like this:

	/bin/sh /Users/USERNAME/.doxywrite/doxywrite.sh -f -x MyTarget

In this example above, the script is invoked with the -f (force) flag and the -x (xcodeenv) flag so enabled to override prompts (e.g. for creation of missing directories) and to import environment variables from Xcode. Doxywrite will end up using Xcode's project/target temp directory to set wDirPath (PATH_WORK).

The following example specifies an alternative temp directory:

	/bin/sh /Users/USERNAME/.doxywrite/doxywrite.sh -f -x -t /tmp/DOXYTEMP MyTarget

The temp directory will be removed once Doxywrite has finished.

**NOTE:** Don't forget to add either "sh" or "/bin/sh" to the front of the script invocation. See **Permissions**.

**NOTE:** Unfortunately, Xcode requires that you specify a full path to the script as shown in the examples above.

### Permissions
Xcode will likely complain with a "Build Failed" message unless you do one of the following:

* Add "/bin/sh" or "sh" to the front of the script invocation as indicated in the above examples;
* Set the execute bits on the `~/.doxwyrite/doxywrite.sh` script (e.g. "chmod 755")

Of the above two options, the preferred method is to explicitly invoke the shell ahead of the script.


### Xcode Aggregate Target Setup
A clean way to setup automated documentation generation is to add an *Aggregate Target* to your Xcode project, possibly named "Documentation." See the following url for an excellent guide on how to do this:

[http://www.simplicate.info/2013/07/25/using-appledoc-to-generate-xcode-help-part-1/](http://www.simplicate.info/2013/07/25/using-appledoc-to-generate-xcode-help-part-1/)

## Bugs and such

Submit bugs by opening an issue on this project's github page.

## License

Doxywrite is licensed under the MIT open source license.

