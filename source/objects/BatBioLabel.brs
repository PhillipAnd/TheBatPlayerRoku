Function BatBioLabel(text as string, song as object) as Object
	this = {
		text: text
		labelObject: invalid
		dropShadowObject: invalid

		x: ResolutionX(120)
		y: ResolutionY(510)
		width: ResolutionX(1030)
		height: ResolutionY(200)

		draw: bioLabel_draw

	}

	this.labelObject = RlTextArea(this.text, GetMediumFont(), GetRegularColorForSong(song), this.x, this.y, this.width, this.height, 6, 1.2)    	

	dropShadowColor = GetDropShadowColorForSong(song)
	if dropShadowColor <> 0 
		this.dropShadowObject = RlTextArea(this.text, GetMediumFont(), dropShadowColor, this.x + 2.0, this.y + 2.0, this.width, this.height, 6, 1.2)
	end if

	return this
End Function

Function bioLabel_draw(screen as Object)
	if m.dropShadowObject <> invalid
		m.dropShadowObject.Draw(screen)
	end if
	m.labelObject.Draw(screen)

End Function