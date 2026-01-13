# bedrock-docker-image

A small, reproducible Docker image for running a **Minecraft Bedrock Dedicated Server**.

This image is built in two stages:

1. **Fetcher stage** downloads the Bedrock server ZIP from **S3**.
2. **Runner stage** extracts it, stores **world/config data** on a persistent volume, and starts the server.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Build the Image](#build-the-image)
- [Configuration](#configuration-environment-variables)
- [Updating the Server Version](#updating-the-server-version)
- [CI](#ci-github-actions)
- [Troubleshooting](#troubleshooting)
  - [Players can't connect](#players-cant-connect)
  - [Container starts but server doesn't load worlds/configs](#container-starts-but-server-doesnt-load-worldsconfig)
  - [Build fails downloading from S3](#build-fails-downloading-from-s3)
- [License](#license)

---

## Features

- **Multi-stage build** (keeps runtime image lean)
- Fetch server ZIP from **Amazon S3** at build time
- Persistent data via a mounted **`/data`** volume
- Configure `server.properties` using **environment variables**
- Works in both **bridge** (`-p .../udp`) and **host** networking modes

---

## Prerequisites

- Docker with **BuildKit** enabled (recommended: Buildx)
- Access to an S3 bucket containing the Bedrock server ZIP
- AWS credentials available as build secrets (examples below)

> Note: This repo expects you to provide the Bedrock server ZIP yourself (typically downloaded from the official source and uploaded to your S3 bucket).

---

## Build the Image

The Dockerfile expects:

- Build args:
  - `S3_BUCKET` – S3 bucket name
  - `S3_FILE` – object key for the Bedrock ZIP (e.g. `bedrock-server.zip`)
- Build secrets (BuildKit secret IDs):
  - `aws_access_key_id`
  - `aws_secret_access_key`
  - `aws_session_token` (optional, but supported)
  - `aws_region`

---

## Configuration (environment variables)

On container start, the entrypoint updates `server.properties` using environment variables when they are set.

Common options:

- `SERVER_NAME` → `server-name`
- `GAMEMODE` → `gamemode`
- `DIFFICULTY` → `difficulty`
- `ALLOW_CHEATS` → `allow-cheats`
- `MAX_PLAYERS` → `max-players`
- `ONLINE_MODE` → `online-mode`
- `ALLOW_LIST` → `allow-list`
- `SERVER_PORT` → `server-port`
- `LEVEL_NAME` → `level-name`
- `LEVEL_SEED` → `level-seed`

Example:
```bash 
docker run -d
--name bedrock
-p 19132:19132/udp
-v bedrock-data:/data
-e SERVER_NAME="My Bedrock Server"
-e GAMEMODE=survival
-e DIFFICULTY=normal
-e MAX_PLAYERS=10
-e ONLINE_MODE=true
bedrock-server:latest
``` 

If you want the full list of supported env vars, check `src/run.sh`.

---

## Updating the Server Version

Because the Bedrock ZIP is fetched at **build time**, you update by:

1. Uploading a new ZIP to S3 (or changing the object key)
2. Rebuilding the image with `S3_BUCKET` / `S3_FILE`
3. Recreating the container (keep the same `/data` volume if you want to preserve worlds/config)

---

## CI (GitHub Actions)

This repository includes workflows that (at minimum) validate builds and run checks. Build validation uses AWS credentials via OIDC and passes build args/secrets to the Docker build.

---

## Troubleshooting

### Players can’t connect
- Ensure you mapped the correct port/protocol: `-p 19132:19132/udp`
- Check host firewall/security groups allow **UDP 19132**
- If you’re on a VPS/cloud VM, confirm inbound rules include UDP

### Container starts but server doesn’t load worlds/config
- Confirm `/data` is mounted and writable
- Inspect logs:
  ```bash
  docker logs -f bedrock
  ```

### Build fails downloading from S3
- Verify `S3_BUCKET` / `S3_FILE` are correct
- Ensure the AWS identity used for the build has permission for `s3:GetObject` on that object
- Confirm `AWS_REGION` matches where you’re operating (or where your config expects)

---

## License

See [LICENSE](LICENSE).
