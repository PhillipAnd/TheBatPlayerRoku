Function ListStations()
  print "------ Displaying Station Selector ------"
  StationSelectionScreen = StationSelectionScreen()

End Function

Function StationSelectionScreen()

  this = {
    Stations: GetStations()
    SelectableStations: invalid
    Screen: CreateObject("roGridScreen")
    SelectedIndex: 0
    RefreshStations: selection_getStations

    SomaFMStations: invalid
    GetSomaFMStations: selection_getSomaFMStations

    DIStations: invalid
    GetDIStations: selection_getDIStations

    FeaturedStations: invalid
    GetFeaturedStations: selection_getFeaturedStations

    DisplayStationPopup: selection_showDirectoryPopup
    Handle: selection_handle
  }

  this.Screen.SetGridStyle("two-row-flat-landscape-custom")
  'this.Screen.SetDescriptionVisible(false)
  'this.Screen.SetUpBehaviorAtTopRow("stop")
  'this.Screen.SetBreadcrumbEnabled(false)
  this.Screen.SetLoadingPoster("pkg:/images/icon-hd.png", "pkg:/images/icon-sd.png")

  this.Screen.SetupLists(4)
  this.Screen.SetListName(0, "Your Stations")
  this.Screen.SetListName(1, "Stations from SomaFM")
  this.Screen.SetListName(2, "Stations from Digitally Imported")
  this.Screen.SetListName(3, "Featured Stations")

  this.Screen.SetListVisible(0, true)
  this.Screen.SetListVisible(1, false)
  this.Screen.SetListVisible(2, false)
  this.Screen.SetListVisible(3, false)

  port = GetPort()
  this.Screen.SetMessagePort(port)

  this.Screen.Show()

  GetGlobalAA().IsStationSelectorDisplayed = true
  GetGlobalAA().delete("screen")
  GetGlobalAA().delete("song")
  GetGlobalAA().Delete("jsonEtag")
  GetGlobalAA().lastSongTitle = invalid

  this.Screen.SetContentList(0,this.Stations)
  GetGlobalAA().AddReplace("StationSelectionScreen", this)

  this.RefreshStations()
  this.GetSomaFMStations()
  this.GetDIStations()
  this.GetFeaturedStations()

  HandleInternetConnectivity()

  'First launch popup
  if RegRead("initialpopupdisplayed", "batplayer") = invalid
    Analytics = GetSession().Analytics
    Analytics.AddEvent("First Session began")
    ShowConfigurationMessage(StationSelectionScreen)
  end if

  return this
End Function

Function selection_getStations()
  print "------ Updating list of stations ------"
  SelectableStations = CreateObject("roArray", m.Stations.Count(), true)

  for i = 0 to m.Stations.Count()-1

      station = m.Stations[i]
      stationObject = CreateSong(station.name,station.provider,"", station.format, station.stream, station.image)
      SelectableStations.Push(stationObject)

      'Download custom poster images
      if NOT FileExists(makemdfive(stationObject.hdposterurl))
        AsyncGetFile(stationObject.hdposterurl, "tmp:/" + makemdfive(stationObject.hdposterurl))
      end if
      if NOT FileExists(makemdfive(stationObject.stationimage))
        AsyncGetFile(stationObject.stationimage, "tmp:/" + makemdfive(stationObject.stationimage))
      end if
      m.Screen.SetContentList(0, SelectableStations)
      m.SelectableStations = SelectableStations
      FetchMetadataForStreamUrlAndName(station.stream, station.name, true, i)
  end for

  m.Stations = SelectableStations
End Function

Function selection_getSomaFMStations()
  url = "https://s3-us-west-2.amazonaws.com/batserver-static-assets/directory/somaFMStations.json"
  stations = GetStationsAtUrl(url)

  m.Screen.SetContentList(1, stations)
  m.Screen.SetListVisible(1, true)

  m.SomaFMStations = stations
End Function

