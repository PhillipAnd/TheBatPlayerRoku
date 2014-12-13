'Called only once when the Now Playing screen is displayed
Function CreateNowPlayingScreen() as Object

  Analytics = GetSession().Analytics
  Analytics.ViewScreen("Now Playing")

	NowPlayingScreen = CreateObject("roAssociativeArray")

	NowPlayingScreen.headerFont = GetHeaderFont()
  NowPlayingScreen.boldFont = GetLargeBoldFont()
  NowPlayingScreen.defaultFont = GetMediumFont()
  NowPlayingScreen.smallFont = GetSmallFont()
  NowPlayingScreen.songNameFont = GetSongNameFont()

  NowPlayingScreen.HeaderLogo = CreateObject("roBitmap", "pkg:/images/bat.png")
  NowPlayingScreen.StationDetailsLabel = invalid
  NowPlayingScreen.BackgroundImage = invalid
  NowPlayingScreen.PreviousBackgroundImage = invalid
  NowPlayingScreen.PopularityImage = invalid
  NowPlayingScreen.Gradient = CreateObject("roBitmap", "pkg:/images/background-gradient-overlay.png")

  NowPlayingScreen.albumImage = invalid
  NowPlayingScreen.previousAlbumImage = invalid

  NowPlayingScreen.ArtistImage = invalid
  NowPlayingScreen.previousArtistImage = invalid

  NowPlayingScreen.lastfmlogo = CreateObject("roBitmap", "pkg:/images/audioscrobbler_black.png")
  NowPlayingScreen.albumPlaceholder = AlbumImage("pkg:/images/album-placeholder.png", 780, 240, false, 200)

  NowPlayingScreen.UpdateBackgroundImage = "true"
  NowPlayingScreen.UpdateArtistImage = "true"
  NowPlayingScreen.UpdateAlbumImage = "true"

  NowPlayingScreen.ScrobbleTimer = invalid
  NowPlayingScreen.NowPlayingOtherStationsTimer = invalid

  NowPlayingScreen.popup = invalid
  NowPlayingScreen.loadingScreen = invalid

  NowPlayingScreen.screen = invalid
  NowPlayingScreen.NowPlayingOtherStationsTimer = CreateObject("roTimespan")

  NowPlayingScreen.Width = GetSession().deviceInfo.GetDisplaySize().w
  NowPlayingScreen.Height = GetSession().deviceInfo.GetDisplaySize().h

	return NowPlayingScreen
End Function

Function ResetNowPlayingScreen()
	GetGlobalAA().Delete("NowPlayingScreen")
	GetGlobalAA().Delete("Song")
  NowPlayingScreen = GetNowPlayingScreen()
  NowPlayingScreen.NowPlayingOtherStationsTimer.mark()
End Function

