$(document).ready(function(){

	/* Show and hide menu */
	$("#navi").hide();
	$(".show_hide").show();
	$('.show_hide').click(function(){
	$("#navi").slideToggle(100);
	});
	
	/* Hide menu when clicked on body */
	$("body").click(function() {
    	$("#navi").hide();
	});
	$("#navi").click(function(e) {
    	e.stopPropagation();
	});
	
	    jQuery( function( $ ) {
    	$( '.toggle-next + *' ).hide();
 		$( '.toggle-next' ).click( function() {
 			$( '.toggle-next' ).removeAttr("id","active"); 
 			$( '.toggle-next + *' ).hide();
			$( this ).next().slideToggle( 'fast' ); 
			$( this ).attr("id","active");
			return false;
    } );
    } );

});