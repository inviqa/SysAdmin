#Description
'gddm.gs' (GoDDaMn) is a Google Script (kind of Java Script) that generates Google Docs based on a template document and data
incoming from a Google Spreadsheet.

GoDDaMn is inspired by the Google Script project named 'Generate Google Docs' by Mikko Ohtamaa (http://opensourcehacker.com), http://opensourcehacker.com/2013/01/21/script-for-generating-google-documents-from-google-spreadsheet-data-source/.

The differences between 'Generated Google Docs' and 'GoDDaMn' are:
- Modified script dubbed GoDDaMn or gddm.gs (Google Docs Data Marge).
- Modified script published.
- Added String replacement instead of Paragraph replacement.
- Modified the replacement string TAG format to ':tag:' .
- The substituted Strings are set in Bold to be 'highlighted' in the output file.
- Changed 'customer' to 'employee' because this is the use we make of it in Inviqa.
- If no employee_ID is embedded in the script, then the script sources it from the currently selected line of the spreadsheet.
- The modified script is meant to be run as an embedded script in a spreadsheet and triggered at any Form submission, in such case the employee_ID is the I of the newly inserted line, and this is a default behaviour of Google Script.


#Requirements
GoDDaMn requires the creation of the following Google Drive elements
- The Google Spreadsheet where to store the employees data.
- The Google Form that will store the data into the Google Spreadsheet.
- The Google Doc that will serve as template for the generation of the Employees Datasheets.
- A folder in Google Drive where to store the automatically generated Employees Datasheets.

#Installation
* Open the desired Google Spreadsheet.
* Open the Script Editor from the menu 'Tools -> Script editor...'.
* Replace the content of the Code.gs with the conected of the gdds.gs script file.
* Open the Triggers editor from the menu (within the Script editor) 'Resources -> All Your Triggers...'.
* Set up a new trigger such:
  * Run: generateEmployeeDatasheet
  * Events: From Spreadsheet - On form submit
* Edit the script and poupulate the following variables with the respective Google Docs IDs:
  * SOURCE_TEMPLAT: Google Doc template
  * employee_SPREADSHEET: Soogle Spreadsheet where the employees data are stored
  * TARGET_FOLDER: In which Google Drive to store the target documents


#Usage
Edit the template document and create the :tag: elements to match the column title of the Google Spreadsheet.

The gddm.gs script is meant to be run as an embedded script in a spreadsheet and triggered at any Form submission, in such case the employee_ID is the I of the newly inserted line, and this is a default behaviour of Google Script.

If the script is run manually, the function to run is 'generateEmployeeDatasheet'.

#Example
Google Spreadsheet columns titles:

Timestamp | Author | Employee Full Name | Employee Email Address| Phone Number | Skype

Google Doc Template tags:

:Timestamp:, :Author:, :Employee Full Name:, :Employee Email Address:, :Phone Number:, :Skype:

#TODO & BUGS
- there is a bug that will break the tag replacement if one of the values for replacement contains a 'carriage and return'

#License and Author
Authors:
* Mikko Ohtamaa, http://opensourcehacker.com (original Google Doc Generator)
* Marco Massari Calderone (mmassari@inviqa.com) (GoDDaMn: adaptation for the Inviqa Group) 

License: MIT
The MIT License (MIT)

Copyright (c) 2013
* Mikko Ohtamaa (http://opensourcehacker.com)
* Inviqa Group (http://inviqa.com)>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
