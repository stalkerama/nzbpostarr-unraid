# NZBPostarr for Unraid

Docker and Unraid packaging for [NZBPostarr](https://github.com/polyn0mial/NZBPostarr).

> **Important:** This repository does **not** modify the original NZBPostarr project. No application source patches are applied and this repository is not a fork of NZBPostarr. Its only purpose is to package the original upstream project into a Docker image and provide an Unraid template so NZBPostarr can run cleanly on Unraid.

The application itself is developed and maintained by the upstream [polyn0mial/NZBPostarr](https://github.com/polyn0mial/NZBPostarr) project. Issues specific to this Docker image or the Unraid template belong here; application bugs and feature requests belong upstream.

## What this repository does

- Builds a Docker image directly from the original `polyn0mial/NZBPostarr` source.
- Adds the runtime dependencies needed by NZBPostarr inside the container.
- Stores configuration and NZBPostarr runtime state under `/config` so it survives container upgrades/recreation.
- Exposes `/data` as a user-configurable Unraid path for the files NZBPostarr should access.
- Exposes the NZBPostarr WebUI on container port `8000`.
- Checks the upstream `main` branch every 6 hours and builds a new image only when a new upstream commit is detected.
- Also rebuilds when the Docker packaging itself changes.

## Docker image

The image is published to GitHub Container Registry:

```text
ghcr.io/stalkerama/nzbpostarr-unraid:latest
```

Each upstream build also receives an immutable-style source tag:

```text
ghcr.io/stalkerama/nzbpostarr-unraid:upstream-<12-character-commit-sha>
```

`latest` follows the newest successfully built upstream commit.

## Unraid paths

| Container path | Purpose | Suggested Unraid path |
|---|---|---|
| `/config` | NZBPostarr configuration and persistent runtime data | `/mnt/user/appdata/nzbpostarr` |
| `/data` | User-selected source/content location | **Choose your own path** |

`/data` is intentionally not hard-coded to any Unraid share. Select the host path that contains the files you want NZBPostarr to see.

For example:

```text
Host:      /mnt/user/Media
Container: /data
```

Inside NZBPostarr, configure folders using `/data/...`, for example `/data/Movies` or `/data/TV`.

## First start

On the first container start, the packaging layer copies NZBPostarr's own default configuration to:

```text
/config/config.yaml
```

The default `base_folder` is changed from the upstream example path to `/data` for container use. No application code is changed.

Open the WebUI at:

```text
http://UNRAID-IP:8000
```

or at whichever host port you mapped to container port `8000`.

## Unraid template

The template is located at:

```text
unraid/nzbpostarr.xml
```

Once this repository and its GHCR package are public, the raw template can also be copied directly into Unraid's Docker template directory if desired.

The template provides:

- WebUI port `8000`
- `/config` appdata mapping
- user-configurable `/data` mapping
- `PUID` and `PGID` settings, defaulting to Unraid's usual `99:100`

## Automatic upstream updates

GitHub Actions checks:

```text
https://github.com/polyn0mial/NZBPostarr
```

for the current `main` commit every 6 hours.

If an image tagged for that upstream commit already exists, the scheduled build is skipped. If upstream has changed, a new image is built and pushed as both `latest` and `upstream-<sha>`.

This keeps the Docker package current without mirroring, modifying, or maintaining a separate copy of the NZBPostarr application source.

## Included external tools

NZBPostarr requires external command-line tools in addition to its Python dependencies. The image includes:

- `nyuu`
- `parpar`
- `rar`
- `mediainfo`

These are packaging/runtime dependencies only and do not alter NZBPostarr's source code.

## Upstream project and license

NZBPostarr is licensed under the MIT License. The upstream license is retained in the Docker image and a copy is included in this packaging repository as `UPSTREAM_LICENSE`.

Original project:

**https://github.com/polyn0mial/NZBPostarr**

All credit for NZBPostarr itself belongs to its upstream authors and contributors.
