import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'models/auth_account.dart';
import 'pages/totp_list_page.dart';
import 'pages/qr_scan_page.dart';
import 'pages/add_account_page.dart';
import 'services/account_storage_service.dart';
import 'services/otpauth_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeAuth',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),  // Google blue
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade50,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,        ),        scaffoldBackgroundColor: Colors.grey.shade50,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            minimumSize: const Size(120, 45),
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8AB4F8),  // Lighter blue for dark theme
          brightness: Brightness.dark,        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            minimumSize: const Size(120, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _authenticated = false;
  String? _error;  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only lock the app when it goes to background for a significant time
    // This prevents authentication loops during quick operations like delete
    if (state == AppLifecycleState.paused) {
      // Use a significant delay to avoid locking during biometric operations
      // This is especially important for delete operations that involve authentication
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && state == AppLifecycleState.paused) {
          setState(() {
            _authenticated = false;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _authenticate() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access MeAuth',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow biometrics or device PIN/password
        ),
      );
      setState(() {
        _authenticated = didAuthenticate;
        _error = didAuthenticate ? null : 'Authentication failed';
      });
    } catch (e) {
      setState(() {
        _error = 'Error: \\${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      return const MyHomePage(title: 'MeAuth');
    }    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and app name
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MeAuth',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Secure Authenticator',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Authentication section
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          _error ?? 'Authentication Required',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: _error != null ? Colors.red : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please authenticate to access your secure accounts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: _authenticate,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text(
                            'Authenticate',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<AuthAccount> _accounts = [];
  final AccountStorageService _storageService = AccountStorageService();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final loaded = await _storageService.loadAccounts();
    setState(() {
      _accounts = loaded;
    });
  }

  Future<void> _saveAccounts() async {
    await _storageService.saveAccounts(_accounts);
  }

  void _addAccount(AuthAccount acc) {
    setState(() {
      _accounts.add(acc);
    });
    _saveAccounts();
  }

  void _scanQrAndAdd(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => QrScanPage(
        onScanned: (data) {
          final acc = OtpAuthParser.parse(data);
          if (acc != null) {
            // Prevent duplicate accounts by secret
            if (_accounts.any((a) => a.secret == acc.secret)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account already exists.')),
              );
            } else {
              _addAccount(acc);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid otpauth:// QR code')),
            );
          }
        },
      ),
    ));
  }

  void _deleteAccount(AuthAccount acc) async {
    // First save the updated accounts list (remove the account)
    final updatedAccounts = List<AuthAccount>.from(_accounts)..remove(acc);
    
    // Save to storage immediately before updating state
    await _storageService.saveAccounts(updatedAccounts);
    
    // Only then update the state to ensure consistency
    if (mounted) {
      setState(() {
        _accounts = updatedAccounts;
      });
    }
  }

  void _manualAdd(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => AddAccountPage(onAdd: _addAccount),
    ));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TotpListPage(
        accounts: _accounts,
        onAddAccount: () => _manualAdd(context),
        onScanQr: () => _scanQrAndAdd(context),
        onDelete: _deleteAccount,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _manualAdd(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }
}
