Function SongNameLabel(text as string, song as object, yLocation as integer, font as Object, color) as Object
	this = {
		text: text
		labelObject: invalid
		dropShadowObject: invalid
		font: font
		x: ResolutionX(580)
		y: ResolutionY(yLocation)
		width: ResolutionX(570)
		height: ResolutionY(200)
		color: color
		draw: songNameLabel_draw

	}
	this.labelObject = DropShadowLabel(this.text, this.x, this.y, this.width, this.height, this.font, this.color, "center", 2)

	return this
End Function

Function songNameLabel_draw(screen as Object)
	if m.labelObject <> invalid
		m.labelObject.Draw(screen)
	end if
End Function
