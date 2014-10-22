Function ListStations()
    GetGlobalAA().IsStationSelectorDisplayed = true
    GetGlobalAA().delete("screen")
    GetGlobalAA().delete("song")
    GetGlobalAA().lastSongTitle = invalid

    StationList = CreateObject("roGridScreen")
    port = GetPort()
    StationList.SetMessagePort(port)

    stationsArray = GetStations()
    
    StationList.SetupLists(1)
    StationList.SetListName(0, "Stations")


    stations = CreateObject("roArray", stationsArray.Count(), true)
    for i = 0 to stationsArray.Count()-1
        station = stationsArray[i]

        stationObject = CreateObject("roAssociativeArray")
        stationObject.ContentType = "episode"
        stationObject.Title = "Test"
        stationObject.ShortDescriptionLine1 = "[ShortDescriptionLine1]"
        stationObject.ShortDescriptionLine2 = "[ShortDescriptionLine2]"
        stations.Push(stationObject)
    end for
    StationList.SetContentList(0, Stations)

    ' rowTitles = CreateObject("roArray", stationsArray.Count(), true)
    ' stations = CreateObject("roArray", stationsArray.Count(), true)

    StationList.Show()
    GetGlobalAA().AddReplace("stationlist", StationList)
    GetGlobalAA().AddReplace("stationscreen", posterScreen)

    ' while true
    '      msg = wait(0, port)
    '      if type(msg) = "roGridScreenEvent" then
    '          if msg.isScreenClosed() then
    '              return -1
    '          elseif msg.isListItemFocused()
    '              print "Focused msg: ";msg.GetMessage();"row: ";msg.GetIndex();
    '              print " col: ";msg.GetData()
    '          elseif msg.isListItemSelected()
    '              print "Selected msg: ";msg.GetMessage();"row: ";msg.GetIndex();
    '              print " col: ";msg.GetData()
    '          endif
    '      endif
    '  end while    

End Function

' Function CreateGridObject(station as object)
'     gridItem = CreateObject("roAssociativeArray")
'     gridItem.Title = station.name
' End Function

Function CreatePosterItem(id as string, desc1 as string, desc2 as string) as Object
    item = CreateObject("roAssociativeArray")
    item.ShortDescriptionLine1 = desc1
    item.ShortDescriptionLine2 = desc2
    item.HDPosterUrl = "pkg:/images/" + id + "/Poster_Logo_HD.png"
    item.SDPosterUrl = item.HDPosterUrl
    return item
end Function

Function ListStationsOld()
    RunGarbageCollector()
    GetGlobalAA().IsStationSelectorDisplayed = true

    SetTheme()
    GetGlobalAA().lastSongTitle = invalid
    
    Analytics = GetSession().Analytics
    Analytics.ViewScreen("Station Selector")

    GetGlobalAA().delete("screen")
    GetGlobalAA().delete("song")
    GetGlobalAA().AddReplace("IsStationSelectorDisplayed", true)

    stationsArray = GetStations()

    StationList = CreateObject("roAssociativeArray")
    StationList.posteritems = CreateObject("roArray", stationsArray.Count(), true)

    genreStations = CreateObject("roAssociativeArray")
    genres = CreateObject("roArray", 10, true)

    for i=0 to stationsArray.Count() - 1
        singleStation = stationsArray[i]
        stationObject = CreateSong(singleStation.name,singleStation.provider,"", singleStation.format, singleStation.stream, singleStation.image)
        StationList.posteritems.push(stationObject)
        AsyncGetFile(singleStation.image, "tmp:/" + makemdfive(singleStation.image))

        ' for g=0 to singleStation.genres.Count()-1
        '     singleGenre = singleStation.genres[i]
        '     if genres[singleGenre] = invalid then
        '         genres.push(singleGenre)
        '     end if
        '     genreStations[singleGenre].push(singleStation)
        ' end for
    end for

    encoder = CreateObject("roUrlTransfer")
    ipAddress = GetIPAddress()
    bannerText = encoder.escape("Configure The Bat Player at http://" + ipAddress + ":9999")
    bannerUrl = "http://cdn.thebatplayer.fm/mp3info/textDraw.php?text=" + bannerText
    
    posterPort = GetPort()
    posterScreen = CreateObject("roPosterScreen")
    posterScreen.SetMessagePort(posterPort)
    posterScreen.SetListStyle("arced-landscape")
    posterScreen.SetListDisplayMode("scale-to-fill")
    posterScreen.SetListNames(genres)
    posterScreen.SetContentList(StationList.posteritems)
    posterScreen.SetBreadcrumbEnabled(false)
    posterScreen.SetTitle("Stations")
    posterScreen.SetLoadingPoster("pkg:/images/icon-hd.png", "pkg:/images/icon-hd.png")
    posterScreen.SetAdURL(bannerUrl,bannerUrl)
    posterScreen.SetAdDisplayMode("scale-to-fit")
    posterScreen.SetAdSelectable(true)
    posterScreen.Show()
    
    GetGlobalAA().AddReplace("stationlist", StationList)
    GetGlobalAA().AddReplace("stationscreen", posterScreen)

    if RegRead("initialpopupdisplayed", "batplayer") = invalid
        Analytics = GetSession().Analytics
        Analytics.AddEvent("First Session began")
        ShowConfigurationMessage(posterScreen)
    end if

End Function

Function ShowConfigurationMessage(stationSelectionScreen as object)
    Analytics = GetSession().Analytics
    Analytics.AddEvent("Configuration Popup Displayed")
    RegWrite("initialpopupdisplayed", "true", "batplayer")

    ipAddress = GetIPAddress()

    message = "Thanks for checking out The Bat Player.  Jump on your computer and visit http://" + ipAddress + ":9999 to customize your Bat Player experience."

    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(GetPort()) 
    dialog.SetTitle("Configure Your Bat Player")
    dialog.SetText(message)
 
    dialog.AddButton(1, "OK")
    dialog.EnableBackButton(true)
    dialog.Show()
    While True
        msg = wait(0, dialog.GetMessagePort())

        If type(msg) = "roMessageDialogEvent"
            if msg.isButtonPressed()
                if msg.GetIndex() = 1
                    Analytics.AddEvent("Configuration Popup Dismissed")
                    exit while
                end if
            else if msg.isScreenClosed()
                exit while
            end if
        end if
        HandleWebEvent(msg) 'Because we created a standalone event loop I still want the web server to respond, so send over events.
    end while 
End Function