
dataTableOptions = {
		// bFilter: false,
		/* http://datatables.net/release-datatables/examples/basic_init/dom.html */
		"sDom": '<"table-responsive"rt>pil',
		"aLengthMenu": [5, 10, 30, 100],
		"language": {
			"info": "Page _PAGE_ of _PAGES_",
			"lengthMenu": "No. of Rows: _MENU_"
		},
		"oLanguage": {
			"sInfo": "Page _PAGE_ of _PAGES_",
			"sLengthMenu": "No. of Rows: _MENU_",
			"oPaginate": {
				"sPrevious": "<<",
				"sNext": ">>"
			}
		}
	};

$(document).ready(function(){
	
	$("body").addClass('adgroup');

	/* turn off markup API for dropdown */
	$(document).off('.dropdown.data-api');
	/* manually turn on dropdown */
	$('.dropdown-toggle').dropdown();

	$(".datepicker-field").datepicker({
		format: 'd MM yyyy',
		autoclose: true,
		orientation: "top"
	});
	$("#date-range-dropdown .datepicker-field").each(function(i,o){
		$(o).datepicker("setDate", new Date());
	});

	$("select").chosen();

	/* overview tabs - line graphs */

	/* line graph */
	var lineGraphData = {
		labels: ["January", "February", "March", "April", "May", "June", "July"],
		datasets: [
		{
			label: "My First dataset",
			fillColor: "rgba(220,220,220,0.2)",
			strokeColor: "rgba(220,220,220,1)",
			pointColor: "rgba(220,220,220,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(220,220,220,1)",
			data: [65, 59, 80, 81, 56, 55, 40]
		},
		{
			label: "My Second dataset",
			fillColor: "rgba(151,187,205,0.2)",
			strokeColor: "rgba(151,187,205,1)",
			pointColor: "rgba(151,187,205,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(151,187,205,1)",
			data: [28, 48, 40, 19, 86, 27, 90]
		}
		]
	};

	var lineGraphOptions = {
		bezierCurve : false
	};

	try{
		var ctx = $("#line-chart1").get(0).getContext("2d");
		new Chart(ctx).Line(lineGraphData, lineGraphOptions);
	}catch(e){}

	try{
		var ctx = $("#line-chart2").get(0).getContext("2d");
		new Chart(ctx).Line(lineGraphData, lineGraphOptions);
	}catch(e){}


	/* keywords tab */
	try{
		$("#keywords-table").DataTable(dataTableOptions);
	}catch(e){console.log(e)}

	try{
		$("#negative-keywords-table").DataTable(dataTableOptions);
	}catch(e){console.log(e)}

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

	/* ads tab */
	try{
	var adsTable = $("#ads-table").DataTable(dataTableOptions);
	}catch(e){}

});