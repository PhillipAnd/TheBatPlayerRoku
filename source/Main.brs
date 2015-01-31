REM ******************************************************
REM
REM Main - all Roku scripts startup here.
REM
REM
REM ******************************************************
Sub Main()
    'DeleteRegistry()

    Analytics = GetSession().Analytics
    internetConnection = GetSession().deviceInfo.GetLinkStatus()
    if internetConnection = true
      Analytics.AddEvent("Application Launched")
      InitBatPlayer()
      InitFonts()
      GetStationSelectionHeader()
      StartServerWithPort(GetPort())
      InitLastFM()
      ListStations()
      StartEventLoop()
    else
      HandleInternetConnectivity()
    end if
End Sub

Function InitBatPlayer()
	GetGlobalAA().lastSongTitle = ""
    FindRdioPlaylist()
End Function
