/**
 * @author elee
 */

var addAccountValid = true;
var editAccountValid = true;
var removeAccountValid = true;
var editAccountAdRedirect = '';
var editAccountChange = false;

var addUserValid = true;
var editUserValid = true;
var removeUserValid = true;

var removeProfilioValid = true;
var addProfilioValid = true;

var resetPasswordValid = true;

var editStatusValid = true;
var editCpcbidValid = true;
var editFindreplaceValid = true;
var editSogouUrl;
var editThreesixtiesUrl;

var uploadValid = true;


var linechart_label=[];
var linechart_data=[];
var date_range_text;

var monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

var backupFilterField;

var networkUrl = '/getnetworkaccounts'
var bulkjobUrl = '/getbulkjob'

var campaignGetUrl='/getcampaigns';
var campaignUpdateUrl='/updatecampaign';

var campaignOverviewGetUrl='/getcampaignoverview';

var campaignAdgroupGetUrl='/getcampaignadgroup';
var campaignAdgroupSogouUpdateUrl='/sogous/updateadgroup';
var campaignAdgroupThreesixtiesUpdateUrl='/threesixties/updateadgroup';

var campaignAdsGetUrl='/getcampaignads';
var campaignAdsSogouUpdateUrl='/sogous/updatead';
var campaignAdsThreesixtiesUpdateUrl='/threesixties/updatead';

var campaignKeywordGetUrl='/getcampaignkeyword';
var campaignKeywordSogouUpdateUrl='/sogous/updatekeyword';
var campaignKeywordThreesixtiesUpdateUrl='/threesixties/updatekeyword';

var campaignClickActivityGetUrl='/getclickactivity';
var advancesearchjobinfoUrl = '/getadvancesearch'


var exportData = {};
var exportUrl;

var pageTotalRecord;
var allPageTotalRecord;

backupFilterField = $(".filter_row").clone();
$(".filter_row").remove();

$.fn.serializeObject = function()
{
    var o = {};
    var a = this.serializeArray();
    $.each(a, function() {
        if (o[this.name] !== undefined) {
            if (!o[this.name].push) {
                o[this.name] = [o[this.name]];
            }
            o[this.name].push(this.value || '');
        } else {
            o[this.name] = this.value || '';
        }
    });
    return o;
};

window.jQuery(function() {
  // detect browser scroll bar width
  var scrollDiv = $('<div class="scrollbar-measure"></div>')
        .appendTo(document.body)[0],
      scrollBarWidth = scrollDiv.offsetWidth - scrollDiv.clientWidth;

  $(document)
    .on('hidden.bs.modal', '.modal', function(evt) {
      // use margin-right 0 for IE8
      $(".header_container").css('padding-right', '');
    })
    .on('show.bs.modal', '.modal', function(evt) {
      // When modal is shown, scrollbar on body disappears.  In order not
      // to experience a "shifting" effect, replace the scrollbar width
      // with a right-margin on the body.
      if ($(window).height() < $(document).height()) {
        $(".header_container").css('padding-right', scrollBarWidth + 'px');
      }
    });
    
	$(document).click(function(event) {
		var target = $(event.target);
		
		if( !target.parents().andSelf().is('#search_sub_navbar')) {
			hideSubMenu('search');
		}
	});
});