Function selection_getDIStations()
  url = "https://s3-us-west-2.amazonaws.com/batserver-static-assets/directory/diStations.json"
  stations = GetStationsAtUrl(url)

  m.Screen.SetContentList(2, stations)
  m.Screen.SetListVisible(2, true)

  m.DIStations = stations
End Function

Function selection_getFeaturedStations()
  url = "https://s3-us-west-2.amazonaws.com/batserver-static-assets/directory/featured.json"
  stations = GetStationsAtUrl(url)

  m.Screen.SetContentList(3, stations)
  m.Screen.SetListVisible(3, true)

  m.FeaturedStations = stations
End Function

Function GetStationsAtUrl(url as String) as object
  Request = GetRequest()
  Request.SetUrl(url)
  jsonString = Request.GetToString()
  stationsJsonArray = ParseJSON(jsonString)

  stationsArray = CreateObject("roArray", stationsJsonArray.count() -1, true)

  for i = 1 to stationsJsonArray.Count()-1
    singleStation = stationsJsonArray[i]
    singleStationItem = CreateSong(singleStation.name, singleStation.provider, "", "mp3", "", singleStation.image)
    singleStationItem.playlist = singleStation.playlist
    stationsArray.push(singleStationItem)
  end for

  return stationsArray
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
    url = imageLocation
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
    StationSelectionScreen = GetGlobalAA().StationSelectionScreen
    Stations = GetGlobalAA().StationSelectionScreen.SelectableStations
    Screen = GetGlobalAA().StationSelectionScreen.Screen

    if track <> invalid AND index <> invalid

      if NOT isnonemptystr(track)
        return false
      end if

      station = Stations[index]
      station.Description = track
      Screen.SetContentListSubset(0, Stations, index, 1)
    end if

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
                    RefreshStationScreen()
                    exit while
                end if
            else if msg.isScreenClosed()
                exit while
            end if
        end if
    end while
End Function

Function selection_showDirectoryPopup(station as object)
  'Analytics = GetSession().Analytics
  'Analytics.AddEvent("Directory Popup Displayed")

  port = GetPort()

  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle(station.stationname)
  dialog.SetText("Add or Play this station.")

  dialog.AddButton(1, "Play")
  dialog.AddButton(2, "Add Station")
  dialog.EnableBackButton(true)

  dialog.Show()

  While True
      msg = port.GetMessage()
      HandleWebEvent(msg) 'Because we created a standalone event loop I still want the web server to respond, so send over events.

      If type(msg) = "roMessageDialogEvent"
          if msg.isButtonPressed()
            if msg.GetIndex() = 2
                ' Add Station'
              else if msg.GetIndex() = 1
                ' Play Station
                updatedStation = GetDirectoryStation(station)
                dialog.close()
                PlayStation(updatedStation)
                exit while
              end if

              dialog.ShowBusyAnimation()
              'RefreshStationScreen()
              exit while

          else if msg.isScreenClosed()
              exit while
          end if
      end if
  end while

End Function

Function selection_handle(msg as Object)

	if GetGlobalAA().IsStationSelectorDisplayed <> true
		return false
	end if

  row = msg.GetIndex()
  item = msg.GetData()

	if msg.isListItemSelected()
    'print row
    if row = 0
		  GetGlobalAA().IsStationSelectorDisplayed = false

      m.SelectedIndex = item
      Station = m.SelectableStations[item]
      PlayStation(Station)
    else
      station = m.SomaFMStations[item]
      m.DisplayStationPopup(station)
    end if
  else if msg.isListItemFocused()
    ' Hide now playing bubble'
    if row <> 0
      m.Screen.SetDescriptionVisible(false)
    else
      m.Screen.SetDescriptionVisible(true)
    end if

	end if

End Function

Function RefreshStationScreen()
  StationSelectionScreen = GetGlobalAA().StationSelectionScreen
  StationSelectionScreen.Stations = GetStations()
  StationSelectionScreen.RefreshStations()
End Function
