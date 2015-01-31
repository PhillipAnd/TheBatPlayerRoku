REM ******************************************************
REM
REM Main - all Roku scripts startup here.
REM
REM
REM ******************************************************
Sub Main()
    'DeleteRegistry()

    Analytics = GetSession().Analytics
    Analytics.AddEvent("Application Launched")

    InitBatPlayer()
    InitFonts()
    GetStationSelectionHeader()
    StartServerWithPort(GetPort())
    InitLastFM()
    ListStations()
    StartEventLoop()
End Sub

Function InitBatPlayer()
	GetGlobalAA().lastSongTitle = ""
    FindRdioPlaylist()
End Function
