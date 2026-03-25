# iOS OAuth Setup

When you create the iOS project on macOS, add the following URL scheme configuration.

## Steps

1. **Create iOS project** (on macOS):
   ```bash
   flutter create --platforms=ios .
   ```

2. **Edit `ios/Runner/Info.plist`** - Add this inside the `<dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.antinvestor.chat</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.antinvestor.chat</string>
        </array>
    </dict>
</array>
```

3. **Verify the redirect URI** matches what's registered on your OAuth server:
   - iOS/Android: `com.antinvestor.chat://sso/redirect`

## Full Info.plist Example

The URL types section should look like this in context:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... other keys ... -->
    
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>com.antinvestor.chat</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.antinvestor.chat</string>
            </array>
        </dict>
    </array>
    
    <!-- ... other keys ... -->
</dict>
</plist>
```
