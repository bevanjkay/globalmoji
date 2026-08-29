SCHEME = Globalmoji
DERIVED = build/DerivedData

.PHONY: generate build test lint format clean emoji-data

generate:
	xcodegen generate

build:
	xcodebuild -project Globalmoji.xcodeproj -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED) CODE_SIGNING_ALLOWED=NO build | xcbeautify || xcodebuild -project Globalmoji.xcodeproj -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED) CODE_SIGNING_ALLOWED=NO build

test:
	cd Packages/PickerCore && swift test
	cd Packages/InputEngine && swift test

lint:
	swiftformat --lint .
	swiftlint

format:
	swiftformat .

clean:
	rm -rf build Packages/*/.build

emoji-data:
	node Scripts/generate-emoji-data.mjs
