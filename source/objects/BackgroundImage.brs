Function BackgroundImage(filePath as String) as Object

	this = {
		bitmap: invalid
		image: invalid

		size: invalid
		alpha: &hFFFFFF00

		FadeIn: backgroundImage_FadeIn
		FadeOut: backgroundImage_FadeOut
		MaxFade: 255
		MinFade: 0

		isFadingIn: true
		isFadingOut: false
		fadeAmount: 2

		valid: false

		draw: backgroundImage_draw
	}

	this.size = GetSession().deviceInfo.GetDisplaySize()
	this.bitmap = CreateObject("roBitmap", filePath)
	if this.bitmap <> invalid then this.valid = true
	this.image = RlGetScaledImage(this.bitmap, this.size.w, this.size.h, 1)
	if this.image = invalid then this.valid = false

	this.bitmap = invalid

	'Disable fading for old devices
	if NOT SupportsAdvancedFeatures()
		this.alpha = this.alpha + this.MaxFade
	end if

	return this
End Function

Function backgroundImage_FadeIn()
	if SupportsAdvancedFeatures()
		m.isFadingIn = true
		m.isFadingOut = false
	end if
End Function

Function backgroundImage_FadeOut()
	if SupportsAdvancedFeatures()
		m.isFadingOut = true
		m.isFadingIn = false
	else
		m.bitmap = invalid
	end if
End Function

Function backgroundImage_draw(screen as Object)
	if m.image <> invalid
		if m.isFadingIn = true
			m.alpha = RlMin(&hFFFFFF00 + m.MaxFade, m.alpha + m.fadeAmount)
			if m.alpha = &hFFFFFF00 + m.MaxFade
				m.isFadingIn = false
			end if
		else if m.isFadingOut = true
			m.alpha = RlMax(&hFFFFFF00 + m.MinFade, m.alpha - m.fadeAmount)
			if m.alpha = &hFFFFFF00
				m.isFadingOut = false
				m.bitmap = invalid
			end if
		end if
		screen.DrawObject(0, 0, m.image, m.alpha)
	end if
End Function