$(document).ready(function(){
	/* turn off markup API for dropdown */
	$(document).off('.dropdown.data-api');
	/* manually turn on dropdown */
	$('.dropdown-toggle').dropdown();

	$(".datepicker-field").datepicker({
		format: 'd MM yyyy',
		autoclose: true,
		orientation: "top",
		endDate: '0d'
	});
	$("#date-range-dropdown .datepicker-field").each(function(i,o){
		$(o).datepicker("setDate", new Date());
		$(o).datepicker().on("changeDate", function(e){
			$("#start_date").datepicker("setEndDate",$("#end_date").val());
			$("#end_date").datepicker("setStartDate",$("#start_date").val());
			setDate("Date Range");
		})
	});
	
	var d=new Date();
	
	
	Chart.defaults.global.responsive = true;

	// $("select").chosen({disable_search:true});
	
	// $("#start_date").datepicker("setEndDate",session_end_date);
	// $("#end_date").datepicker("setStartDate",session_start_date);
// 	
	// $('#start_date').datepicker('update', session_start_date);
	// $('#end_date').datepicker('update', session_end_date);
// 	
	// setDate('Date Range');
	
	
			
	pathname = window.location.pathname;
	
	
	if (pathname == '/bulk/summary'){
		
		if (bulk_session_end_date == null){
			$("#end_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()));
		}else{
			$("#start_date").datepicker("setEndDate",bulk_session_end_date);
			$('#start_date').datepicker('update', bulk_session_start_date);	
			$("#end_date").datepicker("setStartDate",bulk_session_start_date);
			$('#end_date').datepicker('update', bulk_session_end_date);
		}
	}else if(pathname == '/advancedsearchistory'){
		if (adv_session_end_date == null){
			$("#end_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()));
		}else{
			$("#start_date").datepicker("setEndDate",adv_session_end_date);
			$('#start_date').datepicker('update', adv_session_start_date);	
			$("#end_date").datepicker("setStartDate",adv_session_start_date);
			$('#end_date').datepicker('update', adv_session_end_date);
		}
	}else{
	
	
		if (session_end_date == null){
			$("#end_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()-1));
		}else {
			
			var today = new Date(d.getFullYear(), d.getMonth(), d.getDate());
			var time_diff_with_end_date = Math.abs(today.getTime()- session_end_date.getTime());
			var diff_days_with_end_date = Math.ceil(time_diff_with_end_date / (1000 * 3600 * 24));
			var time_diff_with_start_date = Math.abs(today.getTime() - session_start_date.getTime());
			var diff_days_with_start_date = Math.ceil(time_diff_with_start_date / (1000 * 3600 * 24));
					
			
				
				if (diff_days_with_start_date == 0 && diff_days_with_end_date == 0){
					$("#start_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()-1));
					$('#start_date').datepicker('update', new Date(d.getFullYear(), d.getMonth(), d.getDate()-1));	
					$("#end_date").datepicker("setStartDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()-1));
					$("#end_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()-1));				
					$('#end_date').datepicker('update', new Date(d.getFullYear(), d.getMonth(), d.getDate()-1));
				}
				else if (diff_days_with_start_date != 0 && diff_days_with_end_date == 0){
					$("#start_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()-1));				
					$('#start_date').datepicker('update', session_start_date);	
					$("#end_date").datepicker("setStartDate",session_start_date);
					$("#end_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()-1));				
					$('#end_date').datepicker('update', new Date(d.getFullYear(), d.getMonth(), d.getDate()-1));
	
				}
				else if (diff_days_with_start_date != 0 && diff_days_with_end_date != 0){
					$("#start_date").datepicker("setEndDate",session_end_date);
					$('#start_date').datepicker('update', session_start_date);	
					$("#end_date").datepicker("setStartDate",session_start_date);
					$('#end_date').datepicker('update', session_end_date);
				}
			
		}
	
	}
	//Tony: Date selection: default selection(axo #182) 
	setDate('Date Range');
	//Tony: Date selection: default selection(axo #182) 
	
});

function goBack() {
    window.history.back();
}

function firstToUpperCase( str ) {
    return str.substr(0, 1).toUpperCase() + str.substr(1);
}

function trimToLength(str, length){
	if(str.toString().length > length){
		return jQuery.trim(str.toString()).substring(0, length) + "...";
	}else{
		return str;
	}
}

function validateEmail(email){
	var emailreg = /^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/;
	// var emailId = $("#"+inputId).val();
	
	if (emailreg.test(email) == false) {
		return false;
	}else{
		return true;
	}
}

function toggleSidebar(){
	if($(".sidebar").css("margin-left")=="0px"){
		$(".sidebar").animate({
			"margin-left": "-190px",
		}, 1000, function() {
			$(".sidebar_toggle_button").toggleClass("sidebar_open");
		});
		$(".body").animate({
			"margin-left": "-190px",
		}, 1000);
	}else{
		$(".sidebar").animate({
			"margin-left": "0px",
		}, 1000, function() {
			$(".sidebar_toggle_button").toggleClass("sidebar_open");
		});
		$(".body").animate({
			"margin-left": "0px",
		}, 1000);
	}
}

function toggleSubMenu(id){
	if($("."+id+"_sub_navbar").css("display")=="none"){
		showSubMenu(id);
	}else{
		hideSubMenu(id);
	}
}

function showSubMenu(id){
	$(".sub_navbar").hide();
	$("."+id+"_sub_navbar").slideDown();
}

function hideSubMenu(id){
	$("."+id+"_sub_navbar").slideUp("fast");
}

function toggleHiddenSideMenu(id){
	if($("."+id+"_hidden_content").css("display")=="none"){
		$(".side_nav").removeClass("active");
		$("."+id+"_hidden_content").slideDown();
		$(".side_nav").removeClass("active");
		$("."+id+"_side_nav").addClass("active");
	}else{
		$("."+id+"_hidden_content").slideUp("fast");
	}
}

var searchXhr = $.ajax({
					url: "", 
					type: '',
					data: {},
					success: function(data,status,xhr){
					}
				});

function navSearch(){
	searchXhr.abort();
	searchXhr=$.ajax({
		url: "/jsonexample", 
		type: 'GET',
		data: {},
		success: function(data,status,xhr){
			showSubMenu('search');
		}
	});
}

function setDate(range){
	var d=new Date();
	var start_date;
	var end_date;

	if(range=='Yesterday'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-1);
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-1);
	}else if(range=='This Week'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-d.getDay());
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-1);
	}else if(range=='Last Week'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-d.getDay()-7);
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-d.getDay()-1);
	}else if(range=='This Month'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-d.getDate()+1);
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-1);
	}else if(range=='Last Month'){
		start_date=new Date(d.getFullYear(), d.getMonth()-1, 1);
		end_date=new Date(d.getFullYear(), d.getMonth(), 1, -1);
	}else if(range=='Last 3 Months'){
		var start_month;
		if(d.getMonth()%3==0){
			start_month=3;
		}else if(d.getMonth()%3==1){
			start_month=4;
		}else if(d.getMonth()%3==2){
			start_month=5;
		}
		
		start_date=new Date(d.getFullYear(), d.getMonth()-start_month, 1);
		end_date=new Date(d.getFullYear(), d.getMonth()-start_month+3, 1,-1);
	}else if(range=='Last 7 days'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-7);
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-1);
	}else if(range=='Last 30 days'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-30);
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-1);
	}else if(range=='Today'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate());
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate());
	}

	if(range!="Date Range"){
		$("#start_date").datepicker("setEndDate",end_date);
		$('#start_date').datepicker('update', start_date);
		
		$("#end_date").datepicker("setStartDate",start_date);
		$('#end_date').datepicker('update', end_date);
	}

	date_range_text=$('#start_date').val()+" - "+$('#end_date').val();

	$(".date-range").html(range+"<br/>"+date_range_text);
}

function genLineChart(greenDataIndex, orangeDataIndex){
	$("#line-chart").remove();
  	$('.line-chart-container').append('<canvas id="line-chart"><canvas>');
	
	var datasets=[];
	
	if(greenDataIndex!=''){
		datasets.push({
			label: "My First dataset",
			fillColor: "rgba(220,220,220,0)",
			strokeColor: "#8fc449",
			pointColor: "#8fc449",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "#8fc449",
			data: linechart_data[greenDataIndex]
		});
	}
	
	if(orangeDataIndex!=''){
		datasets.push({
			label: "My Second dataset",
			fillColor: "rgba(151,187,205,0)",
			strokeColor: "#ef632e",
			pointColor: "#ef632e",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "#ef632e",
			data: linechart_data[orangeDataIndex]
		});
	}
	
	var lineGraphData = {
		labels: linechart_label,
		datasets: datasets
	};
	
	var gotDecimal = false;
	if(greenDataIndex=='ctr' || greenDataIndex=='conversion_rate' || greenDataIndex=='avg_cpc' || greenDataIndex=='cpa' || greenDataIndex=='revenue' || greenDataIndex=='profit' || greenDataIndex=='avg_pos'){
		gotDecimal = true;
	}
	
	if(orangeDataIndex=='ctr' || orangeDataIndex=='conversion_rate' || orangeDataIndex=='avg_cpc' || orangeDataIndex=='cpa' || orangeDataIndex=='revenue' || orangeDataIndex=='profit' || orangeDataIndex=='avg_pos'){
		gotDecimal = true;
	}
	
	if(gotDecimal){
		var lineGraphOptions = {
			bezierCurve : false,
			scaleLabel: "<%=accounting.formatNumber(value,2)%>",
			multiTooltipTemplate: "<%= accounting.formatNumber(value,2) %>",
		};
	}else{
		var lineGraphOptions = {
			bezierCurve : false,
			scaleLabel: "<%=accounting.formatNumber(value)%>",
			multiTooltipTemplate: "<%= accounting.formatNumber(value) %>",
		};
	}
	
	var ctx = $("#line-chart").get(0).getContext("2d");
	new Chart(ctx).Line(lineGraphData, lineGraphOptions);
}

