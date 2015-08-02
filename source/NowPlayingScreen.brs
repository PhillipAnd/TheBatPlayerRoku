'Called only once when the Now Playing screen is displayed
Function CreateNowPlayingScreen() as Object

  Analytics = GetSession().Analytics
  Analytics.ViewScreen("Now Playing")

	NowPlayingScreen = CreateObject("roAssociativeArray")

  NowPlayingScreen.Width = GetSession().deviceInfo.GetDisplaySize().w
  NowPlayingScreen.Height = GetSession().deviceInfo.GetDisplaySize().h

	NowPlayingScreen.headerFont = GetHeaderFont()
  NowPlayingScreen.boldFont = GetLargeFont()
  NowPlayingScreen.defaultFont = GetMediumFont()
  NowPlayingScreen.smallFont = GetSmallFont()
  NowPlayingScreen.songNameFont = GetSongNameFont()
  NowPlayingScreen.genreFont = GetGenreFont()

  NowPlayingScreen.HeaderLogo = CreateObject("roBitmap", "pkg:/images/bat.png")
  NowPlayingScreen.HeaderHeight = ResolutionY(90)
  NowPlayingScreen.HeaderGrunge =  RlGetScaledImage(CreateObject("roBitmap", "pkg:/images/header-grunge.png"), NowPlayingScreen.Width, NowPlayingScreen.HeaderHeight, 1)
  NowPlayingScreen.StationDetailsLabel = invalid
  NowPlayingScreen.StationTitleLabel = invalid

  NowPlayingScreen.BackgroundImage = invalid
  NowPlayingScreen.PreviousBackgroundImage = invalid
  NowPlayingScreen.BackgroundGrunge = RlGetScaledImage(CreateObject("roBitmap", "pkg:/images/background-grunge.png"), GetSession().deviceInfo.GetDisplaySize().w, GetSession().deviceInfo.GetDisplaySize().h, 1)

  NowPlayingScreen.GradientTop = CreateObject("roBitmap", "pkg:/images/background-gradient-overlay-top.png")
  NowPlayingScreen.GradientBottom = CreateObject("roBitmap", "pkg:/images/background-gradient-overlay-bottom.png")

  NowPlayingScreen.albumImage = invalid
  NowPlayingScreen.previousAlbumImage = invalid

  NowPlayingScreen.ArtistImage = invalid
  NowPlayingScreen.previousArtistImage = invalid

  NowPlayingScreen.lastfmlogo = CreateObject("roBitmap", "pkg:/images/audioscrobbler_black.png")
  NowPlayingScreen.albumPlaceholder = AlbumImage("pkg:/images/album-placeholder.png", 780, 240, false, 240, 0, false)
  NowPlayingScreen.AlbumShadow = RlGetScaledImage(CreateObject("roBitmap", "pkg:/images/album-shadow.png"), ResolutionX(200), ResolutionY(200), 1)

  NowPlayingScreen.UpdateBackgroundImage = true
  NowPlayingScreen.UpdateArtistImage = true
  NowPlayingScreen.UpdateAlbumImage = true

  NowPlayingScreen.ScrobbleTimer = invalid
  NowPlayingScreen.NowPlayingOtherStationsTimer = invalid

  NowPlayingScreen.popup = invalid
  NowPlayingScreen.loadingScreen = invalid

  NowPlayingScreen.screen = invalid
  NowPlayingScreen.NowPlayingOtherStationsTimer = CreateObject("roTimespan")


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

  albumTitle = ""
  bioText = ""
  songTitle = ""
  genreText = ""

  if NowPlayingScreen.screen = invalid
    screen = CreateObject("roScreen", true, NowPlayingScreen.Width, NowPlayingScreen.Height)
    NowPlayingScreen.screen = screen

    screen.setalphaenable(true)
    screen.SetMessagePort(GetPort())
    screen.Clear(&h000000FF)

    GetGlobalAA().IsStationSelectorDisplayed = false
    GetGlobalAA().IsStationLoadingDisplayed = false
  end if

	song = NowPlayingScreen.song

  if song = invalid
    return false
  end if

  'Lighting
  if GetGlobalAA().lookup("song") <> song.Title AND song.DoesExist("image") AND song.image.DoesExist("color") AND song.image.color <> invalid AND song.image.color.DoesExist("rgb") then
    SetLightsToColor(song.image.color.rgb)
  end if

	GetGlobalAA().AddReplace("song", song.title)

  'No image?
  if NOT song.DoesExist("image") then
    song.image = CreateObject("roAssociativeArray")
  end if

  if NOT song.image.DoesExist("color") OR song.image.color.rgb = invalid OR song.image.color.hex = invalid
    song.image.color = CreateObject("roAssociativeArray")
    song.image.color.hex = "#ffffffff"
  end if

  NowPlayingScreen.song.OverlayColor = CreateOverlayColor(song)

  'Artist Image
  if song.UseFallbackArtistImage = true
    NowPlayingScreen.artistImage = ArtistImage("tmp:/" + makemdfive(song.StationImage))
  else if isstr(song.artistimage) AND FileExists(makemdfive(song.artistimage)) then
    artistImageFilePath = "tmp:/" + makemdfive(song.artistimage)

    if artistImageFilePath <> invalid AND NowPlayingScreen.UpdateArtistImage = true then
      NowPlayingScreen.artistImage = ArtistImage(artistImageFilePath)

      if NowPlayingScreen.artistImage = invalid
        song.UseFallbackArtistImage = true
        NowPlayingScreen.UpdateArtistImage = true
      else
        NowPlayingScreen.UpdateArtistImage = false
      end if


    end if

  end if

  'Artist bio
  bioText = GetBioTextForSong(song)

  'Song Name
  if song.Title <> invalid then
 		songTitle = song.Title
  end if

  'Album Image
  if type(song.album) = "roAssociativeArray" AND song.album.DoesExist("name") AND song.album.name <> invalid AND FileExists("album-" + makemdfive(song.album.name + song.artist)) AND NowPlayingScreen.UpdateAlbumImage = true then
    albumImageFilePath = "tmp:/album-" + makemdfive(song.album.name + song.artist)
    NowPlayingScreen.albumImage = AlbumImage(albumImageFilePath, 780, 240, true, 250, CreateAlbumOverlayColor(song))
    NowPlayingScreen.UpdateAlbumImage = false
  endif

  if type(song.album) = "roAssociativeArray" AND song.album.DoesExist("name") AND song.album.name <> invalid
    'Album Name
    if (song.album.DoesExist("released") AND song.album.released <> invalid) then
      albumTitle = song.album.name + " (" + ToStr(song.album.released) + ")"
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
 	if FileExists(makemdfive(song.backgroundimage)) AND NowPlayingScreen.UpdateBackgroundImage <> false
    NowPlayingScreen.BackgroundImage = BackgroundImage("tmp:/" + makemdfive(song.backgroundimage))

    if NowPlayingScreen.BackgroundImage <> invalid
      NowPlayingScreen.BackgroundImage.FadeIn()
      NowPlayingScreen.PreviousBackgroundImage = invalid
    end if

    NowPlayingScreen.UpdateBackgroundImage = false
  else if song.UseFallbackBackgroundImage = true
    NowPlayingScreen.BackgroundImage = BackgroundImage("tmp:/" + makemdfive(song.hdposterurl))
  end if

	'Station Name
	stationTitle = ""
	if song.stationProvider <> song.stationName then
		NowPlayingScreen.stationTitle = song.stationName + " - " + song.stationProvider
	else if song.stationTitle <> invalid
		NowPlayingScreen.stationTitle = song.stationName
	end if
  headerTitleY = 28
  if NowPlayingScreen.song.stationDetails <> invalid AND NowPlayingScreen.song.stationDetails.Listeners <> invalid
    headerTitleY = 22
  end if
  NowPlayingScreen.StationTitleLabel = RlTextArea(NowPlayingScreen.stationTitle, NowPlayingScreen.headerFont, &hFFFFFFFF, 180, headerTitleY, NowPlayingScreen.screen.GetWidth() - 200, 90, 1, 1.0, "left", true)

  songNameHeight = GetTextHeight(songTitle, 580, NowPlayingScreen.songNameFont)
  artistNameLocation = 160 - songNameHeight
  songNameLocation = artistNameLocation + 45

  NowPlayingScreen.artistNameLabel = ArtistNameLabel(song.artist, artistNameLocation, NowPlayingScreen.boldFont, GetRegularColorForSong(song))
  NowPlayingScreen.songNameLabel = SongNameLabel(songTitle, song, songNameLocation, NowPlayingScreen.songNameFont, GetRegularColorForSong(song))
  NowPlayingScreen.albumNameLabel = DropShadowLabel(albumTitle, ResolutionX(675), ResolutionY(425), ResolutionX(400), ResolutionY(200), NowPlayingScreen.smallFont, GetBoldColorForSong(song), "center", 2, 2, 2)
  NowPlayingScreen.bioLabel = BatBioLabel(bioText, song)

  if NowPlayingScreen.artistImage <> invalid then verticalOffset = NowPlayingScreen.artistImage.verticalOffset else verticalOffset = 0

  if GetSession().deviceInfo.GetDisplaySize().W = 1280
    genreX = ResolutionX(120)
    genreY = 437 - verticalOffset
  else
    genreX = ResolutionX(120)
    genreY = ResolutionY(460)
  end if
  NowPlayingScreen.genresLabel = DropShadowLabel(genreText, genreX, genreY, ResolutionX(490), ResolutionY(30), NowPlayingScreen.genreFont, GetRegularColorForSong(song), "center", 1, 2, 2, false)
  onTourText = ""
  if song.isOnTour = true
    onTourText = "On Tour"
  end if

  if NowPlayingScreen.artistImage <> invalid then horizontalOffset = NowPlayingScreen.artistImage.horizontalOffset else horizontalOffset = 0
  NowPlayingScreen.onTourLabel = RlTextArea(onTourText, NowPlayingScreen.smallFont, &hFFFFFF00 + 100, ResolutionX(120 + horizontalOffset + 5), ResolutionY(125 + verticalOffset), 300, 50, 1, 1.0, "left")

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

  if GetGlobalAA().IsStationSelectorDisplayed = true
    return false
  end if

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

    'Overlays
    NowPlayingScreen.screen.DrawObject(NowPlayingScreen.albumPlaceholder.x + 4,NowPlayingScreen.albumPlaceholder.y + 5,NowPlayingScreen.AlbumShadow)
    if NowPlayingScreen.song.OverlayColor <> invalid
      NowPlayingScreen.screen.DrawRect(0, 0, NowPlayingScreen.Width, NowPlayingScreen.Height, NowPlayingScreen.song.OverlayColor) 'Color overlay
    end if
    NowPlayingScreen.screen.DrawObject(0,0,NowPlayingScreen.BackgroundGrunge, &hFFFFFF00 + 65)
    NowPlayingScreen.screen.DrawRect(0, 0, NowPlayingScreen.Width, NowPlayingScreen.Height, &h00000000 + 200) 'Black overlay
    NowPlayingScreen.screen.DrawObject(0, 0, NowPlayingScreen.GradientTop, &hFFFFFF + 140) 'Top Gradient
    NowPlayingScreen.screen.DrawObject(0, NowPlayingScreen.Height - 365, NowPlayingScreen.GradientBottom, &hFFFFFF + 255) 'Bottom Gradient

		'Header
    headerTitleY = 28
    if NowPlayingScreen.song.stationDetails <> invalid AND NowPlayingScreen.song.stationDetails.Listeners <> invalid
      headerTitleY = 22
    end if
    NowPlayingScreen.screen.DrawObject(0,0,NowPlayingScreen.HeaderGrunge, &hFFFFFF00 + 55)
		NowPlayingScreen.screen.DrawRect(0,0, NowPlayingScreen.Width, NowPlayingScreen.HeaderHeight, GetHeaderColor())
		NowPlayingScreen.screen.DrawObject(ResolutionX(30),ResolutionY(13),NowPlayingScreen.HeaderLogo)
    NowPlayingScreen.StationTitleLabel.Draw(NowPlayingScreen.screen)

    DrawStationDetailsLabel(NowPlayingScreen)
    DrawHelpLabel(NowPlayingScreen)

		'Artist
    if NowPlayingScreen.artistImage <> invalid
      NowPlayingScreen.artistImage.Draw(NowPlayingScreen.screen)
    end if
    if NowPlayingScreen.previousArtistImage <> invalid
      NowPlayingScreen.previousArtistImage.Draw(NowPlayingScreen.screen)
    end if

    'All the text
    NowPlayingScreen.artistNameLabel.draw(NowPlayingScreen.screen)
    NowPlayingScreen.songNameLabel.draw(NowPlayingScreen.screen)
    NowPlayingScreen.bioLabel.draw(NowPlayingScreen.screen)
    if NowPlayingScreen.genresLabel <> invalid
      NowPlayingScreen.genresLabel.draw(NowPlayingScreen.screen)
    end if


		'Album
    NowPlayingScreen.albumPlaceholder.Draw(NowPlayingScreen.screen)
    if NowPlayingScreen.albumImage <> invalid
      NowPlayingScreen.albumImage.Draw(NowPlayingScreen.screen)
    end if
    if NowPlayingScreen.previousAlbumImage <> invalid
      NowPlayingScreen.previousAlbumImage.Draw(NowPlayingScreen.screen)
    end if
    if NowPlayingScreen.albumNameLabel <> invalid
      NowPlayingScreen.albumNameLabel.draw(NowPlayingScreen.screen)
    end if

		'LastFM Logo
    if GetGlobalAA().ActiveLastFM <> 0 THEN
		  NowPlayingScreen.screen.DrawObject(NowPlayingScreen.screen.GetWidth() - 80 ,NowPlayingScreen.screen.GetHeight() - 60, NowPlayingScreen.lastfmlogo, &hFFFFFFFF)
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

  if GetGlobalAA().IsStationSelectorDisplayed = true
    return false
  end if

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

  NowPlayingScreen.UpdateBackgroundImage = true
  NowPlayingScreen.UpdateArtistImage = true
  NowPlayingScreen.UpdateAlbumImage = true

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

      if NowPlayingScreen.song.StationDetails.updated AND stationListeners <> invalid AND stationBitrate <> invalid
        NowPlayingScreen.stationDetailsLabel = StationDetailsLabel(stationListeners, stationBitrate)
        NowPlayingScreen.song.StationDetails.updated = false
      end if

      if NowPlayingScreen.stationDetailsLabel <> invalid
        NowPlayingScreen.stationDetailsLabel.draw(NowPlayingScreen.screen)
      end if
    end if
End Function

Function DrawHelpLabel(NowPlayingScreen as Object)

      if NowPlayingScreen.HelpLabel = invalid
        NowPlayingScreen.HelpLabel = RlText("Press OK for help", GetExtraSmallFont(), &hFFFFFF77,  NowPlayingScreen.Width - 140, ResolutionY(70))
      end if

      NowPlayingScreen.HelpLabel.draw(NowPlayingScreen.screen)
End Function
