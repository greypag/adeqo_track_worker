$(window).scroll(function(){
  if($(document).scrollTop()>99){
    $('.navbar').addClass('scrolled');
  } else {
    $('.navbar').removeClass('scrolled');
  }
});
$('.navbar-toggle').click(function(){
  if(($('.navbar-collapse.collapse').length)){
    $('.navbar-header').addClass('navbar-bg');
  }
  if($('.navbar-collapse.collapse.in').length){
    $('.navbar-header').removeClass('navbar-bg');
  }
});
