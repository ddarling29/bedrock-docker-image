FROM amazon/aws-cli:2.32.32 AS fetcher

ARG S3_BUCKET
ARG S3_FILE

RUN --mount=type=secret,id=aws_access_key_id \
    --mount=type=secret,id=aws_secret_access_key \
    --mount=type=secret,id=aws_session_token \
    --mount=type=secret,id=aws_region \
    export AWS_ACCESS_KEY_ID="$(cat /run/secrets/aws_access_key_id)" && \
    export AWS_SECRET_ACCESS_KEY="$(cat /run/secrets/aws_secret_access_key)" && \
    export AWS_SESSION_TOKEN="$(cat /run/secrets/aws_session_token)" && \
    export AWS_REGION="$(cat /run/secrets/aws_region)" && \
    aws s3 cp "s3://${S3_BUCKET}/${S3_FILE}" /out/bedrock-server.zip ; \

FROM ubuntu:24.04 AS runner
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4 ca-certificates unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /bedrock

COPY --from=fetcher /out/bedrock-server.zip ./bedrock-server.zip
COPY src/ ./scripts

RUN ./scripts/build.sh ./bedrock-server.zip /opt/bedrock-server /data/bedrock-server

EXPOSE 19132/udp
VOLUME ["/data"]

ENTRYPOINT [ "./scripts/run.sh", "--binary", "/opt/bedrock-server/bedrock_server", "--data", "/data/bedrock-server" ]