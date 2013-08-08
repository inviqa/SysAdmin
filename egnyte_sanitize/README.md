#Description
egnyte_sanitize is a bash script that given a Egnyte Local Cloud folder, will verify the name of each file and folder looking for unconventional naming NOT supported by all the OSs and that the Egnyte process will refuse to sync. Any file or folder that is found carrying names not compatible with egnyte will be renamed replacing the offending charcter, symbols or spacing as follow:
- multiple blank spaces will be reduced to a single space
- trailing and leading spaces are removed
- trailing dots are removed
- semicolumns are areplaced with _ (underscore symbol)
- vertical bars are areplaced with _ (underscore symbol)

#Requirements
no specific dependency

#Usage
It's advised to place the script in a common path i.e. /usr/bin.
When executed the script needs two parameters: <elc folder path>g 
#TODO
- add support for options like:
"-t" :only tests and output the potential changes without renaming the files or folders
"-a" :rename (sanitize) the files tha are found with 'wrong' namin


#License and Author
Author: Marco Massari Calderone (mmassari@inviqa.com)

Copyright (C) 2013 Inviqa UK Ltd

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

