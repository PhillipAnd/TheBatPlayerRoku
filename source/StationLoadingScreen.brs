Function DisplayStationLoading(station as Object)
	this = {
		close: Loading_close
		stationImage: "tmp:/" + makemdfive(station.StationImage)
		stationName: station.stationName
		canvas: invalid
		init: initStationLoadingScreen
	}

	this.init()
	GetNowPlayingScreen().loadingScreen = this

	return this

End Function

Function initStationLoadingScreen()

    device = GetSession().deviceInfo
    width = device.GetDisplaySize().w
		headerSize = SizeOfImageAtPath("tmp:/headerImage.png")

		canvasItems = [
					{
						url: "tmp:/headerImage.png",
						TargetRect:{x:ResolutionX(0),y:ResolutionY(0),w:width,h:headerSize.height}
					},
	        {
	            url:m.stationImage
	            TargetRect:{x:ResolutionX(390),y:ResolutionY(170),w:ResolutionX(450),h:ResolutionY(400)}
	        },
	        {
	        	url:"pkg:/images/batoverlay.png"
	            TargetRect:{x:ResolutionX(420),y:ResolutionY(300),w:ResolutionX(400),h:ResolutionY(166)}
	        },
	        {
	            Text:"Please wait while we try to find some details about " + m.stationName + "."
	            TextAttrs:{Color:"#FFCCCCCC", Font:"Medium",
	            HAlign:"HCenter", VAlign:"VCenter",
	            Direction:"LeftToRight"}
	            TargetRect:{x:ResolutionX(370),y:ResolutionY(600),w:ResolutionX(500),h:ResolutionY(60)}
	        }
	    ]

	LoadingScreen = CreateObject("roImageCanvas")
	port = GetPort()
	LoadingScreen.SetMessagePort(port)

	LoadingScreen.SetLayer(0, {Color:"#FF000000", CompositionMode:"Source"})
	LoadingScreen.SetRequireAllImagesToDraw(true)
	LoadingScreen.SetLayer(1, canvasItems)
	LoadingScreen.Show()
	m.canvas = LoadingScreen

End Function

Function Loading_close()
	print "Closing loading screen"
	GetGlobalAA().IsStationSelectorDisplayed = false
	m.canvas.close()
	m.canvas = invalid
	m = invalid
End Function
