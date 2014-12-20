Function GetJSONAtUrl(url as String)
  NowPlayingScreen = GetNowPlayingScreen()

  'If we have an expiration time then respect that
  if NowPlayingscreen.song <> invalid
    nowDateTime = CreateObject("roDateTime").asSeconds()
    expiresDateTime = ToStr(NowPlayingScreen.song.dataExpires).toInt() 'Because JSON parsing reads it as a double
    if (nowDateTime < expiresDateTime) THEN return false
  end if

  if NOT GetGlobalAA().DoesExist("jsontransfer") then
    Request = CreateObject("roUrlTransfer")
    Request.SetMinimumTransferRate(1, 20)

    'Sanitize the stream url to get the correct metadata
    if right(url,1) = "/" then
      url = left(url, len(url)-1)
    else if right(url,2) = "/;" then
      url = left(url, len(url)-2)
    end if

    url = UrlEncode(url)
    metadataUrl = GetConfig().ApiHost + "?stream=" + url
    'print "Checking for JSON at " metadataUrl
    Request.SetUrl(metadataUrl)
    Request.SetPort(GetPort())

    GetGlobalAA().AddReplace("jsontransfer", Request)

    Request.AsyncGetToString()
  end if
End Function


Function HandleJSON(jsonString as String)

  jsonObject = ParseJSON(jsonString)
  song = GetGlobalAA().Lookup("SongObject")
  NowPlayingScreen = GetNowPlayingScreen()

  shouldRefresh = false

  if jsonObject <> invalid AND jsonObject.song <> invalid

    song.JSONDownloadDelay = 0

    'Station details if available
    if jsonObject.station <> invalid
      if NOT song.DoesExist("StationDetails") OR song.StationDetails.listeners <> jsonObject.station.listeners
        song.StationDetails = jsonObject.station
        song.StationDetails.updated = true
      end if
    end if

    song.Title = jsonObject.song
    song.Artist = jsonObject.artist
    song.Description = jsonObject.bio
    song.bio = jsonObject.bio
    song.Genres = jsonObject.tags
    song.isOnTour = jsonObject.isOnTour
    song.album = jsonObject.album
    song.dataExpires = jsonObject.expires
    song.metadataFault = false
    song.brightness = 0
    song.metadataFetched = jsonObject.metaDataFetched
    song.PopularityFetchCounter = 0

    if jsonObject.DoesExist("image") AND type(jsonObject.image) = "roAssociativeArray" AND jsonObject.image.DoesExist("url") AND isnonemptystr(jsonObject.image.url)
      song.HDPosterUrl = jsonObject.image.url
      song.SDPosterUrl = jsonObject.image.url
      song.image = jsonObject.image
    else
      song.HDPosterUrl = song.StationImage
      song.SDPosterUrl = song.StationImage
      song.image =  CreateObject("roAssociativeArray")
      song.image.url = song.StationImage
      song.album = invalid
    end if

  else
    BatLog("There was an error processing or downloading metadata", "error")
    song.JSONDownloadDelay = song.JSONDownloadDelay + 1
    song.image = CreateObject("roAssociativeArray")
    song.image.url = song.StationImage
    song.Artist = song.stationName
    song.Title = song.feedurl
    song.bio = CreateObject("roAssociativeArray")
    song.bio.text = "The Bat Player displays additional information about the station and its songs when available.  " + song.stationName + " does not seem to have any data for The Bat to show you either due the Station not providing it or our servers are experiencing difficulties."
    song.HDPosterUrl = song.StationImage
    song.SDPosterUrl = song.StationImage
    song.metadataFault = true
    song.metadataFetched = false
    song.album = invalid
    song.brightness = 0
  end if

  NowPlayingScreen.song = song

  if song.artist = invalid then song.artist = song.stationName
  if song.Title = invalid then song.Title = jsonObject.track

  if GetGlobalAA().lastSongTitle <> song.Title
    shouldRefresh = true
  endif

 if shouldRefresh = true then
     song.popularity = invalid

      RefreshNowPlayingScreen()
      GetGlobalAA().lastSongTitle = song.Title

      'Download artist image if needed
      if NOT FileExists(makemdfive(song.Artist)) AND song.DoesExist("image") AND song.image.DoesExist("url") AND isnonemptystr(song.image.url) then
          DownloadArtistImageForSong(song)
        if NOT FileExists("colored-" + makemdfive(song.Artist)) then
          DownloadBackgroundImageForSong(song)
        endif

      end if

      if type(song.album) = "roAssociativeArray" AND NOT FileExists(makemdfive(song.album.name)) then
        ' Print "Downloading Album art"
        AsyncGetFile(song.album.image, "tmp:/album-" + makemdfive(song.album.name + song.artist))
      endif

      if NowPlayingScreen.scrobbleTimer = invalid then
        NowPlayingScreen.scrobbleTimer = CreateObject("roTimespan")
      end if
      NowPlayingScreen.scrobbleTimer.mark()

      if NowPlayingScreen.PopularityTimer = invalid
      	NowPlayingScreen.PopularityTimer = CreateObject("roTimespan")
      end if
      NowPlayingScreen.PopularityTimer.mark()

  end if

