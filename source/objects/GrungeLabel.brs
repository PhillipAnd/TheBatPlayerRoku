'Represents a single line of text without alignment.
'@param text a string to be displayed
'@return a RlText object
function GrungeLabel(text as String, font as Object, rgba as Integer, x = 0 as integer, y = 0 as integer) as Object
    this = {
        type: "RlText"
        text: text
        font: font
        rgba: rgba
        x: x
        y: y

        Draw: GrungeLabel_Draw
        Set: GrungeLabel_Set
        TextGrunge: invalid

    }

    this.Set()

    return this
end function

'Sets width and height of this object base on the text. Need to call this after changing the text in order to update its width and height
function GrungeLabel_Set() as Void
	m.width = GetFontWidth(m.font, m.text)
	m.height = GetFontHeight(m.font)
  m.TextGrunge = RlGetScaledImage(CreateObject("roBitmap", "pkg:/images/text-grunge-overlay.png"), m.width, m.height, 0)
end function

'Draws this RlText to a component, with the top-left corner of the text corresponding to the x and y coordinates of this object
'@param screen a roScreen/roBitmap/roRegion object
'@return true if successful
function GrungeLabel_Draw(component as Object) as Boolean
    component.DrawText(m.text, m.x, m.y, m.rgba, m.font)
    return component.DrawObject(m.x, m.y, m.TextGrunge)
end function
