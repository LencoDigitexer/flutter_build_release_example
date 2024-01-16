.PHONY: all get_version echo_version flutter_test build_androidApk build_windowsExe create_release

all: create_release

get_version:
	@echo "Current directory: $$(pwd)"
	@ls -la
	@echo "APP_VERSION=$$(grep -oP 'version: \K(.*)' pubspec.yaml | head -n 1 | tr -d '\r')" >> $${GITHUB_ENV}

echo_version: get_version
	@echo "TETSTSTYTDSYFTYUFDTYU   $${github.event.outputs.APP_VERSION}"

flutter_test: get_version
	@echo "Running Flutter Tests"
	@make flutter_test_android
	@make flutter_test_windows

flutter_test_android:
	@echo "Running Flutter Tests for Android"
	@make build_androidApk

flutter_test_windows:
	@echo "Running Flutter Tests for Windows"
	@make build_windowsExe

build_androidApk: flutter_test
	@echo "Building Flutter App (Android)"
	@make flutter_build_android

build_windowsExe: flutter_test
	@echo "Building Flutter App (Windows)"
	@make flutter_build_windows

flutter_build_android:
	@echo "Building Android APK"
	@flutter pub get
	@flutter clean
	@flutter build apk --split-per-abi

flutter_build_windows:
	@echo "Building Windows Executable"
	@flutter pub get
	@flutter clean
	@flutter build windows --release
	@echo "Zipping artifacts"
	@zip -r release$${github.run_number}.zip build/windows/x64/runner/Release/*

create_release: build_androidApk build_windowsExe
	@echo "Creating GitHub Release"
	@make download_android_artifact
	@make download_windows_artifact
	@make github_release

download_android_artifact:
	@echo "Downloading Android Artifact"
	@gh run download -D build/app/outputs/apk/release/ -R $${GITHUB_REPOSITORY} -r $${{ github.run_id }} -p build/app/outputs/apk/release/

download_windows_artifact:
	@echo "Downloading Windows Artifact"
	@gh run download -D build/windows/x64/runner/Release/ -R $${GITHUB_REPOSITORY} -r $${{ github.run_id }} -p build/windows/x64/runner/Release/

github_release: download_android_artifact download_windows_artifact
	@echo "Creating GitHub Release"
	@gh release create v$${github.event.outputs.FLUTTER_VERSION} -t v$${github.event.outputs.FLUTTER_VERSION} -F release-notes.md build/app/outputs/apk/release/*.apk build/windows/x64/runner/Release/*.zip
