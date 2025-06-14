import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:base32/base32.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';
import '../models/auth_account.dart';
import 'dart:math' as math;
import 'settings_page.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'password_vault_page.dart'; // Import PasswordVaultPage

class TotpListPage extends StatefulWidget {
  final List<AuthAccount> accounts;
  final VoidCallback onAddAccount;
  final VoidCallback onScanQr;
  final void Function(AuthAccount) onDelete;
  final void Function(AuthAccount, String, String)? onEdit; // Add onEdit callback
  final ValueNotifier<ThemeMode> themeModeNotifier;
  const TotpListPage({super.key, required this.accounts, required this.onAddAccount, required this.onScanQr, required this.onDelete, this.onEdit, required this.themeModeNotifier});

  @override
  State<TotpListPage> createState() => _TotpListPageState();
}

class _TotpListPageState extends State<TotpListPage> {
  late Timer _timer;
  int _now = DateTime.now().millisecondsSinceEpoch;
  AuthAccount? _longPressedAccount;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

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
    // Auto-clear clipboard after 30 seconds
    Future.delayed(const Duration(seconds: 30), () async {
      final data = await Clipboard.getData('text/plain');
      if (data != null && data.text == code) {
        Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }
  
  void _showAccountOptions(BuildContext context, AuthAccount acc) async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );
    if (result == 'edit') {
      _showEditAccountDialog(context, acc);
    } else if (result == 'delete') {
      _confirmDelete(context, acc);
    }
  }

