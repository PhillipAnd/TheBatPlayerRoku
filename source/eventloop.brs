REM Global event loop


Sub HandleStationSelector (msg as Object)


	if GetGlobalAA().IsStationSelectorDisplayed <> true
		return
	end if

	if type(msg) = "roUniversalControlEvent" AND msg.GetInt() = 0
		end
	endif

	if type(msg) <> "roGridScreenEvent"
		return
	end if

	if msg.isScreenClosed()
		GetGlobalAA().IsStationSelectorDisplayed = false
		return
	end if


	if msg.isListItemSelected()
				GetGlobalAA().IsStationSelectorDisplayed = false

				StationList = GetGlobalAA().StationList

        selectionIndex = msg.GetData()

        Stations = GetGlobalAA().SelectableStations
        Station = Stations[selectionIndex]
				Analytics_StationSelected(Station.stationName, Station.feedurl)

				metadataUrl = GetConfig().Batserver + "metadata/" + UrlEncode(Station.feedurl)
				print "JSON for selected station: " + metadataUrl

        GetGlobalAA().AddReplace("SongObject", Station)
        Show_Audio_Screen(Station)
        DisplayStationLoading(Station)
				SelectionScreen = GetGlobalAA().StationSelectionScreen
				SelectionScreen.close()
				return
	end if

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
	NowPlayingScreen = GetNowPlayingScreen()
	Session = GetSession()

	if GetGlobalAA().IsStationSelectorDisplayed <> true then
		timer = GetNowPlayingTimer()
		if timer <> invalid

			if timer <> invalid and timer.totalSeconds() >= GetConfig().MetadataFetchTimer + song.JSONDownloadDelay then
				Get_Metadata(song, GetPort())
				timer.mark()
			end if
		end if


		'LastFM Scrobbles
		if NowPlayingScreen.scrobbleTimer <> invalid THEN
			if NowPlayingScreen.scrobbleTimer.totalSeconds() >= 10 then
				if song.Artist <> invalid and song.Title <> invalid and song.metadatafault <> true and song.metadataFetched = true
					NowPlayingScreen.scrobbleTimer = invalid
      				ScrobbleTrack(song.Artist, song.Title)
      			end if
      		end if
      	end if

      	'Popularity Ranking
      	if NowPlayingScreen.PopularityTimer <> invalid AND Song.PopularityFetchCounter <> invalid
      		if NowPlayingScreen.PopularityTimer.totalSeconds() >= 5 AND Song.PopularityFetchCounter < 10
      			FetchPopularityForArtistName(song.Artist)
      		end if
      	end if


      	'Now Playing on other stations
      	if (Session.StationDownloads <> invalid AND Session.StationDownloads.Timer <> invalid AND Session.StationDownloads.Timer.totalSeconds() > GetConfig().MetadataFetchTimer)
      		CancelOtherStationsNowPlayingRequests()
      	end if

      	if NowPlayingScreen.NowPlayingOtherStationsTimer <> invalid AND NowPlayingScreen.NowPlayingOtherStationsTimer.totalSeconds() > 1000
  		    NowPlayingScreen.NowPlayingOtherStationsTimer.mark()
      		CreateOtherStationsNowPlaying()
      	end if

				'Image download timeouts
				if (NowPlayingScreen.artistImage = invalid OR song.ArtistImageDownloadTimer <> invalid AND NowPlayingScreen.artistImage.valid <> true ) AND song.ArtistImageDownloadTimer <> invalid AND song.ArtistImageDownloadTimer.totalSeconds() > GetConfig().ImageDownloadTimeout
					song.UseFallbackArtistImage = true
					song.ArtistImageDownloadTimer = invalid
					if GetGlobalAA().IsStationSelectorDisplayed <> true
						UpdateScreen()
					end if
				end if

				if (NowPlayingScreen.BackgroundImage = invalid OR NowPlayingScreen.BackgroundImage <> invalid AND NowPlayingScreen.BackgroundImage.valid <> true ) AND song.BackgroundImageDownloadTimer <> invalid AND song.BackgroundImageDownloadTimer.totalSeconds() > GetConfig().ImageDownloadTimeout
					song.UseFallbackBackgroundImage = true
					song.BackgroundImageDownloadTimer = invalid
					if GetGlobalAA().IsStationSelectorDisplayed <> true
						UpdateScreen()
					end if
				end if

	end if

End Sub


