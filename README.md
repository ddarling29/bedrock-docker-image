# bedrock-docker-image
Dockerfile for Minecraft Bedrock

## Building the Image

To build the image, you need to provide the S3 bucket and file name where your Minecraft Bedrock server zip is stored. You also need to provide AWS credentials as secrets.

```bash
docker build \
  --secret id=aws_credentials,src=$HOME/.aws/credentials \
  --secret id=aws_config,src=$HOME/.aws/config \
  --build-arg S3_BUCKET=your-bucket-name \
  --build-arg S3_FILE=bedrock-server.zip \
  -t bedrock-server .
```

## Running the Container

### Default (Bridge) Mode
By default, Docker uses the bridge network. This allows the container to access the internet (outbound) for services like authentication. To allow players to connect (inbound), you must map the Minecraft UDP port:

```bash
docker run -d \
  -p 19132:19132/udp \
  --name minecraft-server \
  bedrock-server
```

### Host Mode
If you want the container to share the host's network stack directly (which can simplify connectivity issues and improve performance), use the `--network host` flag:

```bash
docker run -d \
  --network host \
  --name minecraft-server \
  bedrock-server
```

Note: In host mode, you don't need `-p` because the server will bind directly to the host's port.

## Environment Variables

You can override `server.properties` values using environment variables:

- `SERVER_NAME`
- `GAMEMODE`
- `DIFFICULTY`
- `ONLINE_MODE`
- (and many others, see `src/run.sh` for the full list)

Example:
```bash
docker run -d \
  -p 19132:19132/udp \
  -e SERVER_NAME="My Awesome Server" \
  -e ONLINE_MODE=true \
  --name minecraft-server \
  bedrock-server
```
