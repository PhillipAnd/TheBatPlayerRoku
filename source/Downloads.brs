Function AsyncGetFile(url as string, filepath as string, overrideFileCheck = false as Boolean) as Object
  if url <> invalid AND filepath <> invalid AND url <> "" then
    'Do we already have this file?
    FileSystem = CreateObject("roFileSystem")
    if FileSystem.Exists(filepath) = true AND overrideFileCheck = false then
      'We already have this file
      print "*** It seems we already have file: " +url
    else
      Request = CreateObject("roUrlTransfer")
      Request.SetUrl(url)
      Request.SetPort(GetPort())
      Request.EnableEncodings(True)
      Request.AddHeader("Accept-Encoding","deflate")
      Request.AddHeader("Accept-Encoding","gzip")
      if Request.AsyncGetToFile(filepath) then
        Identity = ToStr(Request.GetIdentity())
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
      Request.AddHeader("Accept-Encoding","deflate")
      Request.AddHeader("Accept-Encoding","gzip")
      Request.EnableEncodings(True)
      Request.EnableResume(true)
      Request.SetPort(GetPort())
      if Request.GetToFile(filepath) then
        print "Started download of: " + url + " to " + filepath ". "
      else
        BatLog("***** Failure BEGINNING download.", "error")
        return invalid
      end if
    end if
  end if
End Function

Function DownloadBackgroundImageForSong(song as object)
  url = song.backgroundimage
  if url <> invalid
    request = AsyncGetFile(url,"tmp:/" + makemdfive(url))
    GetSession().BackgroundImageDownload = request
  end if
End Function

Function DownloadArtistImageForSong(song as object)
  url = song.artistimage
  if url <> invalid
    request = AsyncGetFile(url, "tmp:/" + makemdfive(url))
    GetSession().ArtistImageDownload = request
  end if
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

    ' I don't know why non-requests (ints to be specific) are showing up
    ' but for now let's just guard against it.
    if type(BackgroundImageDownload) <> "roUrlRequest"
      return false
    end if

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

    ' I don't know why non-requests (ints to be specific) are showing up
    ' but for now let's just guard against it.
    if type(ArtistImageDownload) <> "roUrlRequest"
      return false
    end if

    ArtistImageDownloadIdentity = ToStr(ArtistImageDownload.GetIdentity())

    if ArtistImageDownloadIdentity = invalid
      return false
    end if

    if Identity = ArtistImageDownloadIdentity
      return true
    end if

    return false

End Function
