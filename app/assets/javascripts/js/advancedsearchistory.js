var campaign_linechart_label=[];
var campaign_linechart_data=[];

$(document).ready(function(){
	
	$("body").addClass('advancesearchjobinfo');

	// bind click event for tab
	$("#tab-menu-1 li a").on("click", function(event){

		// tab menu highlight
		$("#tab-menu-1").find(".tab_tag").removeClass("active");
		$(this).addClass("active");

		// show/hide tab content
		$(".tab-content-group-1").hide();
		$($(this).data("showTab")).show();
	});
	$("#tab-menu-1 li a").eq(0).click();

	// modal
	$('#add-keyword-modal').one('show.bs.modal', function (e) {
		$(this).find("select").chosen('destroy');
	});
	$('#add-keyword-modal').one('shown.bs.modal', function (e) {
		$(this).find("select").chosen({disable_search:true});
		// $("#add-keywords").selectize({
		// 	delimiter: ',',
		// 	create: function(input) {
		// 		return {
		// 			value: input,
		// 			text: input
		// 		}
		// 	}
		// });
	});

	$( ".cancel" ).click(function() {
	  // alert( $(this).val() );
	  $(".loading_container").show();
	  
	  $.ajax({
			url: "/canceladvancesearchjob",
			type: 'POST',
			data: "_id="+$(this).val(),
			success: function(data,status,xhr){
				$(".loading_container").hide();
				
				if(data.status=='true'){
					location.reload();
				}else if(data.status=='test'){
				}else{
					$('#edit_error_modal .modal_title').html("Your request is invalid.");
					$('#edit_error_modal').modal('show');
				}
			},
			error: function(xhr,status,error){
				console.log(xhr);
				console.log(error);
				// alert(error);
			}
		});
	  
	  
	});
	

	$(".budget_container span").html(accounting.formatNumber($(".budget_container span").html(),2));
});

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

function applyFilter(clickedElement, apply){
	apply = typeof apply !== 'undefined' ? apply : true;
	$(clickedElement).closest(".dropdown-menu").siblings(".dropdown-toggle").dropdown("toggle");
	
	if(apply){
		getAdvanceSearchData();
	}
}

function applyDTFilter(clickedElement, apply){
	apply = typeof apply !== 'undefined' ? apply : true;
	var dropdownMenu = $(clickedElement).closest(".dropdown-menu");
	dropdownMenu.siblings(".dropdown-toggle").dropdown("toggle");
	if(apply){
		// set value in hidden input
		dropdownMenu.siblings(".filterText").val(
			dropdownMenu.find("[name='type1']").val() +
			dropdownMenu.find("[name='value1']").val() +
			dropdownMenu.find("[name='ao']").val() +
			dropdownMenu.find("[name='type2']").val() +
			dropdownMenu.find("[name='value2']").val()
		).change();
	}
}