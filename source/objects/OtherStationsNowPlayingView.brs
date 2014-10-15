Function OtherStationsNowPlaying(text as string) as Object
this = {
		text: text
		labelObject: invalid
		font: GetSongNameFont()
		ReadyToDestroy: false

		labelX: 0
		labelY: 0

		BackgroundViewY: -80
		
		TextY: -60
		TextX: 0

		width: 1080
		height: 80

		textLength: 0

		backgroundColor: &h000000DD
		
		draw: otherStationsNowPlaying_draw
		destroy: otherStationsNowPlaying_destroy
	}

	
	this.width = GetNowPlayingScreen().screen.GetWidth()
	this.TextX = this.width - 20
	this.textLength = this.font.GetOneLineWidth(text, 9999999)

	return this

End Function

Function CreateOtherStationsNowPlaying()
	Session = GetSession()
	Session.StationDownloads = CreateObject("roAssociativeArray")
	Session.StationDownloads.Downloads = CreateObject("roAssociativeArray")
	Session.StationDownloads.Completed = CreateObject("roArray", 0, true) 
	Session.StationDownloads.Count = 0

	NowPlayingScreen = GetNowPlayingScreen()

    stationsArray = GetStations()

    for each singleStation in stationsArray

    	if NowPlayingScreen.song.feedurl <> singleStation.stream
        	FetchMetadataForStreamUrlAndName(singleStation.stream,singleStation.name)
        end if

    end for

End Function

Function DisplayOtherStationsNowPlaying(nowPlayingArray as Object)

	NowPlayingScreen = GetNowPlayingScreen()

	if NowPlayingScreen.screen = invalid
		return false
	end if

	text = "On other stations: "

    for each nowPlaying in nowPlayingArray
		station = nowPlaying.name
		playing = nowPlaying.playing
    	
    	if nowPlaying <> invalid AND station <> invalid AND playing <> invalid
    		playing = DeParenString(playing)
			text = text + station + ": " + playing + ".   "
		end if
    end for

    NowPlayingScreen.OtherStationsNowPlaying = OtherStationsNowPlaying(text)
End Function

Function otherStationsNowPlaying_draw(screen as Object)
	screen.DrawRect(0,m.BackgroundViewY, m.width, m.height, m.backgroundColor)
	screen.DrawText(m.text,m.TextX,m.TextY,&hFFFFFFBB,m.font)

	m.TextX = m.TextX - 4
	
	'We're done
	if m.BackgroundViewY <= -180 AND m.ReadyToDestroy = true
		m.Destroy()

	'Animate out
	else if m.TextX < (m.textLength * -1) + m.width
		m.BackgroundViewY = m.BackgroundViewY - 2
		m.TextY = m.TextY - 2
		m.ReadyToDestroy = true

	'Animate in
	else if m.BackgroundViewY < 0
		m.BackgroundViewY = m.BackgroundViewY + 2
		m.TextY = m.TextY + 2
	end if

End Function

Function otherStationsNowPlaying_destroy()
	Session = GetSession()
	NowPlayingScreen = GetNowPlayingScreen()

	NowPlayingScreen.OtherStationsNowPlaying = invalid
	Session.Delete("StationDownloads")
	m = invalid
End Function