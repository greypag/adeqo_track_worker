/**
 * @author elee
 */


var advancesearchValid=true;
var checkRulesValid=true;
var dataArray;

$(document).ready(function(){
	$("#rules-content").prepend(backupFilterField);
	
	setDate($("[name=date_range]").val());
	$("[name=date_range]").change(function(){
		setDate($("[name=date_range]").val());
	});
	
	$("#searchCampaignAction").show();
	
	
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
	
	$("[name=happens]").change(function(){
		if($("[name=happens]").val() == "Make Changes"){
			$("#searchHiddenContent").show();
		}else{
			$("#searchHiddenContent").hide();
		}
	});	
	
	$("[name=page]").change(function(){
		// alert($("[name=page]").val());
		
		if($("[name=page]").val() == "Campaign"){
			$(".search_action").hide();
			$("#searchCampaignAction").show();
			
		}else if($("[name=page]").val() == "Ad Groups"){
			$(".search_action").hide();
			$("#searchAdgroupAction").show();
		}else if($("[name=page]").val() == "Ads"){
			$(".search_action").hide();
			$("#searchAdAction").show();
		}else if($("[name=page]").val() == "Keywords"){
			$(".search_action").hide();
			$("#searchKeywordAction").show();
		}else{
			$(".search_action").hide();
			// $("#searchOtherAction").show();
		}
		
		$( ".campaign" ).remove();
		$( ".adgroup" ).remove();
		$( ".ad" ).remove();
		$( ".keyword" ).remove();
		
		if($("[name=page]").val() == "Campaign"){
			$(".form_field_require").append( '<option class="campaign" value="status">Status</option>' );
			$(".form_field_require").append( '<option class="campaign" value="campaign_name">Campaign</option>' );
			$(".form_field_require").append( '<option class="campaign" value="avg_cpc">Avg. CPC</option>' );
			$(".form_field_require").append( '<option class="campaign" value="impr">Impr.</option>' );
			$(".form_field_require").append( '<option class="campaign" value="clicks">Clicks</option>' );
			$(".form_field_require").append( '<option class="campaign" value="ctr">CTR</option>' );
			$(".form_field_require").append( '<option class="campaign" value="cost">Cost</option>' );
			$(".form_field_require").append( '<option class="campaign" value="conv">Conversions</option>' );
			$(".form_field_require").append( '<option class="campaign" value="conv_rate">Conv.Rate</option>' );
			$(".form_field_require").append( '<option class="campaign" value="cpa">CPA</option>' );
			$(".form_field_require").append( '<option class="campaign" value="avg_pos">Avg.Pos</option>' );				
		}
		
		if($("[name=page]").val() == "Ad Groups"){
			$(".form_field_require").append( '<option class="adgroup" value="status">Status</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="adgroup_name">Ad Group Name</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="max_cpc">Default Max. CPC</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="avg_cpc">Avg. CPC</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="impr">Impr.</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="clicks">Clicks</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="ctr">CTR</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="cost">Cost</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="conv">Conversions</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="conv_rate">Conv.Rate</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="cpa">CPA</option>' );
			$(".form_field_require").append( '<option class="adgroup" value="avg_pos">Avg.Pos</option>' );
		}
 		
		if($("[name=page]").val() == "Ads"){
			$(".form_field_require").append( '<option class="ad" value="status">Status</option>' );
			$(".form_field_require").append( '<option class="ad" value="adgroup_name">Ad Group Name</option>' );
			$(".form_field_require").append( '<option class="ad" value="headline">Headline</option>' );
			$(".form_field_require").append( '<option class="ad" value="desc_1">Description Line 1</option>' );
			$(".form_field_require").append( '<option class="ad" value="desc_2">Description Line 2</option>' );
			$(".form_field_require").append( '<option class="ad" value="display_url">Display URL</option>' );
			$(".form_field_require").append( '<option class="ad" value="m_display_url">Mobile Display URL</option>' );
			$(".form_field_require").append( '<option class="ad" value="final_url">Landing page URL</option>' );
			$(".form_field_require").append( '<option class="ad" value="m_final_url">Mobile Landing page URL</option>' );
			$(".form_field_require").append( '<option class="ad" value="max_cpc">Default Max. CPC</option>' );
			$(".form_field_require").append( '<option class="ad" value="avg_cpc">Avg. CPC</option>' );
			$(".form_field_require").append( '<option class="ad" value="impr">Impr.</option>' );
			$(".form_field_require").append( '<option class="ad" value="clicks">Clicks</option>' );
			$(".form_field_require").append( '<option class="ad" value="ctr">CTR</option>' );
			$(".form_field_require").append( '<option class="ad" value="cost">Cost</option>' );
			$(".form_field_require").append( '<option class="ad" value="conv">Conversions</option>' );
			$(".form_field_require").append( '<option class="ad" value="conv_rate">Conv.Rate</option>' );
			$(".form_field_require").append( '<option class="ad" value="cpa">CPA</option>' );
			$(".form_field_require").append( '<option class="ad" value="avg_pos">Avg.Pos</option>' );
		}
 		
		if($("[name=page]").val() == "Keywords"){
			$(".form_field_require").append( '<option class="keyword" value="status">Status</option>' );
			$(".form_field_require").append( '<option class="keyword" value="adgroup_name">Ad group name</option>' );
			$(".form_field_require").append( '<option class="keyword" value="final_url">Landing page URL</option>' );
			$(".form_field_require").append( '<option class="keyword" value="m_final_url">Mobile Landing Page URL</option>' );
			$(".form_field_require").append( '<option class="keyword" value="max_cpc">Default Max. CPC</option>' );
			$(".form_field_require").append( '<option class="keyword" value="avg_cpc">Avg. CPC</option>' );
			$(".form_field_require").append( '<option class="keyword" value="impr">Impr.</option>' );
			$(".form_field_require").append( '<option class="keyword" value="clicks">Clicks</option>' );
			$(".form_field_require").append( '<option class="keyword" value="ctr">CTR</option>' );
			$(".form_field_require").append( '<option class="keyword" value="cost">Cost</option>' );
			$(".form_field_require").append( '<option class="keyword" value="conv">Conversions</option>' );
			$(".form_field_require").append( '<option class="keyword" value="conv_rate">Conv.Rate</option>' );
			$(".form_field_require").append( '<option class="keyword" value="cpa">CPA</option>' );
			$(".form_field_require").append( '<option class="keyword" value="avg_pos">Avg.Pos</option>' );
		}
 		
 		$(".remove_icon").trigger("click");
 		$(".form_field_require").trigger("change");
 		backupFilterField = $(".filter_row").clone();
 		
	});
		
		
	
	$("[name=adgroup_action_type]").change(function(){
		$(this).siblings().prop('disabled',true);
		$(this).siblings().hide();
		
		if(this.value!='active' && this.value!='inactive'){
			$(this).siblings().prop('disabled',false);
			$(this).siblings().show();
		}
		
		if(this.value=='set_cpc'){
			$("[name=adgroup_action_classifier]").val("RMB");
			$("[name=adgroup_action_classifier]").hide();
			$("[name=adgroup_action_classifier]").prop('disabled',false);
		}
		
		if(this.value=='find_and_replace'){
			$(this).siblings().prop('disabled',true);
			$(this).siblings().hide();
			
			$("[id=adgroup_find_and_replace_title]").show();
			$("[name=adgroup_find_and_replace]").parent().show();
			$("[name=adgroup_find_and_replace]").show();
			$("[name=adgroup_find_and_replace]").prop('disabled',false);
			
			$("[id=adgroup_find_and_replace_value_title]").show();
			$("[name=adgroup_find_and_replace_value]").parent().show();
			$("[name=adgroup_find_and_replace_value]").show();
			$("[name=adgroup_find_and_replace_value]").prop('disabled',false)
			
			$("[id=adgroup_find_and_replace_find_title]").show();
			$("[name=adgroup_find_and_replace_find]").parent().show();
			$("[name=adgroup_find_and_replace_find]").show();
			$("[name=adgroup_find_and_replace_find]").prop('disabled',false)
		}else{
			$("[id=adgroup_find_and_replace_title]").hide();
			$("[name=adgroup_find_and_replace]").parent().hide();
			$("[name=adgroup_find_and_replace]").hide();
			$("[name=adgroup_find_and_replace]").prop('disabled',true);
			
			$("[id=adgroup_find_and_replace_value_title]").hide();
			$("[name=adgroup_find_and_replace_value]").parent().hide();
			$("[name=adgroup_find_and_replace_value]").hide();
			$("[name=adgroup_find_and_replace_value]").prop('disabled',true);
			
			$("[id=adgroup_find_and_replace_find_title]").hide();
			$("[name=adgroup_find_and_replace_find]").parent().hide();
			$("[name=adgroup_find_and_replace_find]").hide();
			$("[name=adgroup_find_and_replace_find]").prop('disabled',true);
		}
	});		
		
		
		
	$("[name=ad_action_type]").change(function(){
		$(this).siblings().prop('disabled',true);
		$(this).siblings().hide();
		
		if(this.value!='active' && this.value!='inactive'){
			$(this).siblings().prop('disabled',false);
			$(this).siblings().show();
		}
		
		if(this.value=='set_cpc'){
			$("[name=ad_action_classifier]").val("RMB");
			$("[name=ad_action_classifier]").hide();
			$("[name=ad_action_classifier]").prop('disabled',false);
		}
		
		if(this.value=='find_and_replace'){
			$(this).siblings().prop('disabled',true);
			$(this).siblings().hide();
		
			$("[id=ad_find_and_replace_title]").show();
			$("[name=ad_find_and_replace]").parent().show();	
			$("[name=ad_find_and_replace]").show();
			$("[name=ad_find_and_replace]").prop('disabled',false);
			
			$("[id=ad_find_and_replace_value_title]").show();
			$("[name=ad_find_and_replace_value]").parent().show();
			$("[name=ad_find_and_replace_value]").show();
			$("[name=ad_find_and_replace_value]").prop('disabled',false)
			
			$("[id=ad_find_and_replace_find_title]").show();
			$("[name=ad_find_and_replace_find]").parent().show();
			$("[name=ad_find_and_replace_find]").show();
			$("[name=ad_find_and_replace_find]").prop('disabled',false)
		}else{
			
			$("[id=ad_find_and_replace_title]").hide();
			$("[name=ad_find_and_replace]").parent().hide();
			$("[name=ad_find_and_replace]").hide();
			$("[name=ad_find_and_replace]").prop('disabled',true);
			
			$("[id=ad_find_and_replace_value_title]").hide();
			$("[name=ad_find_and_replace_value]").parent().hide();
			$("[name=ad_find_and_replace_value]").hide();
			$("[name=ad_find_and_replace_value]").prop('disabled',true);
			
			$("[id=ad_find_and_replace_find_title]").hide();
			$("[name=ad_find_and_replace_find_title]").parent().hide();
			$("[name=ad_find_and_replace_find]").hide();
			$("[name=ad_find_and_replace_find]").prop('disabled',true);
		}
	});	
	
		
	
	$("[name=keyword_action_type]").change(function(){
		$(this).siblings().prop('disabled',true);
		$(this).siblings().hide();
		
		if(this.value!='active' && this.value!='inactive'){
			$(this).siblings().prop('disabled',false);
			$(this).siblings().show();
		}
		
		if(this.value=='set_cpc'){
			$("[name=keyword_action_classifier]").val("RMB");
			$("[name=keyword_action_classifier]").hide();
			$("[name=keyword_action_classifier]").prop('disabled',false);
		}
		
		if(this.value=='find_and_replace'){
			$(this).siblings().prop('disabled',true);
			$(this).siblings().hide();
		
			$("[id=keyword_find_and_replace_title]").show();
			$("[name=keyword_find_and_replace]").parent().show();
			$("[name=keyword_find_and_replace]").show();
			$("[name=keyword_find_and_replace]").prop('disabled',false);
			
			$("[id=keyword_find_and_replace_value_title]").show();
			$("[name=keyword_find_and_replace_value]").parent().show();
			$("[name=keyword_find_and_replace_value]").show();
			$("[name=keyword_find_and_replace_value]").prop('disabled',false)
			
			$("[id=keyword_find_and_replace_find_title]").show();
			$("[name=keyword_find_and_replace_find]").parent().show();
			$("[name=keyword_find_and_replace_find]").show();
			$("[name=keyword_find_and_replace_find]").prop('disabled',false)
		}else{
			$("[id=keyword_find_and_replace_title]").hide();
			$("[name=keyword_find_and_replace]").parent().hide();
			$("[name=keyword_find_and_replace]").hide();
			$("[name=keyword_find_and_replace]").prop('disabled',true);
			
			$("[id=keyword_find_and_replace_value_title]").hide();
			$("[name=keyword_find_and_replace_value]").parent().hide();
			$("[name=keyword_find_and_replace_value]").hide();
			$("[name=keyword_find_and_replace_value]").prop('disabled',true);
			
			$("[id=keyword_find_and_replace_find_title]").hide();
			$("[name=keyword_find_and_replace_find]").parent().hide();
			$("[name=keyword_find_and_replace_find]").hide();
			$("[name=keyword_find_and_replace_find]").prop('disabled',true);
		}
	});	
	
		
	// $("[name=action_type]").change(function(){
		// $(this).siblings().prop('disabled',true);
		// $(this).siblings().hide();
// 			
		// if(this.value!='active' && this.value!='inactive'){
			// $(this).siblings().prop('disabled',false);
			// $(this).siblings().show();
		// }
// 		
// 		
		// if(this.value=='set_cpc'){
			// $("[name=action_classifier]").val("RMB");
			// $("[name=action_classifier]").hide();
			// $("[name=action_classifier]").prop('disabled',false);
		// }
// 		
		// if(this.value=='find_and_replace'){
			// $(this).siblings().prop('disabled',true);
			// $(this).siblings().hide();
// 		
			// $("[name=find_and_replace]").show();
			// $("[name=find_and_replace]").prop('disabled',false);
			// $("[name=find_and_replace_value]").show();
			// $("[name=find_and_replace_value]").prop('disabled',false)
		// }else{
			// $("[name=find_and_replace]").hide();
			// $("[name=find_and_replace]").prop('disabled',true);
			// $("[name=find_and_replace_value]").hide();
		// }
	// });
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
