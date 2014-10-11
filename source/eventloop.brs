REM Global event loop





Sub HandleStationSelector (msg as Object)
	' if GetGlobalAA().IsStationSelectorDisplayed = true

		if type(msg)="roPosterScreenEvent"
			posterScreen = GetGlobalAA().StationScreen
	    	key = msg.GetIndex()

			if msg.isAdSelected()
				'Show message
				ShowConfigurationMessage(posterScreen)
			else if msg.isListItemSelected()
				StationList = GetGlobalAA().StationList

		        ' print "msg: ";msg.GetMessage();"idx: ";msg.GetIndex()
		        selectionIndex = msg.GetIndex()
		        
		        Station = StationList.posteritems[selectionIndex]
				Analytics_StationSelected(Station.stationName, Station.feedurl)

		        GetGlobalAA().AddReplace("SongObject", Station)
		        Show_Audio_Screen(Station)
		        DisplayStationLoading(Station)
				' posterScreen.close()
		    else if msg.GetIndex() = 0
			    	if posterScreen <> invalid
						'posterScreen.close()
					end if
				end
			else if msg.isScreenClosed()
			  	GetGlobalAA().AddReplace("IsStationSelectorDisplayed", false)
				return
		    end if

	    endif

	 ' end if
End Sub



Sub HandleWebEvent (msg as Object)
    server = GetGlobalAA().lookup("WebServer")
    if server <> invalid
	    server.prewait()
	    tm = type(msg)
	    if tm="roSocketEvent" or msg=invalid
	        server.postwait()
	    end if
	 else
	end if
End Sub


Sub HandleNowPlayingScreenEvent (msg as Object)
  if type(msg) = "roUniversalControlEvent" AND GetGlobalAA().IsStationSelectorDisplayed <> true
    Audio = GetGlobalAA().AudioPlayer

	key = msg.GetInt()

	  if key = 3 then
	  	ToggleBrightnessMode("up")

	  else if key = 2 then
	  	ToggleBrightnessMode("down")

	  else if key = 10 then
	  	ToggleLastFMAccounts()

	  else if key = 4 then
	  	song = GetGlobalAA().SongObject
	  	if song <> invalid then AttemptToAddToRdioPlaylist(song.artist, song.title)

	  else if key = 0 then
	    'Exit
	    ListStations()

	  else if key = 106
	  	'Show help message
	  	DisplayHelpPopup()
	  end if

    end if

End Sub

Sub HandleTimers()
	song = GetGlobalAA().SongObject

	if GetGlobalAA().IsStationSelectorDisplayed <> true then
		timer = GetNowPlayingTimer()
		if timer <> invalid
			if timer <> invalid and timer.totalSeconds() >= (7 + song.JSONDownloadDelay) then
				timer.mark()
				song = GetGlobalAA().SongObject
				Get_Metadata(song, GetPort())
			end if
		end if


		'LastFM Scrobbles
		if GetNowPlayingScreen().scrobbleTimer <> invalid THEN
			if GetNowPlayingScreen().scrobbleTimer.totalSeconds() >= 10 then
				if song.Artist <> invalid and song.Title <> invalid and song.metadatafault <> true and song.metadataFetched = true
					GetNowPlayingScreen().scrobbleTimer = invalid
      				ScrobbleTrack(song.Artist, song.Title)
      			end if
      		end if
      	end if
      	
	end if

End Sub


Sub HandleAudioPlayerEvent(msg as Object)
	if type(msg) = "roAudioPlayerEvent"  then	' event from audio player
		
		song = GetGlobalAA().SongObject

	    if msg.isStatusMessage() then
	        message = msg.getMessage()
	        ' print "AudioPlayer Status Event - " message
	    else if msg.isListItemSelected() then
	        ' print "starting song:"; msg.GetIndex()
	        song.failCounter = 0
	        ' Audio.audioplayer.Seek(-180000)
	        Get_Metadata(song, GetPort())
	    else if msg.isRequestSucceeded()
	        print "ending song:"; msg.GetIndex()
	        'audio.setPlayState(0)	' stop the player, wait for user input
	    ' else if msg.isRequestFailed()
	    '     BatLog("failed to play station: " + song.feedurl)
	    '     if NOT song.DoesExist("failCounter") THEN 
	    '     	song.failCounter = 0
	    '     End if
	    '     song.failCounter = song.failCounter + 1
	    else if msg.isRequestFailed()
        	Audio = GetGlobalAA().AudioPlayer
	    	if Audio.failCounter < 5 then
	        	print "FullResult: End of Stream.  Restarting.  Failures: " + str(Audio.failCounter)
	        	Audio.AudioPlayer.stop()
	        	Audio.AudioPlayer.play()
	        	Audio.failCounter = Audio.failCounter + 1
	        else
	        	BatLog("Failed playing station.", song.feedurl)
	        	Audio.AudioPlayer.stop()
	        	Audio.failCounter = 0
	        	ListStations()
	        end if
	    endif
	endif
