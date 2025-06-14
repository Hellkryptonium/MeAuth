# MeAuth: Authenticator & Password Manager

A secure, cross-platform mobile app for 2FA (TOTP) code generation and password management. Inspired by Google Authenticator and Bitwarden.

---

## Features

- TOTP (RFC 6238) 6-digit code generator
- Add accounts via QR code or manual entry
- AES-256 encrypted password vault (master password protected)
- Biometric unlock (fingerprint/face)
- Optional: Cloud sync (Firebase/Supabase)
- Optional: Password strength & breach check (HaveIBeenPwned)
- Optional: Autofill support (Android/iOS)
- Built with Flutter for Android & iOS

---

## Tech Stack

- **Flutter** (mobile framework)
- [`otp`](https://pub.dev/packages/otp) (TOTP)
- [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) (secure storage)
- AES-256 + PBKDF2 (encryption)
- [`local_auth`](https://pub.dev/packages/local_auth) (biometrics)
- [`qr_code_scanner`](https://pub.dev/packages/qr_code_scanner)
- State management: Provider / Riverpod / Bloc
- Backend: Firebase/Supabase/Node.js (optional)

---

## Getting Started

1. **Clone repo:**
   ```bash
   git clone https://github.com/yourusername/MeAuth.git
   cd MeAuth
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **(Optional) Set up Firebase/Supabase for sync**
4. **Run app:**
   ```bash
   flutter run
   ```

---

## Roadmap

1. TOTP generation & display
2. QR code/manual account entry
3. Encrypted password vault
4. Master password + biometrics
5. Cloud sync (optional)
6. Password strength/breach check (optional)
7. Autofill (advanced)
8. UI/UX polish

---

## Security

- All secrets/passwords encrypted locally (AES-256)
- Master password derives encryption key (PBKDF2)
- Biometric unlock for quick access
- End-to-end encrypted sync (if enabled)
- No sensitive data logged or sent in plain text

---

## License

MIT License

---

## Contact

**Name:** Mohd Harish  
**Email:** harishjs1006@gmail.com  
**Project:** [github.com/Hellkryptonium/MeAuth](https://github.com/Hellkryptonium/MeAuth)

---
## List of features

1. Core Features (Parity with Google Authenticator)

- TOTP (RFC 6238) & HOTP (RFC 4226) support
- QR code scanning and manual entry
- Multiple account support with custom labels/icons
- Backup & restore (encrypted, user-controlled)
- Cross-platform (Android/iOS) with smooth UX
- No cloud storage by default (privacy-first)

2. Security Best Practices

- All secrets/passwords encrypted at rest (AES-256)
- Master password with PBKDF2 or Argon2 for key derivation
- Biometric unlock (fingerprint/face) with fallback to device PIN/password
- Zero-knowledge: secrets never leave device unencrypted
- Clipboard auto-clear for copied codes
- No analytics or tracking
- App integrity checks (detect tampering/root/jailbreak)
- Secure storage using flutter_secure_storage or platform keystore

3. Advanced Features (Go Beyond Google Authenticator)

- Password manager (AES-256 encrypted vault)
- Cloud sync (optional, end-to-end encrypted, user-controlled)
- Password strength & breach check (HaveIBeenPwned API)
- Autofill support for passwords and OTPs
- Export/import (encrypted, user-initiated)
- App lockout after failed attempts
- Inactivity timeout auto-lock
- Customizable themes (dark/light/system)
- Accessibility support

4. Development Plan
MVP:

1. 
- TOTP/HOTP generation & display
- QR/manual account entry
- Local encrypted storage
- Biometric/device authentication
- Security Hardening:

2. 
- Key derivation (PBKDF2/Argon2)
- Clipboard auto-clear
- App integrity checks
- Password Vault:

3. 
- Add, edit, delete, search passwords
- Master password protection
- Optional Cloud Sync:

4. 
- End-to-end encrypted sync (Firebase/Supabase/self-hosted)
- Advanced UX:

Export/import
Accessibility
Theming
Testing & Audit:

Unit/integration tests
Security audit (manual & automated)

5. Super Secure Practices
Never store master password or secrets in plain text
Use secure random for key/IV generation
Lock app on background/switch
Wipe sensitive data from memory after use
Regularly update dependencies
Open source for transparency
Would you like to start with the MVP (TOTP, QR/manual entry, secure storage, biometric unlock), or focus on a specific area first? Let me know your priorities!

###
What’s implemented:
Local TOTP/HOTP account model
TOTP code generation and display
Add account via manual entry or QR code (UI only)
Biometric/device authentication
App auto-lock on background
What’s missing for real-world use:
No Secure Storage:
Accounts are not saved securely on the device. If you close the app, all accounts are lost.
→ You need to integrate flutter_secure_storage to persist and encrypt accounts.

No otpauth:// Parsing:
QR code scanning does not parse standard otpauth:// URIs, so you can’t add real 2FA accounts from Google, Microsoft, etc.
→ You need to parse otpauth:// URIs and extract label, secret, issuer, digits, etc.

No Backup/Restore:
There’s no way to backup or restore your accounts.

No Cloud Sync:
Optional, but not implemented. All data is local only.

No Password Vault:
Password manager features are not yet implemented.

No Security Hardening:
No clipboard auto-clear, no app integrity checks, etc.

No Backend Required:
For TOTP/HOTP, you do NOT need a backend. All secrets and code generation are local.
Backend is only needed for optional cloud sync or password breach checks.

What to do next to make it real:
Implement secure local storage for accounts.
Parse otpauth:// URIs for QR/manual entry.
Add backup/restore (export/import).
(Optional) Add cloud sync, password vault, and other advanced features.
Summary:
You can use this as a learning/demo authenticator, but not for real 2FA until secure storage and otpauth:// parsing are implemented.

Would you like to proceed with secure storage and otpauth:// parsing so you can use it as a real authenticator? I can implement those next!

1. Dark Mode Support
Automatically switch between light and dark themes based on system settings.
Allow manual theme selection in app settings.
2. Account Backup & Restore
Export accounts to an encrypted file.
Import accounts from a backup file.
(Optional) Integrate with Google Drive/iCloud for cloud backup.
3. Account Search & Organization
Add a search bar to quickly find accounts.
Allow users to reorder accounts (drag-and-drop).
Support folders or tags for grouping accounts.
4. Custom Account Icons
Show service logos (Google, Microsoft, GitHub, etc.) automatically.
Allow users to pick a custom icon or color for each account.
5. Security Enhancements
Add PIN code as an alternative to biometrics.
Allow users to set auto-lock timeout duration.
6. User Experience Improvements
Show a countdown/progress bar for TOTP code expiry.
Add a home screen widget (Android/iOS) for quick code access.
Show a notification with the current code for selected accounts.
Recommended next step:
Implement dark mode support and account backup/restore.
These are highly requested by users and add real value and security.

Would you like to start with dark mode, backup/restore, or another feature from the list?


1. UI/UX Plan
Drawer/Settings:
Add a “Password Vault” option under Settings in your side drawer.

Vault Screen:

List of saved passwords (app/site name, username, masked password, icon).
“Add Password” button (FAB).
Tap to view/copy password (with clipboard auto-clear).
Long-press to edit/delete.
Vault Security:

Require master password (set on first use) or biometrics to unlock.
Use PBKDF2 or Argon2 to derive an encryption key from the master password.
Encrypt all vault data at rest (using AES with the derived key).
Never store the master password, only a hash for verification.
2. Security Best Practices
Key Derivation:
Use PBKDF2 (built-in, cross-platform) or Argon2 (stronger, but needs a package) to derive a key from the master password.
Encryption:
Use AES-GCM or AES-CBC for encrypting vault data.
Clipboard Auto-Clear:
Clear copied passwords after 30 seconds.
Biometric Unlock:
Use device biometrics if available (fallback to master password).
Zero Knowledge:
Never store or transmit the master password.
3. Implementation Steps
A. Add “Password Vault” to Drawer
In your drawer widget, add a ListTile for “Password Vault” that navigates to a new PasswordVaultPage.
B. Vault Lock/Unlock
On first use, prompt user to set a master password (store a PBKDF2 hash).
On subsequent uses, prompt for master password or biometrics to unlock.
C. Vault Data Model
D. Encryption/Decryption
Use the derived key to encrypt/decrypt the vault entries.
Store the encrypted vault in secure storage.
E. UI for Add/Edit/Delete
Modal dialogs for adding/editing entries.
List view for displaying entries.
4. Packages You’ll Need
encrypt (AES encryption)
crypto (PBKDF2)
flutter_secure_storage (secure storage)
local_auth (biometrics)
5. Example: Add to Drawer
6. Next Steps
Would you like me to scaffold the PasswordVaultPage and the secure storage logic for you?
Do you want to use PBKDF2 (simpler, built-in) or Argon2 (stronger, needs extra package) for key derivation?
Let me know your preference and I’ll generate the code for the next step!

Security & Usability
Password Generator:
Add a built-in strong password generator with customizable options (length, symbols, etc.) when adding/editing entries.

Search & Filter:
Allow users to search and filter vault entries by app/site name or username.

Password Strength Meter:
Show a strength indicator when users create or edit passwords.

Export/Import Vault:
Securely export and import the encrypted vault (with warnings and confirmations).

Auto-Lock Timer:
Automatically lock the vault after a period of inactivity or when the app is backgrounded.

Biometric-Only Unlock Option:
Allow users to require biometrics only (no master password) for faster access, if desired.

UI/UX Enhancements
Favorites/Pin Entries:
Let users pin or favorite important accounts for quick access.

Custom Icons/Colors:
Allow more icon choices or custom colors for entries.

Multi-Account Support:
Support multiple vaults or user profiles (useful for families or work/personal separation).

Advanced Features
Breach Check:
Integrate with HaveIBeenPwned or similar to check if stored passwords have been compromised.

Password Expiry Reminders:
Notify users when passwords are old and should be updated.

Cloud Backup (Optional):
Allow users to back up their encrypted vault to a cloud provider (Google Drive, iCloud, etc.)—with strong warnings and opt-in.

Cross-Platform Sync:
Sync vault data securely across devices (requires careful design).

In-App Tutorial/Onboarding:
Guide new users through features and security best practices.

Would you like to implement any of these features next, or do you have a specific idea in mind?

