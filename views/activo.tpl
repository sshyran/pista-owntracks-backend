% include('tbstop.tpl', page='activo', page_title='OwnTracks Activo')
%if 'activo' in pistapages:


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

                        function calendar(fromdate, todate, interval, timestart, timeend, data) {
                                var start = moment(fromdate).unix();
                                var columns = [];
                                var columnHeaders = [];
                                var rowHeaders = [];
                                var calendarData = [];

                                var durationinterval = moment.duration(interval, 'm');
                                var starttime = moment.utc(0);
                                var time = starttime;

                                for (var i = 0; i < 24 * 60; i += interval) {
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
                                                calendarData[i/interval] = row;
                                        }
                                        columnHeaders[columnHeaders.length] = current.format('YYYY-MM-DD');
                                        dayoffset++;
                                        current.add(1, 'd');
                                }

                                for (jobno in data) {
                                        var job = data[jobno];
                                        var epoch = moment.utc(job.start).unix();
                                        var offset = epoch - start;
                                        var dayoffset = Math.floor(offset / (24 * 60 * 60));
                                        var houroffset = Math.floor((offset % (24 * 60 * 60)) / (interval * 60));
                                        if (dayoffset >= 0 && houroffset >= 0) {
                                                var row = calendarData[houroffset];
                                                if (row != null) {
                                                        var key = "T" + dayoffset;
							if (row[key].length > 0) {
                                                        row[key] = row[key] + '\n';
							}
                                                        row[key] = row[key] + job.jobname;
                                                        calendarData[houroffset] = row;
                                                }
                                        }
                                }

                                var     container = document.getElementById('calendar'),
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

			function summary(data) {
				var summaryData = [];
				for (jobno in data) {
					var job = data[jobno];
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
					summaryData[index] = summary;
				}

				for (index = 0; index < summaryData.length; index++) {
					var seconds = parseInt(summaryData[index].total);
					summaryData[index].total = duration(seconds);
					var secondsduration = moment.duration(seconds, 'seconds');
					summaryData[index].human = secondsduration.humanize();
				}

				var	container = document.getElementById('summary'),
					settings = {
						data: summaryData,
						rowHeaders: true,
						colHeaders: ['Job', 'Total', 'Duration'],
						columns: [
							{ data: 'jobname', readOnly: true, className: "htCenter" },
							{ data: 'total', readOnly: true, className: "htRight" },
							{ data: 'human', readOnly: true, className: "htLeft" },
						]
					},
					hot;
				hot = new Handsontable(container, settings);
				hot.render();
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
						for (index = 0; index < data.length; index++) {
							var seconds = parseInt(data[index].duration);
							data[index].time = duration(seconds);
							var secondsduration = moment.duration(seconds, 'seconds');
							data[index].human = secondsduration.humanize();
						}
						var	colheaders = [
								'TID',
								'Job',
								'Task',
								'Place',
								'Machine',
								'Name',
								'Start',
								'End',
								'Time',
								'Duration'
							];
						var	columns = [
								{ data: 'tid', readOnly: true, className: "htCenter" },
								{ data: 'job', readOnly: true, className: "htRight" },
								{ data: 'task', readOnly: true, className: "htRight" },
								{ data: 'place', readOnly: true, className: "htRight" },
								{ data: 'machine', readOnly: true, className: "htRight" },
								{ data: 'jobname', readOnly: true, className: "htLeft" },
								{ data: 'start', readOnly: true, className: "htLeft" },
								{ data: 'end', readOnly: true, className: "htLeft" },
								{ data: 'time', readOnly: true, className: "htRight" },
								{ data: 'human', readOnly: true, className: "htLeft" },
							];
						var	container = document.getElementById('details'),
							settings = {
								data: data,
								rowHeaders: true,
								colHeaders: colheaders,
								columns: columns,
							},
							hot;
		  
						hot = new Handsontable(container, settings);
						hot.render();

						var interval = $('#timeinterval').children(':selected').attr('value');
						var timestart = $('#timestart').children(':selected').attr('value');
						var timeend = $('#timeend').children(':selected').attr('value');

						summary(data); 
						calendar(
							new Date($('#fromdate').val()),
							new Date($('#todate').val()),
							parseInt(interval),
							parseInt(timestart),
							parseInt(timeend),
							data
						);
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
