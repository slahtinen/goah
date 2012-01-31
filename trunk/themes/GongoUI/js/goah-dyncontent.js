/* 
 * Script: goah-dyncontent.js
 *
 *   A collection of simple functions based on jQuery to ease
 *   and improve user interface with GoaH2.
 *
 * About: License
 *
 *   This software is copyright (c) 2009 by Tietovirta Oy and associates.
 *   See LICENSE and COPYRIGHT -files for full details.
 */

/* 
 * Function: loadContent
 *
 *   A simple wrapper for jQuery to change div content dynamically.
 *
 * Parameters:
 *
 *   url - An actual url to load in div
 *   divid - Id for div to be used
 *
 */
function loadContent(url, divid) {

	// form Name needs to be the same than div id
	var frm = document.forms[divid]; 
	var frmfields = frm.elements;

	// Loop trough fields and construct query
	var query='?';
	for(var i = 0; i < frmfields.length; i++) {
		query+=escape(frmfields[i].name) + "=" + escape(frmfields[i].value) + (i + 1 < frmfields.length ? "&" : "");
	}

	$("#"+divid).load(url+query);

}
