% include('tbstop.tpl', page='operations', page_title='OwnTracks Operations')
%if 'operations' in pistapages:


<link href="activo/activo-style.css" rel="stylesheet">
<script src="activo/jstz.min.js" type="text/javascript"></script>
<script src="config.js" type="text/javascript"></script>
<link rel="stylesheet" media="screen" href="handsontable/handsontable.full.css">
<script src="handsontable/handsontable.full.js"></script>
<link href="css/datepicker.css" rel="stylesheet">
<link href="css/datepicker3.css" rel="stylesheet">
<script src="js/bootstrap-datepicker.js" type="text/javascript"></script>

<div id='container'>
 	<div id='navbar'>
                 <input type='hidden' id='fromdate' value='' />
                 <input type='hidden' id='todate' value='' />
		<div>
			<p class='description'>
			Select a <acronym title="Tracker-ID">TID</acronym>
			and a date or a range of dates. Then
			click one of the options below to show in spreadsheet or download data.
			</p>
			Tracker ID: <select id='usertid'></select><br/>
		</div>

		<div id='datepick'></div>

		<div><a href='#' id='getsheet'>Show spreadsheet</a></div>

		<div>
			Download
				[<a href='#' fmt='txt' class='download'>TXT</a>]
				[<a href='#' fmt='csv' class='download'>CSV</a>]
%if have_xls == True:
				[<a href='#' fmt='xls' class='download'>XLS</a>]
