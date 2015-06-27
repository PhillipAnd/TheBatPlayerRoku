Function DropShadowLabel(text as string, x as integer, y as integer, width as integer, height as integer, font as Object, color = &hFFFFFFFF as integer) as Object
	this = {
		text: text
		labelObject: invalid
		dropShadowObject: invalid
		font: font
		x: x
		y: y
		width: width
		height: height

		draw: dropShadowLabelLabel_draw

	}
	this.labelObject = RlTextArea(this.text, font, color, this.x, this.y, this.width, this.height, 1, 1.0, "center")
	this.dropShadowObject = RlTextArea(this.text, font, &h000000FF, this.x + 2.0, this.y + 3.0, this.width, this.height, 1, 1.0, "center")

	return this
End Function

Function dropShadowLabelLabel_draw(screen as Object)
	if m.dropShadowObject <> invalid
		m.dropShadowObject.Draw(screen)
	end if

	if m.labelObject <> invalid
		m.labelObject.Draw(screen)
	end if

End Function
