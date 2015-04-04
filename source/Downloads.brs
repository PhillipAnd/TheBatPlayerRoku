Function AsyncGetFile(url as string, filepath as string) as Object
  if url <> invalid AND filepath <> invalid AND url <> "" then
    'Do we already have this file?
    FileSystem = CreateObject("roFileSystem")
    if FileSystem.Exists(filepath) = true then
      'We already have this file
      'print "*** It seems we already have file: " +url
    else
      Request = CreateObject("roUrlTransfer")
      Request.SetUrl(url)
      Request.SetPort(GetPort())
      Request.EnableEncodings(True)
      if Request.AsyncGetToFile(filepath) then
        Identity = ToStr(Request.GetIdentity())
        'print "Started download of: " + url + " to " + filepath ". " + Identity
        Downloads = GetSession().Downloads
        Downloads.AddReplace(Identity, Request)
        return Request
      else
        BatLog("***** Failure BEGINNING download.", "error")
        return invalid
      end if
    end if
  end if
End Function

Function SyncGetFile(url as string, filepath as string)
  if url <> invalid AND filepath <> invalid AND url <> "" then
    'Do we already have this file?
    FileSystem = CreateObject("roFileSystem")
    if FileSystem.Exists(filepath) = true then
      'We already have this file
      'print "*** It seems we already have file: " +url
    else
      Request = CreateObject("roUrlTransfer")
      Request.SetUrl(url)
      if Request.GetToFile(filepath) then
        'print "Started download of: " + url + " to " + filepath ". " + Identity
      else
        BatLog("***** Failure BEGINNING download.", "error")
        return invalid
      end if
    end if
  end if
End Function

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
