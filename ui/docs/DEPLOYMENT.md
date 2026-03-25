# Deployment Guide

This document explains how to set up the CI/CD pipelines for the Chat application.

## Overview

The deployment pipeline consists of three workflows:

| Workflow | Trigger | Build Type | Target |
|----------|---------|------------|--------|
| **CI** | Pull Requests | Debug | Validation only |
| **Staging** | Push to `main` | Debug | Internal testing |
| **Production** | Tags (`v*`) | Release | App stores |

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Pull       │     │   Push to   │     │   Tag       │
│  Request    │     │   main      │     │   v1.0.0    │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  CI         │     │  Staging    │     │  Production │
│  Workflow   │     │  Workflow   │     │  Workflow   │
└─────────────┘     └──────┬──────┘     └──────┬──────┘
                           │                   │
                           ▼                   ▼
                    ┌─────────────┐     ┌─────────────┐
                    │ Debug Build │     │Release Build│
                    └──────┬──────┘     └──────┬──────┘
                           │                   │
              ┌────────────┼────────────┐     │
              ▼            ▼            ▼     │
        ┌──────────┐ ┌──────────┐ ┌──────────┐│
        │Cloudflare│ │Play Store│ │Firebase  ││
        │ (staging)│ │(internal)│ │App Dist  ││
        └──────────┘ └──────────┘ └──────────┘│
                                              │
                           ┌──────────────────┼──────────────────┐
                           ▼                  ▼                  ▼
                    ┌──────────┐       ┌──────────┐       ┌──────────┐
                    │Cloudflare│       │Play Store│       │App Store │
                    │(prod)    │       │(prod)    │       │Connect   │
                    └──────────┘       └──────────┘       └──────────┘
```

## Required Secrets

Configure these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`).

### 1. Android Signing (Required for signed builds)