%end
		</div>

         </div>

	<div id='content'>
		Summary
		<div id="summary"></div>
		<hr>
		Calendar
		<div id="calendar"></div>
		<hr>
		Details
		<div id="details"></div>

		<script type="text/javascript">

			var tz = jstz.determine();
			var tzname = tz.name();

			var $selecttid = $('#usertid');
			$.ajax({
				type: 'GET',
				url: 'api/userlist',
				async: true,
				success: function(data) {
					$selecttid.html('');
					$.each(data.userlist, function(key, val) {
						$selecttid.append('<option id="' + val.id + '">' + val.name + '</option>');
					})
				},
				error: function() {
					$selecttid.html("none available");
				}
			});

			$('#datepick').datepicker({
				format: "yyyy-mm-dd",
				autoclose: true,
				weekStart: 1,       // 0=Sunday
				multidate: 2,
				multidateSeparator: ',',
				todayHighlight: true,
			}).on('changeDate', function(e){
				console.log( "UTC=" + JSON.stringify($('#datepick').datepicker('getUTCDates' ))  );
				d = $('#datepick').datepicker('getUTCDates' );

				var d1;
				var d2;

				if (d.length == 1) {
					d1 = new Date(d[0]);
					d2 = d1;
				} else {
					d1 = new Date(d[0]);
					d2 = new Date(d[1]);
				}

				if (d2 < d1) {
					var c = d1;
					d1 = d2;
					d2 = c;
				}

				$('#fromdate').val(isodate(d1));
				$('#todate').val(isodate(d2));
			});

			function isodate(d) {
				// http://stackoverflow.com/questions/3066586/
				var yyyy = d.getFullYear().toString();
				var mm = (d.getMonth()+1).toString(); // getMonth() is zero-based
				var dd  = d.getDate().toString();
				var s =  yyyy + "-" +  (mm[1]?mm:"0"+mm[0]) + "-" +  (dd[1]?dd:"0"+dd[0]); // padding
				// console.log(d + ' ---> ' + s);
				return s
			}

			function calendar(fromdate, todate, data) {
				var columns = [
					{ data: 'time', readOnly: true },
				];
				var columnHeaders = [
					'Time'
				];
				var calendarData = [];
				for (i = 0; i < 24 * 3600; i += 30 * 60) {
					var timeString = new Date(i * 1000).toLocaleTimeString();
					calendarData[calendarData.length] = { time: timeString };
				}

				for (date = fromdate; date <= todate; date.setDate(date.getDate() + 1)) {
					var dateString = date.toLocaleDateString();
					columns[columns.length] = { data: dateString, readOnly: true };
					columnHeaders[columnHeaders.length] = dateString;
				}

				for (pointno in data) {
					var point = data[pointno];
					/* do the work here */
				}

				var	calendarContainer = document.getElementById('calendar'),
					calendarSettings = {
						data: calendarData,
						rowHeaders: true,
						colHeaders: columnHeaders,
						columns: columns
					},
					calendarHot;
  
				calendarHot = new Handsontable(calendarContainer, calendarSettings);
				calendarHot.render();
			}

			function getSheet() {
				var $details = $('#details');
				var $summary = $('#summary');
				var $calendar = $('#calendar');
				$details.html('');
				$summary.html('');
				$calendar.html('');

				var params = {
					usertid: $('#usertid').children(':selected').attr('id'),
					fromdate: $('#fromdate').val(),
					todate: $('#todate').val(),
					tzname: tzname,
				};

				$.ajax({
					type: 'POST',
					url: 'api/getOperations',
					async: true,
					data: JSON.stringify(params),
					dataType: 'json',
					success: function(data) {
						//console.log(JSON.stringify(data));

						var	container = document.getElementById('details'),
							settings = {
								data: data,
								rowHeaders: true,
								colHeaders: ['Timestamp', 'T', 'Velocity', 'Distance', 'Trip'],
								columns: [
									{ data: 'tst', readOnly: true },
									{ data: 't', readOnly: true },
									{ data: 'vel', readOnly: true },
									{ data: 'dist', readOnly: true },
									{ data: 'trip', readOnly: true },
								]
							},
							hot;
		  
						hot = new Handsontable(container, settings);
						hot.render();

						var	summaryData = [];
						var	status = 'off';
						var     start = new Date($('#fromdate').val());

						for (pointno in data) {
							var point = data[pointno];

							var newStatus = status;
							if (point.t == 'f') {
								newStatus = 'on';
							} else if (point.t == 't') {
								newStatus = 'driving';
							} else if (point.t == 'T') {
								newStatus = 'on';
							} else if (point.t == 'k') {
								newStatus = 'on';
							} else if (point.t == 'v') {
								newStatus = 'driving';
							} else if (point.t == 'l') {
								newStatus = 'driving';
							} else if (point.t == 'L') {
								newStatus = 'off';
							} else {
								newStatus = 'off';
							}

							var summary = null;
							var index = 0;
							for (index = 0; index < summaryData.length; index++) {
								if (summaryData[index].status == status) {
									summary = summaryData[index];
									break;
								}
							}
							if (summary == null) {
								summary = {}; 
								summary.status = status;
								summary.duration = 0.0;
							}
							console.log("summary " + summary.status + ' ' + summary.duration + ' ' + point.tst);
							summary.duration = summary.duration + Date.parse(point.tst) - start;
							summaryData[index] = summary;
							status = newStatus;
							start = point.tst;
						}

						var	summaryContainer = document.getElementById('summary'),
							summarySettings = {
								data: summaryData,
								rowHeaders: true,
								colHeaders: ['Status', 'Total (s)'],
								columns: [
									{ data: 'status', readOnly: true },
									{ data: 'duration', readOnly: true },
								]
							},
							summaryHot;
		  
						summaryHot = new Handsontable(summaryContainer, summarySettings);
						summaryHot.render();

						calendar(new Date($('#fromdate').val()), new Date($('#todate').val()), data); 

					},
					error: function(xhr, status, error) {
						alert('get: ' + status + ", " + error);
					}
				   });
			}

			function download(format) {
				var params = {
					usertid: $('#usertid').children(':selected').attr('id'),
					fromdate: $('#fromdate').val(),
					todate: $('#todate').val(),
					format: format,
					tzname: tzname,
				};

				$.fileDownload('api/downloadjob', {
					data: params,
					successCallback: function(url) {
						console.log("OK URL " + url);
					},
					failCallback: function(html, url) {
						console.log("ERROR " + url + " " + html);
					}
				});
			}

			$(document).ready(function() {


				function bindDumpButton() {
			  
					Handsontable.Dom.addEvent(document.body, 'click', function (e) {
			  
						var element = e.target || e.srcElement;
			  
						if (element.nodeName == "BUTTON" && element.name == 'dump') {
							var name = element.getAttribute('data-dump');
							var instance = element.getAttribute('data-instance');
							var hot = window[instance];
							console.log('data of ' + name, hot.getData());
						}
					});
				}

				$('.download').on('click', function (e) {
					e.preventDefault();
					var format = $(this).attr('fmt');
					console.log(format);
					download(format);
				});

				$('#getsheet').on('click', function (e) {
					e.preventDefault();
					getSheet();
				});

				bindDumpButton();
			});
		</script>
	</div>
%end
% include('tbsbot.tpl')
