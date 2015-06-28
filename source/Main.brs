Sub RunUserInterface(aa as Object)
    'DeleteRegistry()
    SetTheme()

    print "------ Starting web server ------"
    StartServerWithPort(GetPort())

    GetStationSelectionHeader()

    print "------ Listing stations ------"
    ListStations()
    InitBatPlayer()
    print "------ Starting Loop ------"
    StartEventLoop()
End Sub

Function InitBatPlayer()
	GetGlobalAA().lastSongTitle = ""
    Analytics = GetSession().Analytics
    Analytics.AddEvent("Application Launched")

    print "------ Finding Rdio Playlist ------"
    FindRdioPlaylist()
    print "------ Initializing LastFM ------"
    InitLastFM()
    print "------ Initializing fonts ------"
    InitFonts()
End Function
