# JA Agro Invoice App - Phase 1 & 2 Implementation Guide

## Overview
This update transforms the invoice app into a professional agro-business solution. It introduces GST compliance features (Phase 1) and Agro-specific data fields (Phase 2), along with a robust database normalization.

## 1. Database Changes
**File:** `lib/database/database_helper.dart`

### New Table: `invoice_items`
We have moved from storing items as a JSON string to a normalized table `invoice_items`. This allows for future analytics and querying by batch number.

**Schema:**
- `invoice_number` (Foreign Key)
- `description`
- `hsn_code`
- `quantity`, `unit`, `rate`, `gst_rate`, `amount`, `total`
- **New Fields:** `batch_number`, `expiry_date`, `product_category`, `quality_grade`

### Invoices Table Updates
Added columns:
- `place_of_supply` (State Code)
- `reverse_charge` (Yes/No)
- `supply_type` (Taxable/Exempt)
- `round_off_amount`

### Migration
A migration script (`_migrateItemsTable`) automatically runs when the app is updated. It reads the old JSON `items` from the `invoices` table and inserts them into the new `invoice_items` table.

## 2. UI Changes

### Create Invoice Screen
**File:** `lib/screens/create_invoice_screen.dart`
- **Place of Supply:** Auto-defaults to the selected customer's state. If the customer is in a different state than the company (Assam), it triggers IGST calculation.
- **Reverse Charge:** Toggle switch added.
- **Supply Type:** Dropdown added.

### Add Item Dialog
**File:** `lib/widgets/add_item_dialog.dart`
- **Agro Fields:** Added inputs for Batch #, Expiry Date (Date Picker), and Quality Grade.
- **Auto-Category:** When an HSN is selected, the "Category" field is auto-filled (e.g., HSN 0701 -> Vegetables).

### Invoice Preview
**File:** `lib/screens/invoice_preview_screen.dart`
- Now fetches full invoice details from the database to ensure all fields (including the new items list) are displayed correctly.
- Supports generating the new professional PDF.

## 3. PDF Generation
**File:** `lib/utils/pdf_generator.dart`
- **Layout:** Redesigned to landscape-style table headers to fit more columns.
- **New Columns:** Added "Batch / Exp" and "Category" columns.
- **Header:** Displays Place of Supply and Reverse Charge status.
- **Footer:** Added Bank Details and Terms & Conditions.

## 4. Helper Classes
- **GSTHelper:** Handles IGST vs CGST/SGST logic and currency formatting.
- **Constants:** Contains State Codes, HSN lists, and Unit types.

## 5. Testing & Verification

### How to Test
1.  **Create New Invoice:**
    -   Select a customer from a different state (e.g., Meghalaya).
    -   Verify "Place of Supply" changes to "17 - Meghalaya".
    -   Add an item. Verify "IGST" is calculated in the totals (instead of CGST/SGST).
    -   Add an item with Batch "B-101" and Expiry Date.
    -   Save and Preview.
    -   Generate PDF and verify the columns show the new data.

2.  **Verify Migration (Old Data):**
    -   Open an old invoice from the list.
    -   Verify items still appear (they are migrated to the new table).
    -   Edit the invoice. You should be able to see the items and add new agro details to them.

## 6. Rollback (If needed)
The database version is incremented to `4`. To rollback code without losing data is difficult due to the schema change. However, the original `items` JSON column in the `invoices` table was NOT deleted, just ignored. If you revert the code to the previous version, the old app will still read the `items` JSON column (which will be stale for any *edited* invoices, but safe for *old* invoices).

---
**Status:** Ready for Deployment
**Date:** Jan 3, 2026
