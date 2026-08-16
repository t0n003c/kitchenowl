# Self-hosted Android APK

The fork uses the Android application ID `com.t0n003c.kitchenowl`, so it installs alongside the official KitchenOwl app and can receive independent updates.

## One-time GitHub setup

Create a release keystore and keep a secure backup. Losing this keystore prevents future APKs from updating an installed copy.

```bash
keytool -genkeypair -v \
  -keystore kitchenowl-upload.jks \
  -storetype JKS \
  -alias kitchenowl \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Add these repository secrets under **Settings → Secrets and variables → Actions**:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded contents of `kitchenowl-upload.jks`
- `ANDROID_KEY_ALIAS`: normally `kitchenowl`
- `ANDROID_KEY_PASSWORD`: the key password chosen above
- `ANDROID_STORE_PASSWORD`: the keystore password chosen above

The keystore and passwords must never be committed to the repository.

## Build a release

Update the version in `kitchenowl/pubspec.yaml`, commit it to `main`, and push a tag:

```bash
git tag android-v0.7.10-125
git push origin android-v0.7.10-125
```

The `Build self-hosted Android APK` workflow builds the signed APK and attaches it to a GitHub Release. A manual workflow run is also available and stores the APK as a workflow artifact.

Install the APK from the release page. Future APKs signed with the same keystore and using the same application ID will update the existing forked app in place.
