'General string utilities

'Converts a string into stars (for passwords)
'@text the string to be obscured
'@return an obscured string
function ObscureString(text as String) as String
    temp = ""
    
    max = text.Len() - 1
    for i = 0 to max
        temp = temp + "*"
    end for
    
    return temp
end function

'Tokenizes a string into an array of words (delimited by spaces and newlines) while fixing duplicate spaces
'@param text the string to be tokenized
Function StringToWords(text as String) as Object 
    r = CreateObject("roRegex", "(\t| )+", "")
    return r.Split(text)
end function

'Tokenizes a string into an array of lines (delimited by custom delimiter $n$)
'@param text the string to be tokenized
Function StringToLines(text as String) as Object 
    r = CreateObject("roRegex", " *\$n\$ *", "")
    return r.Split(text)
end function

'Converts time in seconds to an HH:MM string
'@param time an integer number of seconds
'@return a string in HH:MM format 
function SecondsToString(time as Integer) as String
    minutes = Int(time / 60)
    seconds = time - minutes * 60
    
    temp = ""
    if minutes < 10
    	temp = temp + "0"
    end if
    
    temp = temp + tostr(minutes) + ":"
    
    if seconds < 10
        temp = temp + "0"
    end if

    temp = temp + tostr(seconds)
    
    return temp
end function

'Get font width / height
Function GetFontWidth(font, text as String) As Integer
    return font.GetOneLineWidth(text, 9999)
End Function

Function GetFontHeight(font) as Integer
    return font.GetOneLineHeight()
End Function