End Function

Function FetchMetadataForStreamUrlAndName(url as string, name as string, usedForStationSelector = false as Boolean, stationSelectorIndex = invalid as dynamic)
	Session = GetSession()

	if url <> invalid
		url = url + "7.html"

		Request = CreateObject("roUrlTransfer")

		useragent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13"
		Request.AddHeader("user-agent", useragent)
    Request.RetainBodyOnError(true)
		Request.SetUrl(url)

		Request.SetPort(GetPort())
		if Request.AsyncGetToString() then

			stationRequestObject = CreateObject("roAssociativeArray")
			stationRequestObject.name = name
			stationRequestObject.request = Request
      stationRequestObject.usedForStationSelector = usedForStationSelector
      stationRequestObject.stationSelectorIndex = stationSelectorIndex

			key = "OtherStationsRequest-" + ToStr(Request.GetIdentity())
			Session.StationDownloads.Downloads.AddReplace(key, stationRequestObject)

      if usedForStationSelector = false
        Session.StationDownloads.Count = Session.StationDownloads.Count + 1
      end if
		else
			BatLog("Failed downloading accessing " + url)
		end if

	end if
End Function

Function CompletedOtherStationsMetadata(msg as Object)
  Session = GetSession()
  Completed = Session.StationDownloads.Completed

  if msg <> invalid
  	Identity = ToStr(msg.GetSourceIdentity())
  	key = "OtherStationsRequest-" + Identity

  	stationRequestObject = Session.StationDownloads.Downloads.Lookup(key)
  	Session.StationDownloads.Downloads.Delete(key)

  	data = StringRemoveHTMLTags(msg.GetString())
  	track = data.Tokenize(",")
  	track = track[6]

    'If there's no data then don't deal with it
    if track = invalid
      return false
    end if

    if stationRequestObject.usedForStationSelector = true
      StationSelectorNowPlayingTrackReceived(track, stationRequestObject.stationSelectorIndex)
      return false
    end if

  	CompletedObject = CreateObject("roAssociativeArray")
  	CompletedObject.name = stationRequestObject.name
  	CompletedObject.playing = track

  	Completed.push(CompletedObject)
  end if

	if AssocArrayCount(Session.StationDownloads.Downloads) = 0

		'Cleanup
		Session.StationDownloads.Downloads.Clear()
		Session.StationDownloads.Delete("Completed")
		Session.StationDownloads.Count = 0
    Session.StationDownloads.Timer = invalid

		'All the downloads are complete let's display them
		DisplayOtherStationsNowPlaying(Completed)
	end if

End Function

Function IsOtherStationsValidDownload(msg as Object) as Boolean
	Session = GetSession()

	if type(msg) = "roUrlEvent" AND Session.DoesExist("StationDownloads") AND Session.StationDownloads.DoesExist("Downloads")
		Identity = ToStr(msg.GetSourceIdentity())
		key = "OtherStationsRequest-" + Identity

		if Session.StationDownloads.Downloads.DoesExist(key)
			return true
		end if
	end if

	return false

End Function


Function FetchPopularityForArtistName(artistname as String)
	NowPlayingScreen = GetNowPlayingScreen()
	Session = GetSession()
  NowPlayingScreen.Song.PopularityFetchCounter = NowPlayingScreen.Song.PopularityFetchCounter + 1
	NowPlayingScreen.PopularityTimer = invalid

	Request = CreateObject("roUrlTransfer")

	url = "http://api.thebatplayer.fm:4567/artistrank/" + Request.escape(artistname)
	Request.SetUrl(url)
	Request.SetPort(GetPort())

	if Request.AsyncGetToString()
		RequestObject = CreateObject("roAssociativeArray")
		RequestObject.artistname = artistname
		RequestObject.request = Request
		Session.Downloads.PopularityDownload = RequestObject
	end if

End Function

Function CompletedArtistPopulartiy(msg as Object)
		Session = GetSession()
		NowPlayingScreen = GetNowPlayingScreen()
		Song = NowPlayingScreen.song

		if Session.Downloads.PopularityDownload.artistname = Song.Artist
			data = ParseJson(msg.GetString())
			if data <> invalid AND data.DoesExist("comparison")
				popularity = data.comparison
				Song.popularity = popularity
				UpdateScreen()
			else
				RestartFetchPopularityTimer()
			end if
		else
			print "Wrong artist popularity!"
			RestartFetchPopularityTimer()
		end if
		Session.Downloads.PopularityDownload = invalid
End Function

Function RestartFetchPopularityTimer()
	NowPlayingScreen = GetNowPlayingScreen()
	NowPlayingScreen.PopularityTimer = CreateObject("roTimespan")

	print "Restarting fetching of artist popularity."
	NowPlayingScreen.PopularityTimer.mark() 'Reset the timer and try again
End Function
