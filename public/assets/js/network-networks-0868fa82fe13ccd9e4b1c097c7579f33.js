var exportUrl = networkUrl;

editSogouUrl=campaignUpdateUrl;
editThreesixtiesUrl=editSogouUrl;

var aoColumns = [];
for(var i=0;i<12;i++){
	aoColumns.push({ "asSorting": [ "desc", "asc" ] });
}

var networksDataTableOptions = {
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
    "fnFooterCallback": function( nRow, aaData, iStart, iEnd, aiDisplay  ) {
		
		
		// // console.log(aaData);
		// var impr = 0;
		// var click = 0;
		// var cost = 0;
		// var ctr = 0;
		// var conversion = 0;
		// var conversion_rate = 0;
		// var revenue = 0;
// 		
		// aaData.forEach(function(array_d) {
		    // // console.log(array_d);
		    // impr = impr + array_d[3];
		    // click = click + array_d[4];
		    // cost = cost + array_d[5];
		    // ctr = ctr + array_d[6];
		    // conversion = conversion + array_d[7];
		    // revenue = revenue + parseInt(array_d[9]);
// 		    
		// });
// 		
		// conversion_rate = conversion/click
// 		
		// var nCells = nRow.getElementsByTagName('th');
        // nCells[0].innerHTML = "Total";
        // // nCells[1].innerHTML = "N/A";
        // nCells[2].innerHTML = impr;
        // nCells[3].innerHTML = click;
        // nCells[4].innerHTML = cost;
        // nCells[5].innerHTML = ctr;
        // nCells[6].innerHTML = conversion;
        // nCells[7].innerHTML = conversion_rate.toFixed(2)+"%";
        // nCells[8].innerHTML = revenue;
        
        
        
    },
	"columnDefs": [
		{
            "render": function ( data, type, row ) {
            	if(row[11] == 1){
            		return '<div class="text-left checkbox"><label><input type="checkbox" name="id[]" value="'+row[0]+"_"+row[2].toLowerCase()+'"><a href="'+ row[10] +'">'+data+'</a>  (Last Sync : '+row[12]+')</label></div>';	
            	}else{
            		return '<div class="text-left checkbox"><img style="margin-right:8px;" width="22" src="/images/icon/loading-x.gif"><a href="'+ row[10] +'">'+data+'</a></div>';
            	}
                
            },
            "targets": [1]
        },   
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data);
            },
            "targets": [3,4,5,7]
        },
       
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data,2)+"%";
            },
            "targets": [6,8]
        },        
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data,2);
            },
            "targets": [9]
        }
        /*
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left"><a href="'+ row[3] +'">'+ data +'</a></div>';
            },
            "targets": [2]
        },
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left">'+ data +'</div>';
            },
            "targets": [4,5,6]
        },
		*/

        ,{ "visible": false,  "targets": [0,10,11,12] },
        { "orderable": false, "targets": [1]}
       	
    ]
    ,
    "order": [[ 3, "desc" ]],
    "aoColumns": aoColumns
 
}

var networkTable;

$(document).ready(function(){
	if(/\/campaigns\/threesixty/i.test(window.location.href)){
		switchToNetwork('qihoo_360');
	}
	else if(/\/campaigns\/sogou/i.test(window.location.href)){
		switchToNetwork('sogou');
	}
	
	networkTable = $("#networks-table").on('preXhr.dt', function(e,settings,data){
		$(".loading_container").show();
	}).DataTable(networksDataTableOptions);
	
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
	networkTable.columns().every(function(){
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

function getNetworkData(){
	networkTable.draw();
}
;
