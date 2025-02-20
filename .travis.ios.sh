#!/bin/bash
if [[ $TRAVIS_COMMIT_MESSAGE == *"[skip ios]"* ]]
then
	echo "Skipping ios stage"
else
	source .travis.env.sh

    #
	# Provision the required files
	#
	travis_fold start "provision"

  # Install the kdk if required
	if [ $FLAVOR != "prod" ]
	then
		source .travis.kdk.sh
	fi

	# Copy the certificates
	cp workspace/common/ios/*.cer .
	cp workspace/common/ios/*.p12 .
  cp workspace/$FLAVOR/ios/*.cer .
	cp workspace/$FLAVOR/ios/*.p12 .

	# Create a custom keychain
	security create-keychain -p travis ios-build.keychain
	security default-keychain -s ios-build.keychain
	security unlock-keychain -p travis ios-build.keychain
  security set-keychain-settings -t 3600 -l ~/Library/Keychains/ios-build.keychain

	# Import the certificates into the keychain
	security import AppleWWDRCA.cer -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
	for CERTIFICATE in $APPLE_CERTIFICATES; do
 		security import $CERTIFICATE.cer -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
		security import $CERTIFICATE.p12 -k ~/Library/Keychains/ios-build.keychain -P $APPLE_P12_PASSWORD -T /usr/bin/codesign
	done
	
	# see: https://docs.travis-ci.com/user/common-build-problems/#mac-macos-sierra-1012-code-signing-errors
  security set-key-partition-list -S apple-tool:,apple: -s -k travis ios-build.keychain

	# Install the required secret files requied to sign the app
	cp workspace/$FLAVOR/ios/build.json src-cordova/.
	mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
	cp workspace/$FLAVOR/ios/*.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
 
  travis_fold end "provision"

	#
	# Build the app
	#
	travis_fold start "build"

	# Overwrite the title in dev/test flavor
	if [ $FLAVOR != "prod" ]
	then
		TITLE=$TITLE-$FLAVOR
	fi

	# Build the app
	npm run cordova:build:ios > ios.build.log 2>&1
	# Capture the build result
	BUILD_CODE=$?
	# Copy the log whatever the result
	aws s3 cp ios.build.log s3://$BUILDS_BUCKET/$BUILD_NUMBER/ios.build.log
	# Exit if an error has occured
	if [ $BUILD_CODE -ne 0 ]; then
		exit 1
	fi

    # Backup the ios build to S3
	aws s3 sync src-cordova/platforms/ios/build/device s3://$BUILDS_BUCKET/$BUILD_NUMBER/ios > /dev/null
	if [ $? -eq 1 ]; then
		exit 1
	fi

	travis_fold end "build"

	#
    # Deploy the app
	#
	travis_fold start "deploy"

    # Deploy the IPA to the AppleStore
	ALTOOL="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool"
	"$ALTOOL" --upload-app -f "./src-cordova/platforms/ios/build/device/$TITLE.ipa" -u "$APPLE_ID" -p "$APPLE_APP_PASSWORD" > ios.deploy.log 2>&1
	# Capture the deploy result
	DEPLOY_CODE=$?
	# Copy the log whatever the result
	aws s3 cp ios.deploy.log s3://$BUILDS_BUCKET/$BUILD_NUMBER/ios.deploy.log
	# Exit if an error has occured
	if [ $DEPLOY_CODE -ne 0 ]; then
		exit 1
	fi

	travis_fold end "deploy"
fi
