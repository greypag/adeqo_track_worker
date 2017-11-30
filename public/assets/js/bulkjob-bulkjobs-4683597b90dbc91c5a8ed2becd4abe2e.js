var exportUrl = bulkjobUrl;

editSogouUrl=campaignUpdateUrl;
editThreesixtiesUrl=editSogouUrl;

var aoColumns = [];
for(var i=0;i<12;i++){
	aoColumns.push({ "asSorting": [ "desc", "asc" ] });
}

var bulkjobsDataTableOptions = {
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
                return '<div class="text-left">'+ data +'</div>';
            },
            "targets": [1,7]
        },
        
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left" id="status'+row[0]+'">'+ data +'</div>';
            },
            "targets": [6]
        },
        
        {
            "render": function ( data, type, row ) {
            	
            	var text = "" 
            	if(data != ""){
            		text = decodeURIComponent(data).substr(0,7) + "..."
            	}
            	
                return '<div class="text-left"><a onclick="return false" style="cursor:default; color:#333; text-decoration: none;" href="javasrcipt:void(0)" title="'+ data +'">'+ text +'</a></div>';
            },
            "targets": [5]
        },
        
		{
            "render": function ( data, type, row ) {
            	if(row[10] == 1){
            		return '<div class="text-left checkbox"><label><button class="start" value="'+ row[0] +'" type="button">Start</button></label></div>';	
            	}else{
            		return '<div class="text-left"></div>';
            	}
                
            },
            "targets": [10]
        }, 
        
        
        {
            "render": function ( data, type, row ) {
            	if(row[11] == 1){
            		return '<div class="text-left checkbox"><label><button class="cancel" value="'+ row[0] +'" type="button">Cancel</button></label></div>';	
            	}else{
            		return '<div class="text-left"></div>';
            	}
                
            },
            "targets": [11]
        }, 

        { "visible": false,  "targets": [0] },
        { "orderable": false, "targets": [1]}
       	
    ]
    //,
    // "order": [[ 8, "desc" ]],
    // "aoColumns": aoColumns
 
}

var bulkjobTable;

$(document).ready(function(){
	if(/\/campaigns\/threesixty/i.test(window.location.href)){
		switchToNetwork('qihoo_360');
	}
	else if(/\/campaigns\/sogou/i.test(window.location.href)){
		switchToNetwork('sogou');
	}
	
	bulkjobTable = $("#bulk-job-table").on('preXhr.dt', function(e,settings,data){
		$(".loading_container").show();
	}).DataTable(bulkjobsDataTableOptions);
	
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
	bulkjobTable.columns().every(function(){
		var column = this;
		$('input.filterText', this.header()).on('change', function(){
			column.search(this.value).draw();
		});
	});
	
	var d=new Date();
	$("#end_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()));
});



$(document).on('click', '.cancel', function(){
	
	$(".loading_container").show();
	$(this).hide();
	id = $(this).val();
	
	$('.start[value='+id+']').hide();
	
	
	$.ajax({
			url: "/cancelbulkjob",
			type: 'POST',
			data: "_id="+$(this).val(),
			success: function(data,status,xhr){
				$(".loading_container").hide();
				// $(this).remove();
				console.log(data.status);
				
				if(data.status == "true"){
					// location.reload();
					$('#status'+id).text("Cancel")
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
	
	
	
$(document).on('click', '.start', function(){
		
	$(".loading_container").show();
	$(this).hide();
	
	$.ajax({
		url: "/resumebulkjob",
		type: 'POST',
		data: "_id="+$(this).val(),
		success: function(data,status,xhr){
			$(".loading_container").hide();
			// $(this).remove();
			
			console.log(data.status);
			
			if(data.status == "true"){
				// location.reload();
				$('#status'+id).text("Pending")
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
	


function cancelbulkjob(id){
	alert(id);
}

function resumebulkjob(id){
	alert(id);
}


function switchToNetwork(network){
	$("[name^=channel_array]").prop('checked', false);
	$("#"+network).prop('checked', true);
}

function getBulkJobData(){
	bulkjobTable.draw();
}
;
