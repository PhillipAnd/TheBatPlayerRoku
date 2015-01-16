Sub SetLightsToColor(xyz as Object)

	if xyz = invalid OR xyz.x = invalid
		return
	end if

	lightsArray = GetLights(false)
	ip = lightsArray.ip
	if ip = invalid OR lightsArray.lights.count() = 0
		return
	end if

	colorX = xyz.x / (xyz.x + xyz.y + xyz.z)
	colorY = xyz.y / (xyz.x + xyz.y + xyz.z)
	color = CreateObject("roArray", 2, false)
	color[0] = colorX
	color[1] = colorY

	lightRequests = CreateObject("roArray", 0, true)
	GetGlobalAA().lightRequests = lightRequests

	Analytics = GetSession().Analytics
	Analytics.AddEvent("Updated Lighting For Song")

	for each light in lightsArray.lights
		url = "http://" + ip + "/api/thebatplayer/lights/" + light + "/state"
		'url = "http://" + ip + "/api/thebatplayer/groups/TheBatPlayer/action"
	    request = CreateObject("roUrlTransfer")
	    request.RetainBodyOnError(true)
	    request.EnablePeerVerification(false)
	    request.EnableHostVerification(false)
	    request.SetRequest("PUT")
	    request.SetUrl(url)
	    port = GetPort()
	    request.SetMessagePort(port)

	    requestBody = CreateObject("roAssociativeArray")
	    requestBody.on = true
			requestBody.xy = color
	    requestBody.transitiontime = 30

	    GetSession().Lighting.Brightness.Current = requestBody.colorY
	    json = FormatJson(requestBody)

			lightRequests.push(request)

		request.AsyncPostFromString(json)

	end for
End Sub

Function CreateLightingColorFromRGB(rgb as Object) as Object
	'From notes at https://github.com/PhilipsHue/PhilipsHueSDK-iOS-OSX/blob/master/ApplicationDesignNotes/RGB%20to%20xy%20Color%20conversion.md

	' Make each color between - and 1
	red = RlMin(RlMax(rgb.red / 255, 0), 1.0)
	green = RlMin(RlMax(rgb.green / 255, 0), 1.0)
	blue = RlMin(RlMax(rgb.blue / 255, 0), 1.0)

	'Apply a gamma correction
	if red > 0.04045
		red = pow((red + 0.055) / (1.0 + 0.055), 2.4)
	else
		red = red / 12.92
	End if

	if green > 0.04045
		green = pow((green + 0.055) / (1.0 + 0.055), 2.4)
	else
		green = green / 12.92
	end if

	if blue > 0.04045
		blue = pow((blue + 0.055) / (1.0 + 0.055), 2.4)
	else
		blue = blue / 12.92
	end if

	'red = RlMin(RlMax(rgb.red / 255, 0.322), 0.674)
	'green = RlMin(RlMax(rgb.green / 255, 0.408), 0.517)
	'blue = RlMin(RlMax(rgb.blue / 255, 0.168), 1.0)

	X = red * 0.649926 + green * 0.103455 + blue * 0.197109
	Y = red * 0.234327 + green * 0.743075 + blue * 0.022598
	Z = red * 0.0000000 + green * 0.053077 + blue * 1.035763

	'Calculate the xy values from the XYZ values
	x = X / (X + Y + Z)
	y = Y / (X + Y + Z)

	color = CreateObject("roArray", 2, false)
	color[0] = x
	color[1] = y

	return color
End Function

Function Pow(x as Double, y as Double) as Double
	if y = 0
		return 1
	end if

	result = 1
	for i = 0 to y step 1
		result = result * x
	end for

	return result
	'else if y mod 2 = 0
	''	return Pow(x, y/2)*Pow(x, y/2)
	'else
	''	return x*Pow(x, y/2)*Pow(x, y/2)
	'end if
End Function

Function ChangeBrightnessTo(brightness as Integer)
	GetSession().Lighting.Brightness.Current = brightness
	lightsArray = GetLights(false)
	ip = lightsArray.ip

	if ip = invalid
		return false
	end if

	for each light in lightsArray.lights

		url = "http://" + ip + "/api/thebatplayer/lights/" + light + "/state"

	    request = CreateObject("roUrlTransfer")
	    request.RetainBodyOnError(true)
	    request.EnablePeerVerification(false)
	    request.EnableHostVerification(false)
	    request.SetRequest("PUT")
	    request.SetUrl(url)
	    port = GetGlobalAA().screenPort
	    request.SetMessagePort(port)

	    requestBody = CreateObject("roAssociativeArray")
	    requestBody.on = true
	    requestBody.bri = brightness
	    json = FormatJson(requestBody)
		request.PostFromString(json)
	end for

End Function

Function ToggleBrightnessMode(direction as String)
	lights = GetLights(false)

	if NOT lights.DoesExist("brightness")
		Analytics = GetSession().Analytics
		Analytics.AddEvent("Attempted to toggle brightness mode without bulbs configured")

		DisplayPopup("There are no Philips Hue bulbs configured.  Visit: http://" + GetIPAddress() + ":9999 to remedy this.",  &hb20000FF, &hBBBBBB00, 8)
		return false
	end if

	modeString = ""
	brightness = 0
	if direction = "down" then
		GetSession().Lighting.Brightness.Mode = RlMin(GetSession().Lighting.Brightness.Mode + 1, 3)
	end if

	if direction = "up" then
		GetSession().Lighting.Brightness.Mode = RlMax(GetSession().Lighting.Brightness.Mode - 1, 0)
	end if

	if GetSession().Lighting.Brightness.Mode = 2 then
		GetSession().Lighting.Brightness.Minimum = GetSession().Lighting.Brightness.DefaultMinimum
		GetSession().Lighting.Brightness.Maximum = GetSession().Lighting.Brightness.DefaultMaximum
		brightness = 150
		modeString = "default"
	else if GetSession().Lighting.Brightness.Mode = 1 then
		GetSession().Lighting.Brightness.Minimum = GetSession().Lighting.Brightness.DefaultMinimum - 70
		GetSession().Lighting.Brightness.Maximum = GetSession().Lighting.Brightness.DefaultMaximum  - 70
		modeString = "dim"
		brightness = 75
	else if GetSession().Lighting.Brightness.Mode = 3 then
		GetSession().Lighting.Brightness.Minimum = GetSession().Lighting.Brightness.DefaultMinimum + 70
		GetSession().Lighting.Brightness.Maximum = GetSession().Lighting.Brightness.DefaultMaximum  + 70
		modeString = "bright"
		brightness = 250
	end if

	DisplayPopup("Lighting changed to " + modeString + ".")
	ChangeBrightnessTo(brightness)

	details = CreateObject("roAssociativeArray")
	details.LightingMOde = modeString
	Analytics = GetSession().Analytics
	Analytics.AddEvent("Changed Brightness changed",details)


End Function