'Called whenever the data for the screen changes (song)
Function UpdateScreen()
	NowPlayingScreen = GetNowPlayingScreen()

  if NowPlayingScreen.screen = invalid
    screen = CreateObject("roScreen", true, NowPlayingScreen.Width, NowPlayingScreen.Height)
    NowPlayingScreen.screen = screen

    screen.setalphaenable(true)
    screen.SetMessagePort(GetPort())
    screen.Clear(&h000000FF)

    GetGlobalAA().IsStationSelectorDisplayed = false

  end if   

	song = NowPlayingScreen.song

  if song = invalid
    return false
  end if 

  'Lighting
  if GetGlobalAA().lookup("song") <> song.Title AND song.DoesExist("image") AND song.image.DoesExist("color") AND song.image.color.DoesExist("hsv") then
    SetLightsToColor(song.image.color.hsv)
  end if

	GetGlobalAA().AddReplace("song", song.title)

	albumTitle = ""
  bioText = ""
  songTitle = ""
	albumTitle = ""
	genreText = ""
  
  'No image?
  if NOT song.DoesExist("image") then
    song.image = CreateObject("roAssociativeArray")
  end if

  if NOT song.DoesExist("image") OR NOT song.image.DoesExist("color") OR song.image.color.hex = invalid then
    song.image.color = CreateObject("roAssociativeArray")
    song.image.color.hex = "#ffffffff"
  end if
  
    'Artist Image
    if song.Artist <> invalid AND FileExists("artist-" + makemdfive(song.Artist)) then
      artistImageFilePath = "tmp:/artist-" + makemdfive(song.Artist)

      if artistImageFilePath <> invalid AND NowPlayingScreen.UpdateArtistImage = "true" then
        NowPlayingScreen.artistImage = ArtistImage(artistImageFilePath)
        NowPlayingScreen.UpdateArtistImage = "false"
      end if
    end if

    'Artist bio
    bioText = GetBioTextForSong(song)

    'Song Name
    if song.Title <> invalid then
   		songTitle = song.Title
    end if

    'Album Image
    if type(song.album) = "roAssociativeArray" AND FileExists("album-" + makemdfive(song.album.name + song.artist)) AND NowPlayingScreen.UpdateAlbumImage = "true" then
      albumImageFilePath = "tmp:/album-" + makemdfive(song.album.name + song.artist)
      NowPlayingScreen.albumImageOverlayColor = CreateOverlayColor(NowPlayingScreen.song)
      NowPlayingScreen.albumImage = AlbumImage(albumImageFilePath, 780, 240, true, 240, NowPlayingScreen.albumImageOverlayColor)
      NowPlayingScreen.UpdateAlbumImage = "false"
    endif

    if type(song.album) = "roAssociativeArray"
      'Album Name
      if (song.album.DoesExist("releaseDate")) then
        dt = CreateObject("roDateTime")
        dt.FromISO8601String(song.album.releaseDate)
        albumDate = str(dt.GetYear())
        albumTitle = song.album.name + " (" + albumDate.right(4) + ")"
      else
        albumTitle = song.album.name
      endif
  endif

  'Genres
  if song.DoesExist("Genres") AND song.Genres <> invalid AND song.Genres.count() > 0 then
    for i=0 to song.Genres.count()-1
      if song.Genres[i] <> invalid
          genreText = genreText + song.Genres[i] + " "
      end if
    end for
  end if

  'Background Image
 	if song.Artist <> invalid AND FileExists("colored-" + makemdfive(song.Artist)) AND NowPlayingScreen.UpdateBackgroundImage <> "false" then
    NowPlayingScreen.BackgroundImage = BackgroundImage("tmp:/colored-" + makemdfive(song.Artist))

    ' Test if this file is invalid.  If so delete it and redownload it.
    if NowPlayingScreen.BackgroundImage.image = invalid
      NowPlayingScreen.BackgroundImage = invalid
      DeleteTmpFile("colored-" + makemdfive(song.Artist))
      DownloadBackgroundImageForSong(song)
    end if

    if NowPlayingScreen.BackgroundImage <> invalid
      NowPlayingScreen.BackgroundImage.FadeIn()
      NowPlayingScreen.PreviousBackgroundImage = invalid
    end if

    NowPlayingScreen.UpdateBackgroundImage = "false"
  end if

	'Station Name
	stationTitle = ""
	if song.stationProvider <> song.stationName then
		NowPlayingScreen.stationTitle = song.stationName + " - " + song.stationProvider
	else if song.stationTitle <> invalid
		NowPlayingScreen.stationTitle = song.stationName
	endif

  songNameHeight = GetTextHeight(songTitle, 500, NowPlayingScreen.songNameFont)
  artistNameLocation = 165 - songNameHeight
  songNameLocation = artistNameLocation + 40

  NowPlayingScreen.artistNameLabel = ArtistNameLabel(song.artist, song, artistNameLocation, NowPlayingScreen.boldFont)
  NowPlayingScreen.songNameLabel = SongNameLabel(songTitle, song, songNameLocation, NowPlayingScreen.songNameFont)
  NowPlayingScreen.albumNameLabel = RlTextArea(albumTitle, NowPlayingScreen.smallFont, GetBoldColorForSong(song), ResolutionX(725), ResolutionY(425), ResolutionX(300), ResolutionY(200), 3, 0.9, "center")
  NowPlayingScreen.bioLabel = BatBioLabel(bioText, song)

  if NowPlayingScreen.artistImage <> invalid then verticalOffset = NowPlayingScreen.artistImage.verticalOffset else verticalOffset = 0

  if GetSession().deviceInfo.GetDisplaySize().W = 1280
    genreX = 120
    genreY = 455 - verticalOffset
  else
    genreX = ResolutionX(120)
    genreY = ResolutionY(480)
  end if
  NowPlayingScreen.genresLabel = RlTextArea(genreText, NowPlayingScreen.smallFont, GetRegularColorForSong(song), genreX, genreY, ResolutionX(500), ResolutionY(30), 2, 0.8, "center")

  onTourText = ""
  if song.isOnTour = true
    onTourText = "On Tour"
  end if

  if NowPlayingScreen.artistImage <> invalid then horizontalOffset = NowPlayingScreen.artistImage.horizontalOffset else horizontalOffset = 0
  NowPlayingScreen.onTourLabel = RlTextArea(onTourText, NowPlayingScreen.smallFont, &hFFFFFF00 + 80, ResolutionX(120 + horizontalOffset + 5), ResolutionY(120 + verticalOffset), 300, 50, 1, 1.0, "left")

  'Popularity
  if NowPlayingScreen.PopularityImage = invalid AND NowPlayingScreen.Song.popularity <> invalid
    NowPlayingScreen.PopularityImage = CreateObject("roBitmap", "pkg:/images/popularity-" + NowPlayingScreen.Song.Popularity + ".png")
  end if

  if NowPlayingScreen.loadingScreen <> invalid then
    NowPlayingScreen.loadingScreen.close()
    NowPlayingScreen.loadingScreen = invalid
  end if

