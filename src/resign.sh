#!/bin/bash
set -e

#Method used in order to increment a Build version
#It will always increment the X in any case
#Input : Param 1 : build version  Param 2 : bool saying if the Version is a Bundle Version (INTEGER) or a Short Version (DECIMAL)
function incrementVersion(){
    VERSION="$1"

    SPLIT_VERSION=(`echo $VERSION | tr '.' ' '`)
    ARRAY_SIZE=${#SPLIT_VERSION[@]}
    UPDATED_VERSION=$((${SPLIT_VERSION[0]}+1))

    echo ${UPDATED_VERSION%.}
}

#Retrieving parameters
IPA=$1
IPA_NAME=${IPA%%.*}
MOBILEPROVISION=$2
CERT_NAME=$3
BUILD_NUMBER=$4
VERSION_NUMBER=$5

echo $IPA
echo $MOBILEPROVISION
echo $CERT_NAME

#Check if every parameter is here
if [ "$#" -lt 3 ]; then
    echo "Usage: sh resign.sh [ipa_file] [provisionning_file] [distribution certificate name from keychain, example: \"My Company\"] [Facultatif:Build_number] [Facultatif: version_number]"
    exit 1
fi

#Check if the name of the IPA is correct and Unzip it : it creates a Payload folder
if [ ! -f $IPA ]; then
  echo "file not found"
else
  echo "unzipping $IPA"
  unzip $IPA
fi

cd Payload
APP_NAME=$(find . -maxdepth 1 -type d \( -name "*.app" \))
cd ..

#If the name is neither "Info.plist" nor "APPNAME-Info.plist", it won't work
PLIST0=Payload/"${APP_NAME}"/$IPA_NAME-Info.plist
PLIST1=Payload/"${APP_NAME}"/Info.plist

if [ -f "${PLIST0}" ]; then 
    PLIST_SELECTED=${PLIST0}
elif [ -f "${PLIST1}" ]; then
    PLIST_SELECTED=${PLIST1}
else
    echo "No .plist found. Aborting..."
    rm -rf Payload/
    rm -rf SwiftSupport/
    rm Entitlements.plist*
    rm -rf __MACOSX
    exit 1
fi

if [ -f "${PLIST_SELECTED}" ]; then 
    #Retrieving the build number from a *.plist file 
    OLD_BUNDLE_VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_SELECTED"`

    #Increments the build version
    if [ -n "$BUILD_NUMBER" ]; then
        NEW_BUNDLE_VERSION=$BUILD_NUMBER
    else
        NEW_BUNDLE_VERSION=$(incrementVersion $OLD_BUNDLE_VERSION)
        echo "New version : $NEW_BUNDLE_VERSION"
    fi

    #Modification of the *.plist with the new versions
    BUNDLE_IDENTIFIER=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$PLIST_SELECTED"`
    echo "changing version from $OLD_BUNDLE_VERSION to $NEW_BUNDLE_VERSION for $BUNDLE_IDENTIFIER"
    `/usr/libexec/PlistBuddy -c "Set CFBundleVersion $NEW_BUNDLE_VERSION" "$PLIST_SELECTED"`
    if [ -f "${VERSION_NUMBER}" ]; then
        echo "changing short-version from $OLD_BUNDLE_SHORT to $NEW_BUNDLE_SHORT"
        `/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $VERSION_NUMBER" "$PLIST_SELECTED"`
    fi
fi

#Creation of the new certificat
echo "Security Part"
security cms -D -i $MOBILEPROVISION 2> /dev/null > /tmp/tmp.plist && /usr/libexec/PlistBuddy -x -c 'Print:Entitlements' /tmp/tmp.plist > Entitlements.plist
echo "Cleaning Part"
#rm /tmp/tmp.plist
rm -r "Payload/$APP_NAME/_CodeSignature" "Payload/$APP_NAME/CodeResources" 2> /dev/null | true
cp $MOBILEPROVISION "Payload/$APP_NAME/embedded.mobileprovision" 
sed -i -e "s/com.leroymerlin.\*/$BUNDLE_IDENTIFIER/g" Entitlements.plist
/usr/bin/codesign -f -s "iPhone Distribution: $CERT_NAME" --entitlements Entitlements.plist "Payload/$APP_NAME"
echo "$BUNDLE_IDENTIFIER"
#Storage of the new IPAs in a folder named "signed_IPAs"
mkdir -p "signed_IPAs"
zip -qr "signed_IPAs/$IPA_NAME-resigned.ipa" Payload
rm -rf Payload/
rm -rf SwiftSupport/
#rm -rf Entitlements.plist*
rm -rf __MACOSX
echo "Creation de l'IPA : SUCCES"