// account setting start
function removeAccount() {
	if(removeAccountValid){
		$(".loading_container").show();
		removeAccountValid=false;
		$.ajax({
			url: "/removenetwork", 
			type: 'POST',
			data: $("#removeAccountForm").serialize(),
			success: function(data,status,xhr){
				removeAccountValid=true;
				if(data.status=='true'){
					window.location.reload();
				}else{
					$(".loading_container").hide();
				}
			},
			error: function(xhr,status,error){
				removeAccountValid=true;
				$(".loading_container").hide();
			    // alert(error);
			}
		});
	}
}

function showRemoveAccountModal(){
	if($('#removeAccountForm input:checked').length>0){
		$('#remove_account_modal').modal('show');
	}
}

function showAddAccountModal(channel){
	resetAccountForm();
	$('#add_account_modal').modal('show');
	$("#add_network").val(channel);
	selectChannel(channel);
}

function showEditAccountModal(id){
	resetAccountForm();
	$(".loading_container").show();
	$.ajax({
		url: "/getnetwork", 
		type: 'POST',
		data: {"id_str":id},
		success: function(data,status,xhr){
			$(".loading_container").hide();
			if(data.status=='true'){
				$("#edit_account_id").val(id);
				
				$("#edit_network").val(data.network[0].type);
				$("#edit_network2").val(data.network[0].type);
				$("#edit_account_name").val(data.network[0].name);
				$("#edit_currency").val(data.network[0].currency);
				$("#edit_update_ad").val(data.network[0].ad_redirect);
				editAccountAdRedirect=data.network[0].ad_redirect;
				$("#edit_update_keyword").val(data.network[0].keyword_redirect);
				$("#edit_tracking_type").val(data.network[0].tracking_type);
				$("#edit_username").val(data.network[0].username);
				$("#edit_username2").val(data.network[0].username);
				$("#edit_password").val(data.network[0].password);
				$("#edit_api_token").val(data.network[0].api_token);
				selectChannel(data.network[0].type);
				if(data.network[0].type=='360'){
					$("#edit_api_secret").val(data.network[0].api_secret);
				}
				$("#edit_budget").val(data.network[0].budget);
				$("#edit_cookie_length").val(data.network[0].cookie_length);
				
				$('#edit_account_modal').modal('show');
			}
		},
		error: function(xhr,status,error){
			// alert(error);
		}
	});
}

function toggleRemainder(value){
	if(value=='adeqo'){
		$(".modal_remainder").hide();
	}else{
		$(".modal_remainder").show();
	}
}

function selectChannel(channel){
	if(channel=='sogou'){
		$(".api_secret_row").hide();
	}else{
		$(".api_secret_row").show();
	}
}

function resetAccountForm(){
	$("#addAccountForm")[0].reset();
	$("#editAccountForm")[0].reset();
	
	$("#add_account_name_error").html("");
	$("#add_username_error").html("");
	$("#add_password_error").html("");
	$("#add_api_token_error").html("");
	$("#add_api_secret_error").html("");
	
	$("#edit_account_name_error").html("");
	$("#edit_username_error").html("");
	$("#edit_password_error").html("");
	$("#edit_api_token_error").html("");
	$("#edit_api_secret_error").html("");
	
	editAccountAdRedirect = '';
	editAccountChange = false;
	$(".modal_remainder").hide();
}

