Function SongNameLabel(text as string, song as object, yLocation as integer, font as Object) as Object
	this = {
		text: text
		labelObject: invalid
		dropShadowObject: invalid
		font: font
		x: ResolutionX(625)
		y: ResolutionY(yLocation)
		width: ResolutionX(500)
		height: ResolutionY(200)

		draw: songNameLabel_draw

	}
	this.labelObject = RlTextArea(this.text, font, GetRegularColorForSong(song), this.x, this.y, this.width, this.height, 2, 0.87, "center")

	dropShadowColor = GetDropShadowColorForSong(song)

	if dropShadowColor <> 0 
		this.dropShadowObject = RlTextArea(this.text, font, dropShadowColor, this.x + 2, this.y + 2, this.width, this.height, 2, 0.87, "center")
	end if

	return this
End Function

Function songNameLabel_draw(screen as Object)
	if m.dropShadowObject <> invalid
		m.dropShadowObject.Draw(screen)
	end if

	if m.labelObject <> invalid
		m.labelObject.Draw(screen)
	end if

End Function