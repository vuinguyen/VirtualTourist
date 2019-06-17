# VirtualTourist

This app allows users to save locations associated with their vacation, and display pictures with each location.

Locations are displayed as pins on a map.

Pictures are taken from Flickr.

In order to get this app to work, you need to get your own Flickr API key and add it to the APIKeys file as described below.

Please do the following:

1. Copy the APIKeysExample.swift file into the VirtualTourist folder, and rename it to APIKeys.swift,
2. Then add your real API Key into the ApplicationID variable in the APIKeys struct, in the APIKeys file.

On the command line:
> cp APIKeysExample.swift VirtualTourist/APIKeys.swift

In the APIKeys.swift file:
```
struct APIKeys {
  static let ApplicationID = "Your API Key Here"
}
```

Built for my class project, as part of the Udacity iOS nanodegree program.

Main screen with map pins of tourist locations:
[Tourist Locations](/screenshots/MainScreen.png)

Edit pins screen to delete existing pins of tourist locations:
[Edit Pins](/screenshots/EditPinsScreen.png)

Photo album screen displaying pictures for a location:
[Photo Album](/screenshots/PhotoAlbum.png)
