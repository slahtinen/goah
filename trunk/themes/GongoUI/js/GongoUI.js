$(document).ready(function(){
	
// Add datepicker to date inputs. For more information and localizations 
// visit to http://http://keith-wood.name/datepick.html
	$('.date').datepick();
	
	
// Show and hide navigation
	jQuery( function( $ ) {
		$('#navi').hide();
		$( '.toggle-navi' ).click( function() {
			$('#navi').slideToggle( 'fast' );
			return false;
    	} );
    } );

// Toggle subnavi. Close previous and add class active to selected menu item.
	jQuery( function( $ ) {
		$( '.nav-toggle-next + *' ).hide();
		$( '.nav-toggle-next' ).click( function() {
			$( '.nav-toggle-next + *' ).hide();
			$('li').removeAttr("id");
			$( this ).attr("id","active");
			$( this ).next().slideToggle( 'fast' );
			return false;
    	} );
    } );

/* Toggle next tr which is after <tr class="toggle-next-tr">. Default action is set to hide following tr.
	Action is tied to first cell of class=toggle-next-tr.

	NOTE: Add colspan to hided tr => td and class <td class="show-hidden". Also, if you want to toggle values + and -
	then add + sign to <td class="show-hidden">+</td>, or edit below to match you desires.
*/ 
	jQuery( function( $ ) {
		$( '.toggle-next-tr + *' ).hide();
		$( '.toggle-next-tr td:first-child' ).click( function() {	
			$( this ).parent().next().slideToggle( 'fast' );
			var text = $(this).text() == '-' ? '+' : '-';
   		$(this)
   		.text(text)
   		.toggleClass("active");
			return false;
    	} );
    } );

    
});