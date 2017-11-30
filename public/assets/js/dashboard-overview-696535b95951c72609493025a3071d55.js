
var chartOptions = {
	animation: false,
	//Boolean - Whether we should show a stroke on each segment
	segmentShowStroke : true,

	//String - The colour of each segment stroke
	segmentStrokeColor : "#fff",

	//Number - The width of each segment stroke
	segmentStrokeWidth : 2,

	//Number - The percentage of the chart that we cut out of the middle
	percentageInnerCutout : 70, // This is 0 for Pie charts

	//String - A legend template
	legendTemplate :
	'<% for (var i=0; i<segments.length; i++){%>'+
		'<div class="col-xs-5 <%=(i%2==0)?"col-xs-offset-1":""%>">'+
			'<div class="donut-chart-legend-container">'+
			'<span class="label" style="background-color:<%=segments[i].fillColor%>">&nbsp;</span>'+
			'<%=segments[i].label%>'+
			'</div>'+
		'</div>'+
	'<%}%>',
    tooltipTemplate: "<%if (label){%><%=label%>: <%}%><%= accounting.formatNumber(value) %>",
	onAnimationComplete: function(){
		// if(this.chart.textCentered){
			// return;
		// }
		// this.chart.textCentered = true;
		// /* position center text */
		// var chartTitle = $(this.chart.canvas).siblings(".chart-title");
		// var chartCenterText = $(this.chart.canvas).siblings(".chart-center-text");
		// var chartCenterTextTop =  chartTitle.height() + (this.chart.height) /2;
		// chartCenterText.css({top: chartCenterTextTop});
	}
}

$(document).ready(function(){
	getOverviewData();
});

function getColor(str){
	// str to hash
	for (var i = 0, hash = 0; i < str.length; hash = str.charCodeAt(i++) + ((hash << 5) - hash));

	// int/hash to hex
	for (var i = 0, colour = "#"; i < 3; colour += ("00" + ((hash >> i++ * 8) & 0xFF).toString(16)).slice(-2));

	return colour;
}

function ColorLuminance(hex, lum) {

	// validate hex string
	hex = String(hex).replace(/[^0-9a-f]/gi, '');
	if (hex.length < 6) {
		hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
	}
	lum = lum || 0;

	// convert to decimal and change luminosity
	var rgb = "#", c, i;
	for (i = 0; i < 3; i++) {
		c = parseInt(hex.substr(i*2,2), 16);
		c = Math.round(Math.min(Math.max(0, c + (c * lum)), 255)).toString(16);
		rgb += ("00"+c).substr(c.length);
	}

	return rgb;
}

function genSummaryTable(data){
	var d = new Date();
	var n = d.toDateString();
	var today_array=n.split(' ');
	
	$("#summary-table thead th").attr({"colspan":data.length+1})
	// $("#summary-table thead span").html("Last updated "+today_array[2]+" "+today_array[1]+" "+today_array[3]);
	
	var table_obj=[];
	table_obj['channels']=['Channel'];
	table_obj['impressions']=['Impr.'];
	table_obj['clicks']=['Clicks'];
	table_obj['ctr']=['CTR'];
	table_obj['cost']=['Cost'];
	table_obj['avg_cpc']=['Avg. CPC'];
	table_obj['conversion']=['Conversion'];
	table_obj['conversion_rate']=['Conv. Rate'];
	table_obj['cpa']=['CPA'];
	table_obj['revenue']=['Revenue'];
	table_obj['profit']=['Profit'];
	table_obj['avg_pos']=['Avg. Pos'];
	
	for(var item in data){
		table_obj['channels'].push(data[item]['name']);
		table_obj['impressions'].push(data[item]['impressions']);
		table_obj['clicks'].push(data[item]['clicks']);
		table_obj['ctr'].push(data[item]['ctr']);
		table_obj['cost'].push(data[item]['cost']);
		table_obj['avg_cpc'].push(data[item]['avg_cpc']);
		table_obj['conversion'].push(data[item]['conversion']);
		table_obj['conversion_rate'].push(data[item]['conversion_rate']);
		table_obj['cpa'].push(data[item]['cpa']);
		table_obj['revenue'].push(data[item]['revenue']);
		table_obj['profit'].push(data[item]['profit']);
		table_obj['avg_pos'].push(data[item]['avg_pos']);
	}
	
	genDonutChart("spend_donut_chart","spend_donut_chart_indicator", table_obj['channels'], table_obj['cost']);
	genDonutChart("conversion_donut_chart","conversion_donut_chart_indicator", table_obj['channels'], table_obj['conversion']);
	
	var table_html="";
	for(var tr in table_obj){
		table_html+="<tr>";
		for(var td in table_obj[tr]){
			if(tr!='channels' && td>0){
				if(tr=='ctr' || tr=='conversion_rate'){
					table_html+="<td>"+accounting.formatNumber(table_obj[tr][td],2)+"%</td>";
				}else if(tr=='cost' || tr=='avg_cpc' || tr=='cpa' || tr=='revenue' || tr=='profit' || tr=='avg_pos'){
					table_html+="<td>"+accounting.formatNumber(table_obj[tr][td],2)+"</td>";
				}else{
					table_html+="<td>"+accounting.formatNumber(table_obj[tr][td])+"</td>";
				}
			}else if(tr=='channels'){
				table_html+="<td><strong>"+firstToUpperCase(table_obj[tr][td])+"</strong></td>";
			}else{
				table_html+="<td>"+firstToUpperCase(table_obj[tr][td])+"</td>";
			}
		}
		table_html+="</tr>";
	}
	$("#summary-table tbody").html(table_html);
}

