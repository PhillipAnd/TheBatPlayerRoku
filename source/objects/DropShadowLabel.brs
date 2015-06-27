Function DropShadowLabel(text as string, x as integer, y as integer, width as integer, height as integer, font as Object, color = &hFFFFFFFF as integer, alignment = "center" as string, maxLines = 1 as integer) as Object
	this = {
		text: text
		labelObject: invalid
		dropShadowObject: invalid
		font: font
		x: x
		y: y
		width: width
		height: height

    alignment: alignment
    maxLines: maxLines
		draw: dropShadowLabelLabel_draw

	}
	this.labelObject = RlTextArea(this.text, font, color, this.x, this.y, this.width, this.height, maxLines, 1.0, this.alignment)
	this.dropShadowObject = RlTextArea(this.text, font, &h000000FF, this.x + 2.0, this.y + 3.0, this.width, this.height, maxLines, 1.0, this.alignment)

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
