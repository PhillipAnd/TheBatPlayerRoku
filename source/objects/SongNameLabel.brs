Function SongNameLabel(text as string, song as object, yLocation as integer, font as Object, color) as Object
	this = {
		text: text
		labelObject: invalid
		dropShadowObject: invalid
		font: font
		x: ResolutionX(625)
		y: ResolutionY(yLocation)
		width: ResolutionX(500)
		height: ResolutionY(200)
		color: color
		draw: songNameLabel_draw

	}
	this.labelObject = DropShadowLabel(this.text, this.x, this.y, this.width, this.height, this.font, this.color)

	return this
End Function

Function songNameLabel_draw(screen as Object)
	'if m.dropShadowObject <> invalid
	''	m.dropShadowObject.Draw(screen)
	'end if

	if m.labelObject <> invalid
		m.labelObject.Draw(screen)
	end if

End Function
