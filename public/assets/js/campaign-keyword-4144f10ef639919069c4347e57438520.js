/**
 * @author elee
 */


exportUrl = campaignKeywordGetUrl;

editSogouUrl=campaignKeywordSogouUpdateUrl;
editThreesixtiesUrl=campaignKeywordThreesixtiesUpdateUrl;

var aoColumns = [];
for(var i=0;i<23;i++){
	aoColumns.push({ "asSorting": [ "desc", "asc" ] });
}

var keywordTableOption = {
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
			d.start_date = $("#start_date").val();
			d.end_date = $("#end_date").val();
			d.campaign_type = $("#campaign_type").val();
			d.campaign_id = $("#campaign_id").val();
			d.network_id = $("#network_id").val();
			d.adgroup_id = $("#adgroup_id").val();
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
		$(".ellipsis").ellipsis();
		
		pageTotalRecord=oSettings.json.data.length;
		allPageTotalRecord=oSettings.json.recordsTotal;
		
		if(oSettings.json.status == "false" && oSettings.json.recordsTotal == 0){
			$('#edit_error_modal .modal_title').html(oSettings.json.message);
			$('#edit_error_modal').modal('show');	
		}
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
		// var avg_cpc = 0;
		// var cpa = 0;
		// var profit = 0;
		// var avg_pos = 0;
		// var rpa = 0;
		// var roas = 0;
		// var cpm = 0;
// 		
		// aaData.forEach(function(array_d) {
		    // // console.log(array_d);
		    // impr = impr + array_d[8];
		    // click = click + array_d[9];
		    // cost = cost + array_d[11];
		    // avg_cpc = avg_cpc + array_d[12];
		    // ctr = ctr + array_d[10];
		    // conversion = conversion + array_d[13];
		    // revenue = revenue + parseInt(array_d[17]);
		    // avg_pos = avg_pos + array_d[19];
// 		    
		// });
// 		
		// cpa = cost / conversion;
		// avg_cpc = avg_cpc / aaData.length;
		// conversion_rate = conversion/click;
		// avg_pos = avg_pos / aaData.length;
// 		
// 		
// 		
		// var nCells = nRow.getElementsByTagName('th');
// 		
		// console.log(nCells);
        // nCells[0].innerHTML = "Total";
        // // nCells[1].innerHTML = "N/A";
        // nCells[7].innerHTML = impr;
        // nCells[8].innerHTML = click;
        // nCells[9].innerHTML = ctr.toFixed(2)+"%";
        // nCells[10].innerHTML = cost.toFixed(2);
        // nCells[11].innerHTML = avg_cpc.toFixed(2);
//         
        // nCells[12].innerHTML = conversion;
        // nCells[13].innerHTML = conversion_rate.toFixed(2)+"%";
        // nCells[14].innerHTML = cpa.toFixed(2);
        // nCells[15].innerHTML = cpm;
//         
        // nCells[16].innerHTML = revenue;
//         
        // nCells[17].innerHTML = parseInt(profit);
        // nCells[18].innerHTML = avg_pos.toFixed(2);
        // nCells[19].innerHTML = parseInt(rpa);
        // nCells[20].innerHTML = parseInt(roas);
        
    },
	"columnDefs": [
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left checkbox"><label><input type="checkbox" name="id[]" value="'+row[0]+'|'+row[2]+'|'+row[3]+'">'+data+'</label></div>';
            },
            "targets": [1]
        },
        
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left"><a href="'+row[24]+'">'+data+'</a></div>';
            },
            "targets": [2]
        },
        
        {
            "render": function ( data, type, row ) {
            	var link_text = "" 
            	if(data != ""){
            		link_text = decodeURIComponent(data).substr(0,25) + "..."
            	}
                return '<div class="text-left" style="width:200px;"><a target="_blank" href="'+data+'" title="'+decodeURIComponent(data)+'">'+ link_text +'</a></div>';
            },
            "targets": [5,6,22,23]
        },
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left">'+ data +'</div>';
            },
            "targets": [2,3,4]
        },
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data);
            },
            "targets": [8,9,13]
        },
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data,2);
            },
            "targets": [7,11,12,15,16,17,18,19,20]
        },
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data,2)+"%";
            },
            "targets": [10,14,21]
        },
        { "visible": false,  "targets": [ 0,24 ] }
    ],
    "order": [[ 9, "desc" ]],
    "aoColumns": aoColumns
};

var keywordTable;

$(document).ready(function(){
	keywordTable = $("#keywords-table").on('preXhr.dt', function(e,settings,data){
		$(".loading_container").show();
		$("#select_all").prop('checked', false);
	}).DataTable(keywordTableOption);
	
	$("th").on("click selectstart", "input[type=checkbox]", function(e){
		e.stopPropagation();
	});
});

function getCampaignData(){
	keywordTable.draw();
}
;
