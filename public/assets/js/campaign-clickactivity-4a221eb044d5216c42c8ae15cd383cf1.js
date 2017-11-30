/**
 * @author elee
 */


exportUrl = campaignClickActivityGetUrl;

var aoColumns = [];
for(var i=0;i<22;i++){
	aoColumns.push({ "asSorting": [ "desc", "asc" ] });
}

var campaingsDataTableOptions = {
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
			d.clickactivity_id = $("#clickactivity_id").val();
			d.clickactivity_type = $("#clickactivity_type").val();
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
		$(".loading_container").hide();
		tableTopScrollbar();
		$(".ellipsis").ellipsis();
    },
    "columnDefs": [
    	{
            "render": function ( data, type, row ) {
                return '<div class="text-left" style="width:200px;">'+ data +'</div>';
            },
            "targets": [7]
        },
        // {
            // "render": function ( data, type, row ) {
                // return '<div class="text-left ellipsis" style="width:200px;"><a href="'+data+'">'+ data +'</a></div>';
            // },
            // "targets": [20,21]
        // },
        {
            "render": function ( data, type, row ) {
            	var link_text = "" 
            	if(data != ""){
            		link_text = data.substr(0,25) + "..."
            	}
                return '<div class="text-left " style="width:200px;"><a target="_blank" href="'+data+'">'+ link_text +'</a></div>';
            },
            "targets": [20,21]
        },
        {
            "render": function ( data, type, row ) {
                return '<div style="width:400px; word-wrap:break-word; word-break:break-all; display:block;">'+ data +'</div>';
            },
            "targets": [6,8,18] //Tony: set word-break class for search-query 
        },        
        { "sClass": "word-break", "aTargets": [6,8,18] } //Tony: set word-break class for search-query
    ],
    "order": [[ 0, "asc" ]],
    "aoColumns": aoColumns
}

var campaignsTable;

$(document).ready(function(){
	var d=new Date();
	$("#end_date").datepicker("setEndDate",new Date(d.getFullYear(), d.getMonth(), d.getDate()));
	setClickActivityDate('Date Range');	
	
	campaignsTable = $("#campaigns-table").on('preXhr.dt', function(e,settings,data){
		$(".loading_container").show();
	}).DataTable(campaingsDataTableOptions);
	
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
	campaignsTable.columns().every(function(){
		var column = this;
		$('input.filterText', this.header()).on('change', function(){
			column.search(this.value).draw();
		});
	});
});

function getCampaignData(){
	campaignsTable.draw();
}

function setClickActivityDate(range){
	var d=new Date();
	var start_date;
	var end_date;

	if(range=='Today'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate());
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate());
	}else if(range=='Yesterday'){
		setDate(range);
		return;
	}else if(range=='This Week'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-d.getDay());
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate());
	}else if(range=='Last Week'){
		setDate(range);
		return;
	}else if(range=='This Month'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-d.getDate()+1);
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate());
	}else if(range=='Last Month'){
		setDate(range);
		return;
	}else if(range=='Last 3 Months'){
		setDate(range);
		return;
	}else if(range=='Last 7 days'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-6);
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate());
	}else if(range=='Last 30 days'){
		start_date=new Date(d.getFullYear(), d.getMonth(), d.getDate()-29);
		end_date=new Date(d.getFullYear(), d.getMonth(), d.getDate());
	}

	if(range!="Date Range"){
		$("#start_date").datepicker("setEndDate",end_date);
		$("#end_date").datepicker("setStartDate",start_date);
		
		$('#start_date').datepicker('update', start_date);
		$('#end_date').datepicker('update', end_date);
	}

	date_range_text=$('#start_date').val()+" - "+$('#end_date').val();

	$(".date-range").html(range+"<br/>"+date_range_text);
}
;
