Function GetConfig() as Object
	this = {
		type: "Config"

		SegmentApiKey: "v5tyminpyy"

		LastFMKey: "b6153d6e1039f86e308a79531f7c4b6f"
		LastFMSecret: "6ee44c8b24093c67dbe7f66aa82827e9"

		Hostname: "http://api.thebatplayer.fm"
		ApiPath: "/mp3info/"
		ApiHost: invalid
		Batserver: "http://api.thebatplayer.fm:3000/"
		MetadataFetchTimer: 8
	}

	this.ApiHost = this.Hostname + this.ApiPath
	return this
End Function
