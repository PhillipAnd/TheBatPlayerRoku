Sub SetTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "0"
    theme.OverhangOffsetSD_Y = "0"
    theme.OverhangSliceSD = "pkg:/images/selection_header_background.png"
    theme.OverhangLogoSD  = "pkg:/images/selection_bat_logo-SD.png"

    theme.OverhangOffsetHD_X = "60"
    theme.OverhangOffsetHD_Y = "20"
    theme.OverhangSliceHD = "pkg:/images/selection_header_background.png"
    theme.OverhangLogoHD  = "pkg:/images/selection_bat_logo-HD.png"

    theme.PosterScreenLine1Text = "#CC0000"
    theme.PosterScreenLine2Text = "#cA6c6c"

    theme.ListItemHighlightText = "#CC0000"
    theme.listItemText = "#CC0000"

    theme.BackgroundColor = "#000000" 

    theme.BreadcrumbTextRight = "Stations"
    app.SetTheme(theme)

End Sub

Function InitFonts()
	reg = CreateObject("roFontRegistry")
	Filesystem = CreateObject("roFilesystem")
	FontNameDir = "."
	DirectoryListing = Filesystem.GetDirectoryListing("pkg:/fonts/" + FontNameDir + "/")

	DirectoryListing.ResetIndex()
	i = DirectoryListing.GetIndex()
	while i <> invalid
		' print "Registering " + i
		reg.Register("pkg:/fonts/" + FontNameDir + "/" + i)
		i = DirectoryListing.GetIndex()
	end while

    GetGlobalAA().AddReplace("FontRegistry", reg)
    ' print reg.GetFamilies()
End Function

Function GetMediumFont() as Object
	reg = GetGlobalAA().FontRegistry
    Font = reg.GetFont("Calibri", ResolutionY(23), false, false)
    return Font
End Function

Function GetSongNameFont() as Object
	reg = GetGlobalAA().FontRegistry
    Font = reg.GetFont("Calibri", ResolutionY(28), false, false)
    return Font
End Function

Function GetSmallFont() as Object
	reg = GetGlobalAA().FontRegistry
    Font = reg.GetFont("Calibri", ResolutionY(21), false, false)
    return Font
End Function

Function GetExtraSmallFont() as Object
	reg = GetGlobalAA().FontRegistry
    Font = reg.GetFont("Calibri", ResolutionY(14), false, false)
    return Font
End Function

Function GetLargeBoldFont() as Object
	reg = GetGlobalAA().FontRegistry
    Font = reg.GetFont("Calibri", ResolutionY(42), true, false)
    return Font
End Function

Function GetHeaderFont() as Object
	reg = GetGlobalAA().FontRegistry
    Font = reg.GetFont("Calibri", ResolutionY(39), true, false)
    return Font
End Function

Function GetHeaderColor() as Integer
	return &h9b0000BC
End Function

Function GetBoldColorForSong(song as Object) as Integer
	' if NOT song.DoesExist("image") OR NOT song.image.DoesExist("color") OR NOT song.image.color.DoesExist("rgb") OR song.image.color.rgb.red = invalid OR song.image.color.rgb.green = invalid OR song.image.color.rgb.blue = invalid then
	' 	return MakeARGB(255,255,255,255)
	' else
	' 	return AlterSaturationForRGB(song.image.color.rgb.red, song.image.color.rgb.green, song.image.color.rgb.blue, 255, 2.2)	
	' end if
	return GetRegularColorForSong(song)
End Function

