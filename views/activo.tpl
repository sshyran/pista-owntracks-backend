% include('tbstop.tpl', page='activo', page_title='OwnTracks Activo')
%if 'activo' in pistapages:


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
			Select a <acronym title="Tracker-ID">TID</acronym>,
			a <acronym title="Job-ID">JID</acronym>,
			a <acronym title="Place-ID">PID</acronym>,
			a <acronym title="Machine-ID">MID</acronym> and a date or a range of dates. Then
			click one of the options below to show in spreadsheet or download data.
			</p>
			Tracker ID: <select id='usertid'></select><br/>
			Job: <select id='userjid'></select><br/>
			Place: <select id='userpid'></select><br/>
			Machine: <select id='usermid'></select><br/>
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
		Details
		<div id="details"></div>
		<hr>
		Calendar
		<div id="calendar"></div>

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
					$selecttid.append('<option id=0>any</option>');
					$.each(data.userlist, function(key, val) {
						$selecttid.append('<option id="' + val.id + '">' + val.name + '</option>');
					})
				},
				error: function() {
					$selecttid.html("none available");
				}
			});

			var $selectjid = $('#userjid');
			$.ajax({
				type: 'GET',
				url: 'api/joblist',
				async: true,
				success: function(data) {
					$selectjid.html('');
					$selectjid.append('<option id=0>any</option>');
					$.each(data.joblist, function(key, val) {
						$selectjid.append('<option id="' + val.id + '">' + val.name + '</option>');
					})
				},
				error: function() {
					$selectjid.html("none available");
				}
			});

			var $selectpid = $('#userpid');
			$.ajax({
				type: 'GET',
				url: 'api/placelist',
				async: true,
				success: function(data) {
					$selectpid.html('');
					$selectpid.append('<option id=0>any</option>');
					$.each(data.placelist, function(key, val) {
						$selectpid.append('<option id="' + val.id + '">' + val.name + '</option>');
					})
				},
				error: function() {
					$selectpid.html("none available");
				}
			});

			var $selectmid = $('#usermid');
			$.ajax({
				type: 'GET',
				url: 'api/machinelist',
				async: true,
				success: function(data) {
					$selectmid.html('');
					$selectmid.append('<option id=0>any</option>');
					$.each(data.machinelist, function(key, val) {
						$selectmid.append('<option id="' + val.id + '">' + val.name + '</option>');
					})
				},
				error: function() {
					$selectmid.html("none available");
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

			function calendar(fromdate, todate) {
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
					console.log(date);
					var dateString = date.toLocaleDateString();
					columns[columns.length] = { data: dateString, readOnly: true };
					columnHeaders[columnHeaders.length] = dateString;
				}

				for (jobno in data) {
					var job = data[jobno];
					console.log(job);
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
					fromdate: $('#fromdate').val(),
					todate: $('#todate').val(),
					tzname: tzname,
				};

				var usertid = $('#usertid').children(':selected').attr('id');
				if (usertid != 0) {
					params.usertid = $('#usertid').children(':selected').attr('name');
				}
				var userjid = $('#userjid').children(':selected').attr('id');
				if (userjid != 0) {
					params.userjid = userjid;
				}
				var userpid = $('#userpid').children(':selected').attr('id');
				if (userpid != 0) {
					params.userpid = userpid;
				}
				var usermid = $('#usermid').children(':selected').attr('id');
				if (usermid != 0) {
					params.usermid = usermid;
				}

				$.ajax({
					type: 'POST',
					url: 'api/getjoblist',
					async: true,
					data: JSON.stringify(params),
					dataType: 'json',
					success: function(data) {
						// console.log(JSON.stringify(data));

						var	container = document.getElementById('details'),
							settings = {
								data: data,
								rowHeaders: true,
								colHeaders: ['TID', 'Job', 'Task', 'Place', 'Machine', 'Name', 'Start', 'End', 'Duration (s)'],
								columns: [
									{ data: 'tid', readOnly: true },
									{ data: 'job', readOnly: true },
									{ data: 'task', readOnly: true },
									{ data: 'place', readOnly: true },
									{ data: 'machine', readOnly: true },
									{ data: 'jobname', readOnly: true },
									{ data: 'start', readOnly: true },
									{ data: 'end', readOnly: true },
									{ data: 'duration', readOnly: true },
								]
							},
							hot;
		  
						hot = new Handsontable(container, settings);
						hot.render();

						var	summaryData = [];

						for (jobno in data) {
							var job = data[jobno];
							console.log(job);
							var summary = null;
							var index = 0;
							for (index = 0; index < summaryData.length; index++) {
								if (summaryData[index].jobname == job.jobname) {
									summary = summaryData[index];
									break;
								}
							}
							if (summary == null) {
								summary = {}; 
								summary.jobname = job.jobname;
								summary.total = 0;
							}
							summary.total = summary.total + job.duration;
							console.log( index);
							console.log( summary);
							summaryData[index] = summary;
						}

						console.log( summaryData);
						var	summaryContainer = document.getElementById('summary'),
							summarySettings = {
								data: summaryData,
								rowHeaders: true,
								colHeaders: ['Name', 'Total (s)'],
								columns: [
									{ data: 'jobname', readOnly: true },
									{ data: 'total', readOnly: true },
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
						console.log("OK URL ", + url);
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