| Secret | Description | How to Obtain |
|--------|-------------|---------------|
| `ANDROID_SIGNING_KEY` | Base64-encoded keystore file | See [Create Android Keystore](#create-android-keystore) |
| `ANDROID_SIGNING_KEY_PASSWORD` | Key password | Set when creating keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | Set when creating keystore |

### 2. Google Play Store (Required for Android distribution)

| Secret | Description | How to Obtain |
|--------|-------------|---------------|
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | JSON service account key | See [Setup Google Play API](#setup-google-play-api) |

### 3. Apple App Store (Required for iOS distribution)

| Secret | Description | How to Obtain |
|--------|-------------|---------------|
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded .p12 certificate | See [Setup iOS Signing](#setup-ios-signing) |
| `P12_PASSWORD` | Certificate password | Set when exporting certificate |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64-encoded provisioning profile | See [Setup iOS Signing](#setup-ios-signing) |
| `KEYCHAIN_PASSWORD` | Temporary keychain password | Any secure random string |
| `APPLE_ISSUER_ID` | App Store Connect API Issuer ID | See [Setup App Store Connect API](#setup-app-store-connect-api) |
| `APPLE_KEY_ID` | App Store Connect API Key ID | See [Setup App Store Connect API](#setup-app-store-connect-api) |
| `APPLE_API_PRIVATE_KEY` | App Store Connect API private key | See [Setup App Store Connect API](#setup-app-store-connect-api) |

### 4. Cloudflare Pages (Required for Web deployment)

| Secret | Description | How to Obtain |
|--------|-------------|---------------|
| `CLOUDFLARE_API_TOKEN` | API token with Pages permissions | See [Setup Cloudflare Pages](#setup-cloudflare-pages) |
| `CLOUDFLARE_ACCOUNT_ID` | Your Cloudflare account ID | Cloudflare dashboard |

### 5. Firebase (Optional - for App Distribution)

| Secret | Description | How to Obtain |
|--------|-------------|---------------|
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON | Firebase Console > Project Settings > Service Accounts |
| `FIREBASE_APP_ID_ANDROID` | Firebase Android App ID | Firebase Console > Project Settings > General |
| `FIREBASE_APP_ID_IOS` | Firebase iOS App ID | Firebase Console > Project Settings > General |

### 6. Notifications (Optional)

| Secret | Description |
|--------|-------------|
| `SLACK_WEBHOOK_URL` | Slack incoming webhook URL |
| `DISCORD_WEBHOOK` | Discord webhook URL |

## Repository Variables

Configure these in `Settings > Secrets and variables > Actions > Variables`:

| Variable | Description | Example |
|----------|-------------|---------|
| `ANDROID_PACKAGE_NAME` | Android app package name | `com.antinvestor.chat` |
| `CLOUDFLARE_PROJECT_NAME` | Cloudflare Pages project (production) | `chat-app` |
| `CLOUDFLARE_PROJECT_NAME_STAGING` | Cloudflare Pages project (staging) | `chat-staging` |

## Setup Instructions

### Create Android Keystore

```bash
# Generate a new keystore
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias key

# Convert to base64 for GitHub secret
base64 -i upload-keystore.jks | pbcopy  # macOS
base64 upload-keystore.jks | xclip      # Linux
```

Store the output as `ANDROID_SIGNING_KEY` secret.

### Setup Google Play API

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to **Setup > API access**
3. Click **Create new service account**
4. Follow the link to Google Cloud Console
5. Create a service account with **Service Account User** role
6. Create a JSON key for the service account
7. Back in Play Console, grant the service account **Release manager** permission
8. Copy the entire JSON content as `GOOGLE_PLAY_SERVICE_ACCOUNT` secret

### Setup iOS Signing

#### Distribution Certificate

1. Open **Keychain Access** on your Mac
2. Go to **Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority**
3. Enter your email, select **Saved to disk**
4. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates)
5. Create a new **Apple Distribution** certificate using the CSR
6. Download and double-click to install
7. In Keychain Access, find the certificate, right-click > **Export**
8. Save as .p12 with a password
9. Convert to base64:
   ```bash
   base64 -i Certificates.p12 | pbcopy
   ```
10. Store as `BUILD_CERTIFICATE_BASE64`, password as `P12_PASSWORD`

#### Provisioning Profile

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/profiles)
2. Create a new **App Store** distribution profile
3. Select your app ID and distribution certificate
4. Download the .mobileprovision file
5. Convert to base64:
   ```bash
   base64 -i profile.mobileprovision | pbcopy
   ```
6. Store as `BUILD_PROVISION_PROFILE_BASE64`

### Setup App Store Connect API

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access > Keys**
3. Click the **+** to create a new key
4. Give it a name and select **Admin** access
5. Download the .p8 file (you can only download once!)
6. Note the **Key ID** and **Issuer ID**
7. Store:
   - `APPLE_ISSUER_ID`: The Issuer ID shown on the page
   - `APPLE_KEY_ID`: The Key ID for your key
   - `APPLE_API_PRIVATE_KEY`: The entire contents of the .p8 file

### Setup Cloudflare Pages

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Navigate to **Workers & Pages**
3. Create a new Pages project:
   - **Production**: `chat-app` (or your preferred name)
   - **Staging**: `chat-staging`
4. For API token:
   - Go to **My Profile > API Tokens**
   - Create a new token with **Cloudflare Pages:Edit** permission
5. Store:
   - `CLOUDFLARE_API_TOKEN`: The generated token
   - `CLOUDFLARE_ACCOUNT_ID`: Found in the dashboard URL or account settings

## Environment Configuration

### GitHub Environments

Create two environments in `Settings > Environments`:

1. **staging**
   - No protection rules (auto-deploy)
   - Environment URL: `https://chat-staging.pages.dev`

2. **production**
   - Optional: Required reviewers for approval
   - Optional: Wait timer before deployment
   - Environment URL: `https://chat.stawi.im`

## Deployment Process

### Staging Deployment

Staging deployments happen automatically when code is pushed to `main`:

```bash
git checkout main
git pull
git merge feature/my-feature
git push origin main
# Staging deployment starts automatically
```

### Production Deployment

Production deployments happen when you create a version tag:

```bash
# Update version in pubspec.yaml
# version: 1.2.0+123

# Commit the version bump
git add pubspec.yaml
git commit -m "chore: bump version to 1.2.0"
git push origin main

# Create and push the tag
git tag v1.2.0
git push origin v1.2.0
# Production deployment starts automatically
```

### Manual Deployment

You can also trigger deployments manually:

1. Go to **Actions** tab in GitHub
2. Select the workflow (Staging or Production)
3. Click **Run workflow**
4. For production, enter the version number

## Troubleshooting

### Android Build Fails

1. **Signing issues**: Verify `ANDROID_SIGNING_KEY` is properly base64 encoded
2. **Build errors**: Check Flutter and Java versions match `FLUTTER_VERSION` and `JAVA_VERSION`

### iOS Build Fails

1. **Certificate expired**: Create new certificate and update secrets
2. **Provisioning profile invalid**: Regenerate profile with correct app ID and certificate
3. **CocoaPods issues**: The workflow handles pod install, but check `Podfile` syntax

### Play Store Upload Fails

1. **Permission denied**: Ensure service account has Release Manager permissions
2. **Version code exists**: Increment `versionCode` in `pubspec.yaml`
3. **Track not found**: First upload must be done manually via Play Console

### App Store Upload Fails

1. **Invalid credentials**: Regenerate App Store Connect API key
2. **App not found**: Ensure app is created in App Store Connect first
3. **Build processing**: Wait for Apple's processing (can take 10-30 minutes)

### Cloudflare Deployment Fails

1. **Invalid token**: Create new API token with correct permissions
2. **Project not found**: Verify project name matches exactly
3. **Account ID wrong**: Check account ID in Cloudflare dashboard

## Monitoring Deployments

- **GitHub Actions**: Check the Actions tab for workflow runs
- **Cloudflare Pages**: Dashboard shows deployment history
- **Play Console**: Internal testing track shows staged builds
- **App Store Connect**: TestFlight shows processing status

## Security Best Practices

1. **Rotate secrets** regularly (every 6-12 months)
2. **Use environment protection** for production deployments
3. **Review workflow changes** before merging
4. **Keep Flutter version** pinned to avoid unexpected issues
5. **Monitor failed deployments** for security anomalies

## Support

For issues with the deployment pipeline:

1. Check workflow logs in GitHub Actions
2. Review this documentation
3. Contact the platform team
