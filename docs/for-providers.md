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

The next endpoint that every provider needs is one for listing the assets that it can provide.
This is the endpoint that the `asset_list_query` from the initialization step points to.

Let's look at one possible response:

```json
{
	"meta": {
		"kind": "asset_list",
		"message": "OK",
		"version": "0.2"
	},
	"data": {
		"response_statistics":{
			"result_count_total":1
		}
	},
	"assets": [
		{
			"id": "green_apple_001",
			"data": {
				"implementation_list_query": {
					"uri": "https://api.example.com/af/0.2/implementation_list/green_apple_001",
					"method": "get",
					"parameters": [
						{
							"type": "select",
							"id": "texture_resolution",
							"title": "Texture Resolution",
							"default": "1024",
							"mandatory": true,
							"choices": [
								{
									"title":"1K",
									"value":"1024"
								},
								{
									"title":"2K",
									"value":"2048"
								},
								{
									"title":"4K",
									"value":"4096"
								}
							]
						}
					]
				},
				"preview_image_thumbnail": {
					"uris": {
						"256": "https://cdn.example.com/thumbnails/green_apple_001/256.png",
						"512": "https://cdn.example.com/thumbnails/green_apple_001/512.png",
						"1024": "https://cdn.example.com/thumbnails/green_apple_001/1024.png"
					},
					"alt": "A green apple."
				},
				"text": {
					"title": "Green Apple 001",
					"description": "Photogrammetry model of a fresh green apple."
				}
			}
		}
	]
}
```

