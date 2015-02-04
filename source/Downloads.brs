Function DownloadBackgroundImageForSong(song as object)
    url = song.stationimage

    if song.DoesExist("image") AND isnonemptystr(song.image.backgroundurl)
      url = song.image.backgroundurl
      print url
    end if

    AsyncGetFile(url,"tmp:/colored-" + makemdfive(song.Artist))

End Function

Function DownloadArtistImageForSong(song as object)
  url = song.stationimage

  'url = GetConfig().ApiHost + "artistImage.php?url=" + UrlEncode(song.image.url)

	if song.image.DoesExist("color") AND song.image.color.DoesExist("rgb")
    url = song.image.url
  end if
  AsyncGetFile(url, "tmp:/artist-" + makemdfive(song.Artist))
End Function
