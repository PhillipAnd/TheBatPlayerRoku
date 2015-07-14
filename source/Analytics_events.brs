Function Analytics_TrackChanged(artistName as string, trackName as string, stationName as string)
	if artistname <> invalid AND trackname <> invalid AND stationName <> invalid AND isnonemptystr(artistName) AND isnonemptystr(trackName)
		Analytics = GetSession().Analytics

		properties = CreateObject("roAssociativeArray")
		properties.artistName = artistName
		properties.trackName = trackName
		properties.stationName = stationName
		Analytics.AddEvent("Track Changed", properties)
	end if
End Function

Function Analytics_StationSelected(stationName as string, url as string)
	if isnonemptystr(stationName) AND isnonemptystr(url)
		Analytics = GetSession().Analytics

		properties = CreateObject("roAssociativeArray")
		properties.stationName = stationName
		properties.stationStream = url
		Analytics.AddEvent("Station Selected", properties)
	end if
End Function

Function BatLog(logMessage as string, logType = "message" as string, properties = invalid as Object)
	appInfo = CreateObject("roAppInfo")
	isDev = appInfo.IsDev()

	if GetSession().IsDev
		print "****" + logMessage
		return true
	end if

	if logType = "message" OR logType = "error"

		level = 6
		if logType = "error"
			level = 3
		end if

		logging = GetSyslog()
		logging.send("Batlog: " + logMessage, level)
		return true
	end if

	if properties = invalid
		properties = CreateObject("roAssociativeArray")
	end if
	properties.type = logType

	NowPlayingScreen = GetNowPlayingScreen()
	if NowPlayingScreen <> invalid
		properties.song = NowPlayingScreen.song
	end if

	Analytics = GetSession().Analytics
	Analytics.AddEvent("Log", properties)
End Function

Function BatAnalytics_Handle(msg)

	'if GetSession().IsDev = true
''		Batlog("Development device disables Analytics.")
''		return false
''	end if

	Analytics = GetSession().Analytics
	Analytics.HandleAnalyticsEvents(msg)
End Function
