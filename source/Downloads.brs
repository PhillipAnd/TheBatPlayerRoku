Function AsyncGetFile(url as string, filepath as string, overrideFileCheck = false as Boolean) as Object
  if url <> invalid AND filepath <> invalid AND url <> "" then
    'Do we already have this file?
    FileSystem = CreateObject("roFileSystem")
    if FileSystem.Exists(filepath) = true AND overrideFileCheck = false then
      'We already have this file
      'print "*** It seems we already have file: " +url
    else
      Request = GetRequest()
      Request.SetUrl(url)
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

Function SyncGetFile(url as string, filepath as string, overrideFileCheck = false as Boolean)
  if url <> invalid AND filepath <> invalid AND url <> "" then
    'Do we already have this file?
    FileSystem = CreateObject("roFileSystem")
    if FileSystem.Exists(filepath) = true AND overrideFileCheck = false then
      'We already have this file
      'print "*** It seems we already have file: " +url
    else
      Request = GetRequest()
      Request.SetUrl(url)
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
    if type(BackgroundImageDownload) <> "roUrlTransfer"
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
    if type(ArtistImageDownload) <> "roUrlTransfer"
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

Function UrlTransferRequest() as object
  request = CreateObject("roUrlTransfer")
  request.EnablePeerVerification(false)
  request.EnableHostVerification(false)
  request.SetPort(GetPort())
  request.setCertificatesFile("common:/certs/ca-bundle.crt")
  return request
End Function

Function PostRequest() as Object
  request = UrlTransferRequest()
  request.SetRequest("POST")
  return request
End Function

Function GetRequest() as Object
  request = UrlTransferRequest()
  request.EnableEncodings(True)
  request.AddHeader("Accept-Encoding","deflate")
  request.AddHeader("Accept-Encoding","gzip")
  return request
End Function