End Sub

Sub HandleDownloadEvents(msg)
	if type(msg) = "roUrlEvent" then
		Identity = str(msg.GetSourceIdentity())

		' print msg.GetString()
		
		if msg.GetFailureReason() <> invalid then
			IsDownloadingFile = IsDownloading(Identity)
			if IsDownloadingFile = true then
				'print "DOWNLOAD COMPLETE: " + Identity
				song = GetGlobalAA().SongObject
				if GetGlobalAA().IsStationSelectorDisplayed <> true
					UpdateScreen()
				end if
			end if

			'JSON
			if GetGlobalAA().DoesExist("jsontransfer")
				jsontransfer = GetGlobalAA().Lookup("jsontransfer")
				jsonIdentity = str(jsontransfer.GetIdentity())
				if jsonIdentity = Identity then
					HandleJSON(msg.GetString())
					GetGlobalAA().Delete("jsontransfer")
				End if
			end if

			if GetGlobalAA().DoesExist(Identity) THEN
				GetGlobalAA().Delete(Identity)
			End if


			'Rdio Playlist search result
			if GetGlobalAA().DoesExist("RdioPlaylistSearchRequest")
				transfer = GetGlobalAA().RdioPlaylistSearchRequest
				if str(transfer.GetIdentity()) = Identity
					RdioPlaylistSearchResult(msg.GetString())
				end if
			end if


			'Rdio search results
			if GetGlobalAA().DoesExist("RdioRequest")
				transfer = GetGlobalAA().RdioRequest
				if str(transfer.GetIdentity()) = Identity
					RdioSearchResult(msg.GetString())
				end if
			end if

		else
			BatLog("Download failed. " + msg.GetFailureReason())
		end if

	end if

End Sub

'Utilities

function StartEventLoop()
    port = GetPort()
	GetGlobalAA().AddReplace("endloop", false)

	while NOT GetGlobalAA().lookup("endloop")
		HandleTimers()

		msg = wait(5, port)
		HandleWebEvent(msg)

		if msg <> invalid then
			HandleDownloadEvents(msg)
			HandleNowPlayingScreenEvent(msg)
			HandleStationSelector(msg)
			HandleAudioPlayerEvent(msg)

			'Analytics
			Analytics = GetSession().Analytics
			Analytics.HandleAnalyticsEvents(msg)
		end if

		song = GetGlobalAA().SongObject
		if GetGlobalAA().IsStationSelectorDisplayed <> true
			NowPlayingScreen = GetNowPlayingScreen()
		
			' if NowPlayingScreen <> invalid AND NowPlayingScreen.screen <> invalid AND NowPlayingScreen.loadingScreen = invalid AND NowPlayingScreen.DoesExist("song") then
			if NowPlayingScreen <> invalid AND NowPlayingScreen.screen <> invalid AND NowPlayingScreen.DoesExist("song")
				DrawScreen()
			end if
		end if

	end while

end function


function StopEventLoop()
	GetGlobalAA().AddReplace("endloop", true)
end function


Sub GetPort() as Object
	port = GetGlobalAA().lookup("port")
	
	if port = invalid then
		port = CreateObject("roMessagePort")
		GetGlobalAA().AddReplace("port", port)
		return port
	end if

	return port
End Sub


Sub NowPlayingScreenTimer() as Object
	timer = GetGlobalAA().lookup("NowPlayingScreenTimer")
	if timer = invalid then
    	timer = CreateObject("roTimespan")
    	timer.mark()
    	GetGlobalAA().AddReplace("NowPlayingScreenTimer", timer)
    end if

    return timer
End Sub