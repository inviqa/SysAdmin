
/**
 * GoDDaMn is inspired by  the Google Script project named 'Generate Google Docs' by Mikko Ohtamaa (http://opensourcehacker.com)
 * http://opensourcehacker.com/2013/01/21/script-for-generating-google-documents-from-google-spreadsheet-data-source/
 *
 * Generate Google Docs based on a template document and data incoming from a Google Spreadsheet
 *
 * License: MIT
 *
 * Copyright 2013 Mikko Ohtamaa, http://opensourcehacker.com
 *
 * Modified and Adapted for the Inviqa Group http://inviqa.com
 * Authored by Marco Massari Calderone <mmassari@inviqa.com>
 *
 * - modified script dubbed GoDDaMn or gddm.gs (Google Docs Data Marge)
 * - modified script published 
 * - Added String replacement instead of Paragraph replacement
 * - Modified the replacement string TAG format to :key:
 * - the substituted Strings are set in Bold to be 'highlighted' in the output file
 * - changed 'customer' to 'employee' because this is the use we make of it in Inviqa -
 * - if no employee_ID is embedded in the script, then the script sources it from the currently selected line of the spreadsheet
 * - The modified script is meant to be run as an embedded script in a spreadsheet and triggered at any Form submission,
 *   in such case the employee_ID is the I of the newly inserted line, and this is a default behaviour of Google Script
 * 
 * IF the script is run manually, the function to run is 'generateEmployeeDatasheet'
 */

// Row number from where to fill in the data (starts as 1 = first row)
// leave this empty to let script pick the ID from the currently selected row of the spreadsheet
var employee_ID = "";

// Google Doc id from the document template
// (Get ids from the URL)
var SOURCE_TEMPLATE = "";

// In which spreadsheet we have all the employee data
var employee_SPREADSHEET = "";

// In which Google Drive we toss the target documents
var TARGET_FOLDER = "";

/**
 * Return spreadsheet row content as JS array.
 *
 * Note: We assume the row ends when we encounter
 * the first empty cell. This might not be 
 * sometimes the desired behavior.
 *
 * Rows start at 1, not zero based!!!  
 *
 */
function getCurrentRow() {
  var currentRow = SpreadsheetApp.getActiveSheet().getActiveSelection().getRowIndex();
  return currentRow;
}


function getRowAsArray(sheet, row) {
  var dataRange = sheet.getRange(row, 1, 1, 99);
  var data = dataRange.getValues();
  var columns = [];

  for (i in data) {
    var row = data[i];

    Logger.log("Got row", row);

    for(var l=0; l<99; l++) {
        var col = row[l];
        // First empty column interrupts
        if(!col) {
            break;
        }

        columns.push(col);
    }
  }

  return columns;
}

/**
 * Duplicates a Google Apps doc
 *
 * @return a new document with a given name from the orignal
 */
function createDuplicateDocument(sourceId, name) {
    var source = DriveApp.getFileById(sourceId);
    var targetFolder = DriveApp.getFolderById(TARGET_FOLDER);
    var newFile = source.makeCopy(name, targetFolder);

    /** newFile.addToFolder(targetFolder);*/
    return DocumentApp.openById(newFile.getId());
}
/**
 * Search a paragraph in the document and replaces it with the generated text 
 */
function replaceParagraph(doc, keyword, newText) {
  var ps = doc.getParagraphs();
  for(var i=0; i<ps.length; i++) {
    var p = ps[i];
    var text = p.getText();

    if(text.indexOf(keyword) >= 0) {
      p.setText(newText);
      p.setBold(false);
      
    }
  } 
}

/**
 * Search a String in the document and replaces it with the generated newString, and sets it Bold
 */
function replaceString(doc, String, newString) {

  var ps = doc.getParagraphs();
  for(var i=0; i<ps.length; i++) {
    var p = ps[i];
    var text = p.getText();
    //var text = p.editAsText();

    if(text.indexOf(String) >= 0) {
      //look if the String is present in the current paragraph
      

      //p.editAsText().setFontFamily(b, c, DocumentApp.FontFamily.COMIC_SANS_MS);
      p.editAsText().replaceText(String, newString);
      
      
      // we calculte the length of the string to modify, making sure that is trated like a string and not another ind of object.
      var newStringLength = newString.toString().length;
      
      // if a string has been replaced with a NON empty space, it sets the new string to Bold, 
      if (newStringLength > 0) {
        // re-populate the text variable with the updated content of the paragraph
        text = p.getText();
        p.editAsText().setBold(text.indexOf(newString), text.indexOf(newString) + newStringLength - 1, true);
      }
    }
  } 
}



/**
 * Script entry point
 */
function generateEmployeeDatasheet() {

  var data = SpreadsheetApp.openById(employee_SPREADSHEET);

  if(!employee_ID) {
    employee_ID = getCurrentRow();
    //if the current line is the Column Headers line then ask the user to specify the ID, very rare case.
    if (employee_ID == 1) {
      var employee_ID = Browser.inputBox("Enter employee ID (row number) in the spreadsheet", Browser.Buttons.OK_CANCEL);
    }
  }

  // Fetch variable names
  // they are column names in the spreadsheet
  var sheet = data.getSheets()[0];
  var columns = getRowAsArray(sheet, 1);

  Logger.log("Processing columns:" + columns);

  var employeeData = getRowAsArray(sheet, employee_ID);  
  Logger.log("Processing data:" + employeeData);

  // Assume first column holds the name of the employee
  var employeeName = employeeData[2];
  var timeStamp = employeeData[0];
  
  var target = createDuplicateDocument(SOURCE_TEMPLATE, employeeName + " Accounts Datasheet");

  Logger.log("Created new document:" + target.getId());

  for(var i=0; i<columns.length; i++) {
    // TAG forma is :key:
    var key = ":" + columns[i] + ":"; 
    var text = employeeData[i] || ""; // No Javascript undefined
    replaceString(target, key, text);
      
    //var newString = key +" " + text;
    //var newParagraph = key + " " + text;
    //replaceParagraph(target, key, newParagraph);
      
  }

}

