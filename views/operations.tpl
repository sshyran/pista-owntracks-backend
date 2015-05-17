% include('tbstop.tpl', page='operations', page_title='OwnTracks Operations')
%if 'operations' in pistapages:


<link href="activo/activo-style.css" rel="stylesheet">
<script src="activo/jstz.min.js" type="text/javascript"></script>
<script src="js/moment.min.js" type="text/javascript"></script>
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
			click below to show in spreadsheet.
			</p>
			Tracker ID: <select id='usertid'></select><br/>
			<br/>
		</div>

		<div id='datepick'></div>

		<div><a href='#' id='getsheet'>Show spreadsheet</a></div>

         </div>

	<div id='content'>
		Summary
		<div id="summary"></div>

		<hr/>
		Calendar - Time Interval:
			 <select id='timeinterval'>
				<option value="60">1 hour</option>
				<option value="15">15 minutes</option>
				<option value="10">10 minutes</option>
				<option value="180">3 hours</option>
			</select><br/>
		- Start Time:
			 <select id='timestart'>
				<option value="360">06:00</option>
				<option value="480">08:00</option>
				<option value="0">00:00</option>
			</select><br/>
		- End Time:
			 <select id='timeend'>
				<option value="1200">20:00</option>
				<option value="1020">17:00</option>
				<option value="1440">24:00</option>
			</select><br/>
		<div id="calendar"></div>

		<hr/>
		List - Minimum Distance:
			 <select id='minimumdistance'>
				<option value="100">100 m</option>
				<option value="0">0 m</option>
				<option value="1000">1 km</option>
				<option value="10000">10 km</option>
			</select><br/>
		<div id="list"></div>

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
				//console.log( "UTC=" + JSON.stringify($('#datepick').datepicker('getUTCDates' ))  );
				var d = $('#datepick').datepicker('getUTCDates' );

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

			function duration(seconds) {
				var ticks = seconds;
				var durationString = "";
				if (ticks >= 24 * 60 * 60) {
					var days = Math.floor(ticks / (24 * 60 * 60));	
					durationString = days + "d ";	
					ticks -= days * 24 * 60 * 60;	
				}
				if (ticks >= 60 * 60) {
					var hours = Math.floor(ticks / (60 * 60));	
					durationString = durationString + hours + "h ";	
					ticks -= hours * 60 * 60;	
				}
				if (ticks >= 60) {
					var minutes = Math.floor(ticks / 60);	
					durationString = durationString + minutes + "m ";	
					ticks -= minutes * 60;	
				}
				if (ticks >= 1) {
					var seconds = Math.floor(ticks);	
					durationString = durationString + seconds + "s ";	
				} else {
					durationString = durationString + "0s";
				}
				return durationString;
			}

			function summary(fromdate, todate, data) {
				var	summaryData = [];
				var	status = 'off';
				var     start = moment(fromdate).unix();

				function process(point) {
					var newStatus = status;
					if (point.t == 'f') {
						newStatus = 'on';
					} else if (point.t == 't') {
						newStatus = 'driving';
					} else if (point.t == 'm') {
						newStatus = 'on';
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
					var epoch = moment.utc(point.tst).unix();
					//console.log("summary " + summary.status + " " + summary.duration + " " + epoch + " " + start);
					summary.duration = summary.duration + epoch - start;
					summaryData[index] = summary;
					status = newStatus;
					start = epoch;
				}

				for (pointno in data) {
					process(data[pointno]);
				}

				var endOfDay = todate;
				endOfDay.setHours(23, 59, 59, 999);
				process({t:"L", tst:endOfDay});

				for (index = 0; index < summaryData.length; index++) {
					var seconds = parseInt(summaryData[index].duration);
					summaryData[index].duration = duration(seconds);

					var secondsduration = moment.duration(seconds, 'seconds');
					//console.log('seconds ' + seconds + ' ' + secondsduration);
					summaryData[index].human = secondsduration.humanize();
				}

				var	summaryContainer = document.getElementById('summary'),
					summarySettings = {
						data: summaryData,
						rowHeaders: false,
						colHeaders: ['Status', 'Total (s)', 'Duration'],
						columns: [
							{ data: 'status', readOnly: true, className: "htLeft" },
							{ data: 'duration', readOnly: true, className: "htRight" },
							{ data: 'human', readOnly: true, className: "htLeft" },
						],
						cells: function (row, col, prop) {
							var cellProperties = {};
							if (col == 0) {
								cellProperties.renderer = renderer;
							}
							return cellProperties;
						}
					},
					summaryHot;
		 
				function renderer(instance, td, row, col, prop, value, cellProperties) {
					Handsontable.renderers.TextRenderer.apply(this, arguments);
					if (value === 'driving') {
						td.style.background = '#C0ffC0';
					} else if (value === 'on') {
						td.style.background = '#C0C0ff';
					} else if (value === 'off') {
						 td.style.background = '#ffC0C0';
					} else {
						 td.style.background = '#ffffff';
					}	
				}

				summaryHot = new Handsontable(summaryContainer, summarySettings);
				summaryHot.render();
			}

			function calendar(fromdate, todate, interval, timestart, timeend, data) {
				var start = moment(fromdate).unix();
				var columns = [];
				var columnHeaders = [];
				var rowHeaders = [];
				var calendarData = [];

				//console.log(interval)
				var durationinterval = moment.duration(interval, 'm');
				//console.log(durationinterval.humanize())
				var starttime = moment.utc(0);
				//console.log(starttime.format())
				var time = starttime;

				for (var i = 0; i < 24 * 60; i += interval) {
					//console.log(time.format('HH:mm'));
					rowHeaders[rowHeaders.length] = time.format('HH:mm');
					time.add(durationinterval);
				}

				var dayoffset = 0;
				var current = moment(fromdate);	
				var to = moment(todate);
				while (current.isBefore(to) || current.isSame(to)) {
					var key = "T" + dayoffset;
					columns[columns.length] = { data: key, readOnly: true , className: "htCenter"};
					for (var i = 0; i < 24 * 60; i += interval) {
						if (calendarData.length > i/interval) {
							row = calendarData[i/interval];
						} else {
							row = {};
						}
						row[key] = "";
						//console.log( key + ' ' + i/interval);
						calendarData[i/interval] = row;
					}
					columnHeaders[columnHeaders.length] = current.format('YYYY-MM-DD');
					dayoffset++;
					current.add(1, 'd');
				}

				for (pointno in data) {
					var point = data[pointno];
					var epoch = moment.utc(point.tst).unix();
					var offset = epoch - start;
					var dayoffset = Math.floor(offset / (24 * 60 * 60));
					var houroffset = Math.floor((offset % (24 * 60 * 60)) / (interval * 60));
					//console.log(moment.utc(point.tst).format() + ' ' + offset + ' ' + dayoffset + ' ' + houroffset);
					if (dayoffset >= 0 && houroffset >= 0) {
						var row = calendarData[houroffset];
						if (row != null) {
							var key = "T" + dayoffset;
							//console.log('row[key]==', row[key]);
							row[key] = row[key] + point.t;
							calendarData[houroffset] = row;
						}
					}
				}

				console.log('timestart==' + timestart + ' timeend==' + timeend + ' interval==' + interval);
				var	container = document.getElementById('calendar'),
					settings = {
						data: calendarData.slice(timestart / interval, timeend / interval),
						colHeaders: columnHeaders,
					        rowHeaders: rowHeaders.slice(timestart / interval, timeend / interval),
						columns: columns,
						cells: function (row, col, prop) {
							var cellProperties = {};
							cellProperties.renderer = renderer;
							return cellProperties;
						}
					},
					hot;
  
				function renderer(instance, td, row, col, prop, value, cellProperties) {
					Handsontable.renderers.TextRenderer.apply(this, arguments);
					td.style.background = '#ffC0C0';
					if (value != null) {
						if (value.indexOf('m') != -1 ||
							value.indexOf('f') != -1 ||
							value.indexOf('k') != -1 ||
							value.indexOf('T') != -1 ||
							value.indexOf('l') != -1) {
							 td.style.background = '#C0C0ff';
						}
						if (value.indexOf('v') != -1 ||
							value.indexOf('t') != -1) {
							 td.style.background = '#c0ffc0';
						}	
						var hidden = '';
						if (value.length > 0) {
							hidden = '<span title="' + value + '">(Info)</span>';
						}
						td.innerHTML = hidden;
					}
				}

				hot = new Handsontable(container, settings);
				hot.render();
			}

			function list(fromdate, todate, minimum, data) {
				var listData = [];
				var startpoint = null;
				var endpoint = null;

				for (pointno in data) {
					var point = data[pointno];
					if (startpoint == null) {
						if (point.t == 't' || point.t == 'v' || point.t == 'f') {
							startpoint = point;
						}
					} else {
						if (point.t == 'L' || point.t == 'T') {
							var diff = 0;
							if (endpoint != null) {
								if (endpoint.trip != startpoint.trip) {
									diff = startpoint.trip - endpoint.trip;
								}
							}
							endpoint = point;
							var distance = endpoint.trip - startpoint.trip;
							console.log('distance==' + distance + ' minimum==' + minimum);
							if (distance > minimum) {
								var trip = {
									start: startpoint.tst,
									end: endpoint.tst,
									from: startpoint.addr,
									to: endpoint.addr,
									odometer: startpoint.trip / 1000,
									diff: diff,
									distance: distance / 1000,
									comment: "..."
								};
								listData[listData.length] = trip;
							}
							startpoint = null;
						}
					}
				}

				var	container = document.getElementById('list'),
					settings = {
						data: listData,
						colHeaders: [
							'Start',
							'End',
							'From',
							'To',
							'Odometer (km)',
							'Difference (m)',
							'Distance (km)',
							'Comment'
						],
					        rowHeaders: true,
						columns: [
							{ data: 'start', readOnly: true , className: "htLeft"},
							{ data: 'end', readOnly: true , className: "htLeft"},
							{ data: 'from', readOnly: true , className: "htLeft"},
							{ data: 'to', readOnly: true , className: "htLeft"},
							{ data: 'odometer', readOnly: true , className: "htRight"},
							{ data: 'diff', readOnly: true , className: "htRight"},
							{ data: 'distance', readOnly: true , className: "htRight"},
							{ data: 'comment', readOnly: false , className: "htLeft", width: 200},
						],
					},
					hot;

				hot = new Handsontable(container, settings);
				hot.render();
			}

			function getSheet() {
				var $summary = $('#summary');
				var $calendar = $('#calendar');
				var $list = $('#list');
				$summary.html('');
				$calendar.html('');
				$list.html('');

				var params = {
					usertid: $('#usertid').children(':selected').attr('id'),
					fromdate: $('#fromdate').val(),
					todate: $('#todate').val(),
					tzname: tzname,
				};

				var interval = $('#timeinterval').children(':selected').attr('value');
				var timestart = $('#timestart').children(':selected').attr('value');
				var timeend = $('#timeend').children(':selected').attr('value');
				var minimum = $('#minimumdistance').children(':selected').attr('value');

				$.ajax({
					type: 'POST',
					url: 'api/getOperations',
					async: true,
					data: JSON.stringify(params),
					dataType: 'json',
					success: function(data) {
						//console.log(JSON.stringify(data));
						summary(new Date($('#fromdate').val()), new Date($('#todate').val()), data); 
						calendar(new Date($('#fromdate').val()), new Date($('#todate').val()), parseInt(interval), parseInt(timestart), parseInt(timeend), data); 
						list(new Date($('#fromdate').val()), new Date($('#todate').val()), parseInt(minimum), data); 
					},
					error: function(xhr, status, error) {
						alert('get: ' + status + ", " + error);
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
							//console.log('data of ' + name, hot.getData());
						}
					});
				}

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
