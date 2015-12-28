

Sub Get_Metadata(song as Object, port as Object)
        GetJSONAtUrl(song.feedurl)
End Sub

REM ******************************************************
REM
REM Show audio screen
REM
REM Upon entering screen, should start playing first audio stream
REM
REM ******************************************************
Sub Show_Audio_Screen(station as Object)
  GetGlobalAA().AddReplace("NowPlaying", true)

    'If we're already playing this station then don't make any changes
    if GetGlobalAA().DoesExist("SongObject")
      CurrentStation = GetGlobalAA().SongObject
      if CurrentStation <> invalid
        if CurrentStation.feedurl = Station.feedurl
          RefreshNowPlayingScreen()
          return
        end if
      end if
    end if

    ResetNowPlayingScreen()

    if GetGlobalAA().DoesExist("AudioPlayer") then
      Audio = GetGlobalAA().AudioPlayer
      Audio.reset()
      GetGlobalAA().song = ""
    else
      Audio = AudioInit()
      GetGlobalAA().AudioPlayer = Audio
    end if

    GetGlobalAA().AddReplace("SongObject", Station)

    Audio.setPlayState(0)
    Audio.setupSong(station.feedurl, station.streamformat)
    Audio.audioplayer.setNext(0)
    Audio.setPlayState(2)		' start playing
    Audio.audioplayer.Seek(-180000)
End Sub


Function GetDirectoryStation(station) as Object
  if station.DoesExist("feedurl") AND station.feedurl <> invalid AND station.feedurl <> ""
    PlayStation(station)
  else
    ' Need to get the audio stream from playlist
  end if

    if station.DoesExist("playlist") AND station.playlist <> invalid
      print "Trying to convert playlist " + station.playlist + " to an audio stream."

      Request = GetRequest()
      Request.SetUrl(station.playlist)
      playlistString = Request.GetToString()
      splitStringArray = playlistString.tokenize(CHR(10))

      audiourl = invalid

      for i = 0 to splitStringArray.Count()
        singleString = splitStringArray[i]
        if singleString <> invalid
          if singleString.Instr(0, "File1=") <> -1
            startAtCharIndex = singleString.Instr(0, "=") + 1
            audiourl = singleString.Mid(startAtCharIndex)
            station.feedurl = audiourl
            return station
          else
            audiourl = singleString
          end if
        end if
      end for

    end if

  'end if
End Function

Function PlayStation(station)
  if station.DoesExist("feedurl") AND station.feedurl <> ""
    Analytics_StationSelected(Station.stationName, Station.feedurl)

    metadataUrl = GetConfig().Batserver + "metadata/" + UrlEncode(Station.feedurl)
    print "JSON for selected station: " + metadataUrl

    DisplayStationLoading(Station)
    Show_Audio_Screen(Station)
  end if
End Function


Function CreateSong(title as string, description as string, artist as string, streamformat as string, feedurl as string, imagelocation as string) as Object
    item = CreatePosterItem("", title, description)
    url = imageLocation
    item.Artist = artist
    item.Title = title    ' Song name
    item.feedurl = feedurl
    item.streamformat = streamformat
    item.picture = url      ' default audioscreen picture to PosterScreen Image
    item.stationProvider = description
    item.stationName = title
    item.StationImage = imagelocation
    item.Description = "Select Station to find what is currently playing."
    item.JSONDownloadDelay = 0
    item.dataExpires = 0
    item.HDPosterUrl = url
    item.SDPosterUrl = item.HDPosterUrl
    return item
End Function
