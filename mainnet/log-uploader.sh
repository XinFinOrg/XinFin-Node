#!/bin/sh
set -eu

required_vars="AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION S3_LOG_BUCKET INSTANCE_NAME NETWORK"
for var in $required_vars; do
    eval "value=\${$var:-}"
    if [ -z "$value" ]; then
        echo "Missing required environment variable: $var" >&2
        exit 1
    fi
done

sed \
    -e "s|\${S3_LOG_BUCKET}|${S3_LOG_BUCKET}|g" \
    -e "s|\${AWS_DEFAULT_REGION}|${AWS_DEFAULT_REGION}|g" \
    -e "s|\${INSTANCE_NAME}|${INSTANCE_NAME}|g" \
    -e "s|\${NETWORK}|${NETWORK}|g" \
    /fluent-bit/etc/fluent-bit.conf.template >/tmp/fluent-bit.conf

echo "Uploading logs to s3://${S3_LOG_BUCKET}/${NETWORK}/${INSTANCE_NAME}/"
exec /fluent-bit/bin/fluent-bit -c /tmp/fluent-bit.conf