function genDonutChart(elementId, indicatorId, labelData, data){
	var chartdata = [];
	var total=0;
	
	for(var index in labelData){
		if(index!=0){
			chartdata.push({
				value: data[index],
				label: firstToUpperCase(labelData[index])
			});
			
			total+=parseInt(data[index]);
		}
	}
	
	chartdata.forEach(function(element, index, array){
		element.color = getColor(element.label);
		element.highlight = ColorLuminance(element.color, 0.1);	// 20% lighter
	});

	$("#"+elementId).attr({
		width: function(){return $(this).parent().innerWidth() - 100;},
		height: function(){return $(this).parent().innerWidth() - 100;}
	});

	var ctx = $("#"+elementId).get(0).getContext("2d");
	var myDoughnutChart = new Chart(ctx).Doughnut(chartdata,chartOptions);
	$("#"+indicatorId).html(myDoughnutChart.generateLegend());
	$("#"+indicatorId).append('<div class="clearfix"></div>');
	
	$('.chart-title span').html(date_range_text);
	
	if(elementId=='spend_donut_chart'){
		$("#"+elementId).parent().parent().find('.chart-center-text h3').html("$"+accounting.formatNumber(total));
	}else{
		$("#"+elementId).parent().parent().find('.chart-center-text h3').html(accounting.formatNumber(total));
	}
}

function genBudgetTable(data){
	var d = new Date();
	var dayInMonth = new Date(d.getFullYear(), d.getMonth()+1, 1,-1).getDate();
	
	$("#performance-vs-budget-table thead span").html("Number of days in "+monthNames[d.getMonth()]+": "+dayInMonth+" | Days Past: "+(d.getDate()-1));
	
	var table_html='<tr>';
	table_html+='<td><strong>Account</strong></td>';
	table_html+='<td class="text-right"><strong>Cost</strong></td>';
	table_html+='<td class="text-right"><strong>Estimate<i class="fa fa-question-circle budget_tooltips" data-toggle="tooltip" data-placement="top" data-="" title="Estimated spend for this month = (Spend so far this month / Number of Days past) * Number of days in the current month"></i></strong></td>';
	table_html+='<td class="text-right"><strong>Monthly budget / Target</strong></td>';
	table_html+='<td class="text-right"><strong>Index</strong></td>';
	table_html+='<td class="text-right"><strong>Difference</strong></td>';
	table_html+='<td class="text-right"><strong>Current Daily Spend</strong></td>';
	table_html+='<td class="text-right"><strong>Required Daily Spend</strong></td>';
	table_html+='</tr>';
	
	var total=0;
	var estimate=0;
	var target=0;
	var index=0;
	var difference=0;
	var currentperday=0;
	var reqperday=0;
	
	for(var item in data){
		var colorClass="";
		if(data[item]['color']=='y'){
			colorClass='below-budget';
		}else if(data[item]['color']=='g'){
			colorClass='on-budget';
		}else if(data[item]['color']=='r'){
			colorClass='over-budget';
		}
		
		total+=data[item]['total'];
		estimate+=data[item]['estimate'];
		target+=data[item]['target'];
		target+=data[item]['index'];
		difference+=data[item]['difference'];
		currentperday+=data[item]['current_per_day'];
		reqperday+=data[item]['req_per_day'];
		
		table_html+="<tr>";
		table_html+='<td>'+data[item]['name']+"</td>";
		table_html+='<td class="text-right">'+accounting.formatNumber(data[item]['total'])+"</td>";
		table_html+='<td class="text-right">'+accounting.formatNumber(data[item]['estimate'])+"</td>";
		table_html+='<td class="text-right">'+accounting.formatNumber(data[item]['target'])+"</td>";
		table_html+='<td class="text-right">'+accounting.formatNumber(data[item]['index'],2)+"</td>";
		table_html+='<td class="text-right '+colorClass+'">'+accounting.formatNumber(data[item]['difference'])+"</td>";
		table_html+='<td class="text-right">'+accounting.formatNumber(data[item]['current_per_day'])+"</td>";
		table_html+='<td class="text-right">'+accounting.formatNumber(data[item]['req_per_day'])+"</td>";
		table_html+="</tr>";
	}
	
	table_html+='<tr class="budget_total_tr">';
	table_html+='<td class="text-right">Total:</td>';
	table_html+='<td class="text-right">'+accounting.formatNumber(total)+"</td>";
	table_html+='<td class="text-right">'+accounting.formatNumber(estimate)+"</td>";
	table_html+='<td class="text-right">'+accounting.formatNumber(target)+"</td>";
	table_html+='<td class="text-right">'+accounting.formatNumber(index,2)+"</td>";
	table_html+='<td class="text-right">'+accounting.formatNumber(difference)+"</td>";
	table_html+='<td class="text-right">'+accounting.formatNumber(currentperday)+"</td>";
	table_html+='<td class="text-right">'+accounting.formatNumber(reqperday)+"</td>";
	table_html+="</tr>";
	
	$("#performance-vs-budget-table tbody").html(table_html);
}

