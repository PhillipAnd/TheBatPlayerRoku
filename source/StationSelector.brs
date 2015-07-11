Function ListStations()
    print "------ Displaying Station Selector ------"

    GetGlobalAA().IsStationSelectorDisplayed = true
    GetGlobalAA().delete("screen")
    GetGlobalAA().delete("song")
    GetGlobalAA().Delete("jsonEtag")
    GetGlobalAA().lastSongTitle = invalid

    StationSelectionScreen = CreateObject("roGridScreen")
    StationSelectionScreen.SetGridStyle("two-row-flat-landscape-custom")
    StationSelectionScreen.SetDescriptionVisible(true)
    StationSelectionScreen.SetUpBehaviorAtTopRow("stop")
    StationSelectionScreen.SetBreadcrumbEnabled(false)
    StationSelectionScreen.SetLoadingPoster("pkg:/images/icon-hd.png", "pkg:/images/icon-sd.png")
    port = GetPort()
    StationSelectionScreen.SetMessagePort(port)
    GetGlobalAA().AddReplace("StationSelectionScreen", StationSelectionScreen)


    StationSelectionScreen.SetupLists(1)
    StationSelectionScreen.SetListName(0, "Stations")

    UpdateStations()
    HandleInternetConnectivity()
    StationSelectionScreen.Show()

    'First launch popup
    if RegRead("initialpopupdisplayed", "batplayer") = invalid
        Analytics = GetSession().Analytics
        Analytics.AddEvent("First Session began")
        ShowConfigurationMessage(StationSelectionScreen)
    end if

    Return -1

End Function

Function UpdateStations()
  print "------ Updating list of stations ------"
  StationSelectionScreen = GetGlobalAA().StationSelectionScreen
  stationsArray = GetStations()
  SelectableStations = CreateObject("roArray", stationsArray.Count(), true)

  for i = 0 to stationsArray.Count()-1

      station = stationsArray[i]
      stationObject = CreateSong(station.name,station.provider,"", station.format, station.stream, station.image)
      SelectableStations.Push(stationObject)

      'Download custom poster images
      if NOT FileExists(makemdfive(stationObject.hdposterurl))
        AsyncGetFile(stationObject.hdposterurl, "tmp:/" + makemdfive(stationObject.hdposterurl))
      end if
      if NOT FileExists(makemdfive(stationObject.stationimage))
        AsyncGetFile(stationObject.stationimage, "tmp:/" + makemdfive(stationObject.stationimage))
      end if

      FetchMetadataForStreamUrlAndName(station.stream, station.name, true, i)
  end for

  GetGlobalAA().AddReplace("SelectableStations", SelectableStations)
  StationSelectionScreen.SetContentList(0, SelectableStations)
End Function

Function HandleInternetConnectivity()
  internetConnection = GetSession().deviceInfo.GetLinkStatus()
  if internetConnection = false
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(GetPort())
    dialog.SetTitle("Internet Required")
    dialog.SetText("The Bat Player requires an active internet connection.  Please bring your Roku online and re-launch The Bat Player.")

    dialog.AddButton(1, "OK")
    dialog.EnableBackButton(true)
    dialog.Show()

    While True
      msg = wait(0, dialog.GetMessagePort())
      If type(msg) = "roMessageDialogEvent"
        if msg.isButtonPressed()
          if msg.GetIndex() = 1
            end
            exit while
          end if
        else if msg.isScreenClosed()
          end
          exit while
        end if
      end if
    end while

  end if

End Function

Function CreatePosterItem(id as string, desc1 as string, desc2 as string) as Object
    item = CreateObject("roAssociativeArray")
    item.ShortDescriptionLine1 = desc1
    item.ShortDescriptionLine2 = desc2
    return item
end Function

Function CreateSong(title as string, description as string, artist as string, streamformat as string, feedurl as string, imagelocation as string) as Object

    item = CreatePosterItem("", title, description)
    url = GetConfig().BatserverCDN + "images/resize/" + urlencode(imageLocation) + "/" + "266/150"
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

Function StationSelectorNowPlayingTrackReceived(track as dynamic, index as dynamic)

    if track <> invalid AND index <> invalid

      if NOT isnonemptystr(track)
        return false
      end if

        nowPlayingString = track

        StationList = GetGlobalAA().StationSelectionScreen
        SelectableStations = GetGlobalAA().SelectableStations
        station = SelectableStations[index]

        station.Description = nowPlayingString
        StationList.SetContentListSubset(0, SelectableStations, index, 1)
    end if

End Function

Function GetStationSelectionHeader()
    print "------ Downloading header ------"
    ipAddress = GetSession().IPAddress
    text = urlescape("Configure your Bat Player at http://" + ipAddress + ":9999")
    device = GetSession().deviceInfo
    width = ToStr(device.GetDisplaySize().w)
    url = GetConfig().BatserverCDN + "images/header/?text=" + text + "&width=" + width
    SyncGetFile(url, "tmp:/headerImage.jpg", true)
    print "------ Downloading header complete------"
End Function


Function ShowConfigurationMessage(StationSelectionScreen as object)
    Analytics = GetSession().Analytics
    Analytics.AddEvent("Configuration Popup Displayed")
    RegWrite("initialpopupdisplayed", "true", "batplayer")
    port = GetPort()
    ipAddress = GetSession().IPAddress

    message = "Thanks for checking out The Bat Player.  Jump on your computer and visit http://" + ipAddress + ":9999 to customize your Bat Player experience by adding stations, enabling lighting, Last.FM, Rdio support and more."

    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle("Configure Your Bat Player")
    dialog.SetText(message)

    dialog.AddButton(1, "OK")
    dialog.EnableBackButton(true)
    dialog.Show()
    While True
        msg = port.GetMessage()
        HandleWebEvent(msg) 'Because we created a standalone event loop I still want the web server to respond, so send over events.
        If type(msg) = "roMessageDialogEvent"
            if msg.isButtonPressed()
                if msg.GetIndex() = 1
                    Analytics.AddEvent("Configuration Popup Dismissed")
                    dialog.close()
                    UpdateStations()
                    exit while
                end if
            else if msg.isScreenClosed()
                exit while
            end if
        end if
    end while
End Function

Sub HandleStationSelector (msg as Object)

	if GetGlobalAA().IsStationSelectorDisplayed <> true
		return
	end if

	if msg.isScreenClosed()
		GetGlobalAA().IsStationSelectorDisplayed = false
		return
	end if


	if msg.isListItemSelected()
		GetGlobalAA().IsStationSelectorDisplayed = false

		StationList = GetGlobalAA().StationList

    selectionIndex = msg.GetData()

    Stations = GetGlobalAA().SelectableStations
    Station = Stations[selectionIndex]
		Analytics_StationSelected(Station.stationName, Station.feedurl)

		metadataUrl = GetConfig().Batserver + "metadata/" + UrlEncode(Station.feedurl)
		print "JSON for selected station: " + metadataUrl

    GetGlobalAA().AddReplace("SongObject", Station)
    Show_Audio_Screen(Station)
    DisplayStationLoading(Station)
	end if

End Sub
