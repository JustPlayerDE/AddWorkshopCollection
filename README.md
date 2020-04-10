# AddWorkshopCollection

This is a tool to add entire collections to the download for Clients (basicly AddWorkshop in big)

This script adds one serverside command and function:

To use it you can either run "sv_addworkshopcollection <Collection ID(s)>" (support for multiple ids)
or call "resource.AddWorkshopCollection(CollectionID)" in lua.


Disclaimer:
This uses a hacky way to get the Workshop IDs on a collection because there is currently no other way (in my knowledge) and so it may break in the future if Steam changes something on their website.

This will use http.Fetch to get the collection, please dont add too many collection ids (because this will hang your server until its ready when the first Think hook gets called)
