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