End Function

Function GetNowPlayingScreen() as Object
	NowPlayingScreen = GetGlobalAA().Lookup("NowPlayingScreen")

	if NowPlayingScreen = invalid then
		NowPlayingScreen = CreateNowPlayingScreen()
		GetGlobalAA().AddReplace("NowPlayingScreen", NowPlayingScreen)
	end if

	return NowPlayingScreen
End Function

Function DrawScreen()

	NowPlayingScreen = GetNowPlayingScreen()
  if NowPlayingScreen.screen = invalid
    return false
  end if
  
	if NowPlayingScreen.screen <> invalid then
		NowPlayingScreen.screen.Clear(&h000000FF)
		NowPlayingScreen.screen.setalphaenable(true)

		'Background Image
    if NowPlayingScreen.BackgroundImage <> invalid then
      NowPlayingScreen.BackgroundImage.Draw(NowPlayingScreen.screen)
    end if    
    if NowPlayingScreen.PreviousBackgroundImage <> invalid
      NowPlayingScreen.PreviousBackgroundImage.Draw(NowPlayingScreen.screen)
    end if
    NowPlayingScreen.screen.DrawObject(0, NowPlayingScreen.Height - 365, NowPlayingScreen.gradient, &hFFFFFF + 245)
    NowPlayingScreen.screen.DrawRect(0, 0, NowPlayingScreen.Width, NowPlayingScreen.Height, &h00000000 + 215) 'Black overlay

		'Header
		NowPlayingScreen.screen.DrawRect(0,0, NowPlayingScreen.screen.GetWidth(), ResolutionY(80), GetHeaderColor())
		NowPlayingScreen.screen.DrawObject(ResolutionX(20),ResolutionY(3),NowPlayingScreen.HeaderLogo)
		NowPlayingScreen.screen.DrawText(NowPlayingScreen.stationTitle,180,18,&hFFFFFFFF,NowPlayingScreen.headerFont)
    
    DrawStationDetailsLabel(NowPlayingScreen)
    DrawHelpLabel(NowPlayingScreen)

    'All the text
		NowPlayingScreen.artistNameLabel.draw(NowPlayingScreen.screen)
		NowPlayingScreen.songNameLabel.draw(NowPlayingScreen.screen)
		NowPlayingScreen.albumNameLabel.draw(NowPlayingScreen.screen)
    NowPlayingScreen.bioLabel.draw(NowPlayingScreen.screen)
    if NowPlayingScreen.genresLabel <> invalid
		  NowPlayingScreen.genresLabel.draw(NowPlayingScreen.screen)
    end if
		NowPlayingScreen.onTourLabel.draw(NowPlayingScreen.screen)

		'Artist
    NowPlayingScreen.screen.DrawObject(200, 120, NowPlayingScreen.artistPlaceholder, &hFFFFFFFF)
    if NowPlayingScreen.artistImage <> invalid
      NowPlayingScreen.artistImage.Draw(NowPlayingScreen.screen)
    else
      NowPlayingScreen.ArtistPlaceholder.Draw(NowPlayingScreen.screen)
    end if
    if NowPlayingScreen.previousArtistImage <> invalid
      NowPlayingScreen.previousArtistImage.Draw(NowPlayingScreen.screen)
    end if


		'Album
    NowPlayingScreen.albumPlaceholder.Draw(NowPlayingScreen.screen)
    if NowPlayingScreen.albumImage <> invalid
      NowPlayingScreen.albumImage.Draw(NowPlayingScreen.screen)
      overlayColor = &h00000000
      if NowPlayingScreen.song.DoesExist("color")
        overlayColor = CreateOverlayColor(NowPlayingScreen.song.color.hex)
      end if
      NowPlayingScreen.screen.DrawRect(780, 230, 180, 180, overlayColor)
    end if
    if NowPlayingScreen.previousAlbumImage <> invalid
      NowPlayingScreen.previousAlbumImage.Draw(NowPlayingScreen.screen)
    end if

		'LastFM Logo
    if GetGlobalAA().ActiveLastFM <> 0 THEN
		  NowPlayingScreen.screen.DrawObject(NowPlayingScreen.screen.GetWidth() - 70 ,NowPlayingScreen.screen.GetHeight() - 50, NowPlayingScreen.lastfmlogo, &hFFFFFFFF)
    end if

    'Popularity image
    if NowPlayingScreen.PopularityImage <> invalid AND NowPlayingScreen.artistimage <> invalid
      NowPlayingScreen.screen.DrawObject(ResolutionX(NowPlayingScreen.artistimage.horizontalOffset + 130), ResolutionY(NowPlayingScreen.artistimage.verticalOffset + 83) + NowPlayingScreen.artistimage.height , NowPlayingScreen.PopularityImage, &hFFDDDD55)
    end if

    'Possible UI Elements
    if NowPlayingScreen.popup <> invalid then
      NowPlayingScreen.popup.draw(NowPlayingScreen.screen)
    End if

    if NowPlayingScreen.OtherStationsNowPlaying <> invalid
      NowPlayingScreen.OtherStationsNowPlaying.Draw(NowPlayingScreen.screen)
    end if

		NowPlayingScreen.screen.SwapBuffers()
	end if

