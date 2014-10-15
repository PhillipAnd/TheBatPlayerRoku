Sub SetLightsToColor(hsv as Object)
	lightsArray = GetLights(false)
	ip = lightsArray.ip
	
	if ip = invalid OR lightsArray.lights.count() = 0
		return
	end if

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
	    requestBody.sat = RlMax(RlMin(hsv.sat + 20, 255), 150)
	    requestBody.bri = RlMin(RlMax(GetSession().Lighting.Brightness.Minimum, hsv.val), GetSession().Lighting.Brightness.Minimum)
	    requestBody.hue = RlMin(hsv.hue * 255 + 7000, 65535)
	    requestBody.transitiontime = 40
	    GetSession().Lighting.Brightness.Current = RlMin(RlMax(GetSession().Lighting.Brightness.Minimum, hsv.val), GetSession().Lighting.Brightness.Minimum)
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