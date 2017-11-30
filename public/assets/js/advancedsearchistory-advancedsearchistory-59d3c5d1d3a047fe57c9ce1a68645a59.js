var exportUrl = advancesearchjobinfoUrl;

editSogouUrl=campaignUpdateUrl;
editThreesixtiesUrl=editSogouUrl;

var aoColumns = [];
for(var i=0;i<11;i++){
	aoColumns.push({ "asSorting": [ "desc", "asc" ] });
}

var advancesearchsDataTableOptions = {
	// bFilter: false,
	/* http://datatables.net/release-datatables/examples/basic_init/dom.html */
	"sDom": '<"table-responsive"rt>pil',
	"aLengthMenu": page_option,
	"language": {
		"info": "Page _PAGE_ of _PAGES_",
		"lengthMenu": "No. of Rows: _MENU_",
		"paginate": {
			"previous": "<<",
			"next": ">>"
		},
		"emptyTable":"There is no data available for the selected period. Select a different date range to view performance data."
	},
	"oLanguage": {
		"sInfo": "Page _PAGE_ of _PAGES_",
		"sLengthMenu": "No. of Rows: _MENU_",
		"oPaginate": {
			"sPrevious": "<<",
			"sNext": ">>"
		},
		"sEmptyTable":"There is no data available for the selected period. Select a different date range to view performance data."
	},
	"processing": true,
	"serverSide": true,
	"ajax": {
		"url":exportUrl,
		"type":"POST",
		"data": function(d){
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
			
			d.filter_object = filter_object;
			d.channel_array = $("input[name^=channel_array]:checked").map(function(){ return $(this).val(); }).get();
			d.account_array = $("input[name^=account_array]:checked").map(function(){ return $(this).val(); }).get();
			d.start_date = $("#start_date").val();
			d.end_date = $("#end_date").val();
			d.csv=0;
			
			exportData=d;
			
			return d;
		}
	},
	"fnDrawCallback": function( oSettings ) {
		$(".selectAllPageRecordContainer").remove();
		$("#select_all").attr('checked', false);	
		$(".loading_container").hide();
		tableTopScrollbar();
		pageTotalRecord=oSettings.json.data.length;
		allPageTotalRecord=oSettings.json.recordsTotal;		
    },
	"columnDefs": [
        {
			"render": function ( data, type, row ) {
				if (row[8] == 'Pending'){
	                return '<div class="text-left"><button class="cancel" onclick="cancelAdvanceSearchJob(this.value)" value="' + row[10] + '" type="button">Cancel</button></div>';
				}
				else {
					return ''
				}
	        },
        	"targets": [10]
        },
        { "visible": false,  "targets": [0] },
        { "orderable": false, "targets": [1]}
       	
    ]
    //,
    //"order": [[ 7, "desc" ]],
    //"aoColumns": aoColumns
 
}

var advanceSearchTable;

$(document).ready(function(){

	if(/\/campaigns\/threesixty/i.test(window.location.href)){
		switchToNetwork('qihoo_360');
	}
	else if(/\/campaigns\/sogou/i.test(window.location.href)){
		switchToNetwork('sogou');
	}
	
	advanceSearchTable = $("#advance-search-table").on('preXhr.dt', function(e,settings,data){
		$(".loading_container").show();
	}).DataTable(advancesearchsDataTableOptions);
	
	// datatable filters
	// prevent defautl sorting click event
	$("th").on("click selectstart", ".dropdown-menu", function(e){
		e.stopPropagation();
	});
	$("th").on("click selectstart", "input[type=checkbox]", function(e){
		e.stopPropagation();
	});
	

	// reset chosen
	// $('.dropdown').one('show.bs.dropdown', function (e) {
		// $(this).find("select").chosen('destroy');
	// });
	// $('.dropdown').one('shown.bs.dropdown', function (e) {
		// $(this).find("select").chosen({disable_search:true});
	// });
	// bind search event to filterText fieid
	advanceSearchTable.columns().every(function(){
		var column = this;
		$('input.filterText', this.header()).on('change', function(){
			column.search(this.value).draw();
		});
	});
	var d=new Date();
	$("#end_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()));


});


function cancelAdvanceSearchJob(value){

	$(".loading_container").show();
	

	$.ajax({
		url: "/canceladvancesearchjob",
		type: 'POST',
		data: "_id="+ value,
		success: function(data,status,xhr){
			$(".loading_container").hide();
				
			if(data.status=='true'){
				location.reload();
			}
			else if(data.status=='test'){

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
}

function switchToNetwork(network){
	$("[name^=channel_array]").prop('checked', false);
	$("#"+network).prop('checked', true);
}

function getAdvanceSearchData(){
	advanceSearchTable.draw();
}
;
