Function AlbumImage(filePath as String, x as Integer, y as Integer, enableFade = true as Boolean, maxAlpha = 225 as Integer, overlayColor = 0 as Integer, DrawGrunge = true as Boolean) as Object

	this = {
		bitmap: invalid
		image: invalid
		alpha: &hFFFFFF00


		x: ResolutionX(x)
		y: ResolutionY(y)

		DrawGrunge: DrawGrunge
		grunge: invalid
		GrungeAngle: 0
		GrungeX: 0
		GrungeY: 0

		width: ResolutionY(180)
		height: ResolutionY(180)

		EnableFade: enableFade
		FadeIn: albumImage_FadeIn
		FadeOut: albumImage_FadeOut
		MaxFade: maxAlpha
		MinFade: 0

		isFadingIn: true
		isFadingOut: false
		fadeAmount: GetConfig().ImageFadeDuration
		overlayColor: overlayColor

		draw: albumImage_draw
	}

	this.bitmap = CreateObject("roBitmap", filePath)
	this.image = RlGetScaledImage(this.bitmap, this.width, this.height, 1)
	this.bitmap = invalid

	this.GrungeX = this.x
	this.GrungeY = this.y
	angles = CreateObject("roArray", 4, false)
	angles[0] = 0
	angles[1] = 90
	angles[2] = 180
	angles[3] = 270
	this.GrungeAngle = angles[Rnd(3)]

	if this.GrungeAngle = 90
		this.GrungeY = this.GrungeY + this.height
	else if this.GrungeAngle = 180
		this.GrungeY = this.GrungeY + this.height
		this.GrungeX = this.GrungeX + this.width
	else if this.GrungeAngle = 270
		this.GrungeX = this.GrungeX + this.width
	end if


	'Disable fading for old devices
	if NOT SupportsAdvancedFeatures()
		this.alpha = this.alpha + this.MaxFade
		this.enableFade = false
	end if

	if this.DrawGrunge = true
		random = 0 'Rnd(1)
		this.grunge = RlGetScaledImage(CreateObject("roBitmap", "pkg:/images/album-grunge" + ToStr(random) + ".png"), this.width, this.height, 1)
	end if

	return this
End Function

Function albumImage_FadeIn()
	if SupportsAdvancedFeatures()
		m.isFadingIn = true
		m.isFadingOut = false
	end if
End Function

Function albumImage_FadeOut()
	if SupportsAdvancedFeatures()
		m.isFadingOut = true
		m.isFadingIn = false
	else
		m.alpha = &hFFFFFF00
		m.bitmap = invalid
	end if
End Function

Function albumImage_draw(screen as Object)
	if m.image <> invalid
		if m.enableFade
			if m.isFadingIn = true
				m.alpha = RlMin(&hFFFFFF00 + m.MaxFade, m.alpha + m.fadeAmount)
				if m.alpha = &hFFFFFF00 + m.MaxFade
					m.isFadingIn = false
				end if
			else if m.isFadingOut = true
				m.alpha = RlMax(&hFFFFFF00 + m.MinFade, m.alpha - m.fadeAmount)
				if m.alpha = &hFFFFFF00
					m.isFadingOut = false
					m.image = invalid
				end if
			end if
		else
			m.alpha = &hFFFFFF00 + m.MaxFade
		end if

		screen.DrawObject(m.x, m.y, m.image, m.alpha)
		if m.overlayColor <> 0 AND m.image <> invalid
			screen.DrawRect(m.x, m.y, m.image.GetWidth(), m.image.GetHeight(), m.overlayColor)
		end if
		if m.DrawGrunge = true
			color = &h00000000 + 190
			screen.DrawRotatedObject(m.GrungeX, m.GrungeY, m.GrungeAngle, m.grunge)
		end if


	end if
End Function
