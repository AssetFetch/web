# How to Become an AssetFetch Provider

If you are reading this, then you are the owner/developer of a website or similar service, that provides their users with 3D assets (free or paid) and you would like to utilize AssetFetch to achieve this without needing to develop an entire ecosystem of plugins from scratch.
That's a great choice!

This article is a general high-level guide to setting up all the required API-endpoints for AssetFetch on your website.
It isn't a programming tutorial and it may still be necessary to look into the official specification at some point but it will give you an easy-to-follow and mostly technology-neutral overview on what questions you need to ask yourself and what you need to implement.

## General overview

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

If you also want to **sell** assets (for which AF uses the more generic term "asset unlocking") then you need one more endpoints:

`unlock`
:	The endpoint that the client will call to "unlock" a resource.

Those are all the endpoints currently specified by AssetFetch.
You can find detailed information about all their fields in the specification but they will also be explained in this guide.

Also, the names displayed here are only the codes AF uses to refer to these endpoints, but not necessarily the paths that you need to use to implement them.
As we will see, nothing is stopping you from having an easy to remember `initialization` endpoint like `example.com/af/init` but then directing clients to a URL like `eu-west1.api.prod.somecloud.example.com/services/af/asset_list` for later API calls - so you have a lot of freedom in structuring your implementation!

## Initialization

The foundation of every AssetFetch provider is the initialization endpoint.
This is the URL that you will give to users and that they will type or copy-paste into their AssetFetch client.

All other endpoints can be locked behind authentication, but this endpoint must be freely available.

For our example, let's assume we use this URL:

```
https://api.example.com/af/initialization
```

A minimal response from this endpoint could look like this:

```json
{
	"meta": {
		"kind": "initialization",
		"message": "OK",
		"version": "0.4"
	},
	"id": "api.example.com",
	"data": {
		"asset_list_query": {
			"uri": "https://api.example.com/af/asset_list",
			"method": "get",
			"parameters": [
				{
					"type": "text",
					"id": "q",
					"title": "Query",
					"default": "",
					"choices": null
				}
			]
		},
		"text": {
			"title": "Minimal AssetFetch Implementation",
			"description": "This is an imaginary bare-bones implementation of an AssetFetch provider."
		}
	}
}
```

This simple response is a great example to explain several key concepts in AF.