Again, there is the `meta` field and a `data` field for the asset list itself, containing only one datablock with some statistics (this only becomes interesting once you have so many assets that you can't list them in one query and have to use pagination using the `next_query` datablock).

All the truly interesting data is in the `assets` array, which in this case has only a single asset in it, but the specification allows up to 100 per query (with pagination if there are more results).

An asset consists of just an `id` and a collection of datablocks.
The most important datablock is the `implementation_list_query` which is another variable query, but this one is specifically to get the implementations of THIS asset.
The fact that every asset has its own variable query for getting its implementations gives providers great flexibility in how they allow users to configure their assets.
Features like a LOD- or resolution selection (as shown in the example) can of course be implemented using this query, but also more advanced features like dynamically selecting which PBR maps should be included in a material the first place or even variable resolutions per map with thousands of possible implementations can be represented.

Beyond the implementation list query every asset comes with other datablocks such as names or thumbnail data (including optional variable resolution support for different display sizes).
More datablocks with information about authors or licensing are also available.

When the artist has chosen an asset from the list and provided the requested quality choices for the asset, the client can query the provider for the actual implementation list.

## Getting implementations

The previous endpoint (`asset_list`) did not return any information about the actual files related to the asset, this is the job of the `implementation_list` endpoint that gets called by the client using the data provided during the previous step.
Its output is the longest and most detailed, because it describes the way that the asset with all the selected quality parameters can be imported.

```json
{
	"meta": {
		"kind": "implementation_list",
		"message": "OK",
		"version": "0.2"
	},
	"data": {},
	"implementations": [
		{
			"id": "2048_FBX",
			"data": {
				"text": {
					"title": "FBX (loose material)",
					"description": "The model delivered as an FBX file with separate PBR maps with 2048px resolution."
				}
			},
			"components": [
				{
					"id": "green_apple_001.fbx",
					"data": {
						"file_fetch.download": {
							"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001.fbx",
							"method": "get",
							"payload": {}
						},
						"file_info": {
							"local_path": "green_apple_001.fbx",
							"length": 39086,
							"extension": ".fbx"
						},
						"loose_material_apply": {
							"material_name": "green_apple_001_mat"
						}
					}
				},
				{
					"id": "green_apple_001_albedo_2048.png",
					"data": {
						"file_fetch.download": {
							"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_albedo_2048.png",
							"method": "get",
							"payload": {}
						},
						"file_info": {
							"local_path": "green_apple_001_albedo_2048.png",
							"length": 2364589,
							"extension": ".png"
						},
						"loose_material_define": {
							"material_name": "green_apple_001_mat",
							"map": "albedo",
							"colorspace": "srgb"
						}
					}
				},
				{
					"id": "green_apple_001_normal_2048.png",
					"data": {
						"file_fetch.download": {
							"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_normal_2048.png",
							"method": "get",
							"payload": {}
						},
						"file_info": {
							"local_path": "green_apple_001_normal_2048.png",
							"length": 2364589,
							"extension": ".png"
						},
						"loose_material_define": {
							"material_name": "green_apple_001_mat",
							"map": "normal+y",
							"colorspace": "linear"
						}
					}
				},
				{
					"id": "green_apple_001_roughness_2048.png",
					"data": {
						"file_fetch.download": {
							"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_roughness_2048.png",
							"method": "get",
							"payload": {}
						},
						"file_info": {
							"local_path": "green_apple_001_roughness_2048.png",
							"length": 2364589,
							"extension": ".png"
						},
						"loose_material_define": {
							"material_name": "green_apple_001_mat",
							"map": "roughness",
							"colorspace": "linear"
						}
					}
				}
			]
		},
		{
			"id": "2048_USDZ",
			"data": {
				"text": {
					"title": "USDZ",
					"description": "The model delivered as a single packed USDZ file with 2048px textures."
				}
			},
			"components": [
				{
					"id": "green_apple_001_2048.usdz",
					"data": {
						"file_fetch.download": {
							"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_2048.usdz",
							"method": "get",
							"payload": {}
						},
						"file_info": {
							"local_path": "green_apple_001_2048.usdz",
							"length": 39000860,
							"extension": ".usdz"
						}
					}
				}
			]
		},
		{
			"id": "2048_BLEND",
			"data": {
				"text": {
					"title": "Blender",
					"description": "The model delivered as a single packed .blend file with 2048px textures."
				}
			},
			"components": [
				{
					"id": "green_apple_001_2048.blend",
					"data": {
						"file_fetch.download": {
							"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_2048.blend",
							"method": "get",
							"payload": {}
						},
						"file_info": {
							"local_path": "green_apple_001_2048.blend",
							"length": 30908600,
							"extension": ".blend"
						},
						"format.blend": {
							"version": "4",
							"is_asset": true
						}
					}
				}
			]
		}
	]
}
```

This implementation list is essentially a list suggestions for how the asset could be downloaded and imported, because not every 3D software supports every general-purpose 3D file format (and most of them have their own special format that is readable only to them).

In this example, the provider offers the same model with the same quality (2048px textures, which is the only variable here) in three different ways (implementations):

- As an FBX file with separate textures
- As a packed USDZ file
- As a packed BLEND file

It is then up to the client to pick one of these three implementations that it believes it will be able to handle.
The client makes this decision based on the data in the `file_info` datablock and other datablocks (This will be covered in greater detail in the client guide).
It can also simply ask the user to make an implementation choice, especially if multiple implementations turn out to be theoretically viable.

From this list the client is able to generate an "import plan", basically a series of steps to download the files and load them into the current scene or some own internal asset database.

For an open asset library with no authentication and no "asset unlocking" functionality this is already everything that needs to be implemented.
Let's now return to the more advanced use cases.

## Authentication

Authentication is handled via custom headers that the provider can request, which gives them great flexibility to implement an authentication system that fits their need.
The data about required headers is included in the `initialization` endpoint (which, remember, must be openly accessible without any authentication).
When reading the `provider_configuration` datablock during initialization, the client knows that it must collect the requested values from the user before it can continue making requests to any of the other endpoints.

```json
{
	"data": {
		"provider_configuration": {
			"headers": [
				{
					"name": "access-token",
					"is_required": true,
					"is_sensitive": true,
					"title": "Access Token",
					"acquisition_uri": "https://example.com/help/how-to-get-af-token",
					"acquisition_uri_title": "Learn how to get your access token and paste it here."
				}
			],
			"connection_status_query": {
				"uri": "https://api.example.com/af/0.2/connection_status",
				"method": "get",
				"payload": {}
			}
		}
	}
}
```

Part of the `provider_configuration` endpoint is also a fixed query to a `connection_status` endpoint which serves two functions:

- It is the dedicated endpoint for the client to "try out" the header values entered by the user in order to get confirmation that they are correct.
- If successful, it returns profile data about the user that the provider already has in its database, for example the username, subscription tier or account balance.

Since these values (mainly the balance) may change as the user downloads assets, the client re-calls this endpoint after every asset import to get up-to-date data.

## Purchasing ("Unlocking") assets

!!! note "Purchasing vs. Unlocking"
	Instead of "buying" or "purchasing", AssetFetch uses the more generic term "unlocking" since there are some use-cases where assets are "unlocked" without an actual purchase specifically for this asset, for example in a subscription model that offers a fixed number of asset downloads per month.