Function GetRegularColorForSong(song as Object) as Integer
	if NOT song.DoesExist("image") OR NOT song.image.DoesExist("color") OR NOT song.image.color.DoesExist("rgb") OR song.image.color.rgb.red = invalid OR song.image.color.rgb.green = invalid OR song.image.color.rgb.blue = invalid then
		return MakeARGB(255,255,255,255)
	else
	  	targetBrightness = 200
	  	targetContrast = 160
	  	red = song.image.color.rgb.red
	  	green = song.image.color.rgb.green
	  	blue = song.image.color.rgb.blue
	  	alpha = 255

	  	brightness = GetBrightnessForSong(song)
	  	if brightness > 150
	  		alpha = 220
	  	end if

	  	if brightness < 25
		  	brightnessOffset = (targetBrightness / brightness)
		  	updatedColors = AlterBrightnesForRGB(red, green, blue, brightnessOffset/3)
		  	red = updatedColors[0]
		  	green = updatedColors[1]
		  	blue = updatedColors[2]
		  	return AlterSaturationForRGB(red, green, blue, alpha, 1.0)
		 end if

		Contrast = SQR(red * red * 0.241 + green * green * 0.691 + blue * blue * 0.068)
		contrastOffset = (targetContrast / Contrast)

		 if Contrast < targetContrast
			return AlterSaturationForRGB(red, green, blue, alpha, 1.9)	
		else 
			return AlterSaturationForRGB(red, green, blue, alpha, 1.2)	
		end if
	end if
End Function

Function GetBrightnessForSong(song as Object) as Integer
	if song.brightness <> 0
		return song.brightness
	end if

	if song.DoesExist("image") AND song.image.DoesExist("color") AND song.image.color.DoesExist("rgb")
	  	red = song.image.color.rgb.red
	  	green = song.image.color.rgb.green
	  	blue = song.image.color.rgb.blue

		brightness = (0.2126 *red + 0.7152 *green + 0.0722*blue)
		song.brightness = brightness
		return brightness
	else
		return 0
	end if
End Function

Function GetDropShadowColorForSong(song as Object) as integer

	brightness = GetBrightnessForSong(song)
	
	if brightness < 40 AND brightness <> 0 AND brightness > 25
		dropShadowColor = &h99999944'&hF0C2B210
	else 
		dropShadowColor = &h000000FF
	end if

	return dropShadowColor
End Function

Sub CreateOverlayColor(song) as integer
	if song.DoesExist("image") AND song.image.DoesExist("color") AND song.image.color.DoesExist("rgb")
		color = MakeARGB(song.image.color.rgb.red, song.image.color.rgb.green, song.image.color.rgb.blue, 0)
	else 
		color = 0
	end if
  return color
End Sub

Function AlterSaturationForRGB(red as Integer, green as Integer, blue as Integer, alpha as integer, amount as Integer) as Double
	gray = (red + green + blue) / 3

	R = RlMax(0,RlMin(red * amount + gray * (1 - amount), alpha))
	G = RlMax(0,RlMin(green * amount + gray * (1 - amount), alpha))
	B = RlMax(0,RlMin(blue * amount + gray * (1 - amount), alpha))

	return MakeARGB(R,G,B,alpha)
end Function

Function AlterBrightnesForRGB(red as Integer, green as Integer, blue as Integer, amount as Double) as Object
	red = red * amount'(amount / 0.299)
	green = green * amount'(amount / 0.587)
	blue = blue * amount'(amount / 0.114)

	updatedColors = CreateObject("roArray", 3, false)
	updatedColors[0] = RlMax(0, RlMin(red, 255))
	updatedColors[1] = RlMax(0, RlMin(green, 255))
	updatedColors[2] = RlMax(0, RlMin(blue, 255))
	return updatedColors
End Function

Function MakeARGB(r As integer, g As integer, b As integer, alpha as integer) As integer
  return r*256*256*256 + g*256*256 + b*256 + alpha
End Function

Function ResolutionX(x as Integer) as Integer
	deviceSize = GetSession().deviceInfo.GetDisplaySize()
	ratio = deviceSize.W / 1280
	' print "Display width: " + str(deviceSize.W)
	' print "X ratio: " + str(ratio)

	return x * ratio
End Function

Function ResolutionY(y as Integer) as Integer
	deviceSize = GetSession().deviceInfo.GetDisplaySize()
	ratio = deviceSize.H / 720
	' print "Y ratio: " + str(ratio)

	return y * ratio
End Function