The first one is the `meta` field, which absolutely every response from an AF-endpoint must carry.
It contains basic information about the current response, like its `kind` (that's what the titles in the previous section referred to!), the `version` of AF it is using (here that is [0.4](./spec/tags/0.4.md)) and a `message` which becomes the place to communicate details if an error occurs.

The next reoccurring concept is the `data` object.
Every one of its keys and its contents (here `asset_list_query` and `text`) are so-called **datablocks**.
These reusable datablocks are the core building block for nearly everything in AF, from simple title information over other HTTP queries to more detailed import descriptors for specific file formats.
Every datablock is identified by its name (which is just its key in the `data` object) and has a content structure that always remains the same.
For example, the `text` datablock with its `title` and `description` fields can be attached to a provider during initialization but it can also be attached to an asset where it then communicates the same kind of information about that specific asset.
The full specification contains ~30 different kinds of different datablocks.

And finally, the `asset_list_query` datablock is an example of a **variable query**.
A variable query is simply a description for an HTTP query that the client can make to the provider and how it should make it.
It differs from a **fixed query** (which we will observe later) by the fact that its parameters can be controlled by the user.
In the example shown here, the client needs to send an HTTP request to `https://api.example.com/af/asset_list` with parameter `q` in order to get the list of available assets.
The `q` parameter is just the search query that the user would normally type into a website.

The client can then take this information and render a GUI where the user can enter their search query before requesting the asset list.

It is important to note that this query structure is not fixed or prescribed by AF.
If you want to a parameter called `search` instead of `q` or add a second parameter `free_assets_only` to your asset list query, then you are free to do this!
By extending the `parameters` field with more entries providers can essentially serialize a GUI and send it to be rendered on the client which gives you a great amount of freedom to set up a search/filtering system that fits *your* asset collection.
Parameters also don't need to be plain text fields, checkboxes and simple drop-downs are supported as well.

The logical next step is to actually see what needs to happen if a client calls this endpoint.

## Listing assets

The next endpoint that every provider needs is one for listing the assets that it can provide.
This is the endpoint that the `asset_list_query` from the initialization step points to.

Let's assume the client has made contact with `https://api.example.com/af/asset_list?q=apple,green`.
This is what a possible response could look like:

```json
{
	"meta": {
		"kind": "asset_list",
		"message": "OK",
		"version": "0.4"
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
					"uri": "https://api.example.com/af/implementation_list/green_apple_001",
					"method": "get",
					"parameters": [
						{
							"type": "select",
							"id": "texture_resolution",
							"title": "Texture Resolution",
							"default": "1024",
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

Again, there is the `meta` field and a `data` field for the asset list itself, containing only one datablock with some statistics. This particular datablock only becomes interesting once you have so many assets that you can't list them in one query and have to use pagination using the `next_query` datablock but I wanted to show it here to show that both the list as a whole as well as individual assets have their own `data` field.

All the truly interesting data is in the `assets` array, which in this case has only a single asset in it, but the specification allows up to 100 per query (with pagination if there are more results).

An asset consists of an `id` and a collection of datablocks.
The most important datablock is the `implementation_list_query` which describes how the client can query you for the implementations of an asset.

AF uses the term **implementation** of an asset for the different versions of one asset that a provider might provide.
For example, you might offer different texture resolution and LODs of a model.
In that case, every possible combination of the two that you offer ("High-poly and 4K textures", "Low-Poly and 2K textures", "Low-Poly and 1K textures") is called an "implementation" of that asset.
The fact that every asset has its own variable query for getting its implementations gives providers great flexibility in how they allow users to configure their assets.
Features like a LOD- or resolution selection (as shown in the example) can of course be implemented using this query, but also more advanced features like dynamically selecting which PBR maps should be included in a material or even variable resolutions per map (1K roughness but 4K color) with thousands of possible implementations can be represented.
It all depends on what you choose to offer.

Beyond the implementation list query every asset comes with other datablocks such as names or thumbnail data (including optional variable resolution support for different display sizes).
More datablocks with information about authors or licensing are also available.

When the artist has chosen an asset from the list and provided the requested quality choices for the asset, the client can query you for the actual implementation list.

## Getting implementations

The previous endpoint (`asset_list`) did not return any information about the actual files related to the asset, this is the job of the `implementation_list` endpoint that gets called by the client using the data provided during the previous step.
Its output is the longest and most detailed, because it describes the way that the asset with all the selected quality parameters can be imported.

Let's say a request has been made to `https://api.example.com/api/af/implementation_list?texture_resolution=2048`:

```json
{
	"meta": {
		"kind": "implementation_list",
		"message": "OK",
		"version": "0.4"
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
						"format": {
							"extension": ".fbx"
						},
						"store": {
							"local_file_path": "green_apple_001.fbx",
							"bytes": 39086
						},
						"fetch.download": {
							"download_query": {
								"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001.fbx",
								"method": "get",
								"payload": {}
							}
						},
						"handle.native": {},
						"link.loose_material": {
							"material_name": "green_apple_001_mat"
						}
					}
				},
				{
					"id": "green_apple_001_albedo_2048.png",
					"data": {
						"fetch.download": {
							"download_query": {
								"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_albedo_2048.png",
								"method": "get",
								"payload": {}
							}
						},
						"store": {
							"local_file_path": "green_apple_001_albedo_2048.png",
							"bytes": 2364589
						},
						"format": {
							"extension": ".png",
							"mediatype": "image/png"
						},
						"handle.loose_material_map": {
							"material_name": "green_apple_001_mat",
							"map": "albedo"
						}
					}
				},
				{
					"id": "green_apple_001_normal_2048.png",
					"data": {
						"fetch.download": {
							"download_query": {
								"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_normal_2048.png",
								"method": "get",
								"payload": {}
							}
						},
						"store": {
							"local_file_path": "green_apple_001_normal_2048.png",
							"bytes": 2364589
						},
						"format": {
							"extension": ".png",
							"mediatype": "image/png"
						},
						"handle.loose_material_map": {
							"material_name": "green_apple_001_mat",
							"map": "normal+y"
						}
					}
				},
				{
					"id": "green_apple_001_roughness_2048.png",
					"data": {
						"fetch.download": {
							"download_query": {
								"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_roughness_2048.png",
								"method": "get",
								"payload": {}
							}
						},
						"store": {
							"local_file_path": "green_apple_001_roughness_2048.png",
							"bytes": 2364589
						},
						"format": {
							"extension": ".png",
							"mediatype": "image/png"
						},
						"handle.loose_material_map": {
							"material_name": "green_apple_001_mat",
							"map": "roughness"
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
						"fetch.download": {
							"download_query": {
								"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_2048.usdz",
								"method": "get",
								"payload": {}
							}
						},
						"store": {
							"local_file_path": "green_apple_001_2048.usdz",
							"bytes": 39000860
						},
						"format": {
							"extension": ".usdz"
						},
						"handle.native": {}
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
						"fetch.download": {
							"download_query": {
								"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_2048.blend",
								"method": "get",
								"payload": {}
							}
						},
						"store": {
							"local_file_path": "green_apple_001_2048.blend",
							"bytes": 30908600
						},
						"format.blend": {
							"version": "4",
							"is_asset": true
						},
						"handle.native": {}
					}
				}
			]
		}
	]
}
```

This implementation list is essentially a list suggestions for how the asset could be downloaded and imported, because not every 3D software supports every general-purpose 3D file format (and practically all of them also have their own special format that is readable only to them).

In this example, the provider offers the same model with the same quality (2048px textures, which is the only variable here) in three different ways ("implementations"):

- As an FBX file with separate textures
- As a single USDZ file
- As a single BLEND file

The last two implementations are very simple, only containing one file each.
The first implementation lists the FBX model and all relevant textures separately and then links up the materials using `handle.loose_material_map` and `link.loose_material` datablocks.
This "linking" feature exists specifically because not all providers already have ready-made machine readable material definition files for their assets (such as `.mtlx` or `.usda/c` with the USDPreviewSurface).

It is then up to the client to pick one of these three implementations that it believes it will be able to handle.
The client makes this decision based on the data in the `format` datablocks and other datablocks.
It can also simply ask the user to make an implementation choice, especially if multiple implementations turn out to be theoretically viable (This will be covered in greater detail in the client guide).

For an open asset library with no authentication and no "asset unlocking" functionality this is already everything that needs to be implemented.
Let's now return to the more advanced use cases.

## Authentication

Authentication is handled via custom headers that the provider can request, which gives them great flexibility to implement an authentication system that fits their need.
The data about required headers is included in the `initialization` endpoint (which, remember, must be openly accessible without any authentication).
When reading the `provider_configuration` datablock during initialization, the client knows that it must collect the requested values from the user before it can continue making requests to any of the other endpoints.

```json
{
	"meta": {
		"kind": "initialization",
		"message": "OK",
		"version": "0.4"
	},
	"id": "api.example.com",
	"data": {
		"provider_configuration": {
			"headers": [
				{
					"name": "access-token",
					"is_required": true,
					"is_sensitive": true,
					"title": "Access Token"
				}
			],
			"connection_status_query": {
				"uri": "https://api.example.com/af/connection_status",
				"method": "get",
				"payload": {}
			}
		},
		// Remaining datablocks omitted in example
	}
}
```

Part of the `provider_configuration` endpoint is also a fixed query to a `connection_status` endpoint which serves two functions:

- It is the dedicated endpoint for the client to "try out" the header values entered by the user in order to get confirmation that they are correct.
- If successful, it returns profile data about the user that the provider already has in its database, for example the username, subscription tier or account balance.

Since these values (mainly the balance) may change as the user downloads assets, the client re-calls this endpoint after every asset import to get up-to-date user data.

## Unlocking assets

Unlocking functionality requires one additional endpoint for performing the "unlocking" itself.
Let's look at an example.
This is a a possible response coming from an implementation list endpoint which contains not only the implementations (omitted in this example) but also a list of queries in the `unlock_queries` datablock:

```json
{
	"meta": {
		"kind": "implementation_list",
		"message": "OK",
		"version": "0.4"
	},
	"data": {
		"unlock_queries": [
			{
				"id": "green_apple_001",
				"unlocked": false,
				"price": 7.99,
				"query": {
					"uri": "https://api.example.com/af/unlock",
					"method": "post",
					"payload": {
						"id": "green_apple_001"
					}
				},
				"query_fallback_uri": "https://example.com/view-item/green_apple_001"
			}
		]
	},
	"implementations": [
	  // Omitted in example
	]
}
```

The `unlock_queries` datablock gets attached to the implementation list itself. It contains information about one or multiple (in this case just one) concrete purchases that the user can make.
In this example the green apple asset is represented as just one purchasable item which includes all possible variations (You either own the green apple asset or you don't, we will get to more complicated scenarios later).

Every component which needs to be purchased then gets a `unlock_query_id` added to its `fetch.datablock`, letting the client know that this unlocking query must happen, otherwise the asset will be un
This example only shows the USDZ version of the asset, for brevity:

```json
{
	"meta": {
		"kind": "implementation_list",
		"message": "OK",
		"version": "0.4"
	},
	"data": {
		// Omitted in example
	},
	"implementations": [
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
						"fetch.download": {
							"unlock_query_id": "buy_green_apple_001",	// The unlock query is referenced here!
							"download_query": {
								"uri": "https://cdn.example.com/assets/green_apple_001/green_apple_001_2048.usdz",
								"method": "get",
								"payload": {}
							}
						},
						"store": {
							"local_file_path": "green_apple_001_2048.usdz",
							"bytes": 39000860
						},
						"format": {
							"extension": ".usdz"
						},
						"handle.native": {}
					}
				}
			]
		}
	]
}

```

This tells the client that it needs to perform the unlock query with the id `buy_green_apple_001`, if it hasn't already been unlocked (based on the `unlocked` field) before it can start the actual file download.
The client repeats this same procedure for all the components that it needs to download.

The above example assumes that the green apple asset is sold as one unit which includes all variations.
Therefore, all components in all implementations would point to the same unlocking query in the `unlock_queries` datablock.
However, some providers like to offer customers the opportunity to make purchases with a higher granularity, like [Textures.com, where every resolution of every material map is an individual purchase](https://www.textures.com/download/3DScans0412/133019) which means that one asset can consist of dozens, sometimes nearly 100 individual purchases a user could make.
A purchase of one asset from a provider like this could be handled by the provider as just one unlocking query which then unlocks all relevant files in the background, but AssetFetch also allows those providers to expose this information by sending multiple unlocking queries which then get individually linked to specific components in their `fetch.download` datablock.
This way, the client is able to show the user *exactly* how the purchase they are about to make is composed which becomes even more important if the user already owns some parts of the asset they are about to import, for example because they already bought the color and normal maps, but not the roughness and ambient occlusion maps.
In this case, the provider would still send the full list of unlocking queries, but mark some of them as `unlocked=true` from the start to indicate that the purchase behind this query has already been made and that the client can immediately proceed with downloading the files though the `fetch.download` datablock.

## Not (yet) covered by this guide...

This guide already covers many of the most important aspects of AssetFetch, but there are a few more concepts that are not (yet) covered here:

- Component behavior: It controls whether a client should try to directly import a specific file or just download it because it is needed as a dependency by other files (You can see the `handle.native` datablock in the examples which has to do with this).
- Archive handling:  AF enables providers to host only one set of files for both normal web-users (who prefer to download everything in one go as a ZIP-archive) and AF-users. Components can reference other components as their containers which instructs the client to unpack them after downloading.
- Format-specific import instructions which can tell the client details specific to a particular file type, like whether an OBJ file should be read as Y-up or Z-up or whether a BLEND file is marked as an asset for use in Blender's internal asset library system, which would allow the client to handle that file differently. (You can again see this in one of the examples which carries a `format.blend` datablock).
- Pagination, which is only mentioned briefly.