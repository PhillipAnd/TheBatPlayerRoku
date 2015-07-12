Sub ScrobbleTrack(artist as String, track as String)

	if artist <> invalid AND track <> invalid then
		userArray = LastFMAccounts()

		url = "https://ws.audioscrobbler.com/2.0/?method=track.scrobble&format=json"

		if userArray <> invalid AND userArray.count() > 0
			for each user in userArray
				sk = user.token
				'print "Scrobbling Using session token: " + sk
				api_key = GetConfig().LastFMKey
				api_secret = GetConfig().LastFMSecret
				timestamp = tostr(CreateObject("roDateTime").AsSeconds())
				api_sig_unsigned = "api_key" + api_key + "artist" + artist  + "methodtrack.scrobble" + "sk" + sk + "timestamp" + timestamp + "track" + track + api_secret
				api_sig = makemdfive(api_sig_unsigned)

			    request = CreateObject("roUrlTransfer")
			    request.RetainBodyOnError(true)
			    request.EnablePeerVerification(false)
			    request.EnableHostVerification(false)
			    request.SetRequest("POST")
			    request.SetUrl(url)
			    request.SetMessagePort(GetPort())

			    request.PostFromString("artist=" + artist + "&track=" + track + "&timestamp=" + timestamp + "&api_key=" + api_key + "&api_sig=" + api_sig + "&sk=" + sk)
			end for
				Analytics = GetSession().Analytics
				Analytics.AddEvent("Scrobbled Track To LastFM")
	   end if
	end if

End Sub

Function LastFMAccounts() as Object
	if GetGlobalAA().DoesExist("ActiveLastFMUsers") then
		activeUsers = GetGlobalAA().ActiveLastFMUsers
	else
		activeUsers = CreateObject("roArray", 0, true)
		GetGlobalAA().ActiveLastFMUsers = activeUsers
	End if

	return activeUsers
End Function

Function ToggleLastFMAccounts()
	userArray = GetLastFMData(false)
	string = ""

	activeUsers = LastFMAccounts()
	activeUsers.clear()
	totalUsers = userArray.count()

	if totalUsers = 0
		DisplayPopup("There are no Last.FM accounts configured.  Visit: http://" + GetSession().IPAddress + ":9999 to remedy this.",  &hb20000FF, &hBBBBBB00, 8)
		Analytics = GetSession().Analytics
		Analytics.AddEvent("Attempted to enable scrobbling mode without LastFM configured")

		return false
	end if
	i = 0

	'All users
	if GetGlobalAA().ActiveLastFM = 0 OR GetGlobalAA().ActiveLastFM = totalUsers + 1
		for each user in userArray
			activeUsers.push(user)
			string = string + " " + user.username
			i  = i + 1
		end for
		GetGlobalAA().ActiveLastFM = 0
	else
		user = userArray[GetGlobalAA().ActiveLastFM - 1]
		activeUsers.push(user)
		string = user.username
	end if
	GetGlobalAA().ActiveLastFM = GetGlobalAA().ActiveLastFM + 1

	BatLog("Toggling Last.FM Accounts: " + string)

	details = CreateObject("roAssociativeArray")
	details.users = string
	Analytics = GetSession().Analytics
	Analytics.AddEvent("Toggled LastFM",details)

	DisplayPopup("Now Scrobbling to Last.FM as: " + string + ".",  &h000000FF, &hBBBBBB00, 3)

	'Reset the timer
	timer = GetNowPlayingScreen().scrobbleTimer
	if timer <> invalid
		timer.mark()
	end if

End Function

Function InitLastFM()
	GetGlobalAA().AddReplace("ActiveLastFM", 0)
	activeUsers = CreateObject("roArray", 0, true)
	GetGlobalAA().ActiveLastFMUsers = activeUsers
End Function
