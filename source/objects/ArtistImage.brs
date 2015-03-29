Function ArtistImage(filePath as string) as Object

	this = {
		bitmap: invalid
		image: invalid

		x: 0.0
		y: 0.0

		verticalOffset: 0.0
		horizontalOffset: 0.0
		resizeRatio: 1.0

		alpha: &hFFFFFF00

		width: 0.0
		height: 0.0

		FadeIn: FadeIn
		FadeOut: FadeOut
		MaxFade: 230
		MinFade: 0

		isFadingIn: true
		isFadingOut: false
		fadeAmount: 2.5

		valid: false

		draw: artistImage_draw
	}

	this.bitmap = CreateObject("roBitmap", filePath)
	if this.bitmap <> invalid
		this.valid = true

		this.width = this.bitmap.GetWidth()
		this.height = this.bitmap.GetHeight()

		this.resizeRatio = GetResizeRatioForArtistImage(this.bitmap)
	  	this.width = ResolutionX(this.width * this.resizeRatio)
	  	this.height = ResolutionX(this.height * this.resizeRatio)

	  	this.horizontalOffset = ResolutionX(RLMax(0,Int(500.0 - this.width)))
	  	this.verticalOffset = ResolutionY(RLMax(0,Int(330 - (this.height + 5))))

		if this.verticalOffset > 0 then
			this.verticalOffset = ResolutionY(this.verticalOffset / 2)
		end if
		if this.horizontalOffset > 0 then
			this.horizontalOffset = ResolutionX(this.horizontalOffset / 2)
		end if

		this.x = ResolutionX(120 + this.horizontalOffset)
		this.y = ResolutionY(120 + this.verticalOffset)

		this.image = RlGetScaledImage(this.bitmap, this.width, this.height, 1)
		this.bitmap = invalid
	end if

	'Disable fading for old devices
	if NOT SupportsAdvancedFeatures()
		this.alpha = this.alpha + this.MaxFade
	end if

	return this
End Function

Function FadeIn()
	if SupportsAdvancedFeatures()
		m.isFadingIn = true
		m.isFadingOut = false
	end if
End Function

Function FadeOut()
	if SupportsAdvancedFeatures()
		m.isFadingOut = true
		m.isFadingIn = false
	else
		m.alpha = &hFFFFFF00
		m.bitmap = invalid
	end if
End Function

Function artistImage_draw(screen as Object)
	if m.image <> invalid
		if m.isFadingIn = true
			m.alpha = RlMin(&hFFFFFF00 + m.MaxFade, m.alpha + m.fadeAmount)
			if m.alpha = &hFFFFFF00 + 210
				m.isFadingIn = false
			end if
		else if m.isFadingOut = true
			m.alpha = RlMax(&hFFFFFF00 + m.MinFade, m.alpha - m.fadeAmount)
			if m.alpha = &hFFFFFF00
				m.isFadingOut = false
				m.bitmap = invalid
			end if
		end if

		screen.DrawObject(m.x, m.y, m.image, m.alpha)
	end if
End Function

Function GetResizeRatioForArtistImage(artistImageBitmap as Object) as float
	resizeRatio = 1
	resizeHeightRatio = 1
	resizeWidthRatio = 1

	imageWidth = artistImageBitmap.GetWidth()
	imageHeight = artistImageBitmap.GetHeight()

	if imageWidth <> 500 then
		resizeWidthRatio =  500 / imageWidth
	endif

	if (imageHeight * resizeWidthRatio) > 320 then
		resizeHeightRatio = 330 / imageHeight
	endif

	resizeRatio = RlMin(resizeHeightRatio, resizeWidthRatio)

	return resizeRatio
End Function