  void _showEditAccountDialog(BuildContext context, AuthAccount acc) async {
    final labelController = TextEditingController(text: acc.label);
    String selectedIcon = acc.icon;
    final List<String> materialIcons = [
      'key', 'security', 'lock', 'account_circle', 'vpn_key', 'shield', 'star', 'person', 'email', 'phone', 'cloud', 'home', 'work', 'wallet', 'credit_card', 'devices', 'wifi', 'apartment', 'business', 'school', 'shopping_cart', 'flight', 'directions_car', 'favorite', 'pets', 'cake', 'sports_soccer', 'fitness_center', 'music_note', 'movie', 'book', 'camera', 'gamepad', 'code', 'build', 'bug_report', 'emoji_objects', 'lightbulb', 'rocket', 'science', 'medication', 'local_hospital', 'restaurant', 'local_cafe', 'local_bar', 'beach_access', 'park', 'local_florist', 'spa', 'palette', 'brush', 'mic', 'headphones', 'directions_bike', 'directions_run', 'directions_boat', 'directions_bus', 'directions_railway', 'directions_subway', 'directions_transit', 'directions_walk', 'eco', 'electric_bolt', 'emoji_nature', 'emoji_people', 'emoji_transportation', 'engineering', 'face', 'favorite', 'fingerprint', 'gavel', 'group', 'groups', 'hiking', 'hotel', 'icecream', 'language', 'laptop', 'map', 'nightlife', 'outdoor_grill', 'pets', 'public', 'recycle', 'rowing', 'sailing', 'school', 'science', 'skateboarding', 'smartphone', 'sports', 'sports_basketball', 'sports_cricket', 'sports_esports', 'sports_football', 'sports_golf', 'sports_handball', 'sports_hockey', 'sports_kabaddi', 'sports_mma', 'sports_motorsports', 'sports_rugby', 'sports_tennis', 'sports_volleyball', 'surfing', 'theater_comedy', 'toys', 'travel_explore', 'watch', 'work',
    ];
    final List<String> emojis = [
      '🔑', '🛡️', '🔒', '👤', '📧', '📱', '☁️', '🏠', '💼', '💳', '💻', '📶', '🏢', '🏫', '🛒', '✈️', '🚗', '⭐', '🐾', '🎂', '⚽', '🏋️', '🎵', '🎬', '📚', '📷', '🎮', '💡', '🚀', '🧪', '💊', '🏥', '🍽️', '☕', '🍸', '🏖️', '🌳', '🌸', '🧘', '🎨', '🖌️', '🎤', '🎧', '🚴', '🏃', '⛵', '🚌', '🚆', '🚇', '🚍', '🚶', '🌱', '⚡', '🌲', '🧑‍🤝‍🧑', '🚗', '🏄', '🏨', '🍦', '🌐', '🗺️', '🌃', '🔥', '🐶', '🌍', '♻️', '🛶', '🏫', '🧑‍🔬', '🛹', '📱', '🏀', '🏏', '🎮', '🏈', '🏌️', '🤾', '🏒', '🤼', '🥊', '🏎️', '🏉', '🎾', '🏐', '🏄‍♂️', '🎭', '🧸', '🌎', '⌚', '💼',
    ];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Label'),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(hintText: 'Account label'),
                ),
                const SizedBox(height: 16),
                const Text('Pick an icon'),
                SizedBox(
                  height: 80,
                  child: GridView.count(
                    crossAxisCount: 8,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    children: [
                      ...materialIcons.take(16).map((iconName) => GestureDetector(
                        onTap: () => selectedIcon = iconName,
                        child: Container(
                          decoration: BoxDecoration(
                            border: selectedIcon == iconName ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(_iconDataFromName(iconName), color: Colors.black),
                        ),
                      )),
                      ...emojis.take(16).map((emoji) => GestureDetector(
                        onTap: () => selectedIcon = emoji,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: selectedIcon == emoji ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      )),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // Show full icon picker in a dialog
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('All Icons'),
                          content: SizedBox(
                            width: 400,
                            height: 300,
                            child: GridView.count(
                              crossAxisCount: 8,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              children: [
                                ...materialIcons.map((iconName) => GestureDetector(
                                  onTap: () {
                                    selectedIcon = iconName;
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: selectedIcon == iconName ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(_iconDataFromName(iconName), color: Colors.black),
                                  ),
                                )),
                                ...emojis.map((emoji) => GestureDetector(
                                  onTap: () {
                                    selectedIcon = emoji;
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: selectedIcon == emoji ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    setState(() {});
                  },
                  child: const Text('Show all icons'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.onEdit != null) {
                  widget.onEdit!(acc, labelController.text, selectedIcon);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    setState(() {});
  }

  IconData? _iconDataFromName(String name) {
    final iconMap = <String, IconData>{
      'key': Icons.key,
      'security': Icons.security,
      'lock': Icons.lock,
      'account_circle': Icons.account_circle,
      'vpn_key': Icons.vpn_key,
      'shield': Icons.shield,
      'star': Icons.star,
      'person': Icons.person,
      'email': Icons.email,
      'phone': Icons.phone,
      'cloud': Icons.cloud,
      'home': Icons.home,
      'work': Icons.work,
      'wallet': Icons.wallet,
      'credit_card': Icons.credit_card,
      'devices': Icons.devices,
      'wifi': Icons.wifi,
      'apartment': Icons.apartment,
      'business': Icons.business,
      'school': Icons.school,
      'shopping_cart': Icons.shopping_cart,
      'flight': Icons.flight,
      'directions_car': Icons.directions_car,
      'favorite': Icons.favorite,
      'pets': Icons.pets,
      'cake': Icons.cake,
      'sports_soccer': Icons.sports_soccer,
      'fitness_center': Icons.fitness_center,
      'music_note': Icons.music_note,
      'movie': Icons.movie,
      'book': Icons.book,
      'camera': Icons.camera,
      'gamepad': Icons.gamepad,
      'code': Icons.code,
      'build': Icons.build,
      'bug_report': Icons.bug_report,
      'emoji_objects': Icons.emoji_objects,
      'lightbulb': Icons.lightbulb,
      'rocket': Icons.rocket,
      'science': Icons.science,
      'medication': Icons.medication,
      'local_hospital': Icons.local_hospital,
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'beach_access': Icons.beach_access,
      'park': Icons.park,
      'local_florist': Icons.local_florist,
      'spa': Icons.spa,
      'palette': Icons.palette,
      'brush': Icons.brush,
      'mic': Icons.mic,
      'headphones': Icons.headphones,
      'directions_bike': Icons.directions_bike,
      'directions_run': Icons.directions_run,
      'directions_boat': Icons.directions_boat,
      'directions_bus': Icons.directions_bus,
      'directions_railway': Icons.directions_railway,
      'directions_subway': Icons.directions_subway,
      'directions_transit': Icons.directions_transit,
      'directions_walk': Icons.directions_walk,
      'eco': Icons.eco,
      'electric_bolt': Icons.electric_bolt,
      'emoji_nature': Icons.emoji_nature,
      'emoji_people': Icons.emoji_people,
      'emoji_transportation': Icons.emoji_transportation,
      'engineering': Icons.engineering,
      'face': Icons.face,
      'favorite': Icons.favorite,
      'fingerprint': Icons.fingerprint,
      'gavel': Icons.gavel,
      'group': Icons.group,
      'groups': Icons.groups,
      'hiking': Icons.hiking,
      'hotel': Icons.hotel,
      'icecream': Icons.icecream,
      'language': Icons.language,
      'laptop': Icons.laptop,
      'map': Icons.map,
      'nightlife': Icons.nightlife,
      'outdoor_grill': Icons.outdoor_grill,
      'pets': Icons.pets,
      'public': Icons.public,
      'recycle': Icons.recycling,
      'rowing': Icons.rowing,
      'sailing': Icons.sailing,
      'school': Icons.school,
      'science': Icons.science,
      'skateboarding': Icons.skateboarding,
      'smartphone': Icons.smartphone,
      'sports': Icons.sports,
      'sports_basketball': Icons.sports_basketball,
      'sports_cricket': Icons.sports_cricket,
      'sports_esports': Icons.sports_esports,
      'sports_football': Icons.sports_football,
      'sports_golf': Icons.sports_golf,
      'sports_handball': Icons.sports_handball,
      'sports_hockey': Icons.sports_hockey,
      'sports_kabaddi': Icons.sports_kabaddi,
      'sports_mma': Icons.sports_mma,
      'sports_motorsports': Icons.sports_motorsports,
      'sports_rugby': Icons.sports_rugby,
      'sports_tennis': Icons.sports_tennis,
      'sports_volleyball': Icons.sports_volleyball,
      'surfing': Icons.surfing,
      'theater_comedy': Icons.theater_comedy,
      'toys': Icons.toys,
      'travel_explore': Icons.travel_explore,
      'watch': Icons.watch,
      'work': Icons.work,
    };
    return iconMap[name];
  }

  @override
  Widget build(BuildContext context) {
    final filteredAccounts = _searchQuery.isEmpty
        ? widget.accounts
        : widget.accounts.where((acc) =>
            (acc.issuer ?? acc.label).toLowerCase().contains(_searchQuery.toLowerCase()) ||
            acc.label.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            children: [
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title: const Text('Password Vault'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PasswordVaultPage(),
                    ),
                  );
                },
              ),
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
          // Removed dark/light mode toggle icon
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
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
              itemCount: filteredAccounts.length,
              itemBuilder: (context, idx) {
                final acc = filteredAccounts[idx];
                final code = _generateCode(acc);
                // Split the code into groups of 3 for better readability
                String formattedCode = '';
                for (int i = 0; i < code.length; i++) {
                  formattedCode += code[i];
                  if (i == 2 && code.length > 3) formattedCode += ' ';
                }
                final progress = _progress(acc);
                final animatedColor = ColorTween(
                  begin: Colors.red,
                  end: Colors.blue,
                ).transform(progress < 0.2 ? 0 : (progress - 0.2) / 0.8) ?? Colors.blue;
                return Dismissible(
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
                                'Delete "[39m${acc.issuer ?? acc.label}"?',
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
                    try {
                      bool didAuthenticate = await auth.authenticate(
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
                      onLongPress: () => _showAccountOptions(context, acc),
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
                                    // Icon or emoji
                                    if (acc.icon.isNotEmpty && _iconDataFromName(acc.icon) != null)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(_iconDataFromName(acc.icon), color: Theme.of(context).colorScheme.primary, size: 20),
                                      )
                                    else if (acc.icon.isNotEmpty)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(acc.icon, style: const TextStyle(fontSize: 18)),
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
                                    tag: 'code-${acc.secret}',
                                    child: Text(
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
                                    backgroundColor: Colors.grey[100],
                                    valueColor: AlwaysStoppedAnimation<Color>(animatedColor),
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
      floatingActionButton: SpeedDial(
        key: const ValueKey('main-speed-dial'),
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        renderOverlay: true,
        useRotationAnimation: false,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.qr_code_scanner),
            label: 'Scan QR',
            onTap: widget.onScanQr,
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit),
            label: 'Manual Entry',
            onTap: widget.onAddAccount,
          ),
        ],
      ),
    );
  }
  // ...existing code...
}
