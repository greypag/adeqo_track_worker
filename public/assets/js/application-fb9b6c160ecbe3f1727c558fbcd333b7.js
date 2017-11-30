/**
 * @author elee
 */


var loginValid=true;
var signupValid=true;
var resetValid=true;

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
    .on('show.bs.modal', '.modal', function() {
    	resetForm()
    	
      // When modal is shown, scrollbar on body disappears.  In order not
      // to experience a "shifting" effect, replace the scrollbar width
      // with a right-margin on the body.
      if ($(window).height() < $(document).height()) {
        $(".header_container").css('padding-right', scrollBarWidth + 'px');
      }
    });
});

function test(sEmail) {
	return sEmail;
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

function showModal(id){
	if($('.modal').hasClass('in')){
		$('.modal').modal('hide');
		setTimeout(function(){
			$('#'+id+'_modal').modal('show');
		}, 500);
	}else{
		$('#'+id+'_modal').modal('show');
	}
}

function homeScrollDown(){
	var offset = $('.feature_container').offset().top-$('.header_container').height();
	
	$('html,body').animate({scrollTop: offset},'slow');
}

function signupSubmit() {
	if(signupValid){
		$(".loading_container").show();
		signupValid=false;
	
	  	var email = $('input[name="signup_email"]').val();
		var password = $('input[name="signup_password"]').val();
		var password2 = $('input[name="signup_password2"]').val();
		var company = $('input[name="signup_company"]').val();
		var valid = true;
		
		$("#signup_email_error").html("");
		$("#signup_password_error").html("");
		$("#signup_password2_error").html("");
		$("#signup_company_error").html("");
		
		if(email == ""){
			$("#signup_email_error").html("Please input your email address.");
			valid=false;
		}else{
			if (!validateEmail(email)) {
				$("#signup_email_error").html('Please use a valid email address.');
				valid=false;
			}
		}
		
		if(password == "" || password2 == ""){
			$("#signup_password_error").html("Make sure input your passsword");
			$("#signup_password2_error").html("Make sure input your passsword");
			valid=false;
		}
		
		if(password != password2){
			$("#signup_password_error").html("Your password is not match");
			$("#signup_password2_error").html("Your password is not match");
			valid=false;
		}
		
		if(company == ""){
			$("#signup_company_error").html("Please input your company name");
			valid=false;
		}
		
		if(valid){
			$.ajax({
			     url: "/createnewuser", 
			     type: 'POST',
			     data: $("#signupForm").serialize(),
			     success: function(data,status,xhr){
			     	signupValid=true;
			     	if(data.status=='true'){
			     		window.location.href = "/dashboard";
			     	}else{
			     		$(".loading_container").hide();
			     		$("#signup_company_error").html(data.message);
			     	}
			     },
			     error: function(xhr,status,error){
			     	signupValid=true;
			     	$(".loading_container").hide();
			     	console.log(xhr);
			     	console.log(status);
			     	console.log(error);
				 }
		    });
	   	}else{
	   		$(".loading_container").hide();
	   		signupValid=true;
	   	}
   	}
}

function loginSubmit() {
	if(loginValid){
		$(".loading_container").show();
		loginValid=false;
		
	  	var email = $('input[name="login_email"]').val();
		var password = $('input[name="login_password"]').val();
		var valid = true;
		
		$("#login_email_error").html("");
		$("#login_password_error").html("");
		
		if(email == ""){
			$("#login_email_error").html("Please input your email address.");
			valid=false;
		}
		
		if (!validateEmail(email)) {
			$("#login_email_error").html("Please use a valid email address.");
			valid=false;
		}
		
		if(password == ""){
			$("#login_password_error").html("Make sure input your passsword");
			valid=false;
		}
		if(valid){
			$.ajax({
			     url: "/login", 
			     type: 'POST',
			     data: $("#loginForm").serialize(),
			     success: function(data,status,xhr){
			     	loginValid=true;
			     	if(data.status=='true'){
			     		window.location.href = "/dashboard";
			     	}else{
			     		$(".loading_container").hide();
			     		$("#login_password_error").html(data.message);
			     	}
			     },
			     error: function(xhr,status,error){
			     	loginValid=true;
			     	$(".loading_container").hide();
			     	console.log(xhr);
			     	console.log(status);
			     	console.log(error);
				 }
		    });
		}else{
			$(".loading_container").hide();
	   		loginValid=true;
	   	}
	}
}

function resetSubmit() {
	if(resetValid){
		$(".loading_container").show();
		resetValid=false;
		
	  	var email = $('input[name="reset_email"]').val();
		var valid = true;
		
		$("#reset_email_error").html("");
		
		if(email == ""){
			$("#reset_email_error").html("Please input your email address.");
			valid=false;
		}
		
		if (!validateEmail(email)) {
			$("#reset_email_error").html("Please use a valid email address.");
			valid=false;
		}
		if(valid){
			$.ajax({
			     url: "/resetPassword", 
			     type: 'POST',
			     data: $("#resetForm").serialize(),
			     success: function(data,status,xhr){
			     	resetValid=true;
			     	if(data.status=='true'){
			     		window.location.href = "/dashboard";
			     	}else{
			     		$(".loading_container").hide();
			     		$("#reset_email_error").html(data.message);
			     	}
			     },
			     error: function(xhr,status,error){
			     	resetValid=true;
			     	$(".loading_container").hide();
			     	console.log(xhr);
			     	console.log(status);
			     	console.log(error);
				 }
		    });
		}else{
			$(".loading_container").hide();
	   		resetValid=true;
	   	}
	}
}

function resetForm(){
	$("#loginForm")[0].reset();
	$("#signupForm")[0].reset();
	$("#resetForm")[0].reset();
	
	$("#login_email_error").html("");
	$("#login_password_error").html("");
	$("#signup_email_error").html("");
	$("#signup_password_error").html("");
	$("#signup_password2_error").html("");
	$("#signup_company_error").html("");
	$("#reset_email_error").html("");
}
;
