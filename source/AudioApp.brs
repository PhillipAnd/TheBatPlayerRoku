

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
Sub Show_Audio_Screen(song as Object)

    ResetNowPlayingScreen()
    GetGlobalAA().AddReplace("NowPlaying", true)
    ' GetGlobalAA().AddReplace("IsStationSelectorDisplayed", false)

    if GetGlobalAA().DoesExist("AudioPlayer") then
      Audio = GetGlobalAA().AudioPlayer
      Audio.reset()
      GetGlobalAA().song = ""
    else
      Audio = AudioInit()
      GetGlobalAA().AudioPlayer = Audio
    end if

    ' ' start playing
    Audio.setPlayState(0)
    Audio.setupSong(song.feedurl, song.streamformat)
    Audio.audioplayer.setNext(0)
    Audio.setPlayState(2)		' start playing
    Audio.audioplayer.Seek(-180000)
End Sub