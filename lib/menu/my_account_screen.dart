import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bg = Color(0xFF020A14);
const _panel = Color(0xFF0B1B2D);
const _cyan = Color(0xFF25B8FF);
const _muted = Color(0xFF9AACC1);
const _googleServerClientId =
    '924828656704-kk44oad5caing6nco22k8cu2v3qeg0ep.apps.googleusercontent.com';

String _authError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email': return 'Please enter a valid email address.';
    case 'weak-password': return 'Use a stronger password (at least 8 characters).';
    case 'email-already-in-use': return 'This email already has an account. Please log in.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential': return 'The email/password or OTP is incorrect.';
    case 'too-many-requests': return 'Too many attempts. Please wait and try again.';
    case 'operation-not-allowed': return 'This sign-in method is not enabled in Firebase.';
    case 'credential-already-in-use':
    case 'account-exists-with-different-credential':
      return 'This sign-in method belongs to another account. Sign in to that account first; accounts are not merged automatically.';
    case 'invalid-verification-code': return 'The OTP is incorrect. Please check it and retry.';
    case 'session-expired': return 'The OTP expired. Please request a new code.';
    case 'quota-exceeded': return 'The Firebase SMS quota has been reached. Try again later.';
    default: return e.message ?? 'Authentication failed. Please try again.';
  }
}

Future<void> _setProfileSyncPending(
  User user,
  bool pending, {
  DateTime? dateOfBirth,
  String? preferredAddress,
  bool includePreferences = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'account_profile_sync_pending_${user.uid}';
  if (pending) {
    await prefs.setBool(key, true);
    if (includePreferences) {
      final dobKey = '${key}_dob';
      final addressKey = '${key}_address';
      if (dateOfBirth == null) {
        await prefs.setString(dobKey, '');
      } else {
        await prefs.setString(
          dobKey,
          DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day)
              .toIso8601String()
              .split('T')
              .first,
        );
      }
      await prefs.setString(addressKey, preferredAddress ?? 'auto');
    }
  } else {
    await prefs.remove(key);
    await prefs.remove('${key}_dob');
    await prefs.remove('${key}_address');
  }
}

