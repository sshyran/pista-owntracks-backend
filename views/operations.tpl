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
		</div>

		<div id='datepick'></div>

		<div><a href='#' id='getsheet'>Show spreadsheet</a></div>

         </div>

	<div id='content'>
		Summary
		<div id="summary"></div>
		<hr/>
		Calendar
		<div id="calendar"></div>
		<hr/>
		Details
		<div id="details"></div>
		<hr/>
		* t is the trigger of the published message:
		<ul>
			<li>f first publish after reboot</li>
			<li>m for manually requested locations (e.g. by publishing to /cmd)</li>
			<li>t (time) for location published because device is moving.</li>
			<li>T (time) for location published because of time passed (maxInterval); device is stationary</li>
			<li>k When transitioning from move to stationary an additional publish is sent marked with trigger k (park)</li>
			<li>v When transitioning from stationary to move additional publish is sent marked with trigger v (mo-v-e)</li>
			<li>l When device looses GPS fix, an additional publish is sent to transmit the last known position</li>
			<li>L last position before gracefull shutdown</li>
		</ul>

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

			function duration(ticks) {
				var durationString = "";
				if (ticks >= 24 * 60 * 60) {
					days = Math.floor(ticks / (24 * 60 * 60));	
					durationString = days + "d ";	
					ticks -= days * 24 * 60 * 60;	
				}
				if (ticks >= 60 * 60) {
					hours = Math.floor(ticks / (60 * 60));	
					durationString = durationString + hours + "h ";	
					ticks -= hours * 60 * 60;	
				}
				if (ticks >= 60) {
					minutes = Math.floor(ticks / 60);	
					durationString = durationString + minutes + "m ";	
					ticks -= minutes * 60;	
				}
				if (ticks >= 1) {
					seconds = Math.floor(ticks);	
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
				endOfDay = todate;
				endOfDay.setHours(23, 59, 59, 999);
				process({t:"L", tst:endOfDay});

				for (index = 0; index < summaryData.length; index++) {
					summaryData[index].duration = duration(summaryData[index].duration);
				}

				var	summaryContainer = document.getElementById('summary'),
					summarySettings = {
						data: summaryData,
						rowHeaders: false,
						colHeaders: ['Status', 'Total (s)'],
						columns: [
							{ data: 'status', readOnly: true, className: "htLeft" },
							{ data: 'duration', readOnly: true, className: "htRight" },
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

			function calendar(fromdate, todate, data) {
				var start = moment(fromdate).unix();
				var columns = [];
				var columnHeaders = [];
				var rowHeaders = [];
				var calendarData = [];

				for (i = 0; i < 24 ; i++) {
					rowHeaders[rowHeaders.length] = i;
				}

				dayoffset = 0;
				current = moment(fromdate);	
				to = moment(todate);
				while (current.isBefore(to) || current.isSame(to)) {
					key = "T" + dayoffset;
					columns[columns.length] = { data: key, readOnly: true };
					for (i = 0; i < 24 ; i++) {
						if (calendarData.length > i) {
							row = calendarData[i];
						} else {
							row = {};
						}
						row[key] = "";
						calendarData[i] = row;
					}
					columnHeaders[columnHeaders.length] = current.format('YYYY-MM-DD');
					dayoffset++;
					current.add(1, 'd');
				}

				for (pointno in data) {
					point = data[pointno];
					epoch = moment.utc(point.tst).unix();
					offset = epoch - start;
					dayoffset = Math.floor(offset / (24 * 60 * 60));
					houroffset = Math.floor((offset % (24 * 60 * 60)) / (60 * 60));
					if (dayoffset >= 0 && houroffset >= 0) {
						row = calendarData[houroffset];
						key = "T" + dayoffset;
						row[key] = row[key] + point.t;
						calendarData[houroffset] = row;
					}
				}

				var	calendarContainer = document.getElementById('calendar'),
					calendarSettings = {
						data: calendarData,
						colHeaders: columnHeaders,
					        rowHeaders: rowHeaders,
						columns: columns,
						colWidths : 80,
						cells: function (row, col, prop) {
							var cellProperties = {};
							cellProperties.renderer = renderer;
							return cellProperties;
						}
					},
					calendarHot;
  
				function renderer(instance, td, row, col, prop, value, cellProperties) {
					Handsontable.renderers.TextRenderer.apply(this, arguments);
					td.style.background = '#ffC0C0';
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
				}

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
								colHeaders: [
									'Timestamp (local)',
									't*',
									'Velocity (km/h)',
									'Distance (m)',
									'Trip (m)'
								],
								columns: [
									{ data: 'tst', readOnly: true, className: "htLeft"},
									{ data: 't', readOnly: true, className: "htCenter"},
									{ data: 'vel', readOnly: true, className: "htRight"},
									{ data: 'dist', readOnly: true, className: "htRight"},
									{ data: 'trip', readOnly: true, className: "htRight"},
								],
								cells: function (row, col, prop) {
									var cellProperties = {};
									if (col == 1) {
										cellProperties.renderer = renderer;
									}
									return cellProperties;
								}
							},
							hot;
		  
						function renderer(instance, td, row, col, prop, value, cellProperties) {
							Handsontable.renderers.TextRenderer.apply(this, arguments);
							if (value === 'v' || value === 't') {
								 td.style.background = '#C0ffC0';
							} else if (value === 'm' || value === 'f' || value === 'k' || value === 'T' || value === 'l') {
								 td.style.background = '#C0C0ff';
							} else if (value === 'L') {
								 td.style.background = '#ffC0C0';
							} else {
								 td.style.background = '#ffffff';
							}	
						}

						hot = new Handsontable (
							container,
							settings
						);
						hot.render();

						summary(new Date($('#fromdate').val()), new Date($('#todate').val()), data); 
						calendar(new Date($('#fromdate').val()), new Date($('#todate').val()), data); 

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
