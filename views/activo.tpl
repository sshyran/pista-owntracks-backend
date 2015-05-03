% include('tbstop.tpl', page='tracks', page_title='OwnTracks Tracks')
%if 'tracks' in pistapages:


	<link href="activo/activo-style.css" rel="stylesheet">
	<script src="activo/jstz.min.js" type="text/javascript"></script>
	<script src="config.js" type="text/javascript"></script>
	<script src="https://code.jquery.com/jquery-1.11.1.min.js"></script>
	<link rel="stylesheet" media="screen" href="handsontable/handsontable.full.css">
	<script src="handsontable/handsontable.full.js"></script>

  <div id='container'>

    <div id='content'>
	    <div id="handsontable"></div>

    <script type="text/javascript">

	$(document).ready(function() {

	var
	    data1 = [
	      ['', 'Kia', 'Nissan', 'Toyota', 'Honda'],
	      ['2008', 10, 11, 12, 13],
	      ['2009', 20, 11, 14, 13],
	      ['2010', 30, 15, 12, 13]
	    ],
	    container1 = document.getElementById('handsontable'),
	    settings1 = {
	      data: data1
	    },
	    hot1;
  
	  hot1 = new Handsontable(container1, settings1);
	  data1[0][1] = 'Ford'; // change "Kia" to "Ford" programatically
	  hot1.render();
	  
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
	  bindDumpButton();

        });
	
    </script>
    </div>


%end
% include('tbsbot.tpl')
