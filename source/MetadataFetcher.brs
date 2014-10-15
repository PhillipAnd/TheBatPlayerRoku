Function FetchMetadataForStreamUrlAndName(url as string, name as string)
	Session = GetSession()

	if url <> invalid
		url = url + "7.html"
		'print "Attempting download of: " + url

		Request = CreateObject("roUrlTransfer")
		
		useragent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13"
		Request.AddHeader("user-agent", useragent)

		Request.SetUrl(url)
		Request.SetPort(GetPort())
		if Request.AsyncGetToString() then
			stationRequestObject = CreateObject("roAssociativeArray")
			stationRequestObject.name = name
			stationRequestObject.request = Request

			key = "OtherStationsRequest-" + ToStr(Request.GetIdentity())
			Session.StationDownloads.Downloads.AddReplace(key, stationRequestObject)
			Session.StationDownloads.Count = Session.StationDownloads.Count + 1
		else
			BatLog("Failed downloading accessing " + url)
		end if

	end if
End Function

Function CompletedOtherStationsMetadata(msg as Object)
	Identity = ToStr(msg.GetSourceIdentity())
	key = "OtherStationsRequest-" + Identity
	Session = GetSession()

	stationRequestObject = Session.StationDownloads.Downloads.Lookup(key)
	Session.StationDownloads.Downloads.Delete(key)

	data = StringRemoveHTMLTags(msg.GetString())
	track = data.Tokenize(",")
	track = track[6]

	CompletedObject = CreateObject("roAssociativeArray")
	CompletedObject.name = stationRequestObject.name
	CompletedObject.playing = track

	Completed = Session.StationDownloads.Completed
	Completed.push(CompletedObject)

	if Completed.Count() = Session.StationDownloads.Count
		
		'Cleanup
		Session.StationDownloads.Delete("Downloads")
		Session.StationDownloads.Delete("Completed")
		
		'All the downloads are complete let's display them
		DisplayOtherStationsNowPlaying(Completed)
	end if

End Function

Function IsOtherStationsValidDownload(msg as Object) as Boolean
	Session = GetSession()

	if type(msg) = "roUrlEvent" AND Session.DoesExist("StationDownloads") AND Session.StationDownloads.DoesExist("Downloads") 
		Identity = ToStr(msg.GetSourceIdentity())
		key = "OtherStationsRequest-" + Identity

		if Session.StationDownloads.Downloads.DoesExist(key)
			return true
		end if
	end if

	return false

End Function


Function FetchPopularityForArtistName(artistname as String)
	Session = GetSession()
	Request = CreateObject("roUrlTransfer")

	url = "http://api.thebatplayer.fm:4567/artistrank/" + Request.escape(artistname)
	Request.SetUrl(url)
	Request.SetPort(GetPort())
	
	if Request.AsyncGetToString()
		RequestObject = CreateObject("roAssociativeArray")
		RequestObject.artistname = artistname
		RequestObject.request = Request
		Session.Downloads.PopularityDownload = RequestObject
	end if

End Function

Function CompletedArtistPopulartiy(msg as Object)
		Session = GetSession()
		NowPlayingScreen = GetNowPlayingScreen()
		Song = NowPlayingScreen.song

		if Session.Downloads.PopularityDownload.artistname = Song.Artist
			Session.Downloads.PopularityDownload = invalid
			data = ParseJson(msg.GetString())
			if data <> invalid AND data.DoesExist("comparison")
				popularity = data.comparison
				Song.popularity = popularity
				UpdateScreen()

				print popularity
			end if
		else
			print "Wrong artist popularity!"
		end if
End Function