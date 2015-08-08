

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

    ResetNowPlayingScreen()
    GetGlobalAA().AddReplace("NowPlaying", true)

    'If we're already playing this station then don't make any changes
    if GetGlobalAA().DoesExist("SongObject")
      CurrentStation = GetGlobalAA().SongObject
      if CurrentStation <> invalid
        if CurrentStation.feedurl = Station.feedurl
          return
        end if
      end if
    end if

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
