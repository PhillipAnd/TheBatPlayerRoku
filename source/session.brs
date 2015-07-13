Function GetSession() as Object
	if GetGlobalAA().DoesExist("Session") then
		return GetGlobalAA().Session
	else
		return CreateSession()
	endif

End Function

Function CreateSession() as Object
	session = CreateObject("roAssociativeArray")

	lights = GetLights(false)

	Session.userId = createObject("roDeviceInfo").GetDeviceUniqueId()
	Session.Lighting = CreateObject("roAssociativeArray")
	Session.Lighting.Brightness = CreateObject("roAssociativeArray")

	if lights.brightness = invalid
		Session.Lighting.Brightness.DefaultMinimum = 200
		Session.Lighting.Brightness.DefaultMaximum = 255
	else
		Session.Lighting.Brightness.DefaultMinimum = lights.brightness[0]
		Session.Lighting.Brightness.DefaultMaximum = lights.brightness[1]
	end if

	Session.Lighting.Brightness.Minimum = Session.Lighting.Brightness.DefaultMinimum
	Session.Lighting.Brightness.Maximum = Session.Lighting.Brightness.DefaultMaximum
	Session.Lighting.Brightness.Mode = 2

	Session.Analytics = Analytics(Session.userId, GetConfig().AmplitudeApiKey, GetPort())
	Session.IsDev = CreateObject("roAppInfo").IsDev()
	GetGlobalAA().Session = Session

	Session.deviceInfo = CreateObject("roDeviceInfo")
	Session.IPAddress = invalid
	Session.Downloads = CreateObject("roAssociativeArray")
	Session.Downloads.PopularityDownload = invalid

  Session.StationDownloads = CreateObject("roAssociativeArray")
  Session.StationDownloads.Downloads = CreateObject("roAssociativeArray")

	Session.IPAddress = GetIPAddress()
	return Session
End Function