function submitAddAccount() {
	if(addAccountValid){
		$(".loading_container").show();
		addAccountValid=false;
		
		var network_name = $('#add_account_name').val();
		var username = $('#add_username').val();
		var password = $('#add_password').val();
		var apitoken = $('#add_api_token').val();
		var apisecret = $('#add_api_secret').val();
		var budget = $('#add_budget').val();
		var add_cookie_length = $('#add_cookie_length').val();
		var valid = true;
		
		$("#add_account_name_error").html("");
		$("#add_username_error").html("");
		$("#add_password_error").html("");
		$("#add_api_token_error").html("");
		$("#add_api_secret_error").html("");
		$("#add_budget_error").html("");
		$("#add_cookie_length_error").html("");
		
		var numericReg = /^\d*[0-9](|.\d*[0-9]|,\d*[0-9])?$/;
		
		if(!numericReg.test(add_cookie_length)) {
	        $("#add_cookie_length_error").html("Please input number only.");
	        valid = false;
	    }
	    
	    if(add_cookie_length == 0){
	    	$("#add_cookie_length_error").html("Must larger than 0.");
	        valid = false;
	    }
	    
	    if(add_cookie_length == ""){
	    	$("#add_cookie_length_error").html("Please Input.");
	        valid = false;
	    }
		
		if(network_name == ""){
			$("#add_account_name_error").html("Please input network name.");
			valid = false;
		}
		if(username == ""){
			$("#add_username_error").html("Please input username.");
			valid = false;
		}
		if(password == ""){
			$("#add_password_error").html("Please input password.");
			valid = false;
		}
		if(apitoken == ""){
			$("#add_api_token_error").html("Please input api token.");
			valid = false;
		}
		if($('#add_network').val()=='360'){
			if(apisecret == ""){
				$("#add_api_secret_error").html("Please input api secret.");
				valid = false;
			}
		}
		if(budget == ""){
			$("#add_budget_error").html("Please input monthly budget.");
			valid = false;
		}
		
		if(valid){
			$.ajax({
				url: "/createnetwork", 
				type: 'POST',
				data: $("#addAccountForm").serialize(),
				success: function(data,status,xhr){
					addAccountValid=true;
					if(data.status=='true'){
						window.location.reload();
					}else{
						$(".loading_container").hide();
						$("#add_cookie_length_error").html(data.message);
					}
				},
				error: function(xhr,status,error){
					addAccountValid=true;
					$(".loading_container").hide();
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			addAccountValid=true;
		}
	}
}

function submitEditAccount() {
	if(editAccountValid){		
		$(".loading_container").show();
		editAccountValid=false;
		
		var network_name = $('#edit_account_name').val();
		var username = $('#edit_username').val();
		var password = $('#edit_password').val();
		var apitoken = $('#edit_api_token').val();
		var apisecret = $('#edit_api_secret').val();
		var budget = $('#edit_budget').val();
		var edit_cookie_length = $('#edit_cookie_length').val();
		var valid = true;
		
		$("#edit_account_name_error").html("");
		$("#edit_username_error").html("");
		$("#edit_password_error").html("");
		$("#edit_api_token_error").html("");
		$("#edit_api_secret_error").html("");
		$("#edit_budget_error").html("");
		$("#edit_cookie_length_error").html("");
		
		
		var numericReg = /^\d*[0-9](|.\d*[0-9]|,\d*[0-9])?$/;
		
		if(!numericReg.test(edit_cookie_length)) {
	        $("#edit_cookie_length_error").html("Please input number only.");
	        valid = false;
	    }
	    
	    if(edit_cookie_length == 0){
	    	$("#edit_cookie_length_error").html("Must larger than 0.");
	        valid = false;
	    }
	    
	    if(edit_cookie_length == ""){
	    	$("#edit_cookie_length_error").html("Please input.");
	        valid = false;
	    }
	    
		if(network_name == ""){
			$("#edit_account_name_error").html("Please input network name.");
			valid = false;
		}
		if(username == ""){
			$("#edit_username_error").html("Please input username.");
			valid = false;
		}
		if(password == ""){
			$("#edit_password_error").html("Please input password.");
			valid = false;
		}
		if(apitoken == ""){
			$("#edit_api_token_error").html("Please input api token.");
			valid = false;
		}
		if($('edit_network').val()=='360'){
			if(apisecret == ""){
				$("#edit_api_secret_error").html("Please input api secret.");
				valid = false;
			}
		}
		if(budget == ""){
			$("#edit_budget_error").html("Please input monthly budget.");
			valid = false;
		}
		
		if(valid){
			if(editAccountAdRedirect=='yes' && $("#edit_update_ad").val()=='no' && editAccountChange==false){
				$(".loading_container").hide();
				editAccountValid=true;
				
				$(".modal_remainder").show();
				editAccountChange=true;
				return;
			}
			
			$.ajax({
				url: "/editnetwork", 
				type: 'POST',
				data: $("#editAccountForm").serialize(),
				success: function(data,status,xhr){
					editAccountValid=true;
					if(data.status=='true'){
						window.location.reload();
					}else{
						$(".loading_container").hide();
						$("#edit_cookie_length_error").html(data.message);
					}
				},
				error: function(xhr,status,error){
					editAccountValid=true;
					$(".loading_container").hide();
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			editAccountValid=true;
		}
	}
}
// account setting end

// reset password start
function submitResetPassword() {
	if(resetPasswordValid){
		$(".loading_container").show();
		resetPasswordValid=false;
		
	  	var up_c_password = $('#reset_current_password').val();
		var up_n_password = $('#reset_new_password').val();
		var up_cn_password = $('#reset_confirm_new_password').val();		
		var valid = true;
		
		$("#reset_current_password_error").html("");
		$("#reset_new_password_error").html("");
		$("#reset_confirm_new_password_error").html("");
		
		if(up_c_password == ""){
			$("#reset_current_password_error").html("Input Password");
			valid = false;
		}
		
		if(up_n_password == ""){
			$("#reset_new_password_error").html("Input Password");
			valid = false;
		}
		
		if(up_n_password != up_cn_password){
			$("#reset_confirm_new_password_error").html("Make sure your password is matched.");
			valid = false;
		}
		
		if(valid){
			$.ajax({
				url: "/updatepw", 
				type: 'POST',
				data: $("#resetPasswordForm").serialize(),
				success: function(data,status,xhr){
					resetPasswordValid=true;
					if(data.status=='true'){
						window.location.reload();
					}else{
						$(".loading_container").hide();
						$("#reset_confirm_new_password_error").html(data.message);
					}
				},
				error: function(xhr,status,error){
					resetPasswordValid=true;
					$(".loading_container").hide();
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			resetPasswordValid=true;
		}
	}
}
// reset password end

// user start
var remove_userid;

function showAddUserModal(){
	resetUserForm();
	$('#add_user_modal').modal('show');
}

function showEditUserModal(id){
	resetUserForm();
	
	$(".loading_container").show();
	$.ajax({
		url: "/getuser", 
		type: 'POST',
		data: {"id":id},
		success: function(data,status,xhr){
			$(".loading_container").hide();
			if(data.status=='true'){
				$("#edit_user_modal .modal_title").html("Editing Settings for "+data.user[0].username);
				
				$("#edit_id").val(id);
				
				$("#edit_name").val(data.user[0].username);
				$("#edit_email").val(data.user[0].email);
				$("#edit_access_level").val(data.user[0].role);
				
				if(data.user[0].status=='start'){
					$("#disable_button").show();
					$("#enable_button").hide();
				}else{
					$("#disable_button").hide();
					$("#enable_button").show();
				}
				
				$('#edit_user_modal').modal('show');
			}
		},
		error: function(xhr,status,error){
			// alert(error);
		}
	});
}

function showRemoveUserModal(id){
	remove_userid=id;
	$('#remove_user_modal').modal('show');
}

function resetUserForm(){
	$("#addUserForm")[0].reset();
	$("#editUserForm")[0].reset();
	
	$("#add_email_error").html("");
	$("#add_password_error").html("");
	
	$("#edit_email_error").html("");
	$("#edit_password_error").html("");
}

function submitAddUser() {
	if(addUserValid){
		$(".loading_container").show();
		addUserValid=false;
		
		var email = $('#add_email').val();
		var password = $('#add_password').val();
		var valid = true;
		
		$("#add_email_error").html("");
		$("#add_password_error").html("");
		$("#add_access_level_error").html("");
		
		if(email == ""){
			$("#add_email_error").html("Input Email");
			valid = false;
		}
		
		if (!validateEmail(email)) {
			$("#add_email_error").html('Email is invalid');
			valid = false;
		}
		
		if(password == "" ){
			$("#add_password_error").html("Make sure input your passsword");
			valid = false;
		}
		
		if(valid){
			$.ajax({
				url: "/createnewuser", 
				type: 'POST',
				data: $("#addUserForm").serialize(),
				success: function(data,status,xhr){
					addUserValid=true;
					if(data.status=='true'){
						window.location.reload();
					}else{
						$(".loading_container").hide();
						$("#add_access_level_error").html(data.message);
					}
				},
				error: function(xhr,status,error){
					addUserValid=true;
					$(".loading_container").hide();
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			addUserValid=true;
		}
	}
}

function submitEditUser() {
	if(editUserValid){
		$(".loading_container").show();
		editUserValid=false;
		
		var email = $('#edit_email').val();
		var valid = true;
		
		$("#edit_email_error").html("");
		$("#edit_password_error").html("");
		$("#edit_access_level_error").html("");
		
		if(email == ""){
			$("#edit_email_error").html("Input Email");
			valid = false;
		}
		
		if (!validateEmail(email)) {
			$("#edit_email_error").html('Email is invalid');
			valid = false;
		}
		
		if(valid){
			$.ajax({
				url: "/edituser",
				type: 'POST',
				data: $("#editUserForm").serialize(),
				success: function(data,status,xhr){
					editUserValid=true;
					if(data.status=='true'){
						window.location.reload();
					}else{
						$(".loading_container").hide();
						$("#edit_access_level_error").html(data.message);
					}
				},
				error: function(xhr,status,error){
					editUserValid=true;
					$(".loading_container").hide();
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			editUserValid=true;
		}
	}
}

function disableUser() {
	if(editUserValid){
		$(".loading_container").show();
		editUserValid=false;
		
		var email = $('#edit_email').val();
		var password = $('#edit_password').val();
		var valid = true;
		
		$("#edit_email_error").html("");
		$("#edit_password_error").html("");
		$("#edit_access_level_error").html("");
		
		if(valid){
			$.ajax({
				url: "/switchuserstatus",
				type: 'POST',
				data: {"id":$("#edit_id").val(),"status":"pause"},
				success: function(data,status,xhr){
					$(".loading_container").hide();
					editUserValid=true;
					if(data.status=='true'){
						$('#edit_user_modal').modal('hide');
					}
				},
				error: function(xhr,status,error){
					editUserValid=true;
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			editUserValid=true;
		}
	}
}

function enableUser() {
	if(editUserValid){
		$(".loading_container").show();
		editUserValid=false;
		
		var email = $('#edit_email').val();
		var password = $('#edit_password').val();
		var valid = true;
		
		$("#edit_email_error").html("");
		$("#edit_password_error").html("");
		$("#edit_access_level_error").html("");
		
		if(valid){
			$.ajax({
				url: "/switchuserstatus",
				type: 'POST',
				data: {"id":$("#edit_id").val(),"status":"start"},
				success: function(data,status,xhr){
					$(".loading_container").hide();
					editUserValid=true;
					if(data.status=='true'){
						$('#edit_user_modal').modal('hide');
					}
				},
				error: function(xhr,status,error){
					editUserValid=true;
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			editUserValid=true;
		}
	}
}

function submitRemoveUser() {
	if(removeUserValid){
		$(".loading_container").show();
		removeUserValid=false;
		$.ajax({
			url: "/removeuser", 
			type: 'POST',
			data: { remove_userid: remove_userid },
			success: function(data,status,xhr){
				$(".loading_container").hide();
				removeUserValid=true;
				if(data.status=='true'){
					$( "#user_"+remove_userid ).hide();
					$('#remove_user_modal').modal('hide');
				}
			},
			error: function(xhr,status,error){
				removeUserValid=true;
				// alert(error);
			}
		});
	}
}
// user end

// tracking start
function autoSelect(id){
	var sel = window.getSelection(),
    range = document.createRange();
					
	range.setStart($("#"+id)[0].firstChild, 0);
	range.setEnd($("#"+id)[0].lastChild, $("#"+id)[0].lastChild.length);
	sel.removeAllRanges();
	sel.addRange(range);
}
// tracking end

// portfolio start
function toggleHiddenPortfolio(element){
	$(element).next(".portfolio_select_hidden").slideToggle();
}

function selectAllPortfolioOption(element,id){
	if(element.checked){
		$("#"+id+" input").each(function() {
	        this.checked = true;
	    });
	}else{
		$("#"+id+" input").each(function() {
	        this.checked = false;
	    });
	}
}

function submitPortfolioDelete(form_id){
	if(removeProfilioValid){
		$(".loading_container").show();
		removeProfilioValid=false;
		$.ajax({
			url: "/removenetworkuser", 
			type: 'POST',
			data: $("#"+form_id).serialize(),
			success: function(data,status,xhr){
				removeProfilioValid=true;
				if(data.status=='true'){
					window.location.reload();
				}else{
					$("#portfolio_error_content").html(data.message);
					$("#portfolio_error_modal").modal('show');
					
					$(".loading_container").hide();
				}
			},
			error: function(xhr,status,error){
				removeProfilioValid=true;
				$(".loading_container").hide();
				// alert(error);
			}
		});
	}
}

function submitPortfolioAdd(form_id){
	if(addProfilioValid){
		$(".loading_container").show();
		addProfilioValid=false;
		$.ajax({
			url: "/addnetworkuser", 
			type: 'POST',
			data: $("#"+form_id).serialize(),
			success: function(data,status,xhr){
				addProfilioValid=true;
				if(data.status=='true'){
					window.location.reload();
				}else{
					$("#portfolio_error_content").html(data.message);
					$("#portfolio_error_modal").modal('show');
					
					$(".loading_container").hide();
				}
			},
			error: function(xhr,status,error){
				addProfilioValid=true;
				$(".loading_container").hide();
				// alert(error);
			}
		});
	}
}
// portfolio end

function prepareOpenExtendContent(id, callback){
	if($(".extend_content:visible").attr('id')==id){
	}else if($(".extend_content:visible").length==0){
		callback();
	}else{
		$(".extend_content:visible").slideUp("slow",function(){
			callback();
		});
	}
}

// advanced filter
function showRulesContentOuter(){
	prepareOpenExtendContent("rules-content-outer",function(){
		$("#rules-content-outer").slideDown({
			start: function(){
				// $(this).find("select").chosen("destroy");
				// $(this).find("select").chosen();
				
				if($(".filter_row").length==0){
					$("#rules-content").prepend(backupFilterField);
				}
			}
		})
	})
}

function hideRulesContentOuter(){
	$("#rules-content-outer").slideUp();
	
	$("input[name^=id]").removeAttr("disabled");
	$("#select_all").removeAttr("disabled");
}

function addRule(){
	$("#rules-content").append($(backupFilterField).clone());
	selectRuleField($("select[name=field_name]").last());
}

function selectRuleField(element){
	var fieldHtml="";
	
	if($(element).val()=="account_name" || $(element).val()=="adgroup_name" || $(element).val()=="campaign_name" || $(element).val()=="desc_1" || $(element).val()=="desc_2" || $(element).val()=="display_url" || $(element).val()=="m_display_url" || $(element).val()=="final_url" || $(element).val()=="m_final_url" || $(element).val()=="headline"){
		// datatype = text
		
		fieldHtml+='<select name="field_rule" class="form_field">';
		fieldHtml+='<option value="**">contains</option>';
		fieldHtml+='<option value="!**">does not contain</option>';
		fieldHtml+='<option value="=">is</option>';
		fieldHtml+='<option value="*=">starts with</option>';
		fieldHtml+='</select>';
		
		fieldHtml+='<input type="text" name="field_value" class="form_field">';
	}else if($(element).val()=="avg_cpc" || $(element).val()=="cost" || $(element).val()=="cpa" || $(element).val()=="cpm" || $(element).val()=="max_cpc" || $(element).val()=="profit" || $(element).val()=="revenue" || $(element).val()=="rpa"){
		// datatype = currency
		
		fieldHtml+='<select name="field_rule" class="form_field">';
		fieldHtml+='<option value=">=">>=</option>';
		fieldHtml+='<option value="=">=</option>';
		fieldHtml+='<option value="<="><=</option>';
		fieldHtml+='<option value="<"><</option>';
		fieldHtml+='<option value=">">></option>';
		fieldHtml+='<option value="!=">!=</option>';
		fieldHtml+='</select>';
		
		fieldHtml+='$<input type="text" name="field_value" class="form_field">';
	}else if($(element).val()=="conv_rate" || $(element).val()=="ctr" || $(element).val()=="impr_share" || $(element).val()=="roas"){
		// datatype = fraction
		
		fieldHtml+='<select name="field_rule" class="form_field">';
		fieldHtml+='<option value=">=">>=</option>';
		fieldHtml+='<option value="=">=</option>';
		fieldHtml+='<option value="<="><=</option>';
		fieldHtml+='<option value="<"><</option>';
		fieldHtml+='<option value=">">></option>';
		fieldHtml+='<option value="!=">!=</option>';		
		fieldHtml+='</select>';
		
		fieldHtml+='<input type="text" name="field_value" class="form_field">%';
	}else if($(element).val()=="avg_pos" || $(element).val()=="clicks" || $(element).val()=="conv" || $(element).val()=="impr"){
		// datatype = number
		
		fieldHtml+='<select name="field_rule" class="form_field">';
		fieldHtml+='<option value=">=">>=</option>';
		fieldHtml+='<option value="=">=</option>';
		fieldHtml+='<option value="<="><=</option>';
		fieldHtml+='<option value="<"><</option>';
		fieldHtml+='<option value=">">></option>';
		fieldHtml+='<option value="!=">!=</option>';		
		fieldHtml+='</select>';
		 
		fieldHtml+='<input type="text" name="field_value" class="form_field">';
	}else if($(element).val()=="ad_type"){
		// column = ad type
		
		fieldHtml+='<input type="hidden" name="field_rule" class="form_field" value="="/>';
		
		fieldHtml+='<select name="field_value" class="form_field">';
		fieldHtml+='<option value="Text Ad">Text Ad</option>';
		fieldHtml+='<option value="Image Ad">Image Ad</option>';
		fieldHtml+='</select>';
	}
	else if($(element).val()=="currency"){
		// column = currency
		
		fieldHtml+='<input type="hidden" name="field_rule" class="form_field" value="="/>';
		
		fieldHtml+='<select name="field_value" class="form_field">';
		fieldHtml+='<option value="RMB">CNY</option>';
		fieldHtml+='<option value="HKD">HKD</option>';
		fieldHtml+='<option value="US">USD</option>';
		fieldHtml+='<option value="AUD">AUD</option>';
		fieldHtml+='<option value="TWD">TWD</option>';
		fieldHtml+='<option value="JPY">JPY</option>';
		fieldHtml+='<option value="SGD">SGD</option>';
		fieldHtml+='</select>';
	}
	else if($(element).val()=="status"){
		// column = status
		
		fieldHtml+='<input type="hidden" name="field_rule" class="form_field" value="="/>';
		
		fieldHtml+='<select name="field_value" class="form_field">';
		fieldHtml+='<option value="Active">Active</option>';
		fieldHtml+='<option value="Inactive">Inactive</option>';
		fieldHtml+='</select>';
	}
	
	
	$(element).parent().siblings(".field_container").html(fieldHtml);
}

function removeRule(clicked){
	if($(".filter_row").length > 1){
		$(clicked).parent().remove();
	}
}

function resetRule(){	
	$(".filter_row").remove();
	$("#filterForm").prepend(backupFilterField);
}
// advanced filter

// export
function submitExportData(){
	exportData.csv = 1;
	
	$.fileDownload(exportUrl, {
        httpMethod: "POST",
        data: exportData
    });
}

function submitEditExportData(){
	exportData.csv = 2;
	
	$.fileDownload(exportUrl, {
        httpMethod: "POST",
        data: exportData
    });
}
// export

function selectAll(element){
	if(element.checked){
		$("input[name^=id]").each(function() {
	        this.checked = true;
	    });
	    selectAllPageRecordElement();
	}else{
		$("input[name^=id]").each(function() {
	        this.checked = false;
	    });
	    $(".selectAllPageRecordContainer").remove();
	}
}

// edit status
function editStatus(status){
	if($("input[name^=id]:checked").length>0){
		resetEditStatusForm();
		
		$("#edit_hidden_checkbox").html('');
		$("input[name^=id]:checked").each(function(){
			$("#edit_hidden_checkbox").append('<input type="checkbox" name="item_id[]" value="'+this.value+'" checked />');
		});
		$("input[name=status]").val(status);
		
		submitEditStatus();
	}else{
		$('#edit_error_modal').modal('show');
	}
}

function resetEditStatusForm(){
	$("#editStatusForm")[0].reset();
}

function submitEditStatus(){
	if(editStatusValid){
		$(".loading_container").show();
		editStatusValid=false;
		
		var valid = true;
		
		if(valid){
			if($("#campaign_type").val()=="sogou"){
				var url=editSogouUrl;
			}else if($("#campaign_type").val()=="threesixty"){
				var url=editThreesixtiesUrl;
			}
			
			$.ajax({
				url: url,
				type: 'POST',
				data: $("#editStatusForm").serialize(),
				success: function(data,status,xhr){
					$(".loading_container").hide();
					editStatusValid=true;
					if(data.status=='true'){
						$('.dropdown.open .dropdown-toggle').dropdown('toggle');
						$('#edit_error_modal .modal_title').html(data.message);
						$('#edit_error_modal').modal('show');
					}else{
						$("#edit_mobile_final_url_find_error").html(data.message);
					}
				},
				error: function(xhr,status,error){
					editStatusValid=true;
					$(".loading_container").hide();
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			editFindreplaceValid=true;
		}
	}
}
// edit status

function submitSync(){
	
	var ids=[]; 
	$('input[name^=id]:checked').each(function(){
	    ids.push($(this).val());
	});
	
	var id_length = ids.length;
	// var url="/channel/sync";
	
	if(id_length > 0){
		
		$(".loading_container").show();
		var key;
		for (key in ids) {
			
			var id_array = ids[key].split("_");
			
			if(id_array[1] == "sogou"){
				var url = "http://china.adeqo.com:83/sogous/resetdlfile?id="+id_array[0];
				// var url = "http://china.adeqo.com:83/test";
				
			}else if(id_array[1] == "360"){
				var url = "http://china.adeqo.com:83/threesixties/resetdlfile?id="+id_array[0];
				// var url = "http://china.adeqo.com:83/test2";
			}
			
			// alert(url);
			$.ajax({
				url: url,
				dataType: "jsonp",
				type: 'GET',
				// data: 'id='+ids,
				done: function(data,status,xhr){

				}
			});
		}
		
		
		$(".loading_container").hide();
		$('#edit_error_modal .modal_title').html("Please Wait while Account Sync is in progress.");
		$('#edit_error_modal').modal({backdrop: 'static',keyboard: false})
		$('#edit_error_modal .red_button').click(function(){
			location.reload();
		});
		
	}else{
		$('#edit_error_modal .modal_title').html("Please Select Account.");
		$('#edit_error_modal').modal('show');
	}
	
}

// edit find & replace
function showFindReplaceContentOuter(){
	$('.dropdown.open .dropdown-toggle').dropdown('toggle');
	if($("input[name^=id]:checked").length>0){
		$("#findreplace_selected_number").html($("input[name^=id]:checked").length);
		
		resetEditFindReplaceForm();
		
		$("#findreplace_hidden_checkbox").html('');
		$("input[name^=id]:checked").each(function(){
			$("#findreplace_hidden_checkbox").append('<input type="checkbox" name="item_id[]" value="'+this.value+'" checked />');
		})
		prepareOpenExtendContent("find-replace-content-outer",function(){
			$("#find-replace-content-outer").slideDown();
		});
		
		$("input[name^=id]").attr("disabled", true);
		$("#select_all").attr("disabled", true);
	}else{
		$('#edit_error_modal').modal('show');
	}
}

function resetEditFindReplaceForm(){
	$("#editFindReplaceForm")[0].reset();
	
	$("#edit_find_error").html("");
	$("#edit_replace_error").html("");
}

function hideFindReplaceContentOuter(){
	$("#find-replace-content-outer").slideUp();
	
	$("input[name^=id]").removeAttr("disabled");
	$("#select_all").removeAttr("disabled");
}

function submitEditFindReplace() {
	if(editFindreplaceValid){
		$(".loading_container").show();
		editFindreplaceValid=false;
		
		var edit_find = $('#edit_find').val();
		var edit_replace = $('#edit_replace').val();
		var valid = true;
		
		$("#edit_find_error").html("");
		$("#edit_replace_error").html("");
		
		var notEmpty = false;
		var error_id;
		$("#editFindReplaceForm input[type=text]").each(function(){
			if(this.value!=""){
				notEmpty = true;
			}
			error_id=$(this).parent().find("span").attr("id");
		});
		if(!notEmpty){
			$("#"+error_id).html("No Input");
			valid = false;
		}
		
		if(edit_find == "" && edit_replace != ""){
			$("#edit_find_error").html("Input find field");
			valid = false;
		}
		
		if(edit_find != "" && edit_replace == ""){
			$("#edit_replace_error").html("Input replace field");
			valid = false;
		}
		
		if(valid){
			if($("#campaign_type").val()=="sogou"){
				var url=editSogouUrl;
			}else if($("#campaign_type").val()=="threesixty"){
				var url=editThreesixtiesUrl;
			}
			
			$.ajax({
				url: url,
				type: 'POST',
				data: $("#editFindReplaceForm").serialize(),
				success: function(data,status,xhr){
					$(".loading_container").hide();
					editFindreplaceValid=true;
					if(data.status=='true'){
						hideFindReplaceContentOuter();
						$('#edit_error_modal .modal_title').html(data.message);
						$('#edit_error_modal').modal('show');
					}else{
						$("#edit_replace_error").html(data.message);
					}
				},
				error: function(xhr,status,error){
					editFindreplaceValid=true;
					$(".loading_container").hide();
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			editFindreplaceValid=true;
		}
	}
}
// edit find & replace

// edit cpc bid
function showChangeCpcContentOuter(){
	$('.dropdown.open .dropdown-toggle').dropdown('toggle');
	if($("input[name^=id]:checked").length>0){
		$("#cpcbid_selected_number").html($("input[name^=id]:checked").length);
		
		resetEditCpcBidForm();
		
		$("#cpcbid_hidden_checkbox").html('');
		$("input[name^=id]:checked").each(function(){
			$("#cpcbid_hidden_checkbox").append('<input type="checkbox" name="item_id[]" value="'+this.value+'" checked />');
		})
		prepareOpenExtendContent("cpc-content-outer",function(){
			$("#cpc-content-outer").slideDown();
		});
		
		$("input[name^=id]").attr("disabled", true);
		$("#select_all").attr("disabled", true);
	}else{
		$('#edit_error_modal').modal('show');
	}
}

function resetEditCpcBidForm(){
	$("#editCpcBidForm")[0].reset();
	
	$("#edit_cpcbid_error").html("");
	
	changeCpcBidInput('set');
}

function hideCpcContentOuter(){
	$("#cpc-content-outer").slideUp();
	
	$("input[name^=id]").removeAttr("disabled");
	$("#select_all").removeAttr("disabled");
}

function changeCpcBidInput(type){
	$("#edit_cpcbid_error").html("");
	var inputHtml="";
	
	$("#cpcbid_input_container").html("");
	if(type=='set'){
		inputHtml+='<span class="form_spacing"></span>RMB <input type="text" id="edit_value" name="value" class="form_field form_field_short">';
	}else{
		inputHtml+='<span class="form_spacing"></span><input type="text" id="edit_value" name="value" class="form_field form_field_short">';
		inputHtml+='<span class="form_spacing"></span><select name="classifier" class="form_field form_field_short"><option value="%">%</option><option value="RMB">RMB</option></select>';
	}
	
	$("#cpcbid_input_container").html(inputHtml);
}

function submitEditCpcBid() {
	if(editCpcbidValid){
		$(".loading_container").show();
		editCpcbidValid=false;
		
		var value = $('#edit_value').val();
		var valid = true;
		
		
		if(value == ""){
			$("#edit_cpcbid_error").html("Input value please");
			valid = false;
		}
		
		if(valid){
			if($("#campaign_type").val()=="sogou"){
				var url=editSogouUrl;
			}else if($("#campaign_type").val()=="threesixty"){
				var url=editThreesixtiesUrl;
			}
			
			$.ajax({
				url: url,
				type: 'POST',
				data: $("#editCpcBidForm").serialize(),
				success: function(data,status,xhr){
					$(".loading_container").hide();
					editCpcbidValid=true;
					if(data.status=='true'){
						hideCpcContentOuter();
						$('#edit_error_modal .modal_title').html(data.message);
						$('#edit_error_modal').modal('show');
					}else{
						$("#edit_cpcbid_error").html(data.message);
					}
				},
				error: function(xhr,status,error){
					editCpcbidValid=true;
					$(".loading_container").hide();
					// alert(error);
				}
			});
		}else{
			$(".loading_container").hide();
			editCpcbidValid=true;
		}
	}
}
// edit cpc bid


function tableTopScrollbar(){
	$(".tableTopScrollbarWrapper").remove();
	
	$(".table-responsive").before('<div class="tableTopScrollbarWrapper"><div class="tableTopScrollbar">&nbsp;</div></div>');
	$(".tableTopScrollbarWrapper").css({"width":"100%","overflow-x": "auto","overflow-y": "hidden"});
	$(".tableTopScrollbar").css({"width":$(".table-responsive .dataTable").css("width")});
	$(".tableTopScrollbarWrapper").scroll(function(){
		$(".table-responsive").scrollLeft($(".tableTopScrollbarWrapper").scrollLeft());
	});
	$(".table-responsive").scroll(function(){
		$(".tableTopScrollbarWrapper").scrollLeft($(".table-responsive").scrollLeft());
	});
}

function selectAllPageRecordElement(){
	// $(".table-responsive").prepend('<div class="selectAllPageRecordContainer">All '+pageTotalRecord+' rows of this page are selected. <a href="javascript:void(0);" onclick="selectAllPageRecord();">Select all rows across all pages ('+allPageTotalRecord+')</a></div>');
	
	$(".table-responsive").prepend('<div class="selectAllPageRecordContainer">All '+pageTotalRecord+' rows of this page are selected.</div>');
	$(".selectAllPageRecordContainer").css({"width":$(".table-responsive .dataTable").css("width")});
	
	
}

function selectAllPageRecord(){
	$(".selectAllPageRecordContainer").html('All '+allPageTotalRecord+' rows of this page are selected. <a href="javascript:void(0);" onclick="clearAllPageRecord();">Clear selection</a></div>');
}

function clearAllPageRecord(){
	
}

//upload spreadsheet
function showUploadContentOuter(){
	$('.dropdown.open .dropdown-toggle').dropdown('toggle');
	
	resetUploadForm();
	resetEditUploadForm();
	
	prepareOpenExtendContent("upload-content-outer",function(){
		$("#upload-content-outer").slideDown();
	})
}


function showEditUploadContentOuter(){
	$('.dropdown.open .dropdown-toggle').dropdown('toggle');
	
	resetEditUploadForm();
	resetUploadForm();
	
	prepareOpenExtendContent("upload-content-oute-editr",function(){
		$("#upload-content-outer-edit").slideDown();
	})
}

function resetEditUploadForm(){
	$("#uploadeditForm")[0].reset();
	$("#upload_edit_error").html("");
}

function resetUploadForm(){
	$("#uploadForm")[0].reset();
	$("#upload_error").html("");
}



function resetBulkUploadForm(){
	// $("#uploadForm")[0].reset();
}


function submitbulkUpload(type){
	
	$(".loading_container").show();
	$("#upload_error").hide();
	
	if($("input[name=file]").val()!=''){
		$("#uploadForm input[name=type]").val(type);
		
		var file_name = $("input[name=file]").val();
		var ext = file_name.split('.').pop().toLowerCase();
		
		$("#uploadForm").submit();
		
		$("#hiddenUploadIframe").load(function(){
			
			$(".loading_container").hide();
			
			if(ext == "xlsx"){
				$("input[name=file]").val("");
				$('#edit_error_modal .modal_title').html("For the progress and status of the upload, please check the Summary tab.");
			}else{
				$('#edit_error_modal .modal_title').html("Upload Fail. Please make sure your file type is xlsx");
			}
			
			$('#edit_error_modal').modal({backdrop: 'static',keyboard: false})
			$('#edit_error_modal .red_button').click(function(){
				$('#edit_error_modal').modal("hide")
			});
					
			// if($("#hiddenUploadIframe").contents().find("body").html()=="true"){
				// $('#edit_error_modal .modal_title').html("Upload Success.");
				// $('#edit_error_modal').modal({backdrop: 'static',keyboard: false})
				// $('#edit_error_modal .red_button').click(function(){
					// location.reload();
				// });
			// }else{
				// $('#edit_error_modal .modal_title').html($("#hiddenUploadIframe").contents().find("body").html());
				// $('#edit_error_modal').modal({backdrop: 'static',keyboard: false})
				// $('#edit_error_modal .red_button').click(function(){
					// $('#edit_error_modal').modal("hide")
				// });
			// }
		});
			
	}else{
		$(".loading_container").hide();
		$("#upload_error").html("Please select a file first");
		$("#upload_error").show();
	}
	
}


function submitUpload(type){
	if(uploadValid){
		$(".loading_container").show();
		uploadValid=false;
		
		if($("input[name=file]").val()!=''){
			$("#uploadForm input[name=type]").val(type);
			$("#uploadForm").submit();
			
			$("#hiddenUploadIframe").load(function(){
				$(".loading_container").hide();
				uploadValid=true;
				
				if($("#hiddenUploadIframe").contents().find("body").html()=="true"){
					$('#edit_error_modal .modal_title').html("File has been uploaded.");
					$('#edit_error_modal').modal({backdrop: 'static',keyboard: false})
					$('#edit_error_modal .red_button').click(function(){
						location.reload();
					});
				}else{
					$('#edit_error_modal .modal_title').html($("#hiddenUploadIframe").contents().find("body").html());
					$('#edit_error_modal').modal({backdrop: 'static',keyboard: false})
					$('#edit_error_modal .red_button').click(function(){
						$('#edit_error_modal').modal("hide")
					});
				}
			});
		}else{
			$(".loading_container").hide();
			uploadValid=true;
			$("#upload_error").html("Please select a file first");
		}
	}
}

function submitEditUpload(type){
	if(uploadValid){
		$(".loading_container").show();
		uploadValid=false;
		
		if($("input[name=edit_file]").val()!=''){
			$("#uploadeditForm input[name=edit_type]").val(type);
			$("#uploadeditForm").submit();
			
			$("#hiddenEditUploadIframe").load(function(){
				$(".loading_container").hide();
				uploadValid=true;
				
				if($("#hiddenEditUploadIframe").contents().find("body").html()=="true"){
					$('#edit_error_modal .modal_title').html("File has been uploaded.");
					$('#edit_error_modal').modal({backdrop: 'static',keyboard: false})
					$('#edit_error_modal .red_button').click(function(){
						location.reload();
					});
				}else{
					$('#edit_error_modal .modal_title').html($("#hiddenEditUploadIframe").contents().find("body").html());
					$('#edit_error_modal').modal({backdrop: 'static',keyboard: false})
					$('#edit_error_modal .red_button').click(function(){
						$('#edit_error_modal').modal("hide")
					});
				}
			});
		}else{
			$(".loading_container").hide();
			uploadValid=true;
			$("#upload_edit_error").html("Please select a file first");
		}
	}
}

function hideUploadContentOuter(){
	$("#upload-content-outer").slideUp();
}

function hideEditUploadContentOuter(){
	$("#upload-content-outer-edit").slideUp();
}

//upload spreadsheet