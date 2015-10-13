
mx-1.2.0 / 2015-10-13
=====================

NOTE: This release drops support for Cocoapods. Unfortunately, technical changes to Cocoapods that better align with a narrowed mission mean this mode of installation can no longer be implemented. Instructions have been updated to reflect a refined manual install.
  
  * Updated README for 1.2.0 release.
  * Fix output to include DOCSET_PAGE_MAIN in search path.
  * Add support for finding project config file with or without preceding dot.
  * Remove dots from example config and doxywrite script file.
  * Fix tmp path again.
  * Remove pod-specific files.
  * Fix large gap under Discussion title.
  * Fix brief tag output for class discussion section.
  * Add support for DOXYGEN preproc flag.
  * Fix missing trailing quote for DOT_PATH.
  * Add support for better macro handling.
  * Implement separation of @brief and main discussion text.
  * Add support to isolate brief description and discussion content.
  * Improved reliability of isPathWriteable(). Add slash to directories that don't end with one.
  * Correction to vers specified when Docset install became optional. Should have been 1.1.8 instead of 1.8.0.

mx-1.1.11 / 2015-04-23
======================

  * Fix output of number of ENUM values output per line.
  * Improved reliability of isPathWriteable(). Add slash to directories that don't end with one.
  * Fix version number.

mx-1.1.10 / 2015-04-20
======================

  * Add support for case-insensitive BUG tag for generating BUG list.
  * Add support for case-insensitive TODO/FIXME for generating TODO list.
  * Fix support for Apple NS_ENUM typedef macro.

mx-1.1.9 / 2015-04-10
=====================

  * Fix link to documentation on Xcode Aggregate Target Setup.

mx-1.1.8 / 2014-05-15
=====================

  * Updated to make Docset install optional.

mx-1.1.7 / 2014-05-08
=====================

  * Bug fix. File permissions were incorrect for core script. We do not want execute bits on.

mx-1.1.6 / 2014-05-08
=====================

  * Corrections to documentation.

mx-1.1.5 / 2014-05-08
=====================

  * Bug fixes. Inconsistent version numbers.

mx-1.1.4 / 2014-05-08
=====================

  * Fixed default DOCSET values for BUNDLE_ID and PUBLISHER_ID.
  * Fixed incorrect standard sed path.

mx-1.1.3 / 2014-05-07
=====================

  * Corrections to documentation. Added section on explicitly invoking shell when using Xcode Run-Script.
  * Added EXCLUDE_PATTERN for Pods directory. Doxygen was scanning it.
  * Fixed pass-through of wrapper cli options to the actuals doxywrite script.
  * Added more clarity to the use of DOCSET settings. Uncommented settings that should be customized.
  * Removed cruft.
  * Updated to include comments on configuring .gitignore.
  * Added some smarts to wrapper in case a user has checked in the config file but not the Pods.
  * Corrected preserve_paths.
  * Fixed renaming of doxywrite-wrapper.sh.
  * Implemented support for Cocoapods.
  * Working on cocoapods integration. Renamed config file to include -example so that it doesn't overwrite existing configs when updating.

mx-1.1.2 / 2014-05-05
=====================

  * Implemented option to import some Xcode environment vars. Updated documentation.

mx-1.1.1 / 2014-05-04
=====================

  * Removed reference to TARGETNAME in config file because it has to be specified on the command line.

mx-1.1.0 / 2014-05-04
=====================

  * Updated README for 1.1.0 release.
  * Added cleanup function to remove working directory when done or when bailing (aborting).
  * Finished first run at portability rewrite.
  * Initial commits for portability rewrite.

mx-1.0.1 / 2014-04-30
=====================

  * Bug fixes. Project include path has moved. Create temp directory to avoid triggering Xcode warnings. Added some docs in header.

mx-1.0.0 / 2014-04-30
=====================

  * Initial release.
