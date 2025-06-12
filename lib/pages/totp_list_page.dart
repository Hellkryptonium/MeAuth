import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:base32/base32.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';
import '../models/auth_account.dart';
import 'dart:math' as math;
import 'settings_page.dart';

class TotpListPage extends StatefulWidget {
  final List<AuthAccount> accounts;
  final VoidCallback onAddAccount;
  final VoidCallback onScanQr;
  final void Function(AuthAccount) onDelete;
  final ValueNotifier<ThemeMode> themeModeNotifier;
  const TotpListPage({super.key, required this.accounts, required this.onAddAccount, required this.onScanQr, required this.onDelete, required this.themeModeNotifier});

  @override
  State<TotpListPage> createState() => _TotpListPageState();
}

class _TotpListPageState extends State<TotpListPage> {
  late Timer _timer;
  int _now = DateTime.now().millisecondsSinceEpoch;
  AuthAccount? _longPressedAccount;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now().millisecondsSinceEpoch;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  String _generateCode(AuthAccount acc) {
    try {
      // Clean up the secret (remove spaces, uppercase)
      final secretKey = acc.secret.replaceAll(' ', '').toUpperCase();
      
      final algorithm = acc.algorithm.toUpperCase();
      Algorithm algo = Algorithm.SHA1;
      if (algorithm == 'SHA256') algo = Algorithm.SHA256;
      if (algorithm == 'SHA512') algo = Algorithm.SHA512;
      
      if (acc.type == OtpType.totp) {
        final code = OTP.generateTOTPCodeString(
          secretKey,  // Pass the base32 encoded string
          _now,
          interval: acc.period,
          length: acc.digits,
          algorithm: algo,
          isGoogle: true, // Add this flag for Google Authenticator compatibility
        );
        debugPrint('TOTP for \\${acc.label}: code=\\$code, time=\\$_now, secret=\\$secretKey, digits=\\${acc.digits}, period=\\${acc.period}, algo=\\$algorithm');
        return code;
      } else {
        return 'HOTP'; // Placeholder for HOTP
      }
    } catch (e) {
      debugPrint('TOTP error for \\${acc.label}: \\${e.toString()}');
      return 'ERR';
    }
  }