Future<void> _saveCloudProfile(
  User user, {
  String? name,
  DateTime? dateOfBirth,
  String? preferredAddress,
  bool clearDateOfBirth = false,
}) async {
  final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final old = await ref.get();
  final displayName = (name?.trim().isNotEmpty ?? false)
      ? name!.trim()
      : (user.displayName ?? '');
  final data = <String, dynamic>{
    'uid': user.uid,
    'email': user.email,
    'phoneNumber': user.phoneNumber,
    'photoUrl': user.photoURL,
    'emailVerified': user.emailVerified,
    'providerIds': user.providerData.map((p) => p.providerId).toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  if (displayName.isNotEmpty) data['displayName'] = displayName;
  if (dateOfBirth != null) {
    data['dateOfBirth'] = DateTime(
      dateOfBirth.year,
      dateOfBirth.month,
      dateOfBirth.day,
    ).toIso8601String().split('T').first;
  } else if (clearDateOfBirth) {
    data['dateOfBirth'] = FieldValue.delete();
  }
  if (preferredAddress != null && {'auto', 'respectful', 'casual'}.contains(preferredAddress)) {
    data['preferredAddress'] = preferredAddress;
  }
  if (!old.exists) data['createdAt'] = FieldValue.serverTimestamp();
  await ref.set(data, SetOptions(merge: true));
}

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});
  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  User? _user;
  bool _loading = true, _saving = false, _googleBusy = false;
  DateTime? _dateOfBirth;
  String _preferredAddress = 'auto';
  bool _profileLoadFailed = false;
  bool _profileSyncPending = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _name.dispose(); _email.dispose(); super.dispose(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    var name = prefs.getString('account_name') ?? '';
    var email = prefs.getString('account_email') ?? '';
    DateTime? dateOfBirth;
    var preferredAddress = 'auto';
    var profileLoadFailed = false;
    var profileSyncPending = false;
    if (user != null) {
      if ((user.displayName ?? '').isNotEmpty) name = user.displayName!;
      email = user.email ?? email;
      profileSyncPending = prefs.getBool('account_profile_sync_pending_${user.uid}') ?? false;
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = snap.data();
        if ((data?['displayName'] ?? '').toString().isNotEmpty) name = data!['displayName'].toString();
        if ((data?['email'] ?? '').toString().isNotEmpty) email = data!['email'].toString();
        final rawDob = data?['dateOfBirth'];
        if (rawDob is String) dateOfBirth = DateTime.tryParse(rawDob);
        final rawPreference = data?['preferredAddress']?.toString() ?? 'auto';
        if ({'auto', 'respectful', 'casual'}.contains(rawPreference)) preferredAddress = rawPreference;
      } catch (_) {
        // Keep safe local/Auth values, but make the failed cloud read visible.
        profileLoadFailed = true;
      }
    }
    if (!mounted) return;
    _name.text = name;
    _email.text = email;
    setState(() {
      _user = user;
      _dateOfBirth = dateOfBirth;
      _preferredAddress = preferredAddress;
      _profileLoadFailed = profileLoadFailed;
      _profileSyncPending = profileSyncPending;
      _loading = false;
    });
  }

  Future<bool> _refresh() async {
    final auth = FirebaseAuth.instance;
    var syncSucceeded = true;
    try {
      await auth.currentUser?.reload();
    } catch (_) {
      syncSucceeded = false;
    }
    final user = auth.currentUser;
    if (user != null) {
      try {
        final localPrefs = await SharedPreferences.getInstance();
        final localName = localPrefs.getString('account_name') ?? '';
        if ((user.displayName ?? '').isEmpty && localName.isNotEmpty) {
          await user.updateDisplayName(localName);
        }
        final pendingKey = 'account_profile_sync_pending_${user.uid}';
        final pendingDobKey = '${pendingKey}_dob';
        final pendingAddressKey = '${pendingKey}_address';
        final hasPendingPreferences = localPrefs.containsKey(pendingDobKey) &&
            localPrefs.containsKey(pendingAddressKey);
        final pendingDob = hasPendingPreferences
            ? localPrefs.getString(pendingDobKey) ?? ''
            : null;
        await _saveCloudProfile(
          auth.currentUser!,
          name: localName.isEmpty ? null : localName,
          dateOfBirth: pendingDob == null || pendingDob.isEmpty
              ? null
              : DateTime.tryParse(pendingDob),
          preferredAddress: hasPendingPreferences
              ? localPrefs.getString(pendingAddressKey)
              : null,
          clearDateOfBirth: hasPendingPreferences && pendingDob!.isEmpty,
        );
        await _setProfileSyncPending(user, false);
      } catch (_) {
        syncSucceeded = false;
        await _setProfileSyncPending(user, true);
      }
    }
    await _load();
    return syncSucceeded;
  }

  void _notice(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: const Color(0xFF10243B)),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 120, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Select your date of birth',
    );
    if (selected != null && mounted) setState(() => _dateOfBirth = selected);
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim(), email = _email.text.trim();
    if (name.isEmpty) { _notice('Please enter your display name.'); return; }
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _notice('Please enter a valid email address.'); return;
    }
    setState(() => _saving = true);
    User? profileUser;
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null && (_dateOfBirth != null || _preferredAddress != 'auto')) {
        try {
          user = (await FirebaseAuth.instance.signInAnonymously()).user;
        } on FirebaseAuthException {
          // Keep the basic profile usable locally if guest sign-in is disabled.
        }
      }
      profileUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('account_name', name);
      await prefs.setString('account_email', email);
      if (user == null) {
        _notice(
          _dateOfBirth != null || _preferredAddress != 'auto'
              ? 'Name and email saved locally. Sign in to save DOB and Telugu address preferences.'
              : 'Profile saved on this device. Sign in to sync it to Firebase.',
        );
      } else {
        await user.updateDisplayName(name);
        await _saveCloudProfile(
          user,
          name: name,
          dateOfBirth: _dateOfBirth,
          preferredAddress: _preferredAddress,
          clearDateOfBirth: _dateOfBirth == null,
        );
        await _setProfileSyncPending(user, false);
        _notice('Profile saved on this device and Firebase.');
      }
      await _refresh();
    } on FirebaseAuthException catch (e) {
      _notice(_authError(e));
    } catch (_) {
      if (profileUser != null) {
        await _setProfileSyncPending(
          profileUser!,
          true,
          dateOfBirth: _dateOfBirth,
          preferredAddress: _preferredAddress,
          includePreferences: true,
        );
      }
      _notice('Profile is saved locally; cloud sync is pending. Check your connection and retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _phone({required bool signup}) async {
    final done = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (_) => _PhoneDialog(signup: signup),
    );
    if (done == true) {
      final synced = await _refresh();
      _notice(synced
          ? 'Phone verification successful.'
          : 'Phone verified. Profile sync is pending; use Retry on this screen.');
    }
  }

  Future<void> _emailAuth() async {
    final done = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (_) => const _EmailDialog(),
    );
    if (done == true) {
      final synced = await _refresh();
      _notice(synced
          ? 'Email sign-in successful.'
          : 'Email sign-in successful. Profile sync is pending; use Retry on this screen.');
    }
  }

  Future<void> _google() async {
    if (_googleBusy) return;
    setState(() => _googleBusy = true);
    try {
      final google = GoogleSignIn(
        scopes: const ['email'],
        serverClientId: _googleServerClientId,
      );
      final account = await google.signIn();
      if (account == null) return;
      final tokens = await account.authentication;
      final idToken = tokens.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google did not return an ID token. Check the SHA-1 and OAuth client setup.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final current = FirebaseAuth.instance.currentUser;
      final User user = current == null
          ? (await FirebaseAuth.instance.signInWithCredential(credential)).user!
          : (await current.linkWithCredential(credential)).user!;
      await user.reload();
      final synced = await _refresh();
      _notice(synced
          ? 'Google sign-in successful.'
          : 'Google sign-in successful. Profile sync is pending; use Retry on this screen.');
    } on FirebaseAuthException catch (e) {
      _notice(_authError(e));
    } catch (e) {
      _notice('Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _recovery() async {
    await showDialog<void>(context: context, builder: (_) => const _RecoveryDialog());
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      try { await GoogleSignIn().signOut(); } catch (_) {}
      if (mounted) setState(() => _user = null);
      await _load();
      _notice('You have signed out.');
    } catch (e) { _notice('Unable to sign out: $e'); }
  }

  Widget _option(IconData icon, String title, String subtitle, VoidCallback? action, {bool busy = false}) =>
    Card(
      color: _panel,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Icon(icon, color: _cyan, size: 27),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        trailing: busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _cyan))
          : const Icon(Icons.arrow_forward_ios_rounded, color: _muted, size: 16),
        onTap: action,
      ),
    );

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: const Color(0xFF06101E), foregroundColor: Colors.white, title: const Text('My Account')),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: _cyan))
        : ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(Icons.account_circle_rounded, color: _cyan, size: 68),
            const SizedBox(height: 10),
            const Text('Your BUJJI profile', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(user == null ? Icons.phone_android : Icons.verified_user, color: user == null ? _muted : Colors.greenAccent),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  user == null ? 'Local profile — sign in to sync across devices'
                    : 'Signed in: ' + (user.email ?? user.phoneNumber ?? user.displayName ?? 'BUJJI account'),
                  style: const TextStyle(color: Colors.white, fontSize: 12))),
              ]),
            ),
            if (_profileLoadFailed || _profileSyncPending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.6)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _profileSyncPending
                        ? 'Your profile is saved on this device, but cloud sync is pending.'
                        : 'Cloud profile could not be loaded. Your local profile is still available.',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _saving ? null : () async {
                        final synced = await _refresh();
                        _notice(synced ? 'Profile sync completed.' : 'Profile sync is still pending. Please retry later.');
                      },
                      child: const Text('Retry', style: TextStyle(color: _cyan)),
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            TextField(controller: _name, style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'Display name', labelStyle: const TextStyle(color: _muted),
                filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'Email (optional)', labelStyle: const TextStyle(color: _muted),
                filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            Card(
              color: _panel,
              child: ListTile(
                leading: const Icon(Icons.cake_outlined, color: _cyan),
                title: const Text('Date of birth', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _dateOfBirth == null
                      ? 'Optional — used only to calculate an age group'
                      : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dateOfBirth != null)
                      IconButton(
                        tooltip: 'Clear date of birth',
                        onPressed: () => setState(() => _dateOfBirth = null),
                        icon: const Icon(Icons.delete_outline, color: _muted),
                      ),
                    const Icon(Icons.calendar_month, color: _muted),
                  ],
                ),
                onTap: _pickDateOfBirth,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _preferredAddress,
              dropdownColor: _panel,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Preferred Telugu addressing',
                labelStyle: const TextStyle(color: _muted),
                filled: true,
                fillColor: _panel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('Automatic / follow my style')),
                DropdownMenuItem(value: 'respectful', child: Text('Respectful — మీరు / మీకు')),
                DropdownMenuItem(value: 'casual', child: Text('Casual — నువ్వు / నీకు')),
              ],
              onChanged: (value) { if (value != null) setState(() => _preferredAddress = value); },
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: _bg),
              child: Text(_saving ? 'Saving...' : 'Save profile'))),
            if (user != null) ...[
              const SizedBox(height: 12),
              _option(Icons.add_call, 'Add / Change Phone Number',
                'Verify a number with OTP and link it to this account', () => _phone(signup: false)),
              _option(Icons.logout, 'Sign Out', 'Sign out on this device', _signOut),
            ],
            const SizedBox(height: 20),
            const Text('BUJJI ACCOUNT', style: TextStyle(color: _cyan, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 10),
            _option(Icons.person_add_alt_1_rounded, 'Mobile Signup',
              'Create or link an account with phone OTP', () => _phone(signup: true)),
            _option(Icons.phone_android_rounded, 'Mobile Login',
              'Sign in with your verified phone number and OTP', () => _phone(signup: false)),
            _option(Icons.g_mobiledata_rounded, 'Continue with Google',
              'Sign in with Google or link it to the current account', _googleBusy ? null : _google, busy: _googleBusy),
            _option(Icons.email_outlined, 'Email Signup / Login',
              'Email and password; new accounts receive a verification link', _emailAuth),
            _option(Icons.lock_reset_rounded, 'Forgot Password / Account Recovery',
              'Reset your email password or recover with a verified email', _recovery),
            const SizedBox(height: 8),
            const Text(
              'Firebase Phone Authentication uses OTP, not a phone-number password. Email verification is sent as a secure link. To recover a phone account, link and verify an email first; then sign in with that email and verify a replacement phone number.',
              style: TextStyle(color: _muted, height: 1.5, fontSize: 12)),
          ],
        ),
    );
  }
}

