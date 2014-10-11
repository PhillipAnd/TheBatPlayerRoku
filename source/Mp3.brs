'**********************************************************
'**  Audio Player Example Application - Audio Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************
' '
' Mp3 support routines

Function CreateMp3SongList() as Object
    aa = CreateObject("roAssociativeArray")
    aa.posteritems = CreateObject("roArray", 10, true)
    
    song = CreateSong("Future Synthpop","Digitally Imported","Misc Artists", "mp3", "http://prem1.di.fm:80/futuresynthpop_hi?77dfa163f86db61477fe5d21","http://api.audioaddict.com/v1/assets/image/f4b0f3c30b34cf76de0955652ae5664a.jpg?size=185x185&quality=90")
    aa.posteritems.push(song)

    song = CreateSong("Sanctuary Radio","Sanctuary Radio","Misc Artists", "mp3", "http://205.164.41.34:6699/","http://www.sanctuaryradio.com/images/na.jpg")
    aa.posteritems.push(song)

    song = CreateSong("Downtempo Lounge","Digitally Imported","Misc Artists", "mp3", "http://prem1.di.fm:80/downtempolounge?77dfa163f86db61477fe5d21","http://api.audioaddict.com/v1/assets/image/6da83f72080cb225acf608e54f992cf2.jpg?size=185x185&quality=90")
    aa.posteritems.push(song)

    song = CreateSong("Groove Salad","soma fm","Misc Artists", "mp3", "http://ice.somafm.com/groovesalad", "http://i.img.co/radio/80/26/2608_290.png")
    aa.posteritems.push(song)

    return aa
End Function

Sub DoMp3(from as string)
    'Put up poster screen to pick a song to play
    SongList = CreateMp3SongList()
    Pscreen = StartPosterScreen(SongList, from, "Stations")

    while true
        song = Pscreen.GetSelection(0)
        if song = -1 exit while
        Show_Audio_Screen(songlist.posteritems[song],"MP3 Songs")
    end while
End Sub

