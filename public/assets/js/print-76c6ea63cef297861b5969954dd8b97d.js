
var barChartOptions = {
	animation: false,
	//Boolean - Whether we should show a stroke on each segment
	segmentShowStroke : true,
	//String - The colour of each segment stroke
	segmentStrokeColor : "#fff",
	//Number - The width of each segment stroke
	segmentStrokeWidth : 2,
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
	},
	responsive: true
}


var pieChartOptions = {
	animation: false,
	//Boolean - Whether we should show a stroke on each segment
	segmentShowStroke : true,
	//String - The colour of each segment stroke
	segmentStrokeColor : "#fff",
	//Number - The width of each segment stroke
	segmentStrokeWidth : 2,
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
	},
	responsive: true
}

var barChart1Data = {
	labels:	["January","February","March","April","May","June","July","August","September","October","November","December"],
	datasets: [
	{
		label: "My First dataset",
		fillColor: "rgba(220,220,220,0.5)",
		strokeColor: "rgba(220,220,220,0.8)",
		highlightFill: "rgba(220,220,220,0.75)",
		highlightStroke: "rgba(220,220,220,1)",
		data: [65, 59, 80, 81, 56, 55, 40, 23, 34, 45, 46, 22]
	}
	]
};

var barChart2Data = {
	labels: 	["January","February","March","April","May","June","July","August","September","October","November","December"],
	datasets: [
	{
		label: "My Second dataset",
		fillColor: "rgba(151,187,205,0.5)",
		strokeColor: "rgba(151,187,205,0.8)",
		highlightFill: "rgba(151,187,205,0.75)",
		highlightStroke: "rgba(151,187,205,1)",
		data: [28, 48, 40, 19, 86, 27, 90, 56, 55, 40, 23, 34]
	}
	]
};

var pieChart1data = [
    {
        value: 300,
        color:"#F7464A",
        highlight: "#FF5A5E",
        label: "Red"
    },
    {
        value: 50,
        color: "#46BFBD",
        highlight: "#5AD3D1",
        label: "Green"
    },
    {
        value: 100,
        color: "#FDB45C",
        highlight: "#FFC870",
        label: "Yellow"
    }
]

$(document).ready(function(){
	var ctx = $("#bar-chart-1").get(0).getContext("2d");
	var barChart1 = new Chart(ctx).Bar(barChart1Data, barChartOptions);

	var ctx = $("#bar-chart-2").get(0).getContext("2d");
	var barChart2 = new Chart(ctx).Bar(barChart2Data, barChartOptions);

	var ctx = $("#pie-chart-1").get(0).getContext("2d");
	var pieChart1 = new Chart(ctx).Pie(pieChart1data, pieChartOptions);

	var ctx = $("#pie-chart-2").get(0).getContext("2d");
	var pieChart2 = new Chart(ctx).Pie(pieChart1data, pieChartOptions);

	var ctx = $("#pie-chart-3").get(0).getContext("2d");
	var pieChart3 = new Chart(ctx).Pie(pieChart1data, pieChartOptions);

});
