#!/bin/bash
set -e

MOBILEPROVISION=$1
CERT_NAME=$2

if [ $# -ne 2 ]; then
    echo "Usage: sh automate_resign.sh [provisionning_file] [distribution certificate name from keychain, example: \"My Company\"]"
        exit 1
fi


for f in *.ipa
do echo "Processing $f file.."

sh resign.sh "$f" "$MOBILEPROVISION" "$CERT_NAME"

done


