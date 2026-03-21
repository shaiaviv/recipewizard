# Syncing Between Two iPhones with CloudKit

RecipeWizard currently stores recipes locally on each device. This guide explains how to enable two-device sync once you have an Apple Developer account.

---

## Requirements

- Apple Developer Program membership ($99/year) — [enroll here](https://developer.apple.com/programs/enroll/)
- Both users each have their own Apple ID (your setup)

---

## Step 1 — Enable CloudKit in Xcode

1. Open `iOS/RecipeWizard.xcodeproj`
2. Select the **RecipeWizard** target → **Signing & Capabilities**
3. Click `+ Capability` → **iCloud**
4. Check ✅ **CloudKit**
5. Under "Containers", add: `iCloud.com.yourname.recipewizard`

---

## Step 2 — Update entitlements

Open `iOS/RecipeWizard/Resources/RecipeWizard.entitlements` and uncomment the CloudKit section:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.yourname.recipewizard</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

---

## Step 3 — Update RecipeWizardApp.swift

Change the `ModelConfiguration` to use CloudKit:

```swift
// In RecipeWizardApp.swift — replace the existing config with:
let config = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .private("iCloud.com.yourname.recipewizard")
)
```

---

## Step 4 — Set up CloudKit Sharing (separate Apple IDs)

Since you and your partner have separate Apple IDs, you need to share your CloudKit zone.

Add this to your app (e.g. in `RecipeListView`'s toolbar):

```swift
import CloudKit

Button("Share Recipe Book") {
    Task { await shareRecipeBook() }
}

func shareRecipeBook() async {
    // Create a persistent zone for recipes
    let zoneID = CKRecordZone.ID(zoneName: "RecipeZone", ownerName: CKCurrentUserDefaultName)
    let zone = CKRecordZone(zoneID: zoneID)

    do {
        try await CKContainer(identifier: "iCloud.com.yourname.recipewizard")
            .privateCloudDatabase
            .save(zone)

        // Create a share for this zone
        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = "Our Recipe Book"

        try await CKContainer(identifier: "iCloud.com.yourname.recipewizard")
            .privateCloudDatabase
            .save(share)

        // Present the sharing UI
        let sharingController = UICloudSharingController(share: share,
            container: CKContainer(identifier: "iCloud.com.yourname.recipewizard"))
        // Present sharingController...
    } catch {
        print("CloudKit sharing error: \(error)")
    }
}
```

Your partner taps the share link → accepts → their phone syncs the same recipes automatically.

---

## Sync behavior

- **Latency:** 10–60 seconds between devices (this is normal for CloudKit)
- **Conflicts:** SwiftData resolves conflicts by taking the most recently updated record
- **Offline:** Recipes saved offline sync when the device next connects to the internet

---

## SwiftData + CloudKit constraints

CloudKit imposes some limits on SwiftData models. The app's models are already designed to be compatible:

| Constraint | How RecipeWizard handles it |
|-----------|---------------------------|
| All properties must be optional or have defaults | ✅ All fields are optional or have default values |
| No native `[String]` arrays | ✅ `tags` are stored as `Data` (JSON-encoded) |
| No required back-references | ✅ All relationships are optional |

If you add new properties to the models, make sure they follow these rules.
