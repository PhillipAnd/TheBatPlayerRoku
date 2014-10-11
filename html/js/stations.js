	function loadStations() {
		$.ajax({
            url:"/html/stations.json",
            method:'get',
            success:renderStations
        });
	}

	function renderStations(data) {
		var stations = {stations: JSON.parse(data)};
		var templateSource = $("#station-template").html();
		template = Handlebars.compile(templateSource);
		var stationsHtml = template(stations);
		$('#stations-listing').append(stationsHtml);
		$("#stations-listing").sortable({ axis: "y", containment: "parent", handle: ".fa-arrows-v" });

		$(".delete").on('click',function(){
			if (confirm("Are you sure you want to remove this station?")) {
				$(this).closest(".single-station").remove();
				save();
			}
		});		
	}

	function addStation() {
		var newStation = {stations:[ {name: "", provider: "", stream: "", image: ""}]};
		var newStationTemplateSource = $("#station-template").html();
		var newStationHtml = template(newStation);
		var newStationObject = $(newStationHtml);
		var fields = newStationObject.find("input");
		fields.each(function(i, elem) {
			$(elem).attr('name', "" + Math.floor((Math.random() * 100) + 1));
		});
		$('#stations-listing').append(newStationObject);
		addAction("Add stations button pressed");
	}

	loadStations();

	//Show Images
	$(document).on('mouseover', 'input.image-field', function(event) {
		var value = $(this).val();
		if (value != "") {
			var image = '<img width="100%" src="' + value + '">';
	    	// Bind the qTip within the event handler
	    	$(this).qtip({
	    		position: {
	      			target: 'mouse', // Position it where the click was...
	        		adjust: { mouse: false } // ...but don't follow the mouse
	    		},
	        	overwrite: false, // Make sure the tooltip won't be overridden once created
	        	content: image,
		        show: {
		            event: event.type, // Use the same show event as the one that triggered the event handler
		            ready: true // Show the tooltip as soon as it's bound, vital so it shows up the first time you hover!
		        }
			}, event); // Pass through our original event to qTip
		}
	});

	//Play Streams
	$(document).on('mouseover', 'input.stream-field', function(event) {
		var value = $(this).val();
		if (value != "") {
			var stream = 'Preview this station<br><audio controls style="width:100%"><source src="' + value + '; type="audio/mpeg"></audio>';
	    	// Bind the qTip within the event handler
	    	$(this).qtip({
	    		position: {
	      			target: 'mouse', // Position it where the click was...
	        		adjust: { mouse: false } // ...but don't follow the mouse
	    		},
	        	overwrite: false, // Make sure the tooltip won't be overridden once created
	        	content: stream,
				style: { 
				      width: 200,
				      padding: 5,
				      background: '#A2D959',
				      color: 'black',
				      textAlign: 'center',
				      border: {
				         width: 7,
				         radius: 5,
				         color: '#A2D959'
				      },
				      tip: 'bottomLeft',
				      name: 'dark' // Inherit the rest of the attributes from the preset dark style
				   },	        		        	
		        show: {
		            event: event.type, // Use the same show event as the one that triggered the event handler
		            ready: true // Show the tooltip as soon as it's bound, vital so it shows up the first time you hover!
		        },
	    		hide: { when: 'inactive', delay: 1000 }		        
			}, event); // Pass through our original event to qTip
		}
	});

	$(document).ready(function() {

		//Add station button clicked
		$(".add-station-button").click(function() {
			addStation();
		});

		//Save button clicked
		$(".save-button").click(function() {
			save();
		});

		var results;

		$( "#shoutcast-search" ).autocomplete({
		source: function( request, response ) {
		  $.ajax({
		    url: "http://cdn.thebatplayer.fm/search/shoutcast.hh",
		    dataType: "json",
		    data: {
		      k: "D5fBmcLrpBcOBRNo",
		      limit: 10,
		      search: request.term
		    },
		    success: function( data ) {
		    	addAction("Shoutcast search complete");
		      results = [];
		      $.each(data.station, function(index, value) {
		        var station = {};
		        station.value = value["@attributes"].id;
		        station.bitrate = value["@attributes"].br;
		        station.listeners = value["@attributes"].lc;
		        station.label = value["@attributes"].name + " (" + station.listeners + " listeners)";
		        results.push(station);
		      });
		      response( results );
		    }
		  });
		},
		minLength: 3,
		select: function( event, ui ) {
		  console.log( ui.item ? "Selected: " + ui.item.value : "Nothing selected, input was " + this.value);
		  addStationId(ui.item.value, ui.item.label);
		  return false;
		},
		open: function() {
		  $( this ).removeClass( "ui-corner-all" ).addClass( "ui-corner-top" );
		},
		close: function() {
		  $( this ).removeClass( "ui-corner-top" ).addClass( "ui-corner-all" );
		},
		focus: function(event, ui) {
		  return false;
		}
		});
	});   

	function addStationId(id,name) {
		name = processSearchResult(name);

		$.ajax({
			url: "http://cloud2.real-ity.com/batplayer/getStation.php",
			data: {stationId: id},
			dataType: "json",
			success: function(station) {
				console.log(station);
				if (station.server === null) {
					notify("Cannot find data for this station.  Try another.");
				}

				var newStation = {stations:[ {name: name, provider: name, stream: station.server, image: "http://cdn.thebatplayer.fm/assets/icon-hd.png"}]};
				var newStationTemplateSource = $("#station-template").html();
				var newStationHtml = template(newStation);
				var newStationObject = $(newStationHtml);
				var fields = newStationObject.find("input");
				fields.each(function(i, elem) {
					$(elem).attr('name', "" + Math.floor((Math.random() * 100) + 1));
				});
				$('#stations-listing').append(newStationObject);
				notify("Edit the Station name and Provider display names to your liking then find an image to identify this station on The Bat Player.", "Edit Your New Station", "warning");
			}
		});
	}

	function processSearchResult(name) {
		nameArray = name.split(" - ", 2);
		if (nameArray.length > 1) {
		    name = nameArray[0];
		}

		nameArray = name.split("(");
		if (nameArray.length > 1) {
		    name = nameArray[0];
		}
		return name;
	}

	function isValid() {
		
		$.validator.addClassRules("station-stream", {
		  required: true,
		  url: true
		});

		$.validator.addClassRules("station-image", {
		  required: true,
		  url: true,
		  remote: true
		});		

		return $("#stations-form").valid();
	}

	function save() {

		if (isValid()) {
			var stations = [];
			var stationForm = $(".single-station");
			stationForm.each(function(i, elem) {
				var stationEntry = $(elem);
				var singleStation = {};
				singleStation.name = $(stationEntry).find(".station-name").val();
				singleStation.provider = $(stationEntry).find(".station-provider").val();
				singleStation.stream = $(stationEntry).find(".station-stream").val();
				singleStation.image = $(stationEntry).find(".station-image").val();
				singleStation.format = "mp3";
				stations.push(singleStation);
			});
			var json = JSON.stringify(stations);
			var encoded = escape(json);

			$.ajax({
			  url: "/html/savestations.html?data="+encoded,
			}).done(function() {
    			notify("Updated Stations.", "Saved.", "success");
  			});
  			addAction("Saved stations");
		} else {
			addAction("Invalid station data.  Save failed.");
		}

	}