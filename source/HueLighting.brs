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

		DisplayPopup("There are no Philips Hue bulbs configured.  Visit: http://" + GetSession().IPAddress + ":9999 to remedy this.",  &hb20000FF, &hBBBBBB00, 8)
		return false
	end if

	modeString = ""
	brightness = 0
	if direction = "down" then
		GetSession().Lighting.Brightness.Mode = RlMin(GetSession().Lighting.Brightness.Mode + 1, 3)
		modeString = "Brightened lighting."
	end if

	if direction = "up" then
		GetSession().Lighting.Brightness.Mode = RlMax(GetSession().Lighting.Brightness.Mode - 1, 0)
		modeString = "Dimmed lighting."
	end if

	if GetSession().Lighting.Brightness.Mode = 2 then
		GetSession().Lighting.Brightness.Minimum = GetSession().Lighting.Brightness.DefaultMinimum
		GetSession().Lighting.Brightness.Maximum = GetSession().Lighting.Brightness.DefaultMaximum
		brightness = 150
	else if GetSession().Lighting.Brightness.Mode = 1 then
		GetSession().Lighting.Brightness.Minimum = GetSession().Lighting.Brightness.DefaultMinimum - 70
		GetSession().Lighting.Brightness.Maximum = GetSession().Lighting.Brightness.DefaultMaximum  - 70
		brightness = 75
	else if GetSession().Lighting.Brightness.Mode = 3 then
		GetSession().Lighting.Brightness.Minimum = GetSession().Lighting.Brightness.DefaultMinimum + 70
		GetSession().Lighting.Brightness.Maximum = GetSession().Lighting.Brightness.DefaultMaximum  + 70
		brightness = 250
	end if

	DisplayPopup(modeString)
	ChangeBrightnessTo(brightness)

	details = CreateObject("roAssociativeArray")
	details.LightingMOde = modeString
	Analytics = GetSession().Analytics
	Analytics.AddEvent("Changed Brightness changed",details)


End Function
