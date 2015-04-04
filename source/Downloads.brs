Function DownloadBackgroundImageForSong(song as object)
  url = song.backgroundimage
  request = AsyncGetFile(url,"tmp:/" + makemdfive(url))
  GetSession().BackgroundImageDownload = request
End Function

Function DownloadArtistImageForSong(song as object)
  url = song.artistimage
  request = AsyncGetFile(url, "tmp:/" + makemdfive(url))
  GetSession().ArtistImageDownload = request
End Function

Function IsDownloading(Identity as String) as Boolean
    Downloads = GetSession().Downloads
    return (Downloads.DoesExist(Identity))
End Function

Function IsBackgroundImageDownload(Identity as String) as Boolean
    if GetSession().BackgroundImageDownload = invalid
      return false
    end if

    BackgroundImageDownload = GetSession().BackgroundImageDownload
    BackgroundImageDownloadIdentity = ToStr(BackgroundImageDownload.GetIdentity())

    if BackgroundImageDownloadIdentity = invalid
      return false
    end if

    if Identity = BackgroundImageDownloadIdentity
      return true
    end if

    return false
End Function

Function IsArtistImageDownload(Identity as String) as Boolean
    if GetSession().ArtistImageDownload = invalid
      return false
    end if

    ArtistImageDownload = GetSession().ArtistImageDownload
    ArtistImageDownloadIdentity = ToStr(ArtistImageDownload.GetIdentity())

    if ArtistImageDownloadIdentity = invalid
      return false
    end if

    if Identity = ArtistImageDownloadIdentity
      return true
    end if

    return false

End Function
