#!/bin/bash

# See https://esc.sh/blog/access-s3-gcs-curl/

req_path="/secrets/ios/secrets.${1}.xcconfig"

# We need the current date to calculate the signature and also to pass to S3/GCS
curr_date=`date +'%a, %d %b %Y %H:%M:%S %z'`

# This is the name of your S3/GCS bucket
bucket_name="emitron"
string_to_sign="GET\n\n\n${curr_date}\n/${bucket_name}${req_path}"

# Your S3 key
s3_key=${AWS_ACCESS_KEY_ID}

# Your secret
secret=${AWS_SECRET_ACCESS_KEY}

# We will now calculate the signature to be sent as a header.
signature=$(echo -en "${string_to_sign}" | openssl sha1 -hmac "${secret}" -binary | base64)

# That's all we need. Now we can make the request as follows.

# S3
curl -v -H "Host: ${bucket_name}.s3.amazonaws.com" \
        -H "Date: $curr_date" \
        -H "Authorization: AWS ${s3_key}:${signature}" \
         "https://${bucket_name}.s3.amazonaws.com${req_path}" --compressed
