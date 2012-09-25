$(document).ready(function(){
	$(".sidebar-outer").next().hide();
	$(".sidebar-outer").click( function () {
	    $(this).next().toggle("fast");
	});
});