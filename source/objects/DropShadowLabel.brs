Function DropShadowLabel(text as string, x as integer, y as integer, width as integer, height as integer, font as Object, color = &hFFFFFFFF as integer, alignment = "center" as string, maxLines = 1 as integer, shadowOffsetX = 2 as integer, shadowOffsetY = 3 as integer, useEllipses = true as Boolean) as Object
	this = {
		text: text
		labelObject: invalid
		dropShadowObject: invalid

		shadowOffsetX: shadowOffsetX
		shadowOffsetY: shadowOffsetY

		image: invalid

		font: font
		x: x
		y: y
		width: width
		height: height

		alpha: &hFFFFFF00
		isFadingIn: true
		isFadingOut: false
		fadeAmount: GetConfig().ImageFadeDuration
		EnableFade: true
		FadeIn: shadowLabel_FadeIn
		FadeOut: shadowLabel_FadeOut
		MaxFade: 255
		MinFade: 0

		useEllipses: useEllipses
    alignment: alignment
    maxLines: maxLines
		draw: dropShadowLabelLabel_draw

	}
	this.labelObject = RlTextArea(this.text, font, color, 0, 0, this.width, this.height, maxLines, 1.0, this.alignment, useEllipses, true)
	this.dropShadowObject = RlTextArea(this.text, font, &h000000FF, this.shadowOffsetX, this.shadowOffsetY, this.width, this.height, maxLines, 1.0, this.alignment, useEllipses, true)

	' Create the bitmap
	this.image = CreateObject("roBitmap", {width:this.width, height: this.height, alphaenable: true})
	this.dropShadowObject.Draw(this.image)
	this.labelObject.Draw(this.image)
	this.image.finish()
	this.image.SetAlphaEnable(false)

	return this
End Function

Function shadowLabel_FadeIn()
	if SupportsAdvancedFeatures()
		m.isFadingIn = true
		m.isFadingOut = false
	end if
End Function

Function shadowLabel_FadeOut()
	if SupportsAdvancedFeatures()
		m.isFadingOut = true
		m.isFadingIn = false
	else
		m.alpha = &hFFFFFF00
		m.bitmap = invalid
	end if
End Function

Function dropShadowLabelLabel_draw(screen as Object)
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
		'Fade disabled
		m.alpha = &hFFFFFF00 + m.MaxFade
	end if
end if

screen.DrawObject(m.x, m.y, m.image, m.alpha)

End Function