class _PhoneDialog extends StatefulWidget {
  final bool signup;
  const _PhoneDialog({required this.signup});
  @override
  State<_PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<_PhoneDialog> {
  final _name = TextEditingController(), _phone = TextEditingController(), _otp = TextEditingController();
  String? _verificationId, _error;
  bool _sent = false, _busy = false, _finished = false;

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _otp.dispose(); super.dispose(); }

  String _normalise(String input) {
    final value = input.replaceAll(RegExp(r'[\s()-]'), '');
    if (value.startsWith('+')) return value;
    if (value.length == 10) return '+91$value';
    if (value.startsWith('91') && value.length == 12) return '+$value';
    return '+$value';
  }

  Future<void> _send() async {
    if (_busy) return;
    if (widget.signup && _name.text.trim().isEmpty) {
      setState(() => _error = 'Enter your display name.'); return;
    }
    final phone = _normalise(_phone.text.trim());
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      setState(() => _error = 'Enter a valid phone number. Use +91 for India.'); return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) => _finish(credential),
        verificationFailed: (e) {
          if (mounted) setState(() { _busy = false; _error = _authError(e); });
        },
        codeSent: (id, token) {
          if (mounted) setState(() { _verificationId = id; _sent = true; _busy = false; _error = 'OTP sent. Check your SMS messages.'; });
        },
        codeAutoRetrievalTimeout: (id) { _verificationId = id; },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _busy = false; _error = _authError(e); });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = 'Unable to send OTP: $e'; });
    }
  }

  Future<void> _finish(PhoneAuthCredential credential) async {
    if (_finished || !mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      final auth = FirebaseAuth.instance;
      final current = auth.currentUser;
      User user;
      if (current == null) {
        user = (await auth.signInWithCredential(credential)).user!;
      } else if (current.phoneNumber != null) {
        await current.updatePhoneNumber(credential);
        user = auth.currentUser!;
      } else {
        user = (await current.linkWithCredential(credential)).user!;
      }
      if (widget.signup && _name.text.trim().isNotEmpty) {
        await user.updateDisplayName(_name.text.trim());
        user = auth.currentUser!;
      }
      try {
        await _saveCloudProfile(user, name: widget.signup ? _name.text.trim() : null);
        await _setProfileSyncPending(user, false);
      } catch (_) {
        await _setProfileSyncPending(user, true);
      }
      _finished = true;
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _busy = false; _error = _authError(e); });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = 'Phone verification failed: $e'; });
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_verificationId == null || _otp.text.trim().length < 4) {
      setState(() => _error = 'Enter the OTP received by SMS.'); return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!, smsCode: _otp.text.trim());
      await _finish(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _busy = false; _error = _authError(e); });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = 'OTP verification failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _panel,
    title: Text(widget.signup ? 'Mobile Signup' : 'Mobile Login / OTP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (widget.signup) TextField(controller: _name, enabled: !_sent && !_busy,
        style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Display name', labelStyle: TextStyle(color: _muted))),
      if (widget.signup) const SizedBox(height: 8),
      TextField(controller: _phone, enabled: !_sent && !_busy, keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: 'Mobile number (default +91)', hintText: '9876543210 or +919876543210', labelStyle: TextStyle(color: _muted), hintStyle: TextStyle(color: _muted))),
      if (_sent) ...[
        const SizedBox(height: 10),
        TextField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6,
          style: const TextStyle(color: Colors.white, letterSpacing: 5),
          decoration: const InputDecoration(labelText: 'SMS OTP', labelStyle: TextStyle(color: _muted))),
      ],
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: _cyan, fontSize: 12))],
    ])),
    actions: [
      TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
      if (!_sent)
        ElevatedButton(onPressed: _busy ? null : _send, style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: _bg), child: Text(_busy ? 'Sending...' : 'Send OTP'))
      else ...[
        TextButton(onPressed: _busy ? null : () => setState(() { _sent = false; _verificationId = null; _otp.clear(); }), child: const Text('Change number')),
        ElevatedButton(onPressed: _busy ? null : _verify, style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: _bg), child: Text(_busy ? 'Verifying...' : 'Verify OTP')),
      ],
    ],
  );
}

