Function DownloadBackgroundImageForSong(song as object)
  url = song.backgroundimage
  AsyncGetFile(url,"tmp:/colored-" + makemdfive(song.Artist))
End Function

Function DownloadArtistImageForSong(song as object)
  url = song.artistimage
  AsyncGetFile(url, "tmp:/artist-" + makemdfive(song.Artist))
End Function