Sub HandleAudioPlayerEvent(msg as Object)
	if type(msg) = "roAudioPlayerEvent"  then	' event from audio player
	Audio = GetGlobalAA().AudioPlayer

		song = GetGlobalAA().SongObject

	    if msg.isStatusMessage() then
	        message = msg.getMessage()
	    else if msg.isListItemSelected() then
	        song.failCounter = 0
					Audio.audioplayer.Seek(-180000)
	        Get_Metadata(song, GetPort())
	    else if msg.isRequestSucceeded() OR msg.isRequestFailed()
	    	if Audio.failCounter < 5 then
	        	print "FullResult: End of Stream.  Restarting.  Failures: " + str(Audio.failCounter)
	        	Audio.AudioPlayer.stop()
	        	Audio.AudioPlayer.play()
						Audio.Audioplayer.Seek(-180000)
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
		Identity = ToStr(msg.GetSourceIdentity())
		Downloads = GetSession().Downloads
		TransferRequest = Downloads.lookup(Identity)

		'print msg.GetString() 'Uncomment for troubleshooting
		'print ToStr(msg.GetResponseCode())

		if msg.GetResponseCode() = 200 OR msg.GetFailureReason() = invalid then

			IsDownloadingFile = IsDownloading(Identity)
			if IsDownloadingFile = true then
				song = GetGlobalAA().SongObject
				if GetGlobalAA().IsStationSelectorDisplayed <> true
					UpdateScreen()
				end if
			end if

			'JSON
			if GetGlobalAA().DoesExist("jsontransfer")
				jsontransfer = GetGlobalAA().Lookup("jsontransfer")
				jsonIdentity = ToStr(jsontransfer.GetIdentity())
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
				if ToStr(transfer.GetIdentity()) = Identity
					RdioPlaylistSearchResult(msg.GetString())
				end if
			end if


			'Rdio search results
			if GetGlobalAA().DoesExist("RdioRequest")
				transfer = GetGlobalAA().RdioRequest
				if ToStr(transfer.GetIdentity()) = Identity
					RdioSearchResult(msg.GetString())
				end if
			end if


			'Downloads for what other stations are playing
			if (IsOtherStationsValidDownload(msg))
				CompletedOtherStationsMetadata(msg)
			end if


			'Artist popularity
			if Downloads.DoesExist("PopularityDownload") AND type(Downloads.PopularityDownload) = "roAssociativeArray" AND Identity = ToStr(Downloads.PopularityDownload.Request.GetIdentity())
				CompletedArtistPopulartiy(msg)
			end if

		else
			if TransferRequest <> invalid
				errorUrl = TransferRequest.GetUrl()
				print("Download failed. " + errorUrl + " " + str(msg.GetResponseCode()) + " : " + msg.GetFailureReason())
			else
				print("Download failed. " + str(msg.GetResponseCode()) + " : " + msg.GetFailureReason())
			endif

			song = GetGlobalAA().SongObject

			if IsBackgroundImageDownload(Identity)
				'Background Image download failed
				song.UseFallbackBackgroundImage = true
				GetSession().BackgroundImageDownload = invalid
				UpdateScreen()
				return
			end if

			if IsArtistImageDownload(Identity)
				'Artist Image download failed
				song.UseFallbackArtistImage = true
				GetSession().ArtistImageDownload = invalid
				UpdateScreen()
				return
			end if


			if GetGlobalAA().DoesExist("jsontransfer")
				'Metadata download failed so reset the timer

				if song.MetadataFetchFailure >= 2
					UpdateScreen()
				end if

				song.MetadataFetchFailure = song.MetadataFetchFailure + 1
				timer = GetNowPlayingTimer()
				timer.mark()
				return
			end if



		end if

	end if

End Sub

'Utilities

function StartEventLoop()
    port = GetPort()
	GetGlobalAA().AddReplace("endloop", false)

	while NOT GetGlobalAA().lookup("endloop")
		HandleTimers()

		'msg = wait(1, port)
		msg = port.GetMessage() ' get a message, if available

		HandleWebEvent(msg)

		if msg <> invalid then

			if GetGlobalAA().IsStationSelectorDisplayed = true
				HandleStationSelector(msg)
			end if

			HandleDownloadEvents(msg)
			HandleNowPlayingScreenEvent(msg)
			HandleAudioPlayerEvent(msg)

			if type(msg)="roTextureRequestEvent"
				HandleTextureManager(msg)
			end if

			'Analytics
			Analytics = GetSession().Analytics
			Analytics.HandleAnalyticsEvents(msg)
		end if

		song = GetGlobalAA().SongObject
		if GetGlobalAA().IsStationSelectorDisplayed <> true
			NowPlayingScreen = GetNowPlayingScreen()

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