class _EmailDialog extends StatefulWidget {
  const _EmailDialog();
  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  final _name = TextEditingController(), _email = TextEditingController(), _password = TextEditingController(), _confirm = TextEditingController();
  bool _signup = true, _busy = false, _obscure = true;
  String? _error;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim(), password = _password.text;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) { setState(() => _error = 'Enter a valid email address.'); return; }
    if (password.length < 8) { setState(() => _error = 'Password must be at least 8 characters.'); return; }
    if (_signup && password != _confirm.text) { setState(() => _error = 'Passwords do not match.'); return; }
    if (_signup && _name.text.trim().isEmpty) { setState(() => _error = 'Enter your display name.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      final auth = FirebaseAuth.instance;
      User user;
      if (_signup) {
        final credential = EmailAuthProvider.credential(email: email, password: password);
        final current = auth.currentUser;
        user = current == null
          ? (await auth.createUserWithEmailAndPassword(email: email, password: password)).user!
          : (await current.linkWithCredential(credential)).user!;
        await user.updateDisplayName(_name.text.trim());
        user = auth.currentUser!;
        await user.sendEmailVerification();
        try {
          await _saveCloudProfile(user, name: _name.text.trim());
          await _setProfileSyncPending(user, false);
        } catch (_) {
          await _setProfileSyncPending(user, true);
        }
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created. Open your email and tap the Firebase verification link.')));
        }
      } else {
        user = (await auth.signInWithEmailAndPassword(email: email, password: password)).user!;
        await user.reload();
        user = auth.currentUser!;
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          await auth.signOut();
          if (mounted) {
            Navigator.pop(context, false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email is not verified. A fresh verification link was sent; verify it, then log in again.')));
          }
          return;
        }
        try {
          await _saveCloudProfile(user);
          await _setProfileSyncPending(user, false);
        } catch (_) {
          await _setProfileSyncPending(user, true);
        }
        if (mounted) Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _busy = false; _error = _authError(e); });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = 'Email authentication failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _panel,
    title: Text(_signup ? 'Email Signup' : 'Email Login', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      SegmentedButton<bool>(
        segments: const [ButtonSegment(value: true, label: Text('Sign up')), ButtonSegment(value: false, label: Text('Log in'))],
        selected: {_signup},
        onSelectionChanged: _busy ? null : (value) => setState(() { _signup = value.first; _error = null; }),
      ),
      if (_signup) ...[
        const SizedBox(height: 8),
        TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Display name', labelStyle: TextStyle(color: _muted))),
      ],
      const SizedBox(height: 8),
      TextField(controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false,
        style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Email address', labelStyle: TextStyle(color: _muted))),
      const SizedBox(height: 8),
      TextField(controller: _password, obscureText: _obscure, style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: 'Password', labelStyle: const TextStyle(color: _muted),
          suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: _muted)))),
      if (_signup) ...[
        const SizedBox(height: 8),
        TextField(controller: _confirm, obscureText: true, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Confirm password', labelStyle: TextStyle(color: _muted))),
      ],
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12))],
      const SizedBox(height: 8),
      const Text('New email accounts receive a verification link. If you are already signed in, Sign up links this email to your current BUJJI account.', style: TextStyle(color: _muted, fontSize: 11, height: 1.4)),
    ])),
    actions: [
      TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
      ElevatedButton(onPressed: _busy ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: _bg), child: Text(_busy ? 'Please wait...' : (_signup ? 'Create account' : 'Log in'))),
    ],
  );
}

class _RecoveryDialog extends StatefulWidget {
  const _RecoveryDialog();
  @override
  State<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<_RecoveryDialog> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _message;
  @override
  void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) { setState(() => _message = 'Enter the email linked to your account.'); return; }
    setState(() { _busy = true; _message = null; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _message = 'If an account uses this email, Firebase will send a password reset link. Check inbox and spam.');
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _message = _authError(e));
    } catch (e) {
      if (mounted) setState(() => _message = 'Unable to send recovery link: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _panel,
    title: const Text('Account Recovery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Enter your verified recovery email to receive a password reset link. After signing in, use Add / Change Phone Number to verify a replacement mobile number.', style: TextStyle(color: _muted, height: 1.4)),
      const SizedBox(height: 12),
      TextField(controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: 'Recovery email', labelStyle: TextStyle(color: _muted))),
      if (_message != null) ...[const SizedBox(height: 10), Text(_message!, style: const TextStyle(color: _cyan, fontSize: 12))],
    ]),
    actions: [
      TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Close')),
      ElevatedButton(onPressed: _busy ? null : _send, style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: _bg), child: Text(_busy ? 'Sending...' : 'Send recovery link')),
    ],
  );
}
