Function ArtistNameLabel(text as string, yLocation as integer, font as Object, color as Integer) as Object
	this = {
		text: text
		labelObject: invalid
		font: font
		x: ResolutionX(640)
		y: ResolutionY(yLocation)
		width: ResolutionX(600)
		height: ResolutionY(60)
		color: color

		draw: artistNameLabel_draw

	}
	this.labelObject = DropShadowLabel(this.text, this.x, this.y, this.width, this.height, this.font, this.color, "center", 1)

	return this
End Function

Function artistNameLabel_draw(screen as Object)
	if m.labelObject <> invalid
		m.labelObject.Draw(screen)
	end if
End Function
