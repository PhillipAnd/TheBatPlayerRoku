Function BatPopup(text as String, textColor = &h000000FF as Integer, backgroundColor = &hBBBBBB00 as Integer, displayTime = 3 as Integer) as Object
	this = {
		type: "BatPopup"
		text: text
		font: GetMediumFont()
		time: displayTime
		x: 0
		y: 0
		width: 0
		height: 0
		textColor: textColor
		currentAlpha: 200
		backgroundColor: backgroundColor

		textArea: invalid

		timer: CreateObject("roTimespan")
		Init: initBatpopup
		Draw: DrawBatpopup
		Close: CloseBatpopup

	}

	this.init()

	return this
End function

Function initBatpopup() as Void
	screen = GetNowPlayingScreen().screen
	screenHeight = screen.GetHeight()
	screenWidth = screen.GetWidth()

	width = GetFontWidth(m.font, m.text)
	height = GetFontHeight(m.font)

	m.width = width + 40
	m.height = height + 60


	m.x = (screenWidth - m.width) / 2
	m.y = (screenHeight - m.height) / 2
	m.textArea = RlTextArea(m.text, m.font, m.textColor, m.x + 20, m.y + 30, m.width - 20, m.height - 20, 5, 1.0, "center")
	m.timer.mark()
End Function

Function CloseBatpopup()
	GetNowPlayingScreen().popup = invalid
	m.timer = invalid
	m = invalid
End Function

Function DrawBatpopup(screen as Object)

	if m.timer <> invalid AND m.timer.totalSeconds() >= m.time
		m.currentAlpha = m.currentAlpha - 40
	End if

	if m.currentAlpha <= 0
		m.close()
		return false
	End if

	if m.timer <> invalid
		screen.DrawRect(m.x, m.y, m.width, m.height, m.backgroundColor + m.currentAlpha)
		m.textArea.draw(screen)
	end if

End Function

Function HandlePopupEvent(msg as Object)
End Function

Function DisplayPopup(text as string, textColor = &h000000FF as Integer, backgroundColor = &hBBBBBB00 as Integer, duration = 3 as integer)
	popup = BatPopup(text, textColor, backgroundColor, duration)
	GetNowPlayingScreen().popup = popup
End Function