End Function

Function RefreshNowPlayingScreen()

  NowPlayingScreen = GetNowPlayingScreen()

  song = NowPlayingScreen.song
  
  GetGlobalAA().lastSongTitle = invalid
  NowPlayingScreen.PopularityImage = invalid

  if NowPlayingScreen.artistImage <> invalid
    if SupportsAdvancedFeatures()
      NowPlayingScreen.previousArtistImage = NowPlayingScreen.artistImage
      NowPlayingScreen.previousArtistImage.FadeIn()
    end if
    NowPlayingScreen.artistImage.FadeOut()
  end if

  if NowPlayingScreen.albumImage <> invalid
    if SupportsAdvancedFeatures()
      NowPlayingScreen.previousAlbumImage = NowPlayingScreen.albumImage
      NowPlayingScreen.previousAlbumImage.FadeIn()
    end if
    NowPlayingScreen.albumImage.FadeOut()
  end if

  if NowPlayingScreen.BackgroundImage <> invalid
    if SupportsAdvancedFeatures()
      NowPlayingScreen.PreviousBackgroundImage = NowPlayingScreen.BackgroundImage
      NowPlayingScreen.PreviousBackgroundImage.FadeOut()
    end if
  end if
  
  NowPlayingScreen.UpdateBackgroundImage = "true"
  NowPlayingScreen.UpdateArtistImage = "true"
  NowPlayingScreen.UpdateAlbumImage = "true"

  NowPlayingScreen.ArtistPlaceholder = ArtistImage("tmp:/" + makemdfive(song.StationImage))

  NowPlayingScreen.stationTitle = song.stationName
  
  RunGarbageCollector()
  UpdateScreen()

  if song.metadataFault <> true AND song.artist <> invalid AND song.title <> invalid
    Analytics_TrackChanged(song.artist, song.title, song.stationName)
  end if
End Function

Function GetNowPlayingTimer()
	timer = GetGlobalAA().lookup("NowPlayingTimer")
	if timer = invalid then
		timer = CreateObject("roTimespan")
		GetGlobalAA().AddReplace("NowPlayingTimer", timer)
	endif

	return timer
End Function

Function DrawStationDetailsLabel(NowPlayingScreen as object)

    if NowPlayingScreen.song.stationDetails <> invalid then
      stationListeners = NowPlayingScreen.song.stationDetails.Listeners
      stationBitrate = NowPlayingScreen.song.stationDetails.bitrate

      if NowPlayingScreen.song.StationDetails.updated
        NowPlayingScreen.stationDetailsLabel = StationDetailsLabel(stationListeners, stationBitrate)
        NowPlayingScreen.song.StationDetails.updated = false
      end if

      NowPlayingScreen.stationDetailsLabel.draw(NowPlayingScreen.screen)
    end if
End Function

Function DrawHelpLabel(NowPlayingScreen as Object)

      if NowPlayingScreen.HelpLabel = invalid
        NowPlayingScreen.HelpLabel = RlText("Press OK for help", GetExtraSmallFont(), &hFFFFFF77, ResolutionX(1150), ResolutionY(60))
      end if

      NowPlayingScreen.HelpLabel.draw(NowPlayingScreen.screen)
End Function