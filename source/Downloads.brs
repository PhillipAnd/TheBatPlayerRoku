Function DownloadBackgroundImageForSong(song as object)
    if song.DoesExist("image") AND isnonemptystr(song.image.url)

      if song.image.DoesExist("color") AND song.image.color.DoesExist("rgb")
        ColorFilter = right(ToStr(song.image.color.rgb.red),3) + "," + right(ToStr(song.image.color.rgb.green),3) + "," + right(ToStr(song.image.color.rgb.blue),3)
      else
        ColorFilter = "255,255,255"
      end if

      FilteredImageUrl = "http://cdn.thebatplayer.fm/mp3info/imageFilter.hh?url=" + song.image.url + "&filter=grayscale&colorize=" + ColorFilter
      AsyncGetFile(FilteredImageUrl,"tmp:/colored-" + makemdfive(song.Artist))
    end if
End Function

Function DownloadArtistImageForSong(song as object)
  url = "http://cdn.thebatplayer.fm/mp3info/artistImage.php?url=" + UrlEncode(song.image.url)

	if song.image.DoesExist("color") AND song.image.color.DoesExist("rgb")
		ColorFilter = right(ToStr(song.image.color.rgb.red),3) + "," + right(ToStr(song.image.color.rgb.green),3) + "," + right(ToStr(song.image.color.rgb.blue),3)
		url = url + "&color=" + ColorFilter
	end if

  AsyncGetFile(url, "tmp:/artist-" + makemdfive(song.Artist))

End Function