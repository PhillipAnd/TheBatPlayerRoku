Function DownloadBackgroundImageForSong(song as object)
  url = song.backgroundimage
  AsyncGetFile(url,"tmp:/" + makemdfive(url))
End Function

Function DownloadArtistImageForSong(song as object)
  url = song.artistimage
  AsyncGetFile(url, "tmp:/" + makemdfive(url))
End Function
