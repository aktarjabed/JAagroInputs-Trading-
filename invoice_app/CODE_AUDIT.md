# Code Audit Report

## 1. Critical Issues (Crashes & Data Integrity)

### Database Schema & Initialization
- **Duplicate HSN Codes**: In `database_helper.dart` (`_insertDefaultHSN`), HSN codes `0704` (Cauliflower & Cabbage) and `3808` (Insecticides, Pesticides, Herbicides) are duplicated. This causes multiple identical entries in the search results, confusing the user.
- **Hardcoded Business Logic**: The company details (Name, Address, GSTIN) are hardcoded in `_createDB`. If the user clears app data or reinstalls, they cannot easily restore this unless they backup `invoice.db`.
- **Search Limitation**: `searchHSN` in `database_helper.dart` limits results to 20. If a user types a generic term like "Fresh", they might not see all relevant items.

### PDF Generation (`pdf_generator.dart`)
- **GST Rate Display Logic Error**: `_getCGSTRate` and `_getSGSTRate` blindly take the GST rate of the *first* item in the list (`gstItems.first.gstRate`). If an invoice contains items with different tax rates (e.g., 5% Fertilizer and 18% Pesticide), the summary table in the PDF will display the *wrong* tax rate for the entire tax amount, misleading the customer and potentially violating tax compliance.
- **Context Usage Risk**: `ScaffoldMessenger.of(context)` is called inside `catch` blocks in `generateAndSharePDF` and `printInvoice`. If the user navigates away before the async operation completes, `context` might be invalid. Although `context.mounted` checks were added (which is good), reliance on `BuildContext` in a static utility method is brittle design.

### UI & State Management
- **Async Gap Handling**: In `DashboardScreen` and `CreateInvoiceScreen`, there are `await` calls (e.g., `Navigator.push`, `DatabaseHelper` calls) followed by `loadStats` or `ScaffoldMessenger` usage. While `mounted` checks are present in some places, `Navigator.push` in `DashboardScreen` is followed by `loadStats()` without a `mounted` check. If the widget is disposed while on the other screen (unlikely but possible if deep linking or complex nav was involved), this throws an error.
- **TypeAhead Field Controller Logic**: In `CreateInvoiceScreen`, `customerNameController.text = controller.text;` inside the builder might cause conflicts if the controller is being updated from `onSelected` simultaneously.

## 2. Business Logic Errors

### Tax Calculations
- **GST Calculation Display**: As noted above, the PDF displays a single "CGST @ X%" line even if multiple rates exist. The calculation logic in `CreateInvoiceScreen` (`calculateTotals`) correctly sums up tax amounts, but the *display* in the PDF simplifies it incorrectly.
- **Intrastate vs Interstate**: The logic relies on string comparison `customerStateController.text.trim().toLowerCase() != 'assam'`. This is fragile. 'Assam ' or 'assam' works, but typos like 'Asam' would trigger IGST incorrectly.

### Currency Formatting
- **Number Format**: The app uses `NumberFormat('#,##,##0.00')` manually. The standard Indian format is handled better by `NumberFormat.currency(locale: 'en_IN', symbol: '₹')`. The manual pattern `#,##,##0.00` attempts to force Indian grouping but `intl` package patterns behave differently than standard Java/C#. The correct pattern for Indian lakh/crore grouping is complex to hardcode manually without the locale.
- **Number to Words**: The `_convertToWords` function in `pdf_generator.dart` has a logic flaw where it rounds the total (`value.round()`). An invoice of ₹100.50 should be "One Hundred Rupees and Fifty Paise", not "One Hundred and One Rupees". Rounding money without user consent is generally incorrect for accounting.

## 3. Code Duplication & Maintainability

### Duplication
- **StatCard**: Good use of a reusable widget.
- **Add Item Dialog**: Logic for validating numbers is repeated for quantity and rate.
- **Date Formatting**: `DateFormat('dd/MM/yyyy')` is instantiated multiple times. It should be a constant or a utility.

### Configuration
- **Assets**: `pubspec.yaml` has `assets` commented out. If the user adds a logo later, this needs uncommenting.
- **Linting**: `flutter_lints` is present, which is good.

## 4. Recommendations
1. **Fix PDF GST Display**: Instead of showing one rate, group taxes by rate (e.g., "CGST @ 2.5%", "CGST @ 9%") or just show the total tax amount if a detailed breakup is not required.
2. **Refactor Database Init**: Move hardcoded HSN data and Company Settings to a JSON file or a separate constant file to keep `database_helper.dart` clean.
3. **Robust Currency Formatting**: Use `NumberFormat.currency(locale: 'en_IN')` for all price displays.
4. **Fix Number-to-Words**: Implement decimal handling (Paise) instead of rounding.
5. **Safe Async UI**: Ensure all `await` calls in UI widgets are followed by `if (!mounted) return;` before touching state or context.
