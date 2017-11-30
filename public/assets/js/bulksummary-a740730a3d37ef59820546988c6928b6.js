/**
 * @author elee
 */


var advancesearchValid=true;
var checkRulesValid=true;
var dataArray;

$(document).ready(function(){
	
	$( ".cancel" ).click(function() {
	  // alert( $(this).val() );
	  $(".loading_container").show();
	  console.log("run cancel");
	  
	  $.ajax({
			url: "/cancelbulkjob",
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
				
				
				console.log("error lol");
				
				console.log(xhr);
				console.log(error);
				
				
				// alert(error);
			}
		});
	  
	});
	
	
	$( ".start" ).click(function() {
	  // alert( $(this).val() );
	  $(".loading_container").show();
	  console.log("run resume");
	  
	  $.ajax({
			url: "/resumebulkjob",
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
				
				console.log("error lol");
				
				console.log(xhr);
				console.log(error);
				// alert(error);
				
			}
		});
	  
	});
	
		
		
});

function checkRules(){
	if(checkRulesValid){
		$(".loading_container").show();
		checkRulesValid=false;
		var valid=true;
		
		$("#searchNumberResult").hide();
		$("#searchHiddenContent").hide();
		
 		if($("[name=page]").val()=='Campaign'){
 			exportUrl=campaignGetUrl;
 		}else if($("[name=page]").val()=='Ad Groups'){
 			
 			campaignAdgroupGetUrl = "/advancesearchadgroup"
 			exportUrl=campaignAdgroupGetUrl;
 			
 		}else if($("[name=page]").val()=='Ads'){
 			
 			campaignAdsGetUrl = "/advancesearchjob"
 			exportUrl=campaignAdsGetUrl;
 			
 		}else if($("[name=page]").val()=='Keywords'){
 			
 			campaignKeywordGetUrl = "/advancesearchjob"
 			exportUrl=campaignKeywordGetUrl;
 		}else{
 			valid=false;
 		}
		
		if(valid){
			var postData={};
		
			var filter_object=[];
			$(".filter_row").each(function(){
				if($(this).find("[name=field_value]").val()!=''){
					var filter={};
					
					filter.name=$(this).find("[name=field_name]").val();
					filter.rule=$(this).find("[name=field_rule]").val();
					filter.value=$(this).find("[name=field_value]").val();
					
					filter_object.push(filter);
				}
			});
			postData.filter_object = filter_object;
			postData.account_array = [$("[name=account]").val()];
			postData.start_date = $("#start_date").val();
			postData.end_date = $("#end_date").val();
			postData.csv=0;
			postData.advancesearch=1;
			postData.page = $("[name=page]").val();
						
			exportData=postData;
			
			$.ajax({
				url: exportUrl,
				type: 'POST',
				data: postData,
				success: function(data,status,xhr){
					checkRulesValid=true;
					$(".loading_container").hide();
					
					if(data.status=='true'){
						if(data.data.length>0){
							$("#export_button").prop('disabled', false);
							$("#export_button").removeClass('disabled');
							$("#submit_button").prop('disabled', false);
							$("#submit_button").removeClass('disabled');
							
							$("#searchNumber").html(data.data.length);
							$("#searchNumberResult").show();
							$("#searchHiddenContent").show();
							
							dataArray = data.data;
							
							if($("[name=page]").val()=='Campaign'){
								$("#searchCampaignAction").show();
								$("#searchOtherAction").hide();
								
								$("[name=status]").attr({'disabled':false});
								$("[name=action_type]").attr({'disabled':true});
							}else{
								$("#searchOtherAction").show();
								$("#searchCampaignAction").hide();
								
								$("[name=action_type]").attr({'disabled':false});
								$("[name=status]").attr({'disabled':true});
							}
						}
					}else if(data.status=='test'){
						$("#export_button").prop('disabled', false);
						$("#export_button").removeClass('disabled');
						$("#submit_button").prop('disabled', false);
						$("#submit_button").removeClass('disabled');
						
						// $("#searchNumber").html(data.data.length);
						// $("#searchNumberResult").show();
						$("#searchHiddenContent").show();
						
						dataArray = data.data;
						
						if($("[name=page]").val()=='Campaign'){
							$("#searchCampaignAction").show();
							$("#searchOtherAction").hide();
							
							$("[name=status]").attr({'disabled':false});
							$("[name=action_type]").attr({'disabled':true});
						}else{
							$("#searchOtherAction").show();
							$("#searchCampaignAction").hide();
							
							$("[name=action_type]").attr({'disabled':false});
							$("[name=status]").attr({'disabled':true});
						}
					}else{
						$('#edit_error_modal .modal_title').html(data.message);
						$('#edit_error_modal').modal('show');
					}
				},
				error: function(xhr,status,error){
					checkRulesValid=true;
					$(".loading_container").hide();
					console.log(xhr);
					console.log(error);
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			checkRulesValid=true;
		}
	}
}

function submitAdvancesearch(){
	if(advancesearchValid){
		$(".loading_container").show();
		advancesearchValid=false;
		var valid=true;
		
		var postData=$("#advancesearchForm").serializeObject();
		var filter_object=[];
		
		$(".filter_row").each(function(){
			if($(this).find("[name=field_value]").val()!=''){
				var filter={};
				
				filter.name=$(this).find("[name=field_name]").val();
				filter.rule=$(this).find("[name=field_rule]").val();
				filter.value=$(this).find("[name=field_value]").val();
				
				filter_object.push(filter);
			}
		});
		
		
		postData.filter_object = filter_object;
		delete postData.field_name;
		delete postData.field_rule;
		delete postData.field_value;
		postData.type = $("#account option:selected").attr('name');
		postData.advancesearch = 1 ;
		postData.item_id = dataArray;
		
		if($("[name=page]").val()=='Campaign'){
 			// apiUrl="/updatecampaign";
 			apiUrl="/advancesearchjob";
 		}else if($("[name=page]").val()=='Ad Groups'){
 			// apiUrl="/advancesearchadgroupupdate";
 			apiUrl="/advancesearchjob";
 		}else if($("[name=page]").val()=='Ads'){
 			// apiUrl="/advancesearchjobupdate";
 			apiUrl="/advancesearchjob";
 		}else if($("[name=page]").val()=='Keywords'){
 			// apiUrl="/advancesearchjobupdate";
 			apiUrl="/advancesearchjob";
 		}else{
 			valid=false;
 		}
		
		if(valid){
			$.ajax({
				url: apiUrl, 
				type: 'POST',
				data: postData,
				success: function(data,status,xhr){
					advancesearchValid=true;
					$(".loading_container").hide();
					
					$('#edit_error_modal .modal_title').html(data.message);
					$('#edit_error_modal').modal('show');
				},
				error: function(xhr,status,error){
					advancesearchValid=true;
					$(".loading_container").hide();
					console.log(xhr);
					console.log(error);
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			advancesearchValid=true;
		}
	}
}
;
