import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bg = Color(0xFF030D1B);
const _panel = Color(0xFF10243D);
const _cyan = Color(0xFF20D9E8);
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

Future<void> _saveCloudProfile(User user, {String? name}) async {
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

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _name.dispose(); _email.dispose(); super.dispose(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    var name = prefs.getString('account_name') ?? '';
    var email = prefs.getString('account_email') ?? '';
    if (user != null) {
      if ((user.displayName ?? '').isNotEmpty) name = user.displayName!;
      email = user.email ?? email;
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = snap.data();
        if ((data?['displayName'] ?? '').toString().isNotEmpty) name = data!['displayName'].toString();
        if ((data?['email'] ?? '').toString().isNotEmpty) email = data!['email'].toString();
      } catch (_) {}
    }
    if (!mounted) return;
    _name.text = name;
    _email.text = email;
    setState(() { _user = user; _loading = false; });
  }

  Future<void> _refresh() async {
    final auth = FirebaseAuth.instance;
    await auth.currentUser?.reload();
    final user = auth.currentUser;
    if (user != null) {
      try {
        final reference = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snapshot = await reference.get();
        final data = snapshot.data();
        final localPrefs = await SharedPreferences.getInstance();
        final localName = localPrefs.getString('account_name') ?? '';
        final cloudName = data?['displayName']?.toString() ?? '';
        if (cloudName.isEmpty && (user.displayName ?? '').isEmpty && localName.isNotEmpty) {
          await user.updateDisplayName(localName);
        }
        await _saveCloudProfile(
          auth.currentUser!,
          name: cloudName.isEmpty ? localName : cloudName,
        );
      } catch (_) {
        // Firestore rules may be awaiting publication; local profile remains safe.
      }
    }
    await _load();
  }

  void _notice(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: const Color(0xFF142B42)),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim(), email = _email.text.trim();
    if (name.isEmpty) { _notice('Please enter your display name.'); return; }
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _notice('Please enter a valid email address.'); return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('account_name', name);
      await prefs.setString('account_email', email);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _notice('Profile saved on this device. Sign in to sync it to Firebase.');
      } else {
        await user.updateDisplayName(name);
        await _saveCloudProfile(user, name: name);
        _notice('Profile saved on this device and Firebase.');
      }
      await _refresh();
    } on FirebaseAuthException catch (e) {
      _notice(_authError(e));
    } catch (e) {
      _notice('Profile is saved locally; Firebase sync needs attention: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _phone({required bool signup}) async {
    final done = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (_) => _PhoneDialog(signup: signup),
    );
    if (done == true) { await _refresh(); _notice('Phone verification successful.'); }
  }

  Future<void> _emailAuth() async {
    final done = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (_) => const _EmailDialog(),
    );
    if (done == true) await _refresh();
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
      try { await _saveCloudProfile(FirebaseAuth.instance.currentUser!); }
      catch (_) { _notice('Google sign-in succeeded, but Firestore profile sync needs its security rules.'); }
      await _refresh();
      _notice('Google sign-in successful.');
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
      appBar: AppBar(backgroundColor: const Color(0xFF071426), foregroundColor: Colors.white, title: const Text('My Account')),
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
            const SizedBox(height: 16),
            TextField(controller: _name, style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'Display name', labelStyle: const TextStyle(color: _muted),
                filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'Email (optional)', labelStyle: const TextStyle(color: _muted),
                filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
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
      try { await _saveCloudProfile(user, name: widget.signup ? _name.text.trim() : null); } catch (_) {}
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
        try { await _saveCloudProfile(user, name: _name.text.trim()); } catch (_) {}
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
        try { await _saveCloudProfile(user); } catch (_) {}
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
