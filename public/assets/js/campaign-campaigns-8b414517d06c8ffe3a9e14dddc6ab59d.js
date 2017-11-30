/**
 * @author elee
 */


exportUrl = campaignGetUrl;

editSogouUrl=campaignUpdateUrl;
editThreesixtiesUrl=editSogouUrl;

var aoColumns = [];
for(var i=0;i<21;i++){
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
                return '<div class="text-left checkbox"><label><input type="checkbox" name="id[]" value="'+row[20]+'|'+row[4]+'|'+row[0]+'|'+row[2]+'">'+data+'</label></div>';
            },
            "targets": [1]
        },
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left"><a href="'+ row[3] +'">'+ data +'</a></div>';
            },
            "targets": [2]
        },
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left"><a href="'+ row[21] +'">'+ data +'</a></div>';
            },
            "targets": [5]
        },
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left">'+ data +'</div>';
            },
            "targets": [4,6]
        },
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data);
            },
            "targets": [7,8,12]
        },
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data,2);
            },
            "targets": [9,10,14,15,16,17,18]
        },
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data,2)+"%";
            },
            "targets": [11,13,19]
        },
        { "visible": false,  "targets": [ 0,3,20 ] },
        { "orderable": false, "targets": [1]}
    ],
    "order": [[ 7, "desc" ]],
    "aoColumns": aoColumns
}

var campaignsTable;

$(document).ready(function(){
	if(/\/campaigns\/threesixty/i.test(window.location.href)){
		switchToNetwork('qihoo_360');
	}
	else if(/\/campaigns\/sogou/i.test(window.location.href)){
		switchToNetwork('sogou');
	}
	
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

function switchToNetwork(network){
	$("[name^=channel_array]").prop('checked', false);
	$("#"+network).prop('checked', true);
}

function getCampaignData(){
	campaignsTable.draw();
}
;
