Sub RunUserInterface(aa as Object)
    'DeleteRegistry()

    internetConnection = GetSession().deviceInfo.GetLinkStatus()
    if internetConnection = true
      Analytics = GetSession().Analytics
      Analytics.AddEvent("Application Launched")

      GetStationSelectionHeader()
      ListStations()
      InitBatPlayer()
      StartServerWithPort(GetPort())
      StartEventLoop()
    else
      HandleInternetConnectivity()
    end if
End Sub

Function InitBatPlayer()
	GetGlobalAA().lastSongTitle = ""
    FindRdioPlaylist()
    InitLastFM()
    InitFonts()

End Function