function getOverviewData(){
	$(".loading_container").show();
	$.ajax({
		url: "/getdashboard",
		type: 'POST',
		data: $("#dashboardFilterForm").serialize(),
		success: function(data,status,xhr){
			$(".loading_container").hide();
			if(data.status=='true'){
				var dataBydate=data.request_date;
				dataBydate.sort(function(a, b){
					var dateA=new Date(a.date), dateB=new Date(b.date);
					return dateA-dateB; //sort by date ascending
				})
				
				linechart_label=[];
				linechart_data=[];
				linechart_data['impressions']=[];
				linechart_data['clicks']=[];
				linechart_data['ctr']=[];
				linechart_data['cost']=[];
				linechart_data['avg_cpc']=[];
				linechart_data['conversion']=[];
				linechart_data['conversion_rate']=[];
				linechart_data['cpa']=[];
				linechart_data['revenue']=[];
				linechart_data['profit']=[];
				linechart_data['avg_pos']=[];
				
				for(var item in dataBydate){
					linechart_label.push(dataBydate[item]['date']);
					
					linechart_data['impressions'].push(dataBydate[item]['impressions']);
					linechart_data['clicks'].push(dataBydate[item]['clicks']);
					if(dataBydate[item]['ctr']!=0){
						linechart_data['ctr'].push(dataBydate[item]['ctr'].replace("%",""));
					}else{
						linechart_data['ctr'].push(dataBydate[item]['ctr']);
					}
					linechart_data['cost'].push(dataBydate[item]['cost']);
					linechart_data['avg_cpc'].push(dataBydate[item]['avg_cpc']);
					linechart_data['conversion'].push(dataBydate[item]['conversion']);
					linechart_data['conversion_rate'].push(dataBydate[item]['conversion_rate']);
					linechart_data['cpa'].push(dataBydate[item]['cpa']);
					linechart_data['revenue'].push(dataBydate[item]['revenue']);
					linechart_data['profit'].push(dataBydate[item]['profit']);
					linechart_data['avg_pos'].push(dataBydate[item]['avg_pos']);
				}
				
				$("#line-chart-dropdown-1").val('impressions');
				$("#line-chart-dropdown-2").val('clicks');
				genLineChart('impressions','clicks');
				genSummaryTable(data.channels);
				genBudgetTable(data.accounts);
				
				
				if ($('.account_id:checked').length != data.accounts.length) {
			    	$( "#all").prop('checked', false);
			    }else{
			    	$( "#all").prop('checked', true);
			    }
			    
				$('[data-toggle="tooltip"]').tooltip();
			}
		},
		error: function(xhr,status,error){
			$(".loading_container").hide();
		    // alert(error);
		}
	});
}
;
