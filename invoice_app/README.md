# Invoice App

A Flutter application for managing invoices.

## Setup Instructions

1.  **Create Project**:
    Ensure you have Flutter installed. Run the following command in your terminal (outside this directory if you moved the files):
    ```bash
    flutter create invoice_app
    ```
    *Note: If you are using this folder as is, ensure you run `flutter pub get`.*

2.  **Android Configuration for Share Plus**:
    The app uses the `share_plus` package which requires configuration on Android to share files.

    **Step 1**: Create `android/app/src/main/res/xml/filepaths.xml` with the following content:
    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <paths xmlns:android="http://schemas.android.com/apk/res/android">
        <external-path name="external_files" path="." />
    </paths>
    ```

    **Step 2**: Edit `android/app/src/main/AndroidManifest.xml` and add the provider tag inside the `<application>` tag (before the closing `</application>`):
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

3.  **Run the App**:
    ```bash
    flutter run
    ```