  double _progress(AuthAccount acc) {
    final seconds = (_now / 1000).floor();
    return ((acc.period - (seconds % acc.period)) / acc.period);
  }  void _confirmDelete(BuildContext context, AuthAccount account) async {
    // Show a modern bottom sheet dialog first
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 220,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 15),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                'Delete "${account.issuer ?? account.label}"?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('This action requires authentication and cannot be undone'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 45),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(120, 45),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != true) {
      setState(() => _longPressedAccount = null);
      return;
    }

    // Proceed with biometric authentication
    final LocalAuthentication auth = LocalAuthentication();
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to delete this account',
        options: const AuthenticationOptions(
          biometricOnly: false,
        ),
      );
      
      if (didAuthenticate && context.mounted) {
        widget.onDelete(account);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${account.issuer ?? account.label} deleted'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: ${e.toString()}')),
        );
      }
    }
    
    setState(() => _longPressedAccount = null);
  }
  
  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Code copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            children: [
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.blueGrey),
                title: const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(themeModeNotifier: widget.themeModeNotifier),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        title: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: const Text('MeAuth',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR',
            onPressed: widget.onScanQr,
          ),
        ],
      ),
      body: widget.accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, size: 64, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No authenticator accounts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Add an account by scanning a QR code or entering details manually',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: widget.onAddAccount,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: widget.accounts.length,
              itemBuilder: (context, index) {
                final acc = widget.accounts[index];
                final code = _generateCode(acc);
                final progress = _progress(acc);
                
                // Split the code into groups of 3 for better readability
                String formattedCode = '';
                for (int i = 0; i < code.length; i++) {
                  formattedCode += code[i];
                  if (i == 2 && code.length > 3) formattedCode += ' ';
                }

                // Calculate animation values for progress
                final animatedColor = ColorTween(
                  begin: Colors.red,
                  end: Colors.blue,
                ).transform(progress < 0.2 ? 0 : (progress - 0.2) / 0.8) ?? Colors.blue;                  return Dismissible(
                  key: Key(acc.secret),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    // Show confirmation and authenticate
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) {
                        return Container(
                          height: 220,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 10, bottom: 15),
                                height: 4,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Delete "${acc.issuer ?? acc.label}"?',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text('This action requires authentication and cannot be undone'),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(120, 45),
                                      side: const BorderSide(color: Colors.grey),
                                    ),
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      minimumSize: const Size(120, 45),
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                    if (result != true) return false;
                    // Biometric authentication
                    final LocalAuthentication auth = LocalAuthentication();
                    try {                      bool didAuthenticate = await auth.authenticate(
                        localizedReason: 'Please authenticate to delete this account',
                        options: const AuthenticationOptions(
                          biometricOnly: false,
                          stickyAuth: true, // Keep authentication session open
                          useErrorDialogs: true,
                        ),
                      );
                      if (didAuthenticate) {
                        return true;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Authentication failed. Account not deleted.')),
                        );
                        return false;
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Authentication failed: \\${e.toString()}')),
                      );
                      return false;
                    }
                  },
                  onDismissed: (_) {
                    widget.onDelete(acc);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Text('${acc.issuer ?? acc.label} deleted'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        margin: const EdgeInsets.all(8),
                      ),
                    );
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline, color: Colors.white),
                      ],
                    ),
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _copyToClipboard(context, code),
                      onLongPress: () async {
                        HapticFeedback.mediumImpact();
                        _longPressedAccount = acc;
                        // Show the same confirmation and authentication dialog as swipe
                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) {
                            return Container(
                              height: 220,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 10, bottom: 15),
                                    height: 4,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Delete "${acc.issuer ?? acc.label}"?',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('This action requires authentication and cannot be undone'),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(120, 45),
                                          side: const BorderSide(color: Colors.grey),
                                        ),
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          minimumSize: const Size(120, 45),
                                        ),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        if (result == true) {
                          // Biometric authentication
                          final LocalAuthentication auth = LocalAuthentication();
                          try {                            // First get the account name before deletion
                            final accountName = acc.issuer ?? acc.label;

                            // Use a shorter timeout and stickyAuth to prevent app from locking
                            bool didAuthenticate = await auth.authenticate(
                              localizedReason: 'Please authenticate to delete this account',
                              options: const AuthenticationOptions(
                                biometricOnly: false,
                                stickyAuth: true, // Keep authentication session open
                                useErrorDialogs: true,
                              ),
                            );

                            if (didAuthenticate && context.mounted) {
                              // Call delete first - must happen before any UI updates
                              widget.onDelete(acc);
                              
                              // Show success message after deletion
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text('$accountName deleted'),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    margin: const EdgeInsets.all(8),
                                  ),
                                );
                              }
                            }else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Authentication failed. Account not deleted.')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Authentication failed: \\${e.toString()}')),
                              );
                            }
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with issuer and copy icon
                                Row(
                                  children: [
                                    // Issuer icon
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Color((acc.issuer?.hashCode ?? acc.label.hashCode) | 0xFF000000).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        (acc.issuer?.isNotEmpty == true ? acc.issuer![0] : acc.label[0]).toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Issuer name
                                    Expanded(
                                      child: Text(
                                        acc.issuer ?? acc.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    // Copy icon
                                    Icon(Icons.copy_outlined, size: 16, color: Colors.grey[400]),
                                  ],
                                ),
                                // Account label if different from issuer
                                if (acc.issuer != null && acc.issuer != acc.label)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 36),
                                    child: Text(
                                      acc.label,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                // Code display with animation
                                Center(
                                  child: Hero(
                                    tag: 'code-${acc.secret}',                                    child: Text(
                                      formattedCode,
                                      style: TextStyle(
                                        fontSize: 32, 
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2.0,
                                        color: progress < 0.2 ? 
                                          Colors.red.shade700 : 
                                          Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                          // Modern animated progress bar at the bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                builder: (context, value, _) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 4,
                                    backgroundColor: Colors.grey[100],                                    valueColor: AlwaysStoppedAnimation<Color>(animatedColor),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
