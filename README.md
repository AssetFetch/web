# The AssetFetch Website

This repository contains the code for [AssetFetch.org](https://assetfetch.org).

**If you are looking for the specification itself, simply visit [AssetFetch/spec](https://github.com/AssetFetch/spec)**

## Local Development
The site is built automatically using [MkDocs-Material](https://squidfunk.github.io/mkdocs-material/) which means that the markdown files in the `/docs` subdirectory are rendered out into static HTML.
To get started with local development, run `docker compose up`.
To simulate the real build process, set the environment variable `AF_MKDOCS_COMMAND` to `build` and then run `docker compose up` again. This will output the final site into `/site`.