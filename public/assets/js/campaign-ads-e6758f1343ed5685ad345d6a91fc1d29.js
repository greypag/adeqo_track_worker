/**
 * @author elee
 */


exportUrl = campaignAdsGetUrl;

editSogouUrl=campaignAdsSogouUpdateUrl;
editThreesixtiesUrl=campaignAdsThreesixtiesUpdateUrl;

var aoColumns = [];
for(var i=0;i<25;i++){
	aoColumns.push({ "asSorting": [ "desc", "asc" ] });
}

var adsTableOption = {
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
		},
		
	},
	"fnDrawCallback": function( oSettings ) {
		$(".selectAllPageRecordContainer").remove();
		$("#select_all").attr('checked', false); 
		$(".loading_container").hide();
		tableTopScrollbar();
		$(".ellipsis").ellipsis();
		
		pageTotalRecord=oSettings.json.data.length;
		allPageTotalRecord=oSettings.json.recordsTotal;
		
		// console.log(oSettings.json.message)
		
		if(oSettings.json.status == "false" && oSettings.json.recordsTotal == 0){
			$('#edit_error_modal .modal_title').html(oSettings.json.message);
			$('#edit_error_modal').modal('show');	
		}
		
		
    },
   
	"columnDefs": [
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left checkbox"><label><input type="checkbox" name="id[]" value="'+row[0]+'|'+row[2]+'">'+data+'</label></div>';
            },
            "targets": [1]
        },
        
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left"><a href="'+row[25]+'">'+data+'</a></div>';
            },
            "targets": [2]
        },
        
        {
            "render": function ( data, type, row ) {
            	var link_text = "" 
            	if(data != ""){
            		link_text = data.substr(0,25) + "..."
            	}
                return '<div class="text-left ellipsis" style="width:200px;"><a target="_blank" href="'+data+'" title="'+link_text+'">'+ data +'</a></div>';
            },
            "targets": [6,7,8,9]
        },
        {
            "render": function ( data, type, row ) {
            	var html = '';
            	var link_text = "" 
            	if(data != ""){
            		link_text = data.substr(0,25) + "..."
            	}
            	html+= '<div class="text-left" style="width:200px;">';
            	html+= '<div class="ellipsis" style="height: 20px;"><a target="_blank" href="'+row[7]+'" title="'+data+'">'+link_text+'</a></div>';
            	html+= '<div class="ellipsis" style="height: 20px;">'+row[4]+'</div>';
            	html+= '<div class="ellipsis" style="height: 20px;">'+row[5]+'</div>';
            	html+= '<div class="ellipsis" style="height: 20px;color:#006621;">'+row[6]+'</div>';
            	html+= '</div>';
            	
                return html;
            },
            "targets": [3]
        },
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left">'+ data +'</div>';
            },
            "targets": [2,10]
        },
        {
            "render": function ( data, type, row ) {
                return '<div class="text-left" style="white-space: nowrap;">'+ data +'</div>';
            },
            "targets": [4,5]
        },
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data);
            },
            // "targets": [13,14]
            "targets": [11,12,16]
        },
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data,2);
            },
            // "targets": [11,12,16,19,20,21,22,23,24]
            "targets": [14,19,20,21,22,23,15,18]
        },
        {
            "render": function ( data, type, row ) {
                return accounting.formatNumber(data,2)+"%";
            },
            // "targets": [15,18,25]
            "targets": [13,17,24]
        },
        { "visible": false,  "targets": [ 0,25 ] },
        { "orderable": false, "targets": [1]}
    ],
    // "order": [[ 13, "desc" ]],
    "order": [[ 11, "desc" ]],
    "aoColumns": aoColumns
};

var adsTable;

$(document).ready(function(){
	adsTable = $("#ads-table").on('preXhr.dt', function(e,settings,data){
		$('.selectAllPageRecordContainer').remove();
		$(".loading_container").show();
		$("#select_all").prop('checked', false);
	}).DataTable(adsTableOption);
	
	$("th").on("click selectstart", "input[type=checkbox]", function(e){
		e.stopPropagation();
	});
	
	// console.log(adsTable.fnCallback);
	// console.log(adsTable["context"]);
	// console.log(adsTable["context"][0]);
	// console.log(adsTable["context"][0]._iRecordsDisplay);
	
});

function getCampaignData(){
	adsTable.draw();
}
;
