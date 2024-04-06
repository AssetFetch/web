# How AssetFetch Works

Traditionally, acquiring pre-made assets for use in a project usually involves visiting the website of a vendor offering 3D models, materials, and other resources and downloading one or multiple files to local storage.
These asset files are then manually imported into the desired application, a process which often involves additional manual steps for unpacking, file organization and adjustments after the initial import such as setting up a material from texture maps that came with a model file.

Some vendors have improved this experience by creating bespoke plugins or integrations for specific tools that make it possible to purchase, download and import assets all through a convenient panel in a 3D application like Blender, 3DSMax or Unreal Engine.
But this approach hardly scales and creates lock-in effects as only large vendors can afford to develop high-quality integrations for multiple tools.

This is where AssetFetch wants to help by providing a standardized API for browsing, downloading and importing 3D assets.
The specifications aims to help in creating an artist experience similar to the existing native integrations with less development overhead in order to increase interoperability between vendors and applications and allow more vendors - especially smaller ones - to offer their assets to artists right in the applications where they need them.

It's an open system like RSS or Email, for browsing and downloading 3D assets.

## Getting started as an artist
Since AF is currently still in its infancy, there isn't a way to use in production quite yet.
The first real-world implementations are scheduled to launch in 2024.

## Getting started as a provider
AF is an open standard, therefore any provider interested offering AssetFetch can do so by implementing the HTTP-endpoints defined in the specification.
A more detailed implementation guide for providers is planned for the future.

## Getting started as a client developer
In the same way that anyone can become an AssetFetch provider anyone is also able to develop a client, either as a standalone application or as a plugin for an existing one.