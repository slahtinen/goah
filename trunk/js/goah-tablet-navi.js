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
	
	/* Menu subnavi actions */
	$("#basket_sub").hide();
   $(".Basket").show();
	$('.Basket').click(function(){
	$("#basket_sub").slideToggle(100);
	});
	
	$("#customermanagement_sub").hide();
   $(".Customermanagement").show();
	$('.Customermanagement').click(function(){
	$("#customermanagement_sub").slideToggle(100);
	});
	
	$("#productmanagement_sub").hide();
   $(".Productmanagement").show();
	$('.Productmanagement').click(function(){
	$("#productmanagement_sub").slideToggle(100);
	});	

	$("#systemsettings_sub").hide();
   $(".Systemsettings").show();
	$('.Systemsettings').click(function(){
	$("#systemsettings_sub").slideToggle(100);
	});
	
	$("#storagemanagement_sub").hide();
   $(".Storagemanagement").show();
	$('.Storagemanagement').click(function(){
	$("#storagemanagement_sub").slideToggle(100);
	});

});