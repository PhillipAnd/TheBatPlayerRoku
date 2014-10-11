[The Bat Player for Roku](http://thebatplayer.fm)
======================
A [BrightScript](http://sdkdocs.roku.com/display/sdkdoc/BrightScript+Language+Reference) application for listening to internet radio on your Roku media player.

###**Features**
1. Uses data from Last.FM to display artist and track information.
2. Can take advantage of your Philips Hue connected lighting system to surround yourself in the colors that are on the screen.
3. Uses a web-based configuration page to configure the application instead of the remote and on-screen keyboards.
4. Can Scrobble to two different Last.FM accounts to keep your listening history up to date.
5. Add the track that you're currently hearing to a custom Rdio playlist.
6. Uses a server-side component for image processing and metadata caching.

###**Acknowledgements**
1. Utilizes [RokuLib](https://github.com/dphang/roku-lib).
2. Analytics are enabled via Segment.IO and the [SegmentIO-Brightscript](https://github.com/gabek/SegmentIO-Brightscript) library.

###**TODOs**
1. Migrate more of the server-side logic to the client.
2. Display periodic "Playing on other stations" notifications to let you know what you're missing on the other stations you have configured.
3. Calculate an "Artist Popularity" value to compare the current artist to others in terms of listener counts.
