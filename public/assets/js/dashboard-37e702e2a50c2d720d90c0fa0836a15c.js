$(document).ready(function(){
	$("body").addClass('dashboard');
	
	$(".account_id").change(function(){
	    if ($('.account_id:checked').length != $('.account_id').length) {
	    	$( "#all").prop('checked', false);
	    }else{
	    	$( "#all").prop('checked', true);
	    }
	});
});

function applyFilter(clickedElement, apply){
	apply = typeof apply !== 'undefined' ? apply : true;
	$(clickedElement).closest(".dropdown-menu").siblings(".dropdown-toggle").dropdown("toggle");
	
	if(apply){
		getOverviewData();
	}
}

function selectAllFilterAccountOption(element){
	if(element.checked){
		$("input[name='account_array[]']").each(function() {
		       this.checked = true;
	   });
	}else{
		$("input[name='account_array[]']").each(function() {
		       this.checked = false;
	   });
	}
} 
;
