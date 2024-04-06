# How to Become an AssetFetch Provider

If you are reading this, then you are the owner/developer of a website or similar service, that provides their users with 3D assets (free or paid) and you would like to utilize AssetFetch to achieve this without needing to develop an entire ecosystem of plugins from scratch.
That's a great choice!

This article is a general high-level guide to setting up all the required API-endpoints for AssetFetch on your website.
It isn't a programming tutorial and it likely won't replace [reading the full specification](./latest-draft.md) but it will give you an easy-to-follow and mostly technology-neutral overview on what questions you need to ask yourself and what you need to implement.

## General Overview

As a provider, the implementation of AF is done by offering a handful of HTTP endpoints with a specific, JSON-based format.

A minimal setup consists of three endpoints:

`initialization`
:	Contains basic information like your name and how to query for assets

`asset_list`
:	Gets users a list of assets along with high-level metadata like thumbnails and titles.
	"Assets" are at this point just logical objects and not yet tied to specific file formats or variations.

`implementation_list`
:	Returns the ways ONE asset can be imported, like available variations (Level of Detail, Resolution, ...) and available file formats.
	One such combination that precisely defines as a specific set of files an asset is called an "implementation" of that asset.

If you are planning to host your asset collection freely for anyone on the internet, then this is already enough!
For simple asset structures (like plain OBJ files) a minimal AssetFetch implementation [can be done in less than 200 lines of Python.](https://github.com/AssetFetch/examples/blob/main/provider/python-fastapi-minimal/app/main.py)

If you want to require users to authenticate, you need to add one additional endpoint:

`connection_status`
:	Is used by the client to verify that the login credentials work properly
	Returns information about the user like name, subscription tier or account balance.

If you also want to **sell** assets (for which AF uses the more generic term "asset unlocking") then you need two more endpoints:

`unlock`
:	The endpoint that the client will call to actually make a purchase.

`unlocked_datablocks`
:	The endpoint that returns details about the asset that were previously withheld by you, like the download link for a specific file (which can be randomly generated to prevent 	link-sharing, if you want).

Those are all the endpoints currently specified by AssetFetch.
You can find detailed information about all their fields in the [spec](https://github.com/AssetFetch/spec/blob/main/spec.md#endpoint-list) but they will also be explained in this guide.

## Initialization

The foundation of any AssetFetch provider is the initialization endpoint.
This is a URL that you host and that users will type or copy-paste into their AssetFetch client.
All other endpoints can be locked behind authentication, but this endpoint must be freely available via HTTP-GET.

The specification does not prescribe a specific URL format but it is sensible to add some versioning to it, so for example:

```
https://api.example.com/af/0.2/initialization
```

A minimal response from this endpoint could look like this:

```json
{
	"meta": {
		"kind": "initialization",
		"message": "OK",
		"version": "0.2"
	},
	"id": "api.example.com",
	"data": {
		"asset_list_query": {
			"uri": "https://api.example.com/af/0.2/asset_list",
			"method": "get",
			"parameters": [
				{
					"type": "text",
					"id": "q",
					"title": "Query",
					"default": "",
					"mandatory": false,
					"choices": null
				}
			]
		},
		"text": {
			"title": "Minimal AssetFetch Implementation",
			"description": "This is a bare-bones sample implementation of an AssetFetch provider."
		}
	}
}
```

This simple response is a great example to explain several key concepts in AF.

The first one is the `meta` field, which every response from an AF-enpoint must carry.
It contains basic information about the current response, like its `kind`, the `version` of AF it is targeting and a `message` which becomes the place to communicate details if an error occurs.

The next reoccurring concept is the `data` field.
Every one of its keys and its contents (here `asset_list_query` and `text`) are so-called **datablocks**.
These reusable datablocks are the core building block for nearly everything in AF, from simple title information over HTTP queries to more detailed import descriptors for specific file formats.
Every datablock is identified by its name (which is just its key in the `data` field) and has a content structure that always remains the same.
For example, the `text` datablock with its `title` and `description` fields can be attached to a provider during initialization but it can also be attached to an asset where it then communicates the same information about that specific asset.
The full specification currently contains roughly 30 different datablocks.

And finally, the `asset_list_query` datablock is an example of a **variable query**.
A variable query is simply a description for an HTTP query that the client can make to the provider and how it should make it.
It differs from a **fixed query** (which we will observe later) by the fact that its parameters can be controlled by the user.
In the example shown here, parameter `q` with the full name `Query` indicates that in order to get the list of assets the client needs to send an HTTP `get` request to `https://api.example.com/af/0.2/asset_list` on which it MAY (`mandatory=false`) include the parameter `q`.

The client can then take this information and render a GUI where the user can enter their search query before requesting the asset list.
By extending the `parameters` field with more entries providers can essentially serialize a GUI and send it to be rendered on the client which gives you a great amount of freedom to set up a search/filtering system that fits *your* collection.
Parameters also don't need to be plain text fields, checkboxes and simple drop-downs are supported as well.

The logical next step is to actually list assets.

## Listing assets
