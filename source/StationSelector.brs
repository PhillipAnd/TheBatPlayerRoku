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

    GabeStations: invalid
    GetGabeStations: selection_getGabeStations

    DisplayStationPopup: selection_showDirectoryPopup
    Handle: selection_handle
  }

  this.Screen.SetGridStyle("two-row-flat-landscape-custom")
  this.Screen.SetLoadingPoster("pkg:/images/icon-hd.png", "pkg:/images/icon-sd.png")

  this.Screen.SetupLists(5)
  this.Screen.SetListName(0, "Your Stations")
  this.Screen.SetListName(1, "Stations from SomaFM")
  this.Screen.SetListName(2, "Stations from Digitally Imported")
  this.Screen.SetListName(3, "Featured Stations")
  this.Screen.SetListName(4, "Gabe's Current Favorites")

  this.Screen.SetListVisible(0, true)
  this.Screen.SetListVisible(1, false)
  this.Screen.SetListVisible(2, false)
  this.Screen.SetListVisible(3, false)
  this.Screen.SetListVisible(4, false)

  port = GetPort()
  this.Screen.SetMessagePort(port)

  GetGlobalAA().IsStationSelectorDisplayed = true
  GetGlobalAA().delete("screen")
  GetGlobalAA().delete("song")
  GetGlobalAA().Delete("jsonEtag")
  GetGlobalAA().lastSongTitle = invalid

  this.Screen.SetContentList(0,this.Stations)
  GetGlobalAA().AddReplace("StationSelectionScreen", this)


  this.RefreshStations()
  this.Screen.Show()

  this.GetSomaFMStations()
  this.GetDIStations()
  this.GetFeaturedStations()
  this.GetGabeStations()

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
      if station.DoesExist("stream") AND station.stream <> ""
        stationObject = CreateSong(station.name,station.provider,"", station.format, station.stream, station.image)
        SelectableStations.Push(stationObject)
        FetchMetadataForStreamUrlAndName(station.stream, station.name, true, i)

        'Download custom poster images
        if NOT FileExists(makemdfive(stationObject.hdposterurl))
          SyncGetFile(stationObject.hdposterurl, "tmp:/" + makemdfive(stationObject.hdposterurl))
        end if
        if NOT FileExists(makemdfive(stationObject.stationimage))
          SyncGetFile(stationObject.stationimage, "tmp:/" + makemdfive(stationObject.stationimage))
        end if

      end if
  end for

  m.Screen.SetContentList(0, SelectableStations)
  m.SelectableStations = SelectableStations

  m.Stations = SelectableStations
End Function

Function selection_getSomaFMStations()
  url = "https://s3-us-west-2.amazonaws.com/batserver-static-assets/directory/somaFMStations.json"
  stations = GetStationsAtUrl(url)

  m.Screen.SetContentList(1, stations)
  m.Screen.SetListVisible(1, true)

  m.SomaFMStations = stations
  RefreshStationScreen()
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

Function selection_getGabeStations()
  url = "https://s3-us-west-2.amazonaws.com/batserver-static-assets/directory/gabeFavorites.json"
  stations = GetStationsAtUrl(url)

  m.Screen.SetContentList(4, stations)
  m.Screen.SetListVisible(4, true)

  m.GabeStations = stations
End Function

Function GetStationsAtUrl(url as String) as object
  print "Fetching stations at: " + url
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
  Analytics = GetSession().Analytics
  Analytics.AddEvent("Directory Popup Displayed")

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
            updatedStation = GetDirectoryStation(station)

            if msg.GetIndex() = 2
                ' Add Station'
                stationObject = CreateObject("roAssociativeArray")
                stationObject.format = updatedStation.streamformat
                stationObject.image = updatedStation.stationimage
                stationObject.name = updatedStation.stationname
                stationObject.provider = updatedStation.stationprovider
                stationObject.stream = updatedStation.feedurl
                AddStation(stationObject)
              else if msg.GetIndex() = 1
                ' Play Station
                dialog.close()
                PlayStation(updatedStation)
                exit while
              end if

              dialog.ShowBusyAnimation()
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
      station = invalid

      if row = 1
        station = m.SomaFMStations[item]
      else if row = 2
        station = m.DIStations[item]
      else if row = 3
        station = m.FeaturedStations[item]
      else if row = 4
        station = m.GabeStations[item]
      end if

      if station <> invalid
        m.DisplayStationPopup(station)
      end if

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
