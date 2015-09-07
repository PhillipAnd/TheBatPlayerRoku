Function GetBioTextForSong(song as Object) as string
	bioText = ""

    if (song.DoesExist("bio") and song.bio <> invalid and song.bio.DoesExist("published")) AND song.bio.published <> invalid
      publishedYear = ToStr(song.bio.published)
      bioText = song.bio.text + " (" + publishedYear + ")"
    else if song.DoesExist("bio") and song.bio <> invalid
      bioText = song.bio.text
    endif
	if bioText <> invalid
    return HtmlEntityDecode(bioText)
	else
		return ""
	end if
End Function

Function GetTextHeight(text as string, width as integer, font as Object) as integer
  lines = 0
  singleLineWidth = font.GetOneLineWidth(text, 999999)
  if singleLineWidth > width
    lines = 2
  else
    lines = 1
  end if

  return (lines * (font.GetOneLineHeight() - 4))
End Function

Function DisplayHelpPopup()
  DisplayPopup("* to toggle LastFM Scrobbling. UP and DOWN to adjust the lighting brightness. Left to add to your Rdio Playlist.", &hFFFFFFFF, &h000000FF, 5)
End Function


Sub StationDetailsLabel(listeners as String, bitrate as String) as Object
    text = ""

    font = GetExtraSmallFont()

    if listeners <> "" AND bitrate <> ""
      text = "This server: " + listeners + " listeners " + bitrate + "kbps"
    end if

    label = RlTextArea(text, font, &hEEEEEEEE, 182, ResolutionY(68), 300, 50, 1, 1, "left", false, false)
    return label
End Sub

Function ResolutionX(x as Integer) as Integer
	deviceSize = GetSession().deviceInfo.GetDisplaySize()
	ratio = deviceSize.W / 1280
	return x * ratio
End Function

Function ResolutionY(y as Integer) as Integer
	deviceSize = GetSession().deviceInfo.GetDisplaySize()
	ratio = deviceSize.H / 710
	return y * ratio
End Function
