# JA Agro Invoice Manager

A Flutter application for managing invoices for **JA Agro Inputs & Trading**.

## Company Details
**JA Agro Inputs & Trading**
Dhanehari II, P.O - Saidpur(Mukam)
Cachar, Assam - 788013

- **GSTIN:** 18CCFPB3144R1Z5
- **Phone:** 8133878179
- **Email:** jaagro@example.com

### Bank Details
- **Bank:** State Bank of India
- **Account Number:** 36893269388
- **IFSC Code:** SBIN0001803
- **Account Holder:** JA Agro Inputs & Trading

## Setup Instructions

### Prerequisites
- Flutter SDK installed
- Android SDK installed (for Android build)

### Running the App

1.  **Navigate to the project directory:**
    ```bash
    cd invoice_app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

## Android Configuration for Share Plus

The app uses the `share_plus` package which requires configuration on Android to share files.

**Step 1**: Ensure `android/app/src/main/res/xml/filepaths.xml` exists with:
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-path name="external_files" path="." />
</paths>
```

**Step 2**: Ensure `android/app/src/main/AndroidManifest.xml` has the provider tag inside the `<application>` tag:
```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/filepaths" />
</provider>
```

## Features
- **Dashboard:** View daily and total revenue, recent invoices.
- **Create Invoice:** Generate invoices with auto-calculated GST (CGST/SGST/IGST).
- **PDF Generation:** Create professional PDFs with company branding.
- **Share:** Share invoices via WhatsApp/Email.
- **Search:** Search invoices by number.
- **Database:** Local SQLite database for offline storage.
