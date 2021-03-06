Function InitRdio()
	accessToken = GetRdioAccessToken()

	if accessToken <> invalid
		GetRdioPlaylistKey()
	end if

End Function

Function AttemptToAddToRdioPlaylist(artist as string, track as string)
	accessToken = GetRdioAccessToken()
	if accessToken = invalid
		DisplayPopup("Visit the web setup on your computer to enable Rdio.")
		return false
	end if

	DisplayPopup("Attempting to find " + artist + " - " + track + " on Rdio.")
	FindRdioSourceIdForSong(artist, track)
End Function

Function AddSongKeyToRdioPlaylist(key as string)

	url = "https://www.rdio.com/api/1/search"
	playlistKey = GetRdioPlaylistKey()
	accessToken = GetRdioAccessToken()

	if playlistKey = invalid
		CreateRdioPlaylistWithTrackId(key)
		return true
	end if

	body = "playlist=" + playlistKey
	body = body + "&tracks%5B%5D=" + key
	body = body + "&method=addToPlaylist"
	body = body + "&access_token=" + accessToken

	request = PostRequest()
  request.SetUrl(url)
	request.PostFromString(body)

End Function

Function FindRdioSourceIdForSong(artist as string, track as string)
	Analytics = GetSession().Analytics
	Analytics.AddEvent("Rdio track search began")

	artist = DeParenString(artist)
	track = DeParenString(track)

	url = "https://www.rdio.com/api/1/search"

	accessToken = GetRdioAccessToken()

	if accessToken <> invalid
    request = PostRequest()
    request.SetPort(GetPort())
    request.SetUrl(url)

		body = "query=" + UrlEscape(artist) + "+" + UrlEscape(track)
		body = body + "&types%5B%5D=Track&never_or=true&method=search"
		body = body + "&access_token=" + accessToken

		GetGlobalAA().RdioRequest = request

		request.AsyncPostFromString(body)
	end if
End Function

Function RdioSearchResult(result as string)
	GetGlobalAA().Delete("RdioRequest")
	Analytics = GetSession().Analytics

	object = ParseJSON(result)

	if object.DoesExist("error")
		DisplayPopup("Error accessing your Rdio account. Please reauthorize via the setup page. " + object.error_description)
		return false
	end if

	if object.result.DoesExist("results")
		results = object.result.results

		if object.result.number_results = 0
			DisplayPopup("Unable to find this song in the Rdio streaming catalog")
			Analytics.AddEvent("Rdio track search failed")
			return false
		end if

		Analytics.AddEvent("Rdio track search completed")

		for each singleResult in results
			if singleResult.canStream = true
				trackName = singleResult.artist + " - " + singleResult.name

				'Add to playlist
				AddSongKeyToRdioPlaylist(singleResult.key)
				DisplayPopup("Adding " + trackName + " to your Rdio playlist.", &h000000FF, &hBBBBBB00, 5)

				return false
			end if
		end for

	end if
End Function

Function FindRdioPlaylist()
	accessToken = GetRdioAccessToken()

	if accessToken <> invalid
		Analytics = GetSession().Analytics
		Analytics.AddEvent("Rdio playlist search began")

	  request = PostRequest()
		url = "https://www.rdio.com/api/1/getPlaylists"

		body = "access_token=" + accessToken
		body = body + "&method=getPlaylists"
		body = body + "&extras=-*,name,key"

    request = PostRequest()
    request.SetUrl(url)

		GetGlobalAA().RdioPlaylistSearchRequest = request

		request.AsyncPostFromString(body)
	end if
End Function

Function RdioPlaylistSearchResult(result as string)
	GetGlobalAA().Delete("RdioPlaylistSearchRequest")
	playlistName = RdioPlaylistName()

	playlistsObject = ParseJSON(result)
	if playlistsObject.DoesExist("result") AND playlistsObject.result.DoesExist("owned")
		myPlaylists = playlistsObject.result.owned

		key = invalid
		for each singlePlaylist in myPlaylists
			if singlePlaylist.name = playlistName
				key = singlePlaylist.key
			end if
		end for

		GetGlobalAA().rdioPlaylistKey = key
	end if

End Function

Function CreateRdioPlaylistWithTrackId(trackId as String)
	DisplayPopup("Creating a new Playlist and adding this song.", &h000000FF, &hBBBBBB00, 5)

	playlistName = RdioPlaylistName()
	accessToken = GetRdioAccessToken()

	if accessToken <> invalid
		url = "https://www.rdio.com/api/1/createPlaylist"

		description = "Songs discovered by listening to The Bat Player on my Roku."

	  request = PostRequest()
		description = request.UrlEncode(description)

		body = "access_token=" + accessToken
		body = body + "&method=createPlaylist"
		body = body + "&name=" + request.UrlEncode(RdioPlaylistName())
		body = body + "&description=" + description
		body = body + "&tracks=" + trackId

    request.SetUrl(url)
		request.AsyncPostFromString(body)
		GetGlobalAA().RdioCreatePlaylistRequest = request
	end if
End Function

Function GetRdioPlaylistKey() as Dynamic
	return GetGlobalAA().rdioPlaylistKey
End Function

Function GetRdioAccessToken() as dynamic
	token = GetRdioAuthToken(false)
	if token <> invalid
		token = token
	end if

	return token
End Function

'Function GetRdioRefreshToken() as dynamic
''	rdioRefreshToken = RegRead("rdioRefreshToken", "batplayer")
''	return rdioRefreshToken
'End Function

Function RefreshRdioAuthToken() as dynamic
	accessToken = GetRdioAccessToken()
	tokenEndpoint = "https://services.rdio.com/oauth2/token"

	request = PostRequest()
	request.SetUrl(tokenEndpoint)
	body = "grant_type=refresh_token&refresh_token=" + accessToken + "&client_id=" + GetConfig().RdioClientID + "&client_secret=" + GetConfig().RdioClientSecret
	print body

	GetGlobalAA().RdioRefreshRequest = request
	request.AsyncPostFromString(body)
End Function

Function RdioPlaylistName() as String
	return 	"Heard on The Bat Player"
end Function
