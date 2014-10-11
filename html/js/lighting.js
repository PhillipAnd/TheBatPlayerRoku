	function handleHue() {
		if (window.hueIpAddress != null) {
			$(".hue-enabled").show();
			createUser(window.hueIpAddress);
			console.log("Found hue");
		} else {
			$(".hue-disabled").show();
			console.log("Can't find hue");
		}
	}

	function createUser(hueIpAddress) {
		var newUserReqest = JSON.stringify({"devicetype":"test user","username":"thebatplayer"});
		var endpoint = "http://" + window.hueIpAddress + "/api";
		$.post(endpoint, newUserReqest, function( data ) {
			var response = data[0];
			var type;
			for (key in response) {
				type = key
			}
			
			console.log(type);
			if (type == "error") {
				var responseDescription = data[0].error.description;
				var responseCode = data[0].error.type;
				if (responseCode == 101) {
					$(".hue-enabled").show();
					$("#header").html("Step One");
					$("#instruction").html("Please go walk over to your Hue Hub and press the button on top. When you're done come back and press the setup button.");
					addAction("Philips Hue prompt to press button");
				} else {
	  				alert("Unknown error: " + responseDescription);
	  				addAction("Philips Hue unknown error: " + responseDescription);
	  			}
	  		} else if (type == "success") {
	  			addAction("Philips Hue user created");
	  			var username = data[0].success.username;
	  			console.log(username);
	  			$("#hue-enabled").hide();
	  			$("#light-list").show();
	  			getLights(window.hueIpAddress);
	  		}
		});
	}

	function getLights(hueIpAddress) {
		$.getJSON("http://" + hueIpAddress + "/api/thebatplayer/lights",function(lightsData) {
			$(".hue-enabled").hide();

			var lights = [];
		  	$.each(lightsData, 	function(i, obj) {
		  		var light = {name: obj.name, id: i};
		  		lights.push(light);
		  	});

			var lights = {lights: lights};
			var templateSource = $("#light-template").html();
			template = Handlebars.compile(templateSource);
			var lightsHtml = template(lights);
			$('.lights').append(lightsHtml);

			//Check the boxes
			$.each(enabledLights, function(i, obj) {
				$("#checkbox-"+obj).prop('checked', true);
			});		

			$("input[type=checkbox]").switchButton({
		  		on_label: 'ON',
		  		off_label: 'OFF',
		  		width: 70,
  				height: 20,
  				button_width: 50
			});

			//Checkbox changed state
			$(':checkbox').on('change',function(){
		    	lightId = this.value;
		    	blinkLight(lightId);
		    	save();
		    });

		    enableLights();
		});
	}

	function saveLightIp(ip) {
		save();
		// $.ajax({
		//   url: "/html/savelightip.html",
		//   data: "data=" + ip
		// }).done(function() {
		// 	addAction("Philips Hue IP saved");
		// });
	}

	function getSavedLightData() {
		console.log("Running get saved light data");
		$.getJSON("/html/lights.html",function(data) {
			console.log(data);
			if (data.ip != null) {
				window.hueIpAddress = data.ip;
				enabledLights = data.lights;
				brightness = data.brightness
		  		$( "#slider-range" ).slider( "values", brightness );
				$( "#brightness-values" ).html(brightness[0] + " - " + brightness[1]);
				getLights(window.hueIpAddress);
				$(".hue-enabled").hide();
			} else {
				$.getJSON("https://www.meethue.com/api/nupnp",function(result){
					if (result && result.length > 0 && result[0].hasOwnProperty("internalipaddress")) {
						enabledLights = [];
						window.hueIpAddress = result[0].internalipaddress;
						saveLightIp(window.hueIpAddress);
					  	console.log(window.hueIpAddress);
						createUser(window.hueIpAddress);
					} else {
						//No Hue Found
					}
				});
			}
		});
	}

	function save() {
		var lights = $( "input:checked" );
		lightArray = [];
		$.each(lights, function (i, obj) {
			lightArray.push(obj.value);
		});

		var brightness = $( "#slider-range" ).slider( "values");

		var data = {};
		data.lights = lightArray;
		data.brightness = [brightness[0],brightness[1]];
		data.ip = window.hueIpAddress;

		$.ajax({
			url: "/html/savelights.html?data=" + escape(JSON.stringify(data))
		}).done(function() {
			notify("Saved lighting settings.");
		});

		addAction("Philips Hue settings saved");
	}

	function blinkLight(lightNumber) {
		url = "http://" + window.hueIpAddress + "/api/thebatplayer/lights/" + lightNumber + "/state";
		console.log(url);
		$.ajax({
		  type: "PUT",
		  url: url,
		  data: '{"hue":50000, "on":true, "bri":200, "alert":"select"}'
  		});
  	}

  	function setLightsBrightness(brightness) {
  		url = "http://" + window.hueIpAddress + "/api/thebatplayer/groups/0/action";
		$.ajax({
		  type: "PUT",
		  url: url,
		  data: '{"on":true, "bri":200, "alert":"select"}'
  		});
  		addAction("Philips Hue brightness levels changed");
  	}

  	function enableLights() {
  		$("#light-selection").show();
  		$(".hue-disabled").hide();
  	}


	$(document).ready(function() {
		getSavedLightData();

		//Setup button
		$("#enable-lighting-button").click(function() {
			createUser(window.hueIpAddress);
		});

		//Save button clicked
		$("#save-button").click(function() {
			save();
		});

		//Brightness slider
	    $( "#slider-range" ).slider({
	      range: true,
	      min: 0,
	      max: 255,
	      values: [ 140, 200 ],
	      slide: function( event, ui ) {
	        $( "#brightness-values" ).html( ui.values[ 0 ] + " - " + ui.values[ 1 ] );
	      },
	      stop: function(event, ui) {
	        setLightsBrightness(ui.values[1]);
	        save();
	      }
	    });
	    $( "#brightness-values" ).html( $( "#slider-range" ).slider( "values", 0 ) + " - " + $( "#slider-range" ).slider( "values", 1 ) );
	});