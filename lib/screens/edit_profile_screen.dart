import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _nameError;
  String? _emailError;

  final Color _accent = const Color(0xFF67C9E6);
  final Color _errorColor = const Color(0xFFFF4D4D);

  SupabaseClient get sb => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = sb.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await sb
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      _nameController.text  = data?['display_name'] ?? '';
      _emailController.text = data?['email'] ?? user.email ?? '';
    } catch (_) {
      // يمكن إضافة SnackBar عند الحاجة
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String? _validateName(String value) {
    final name = value.trim();

    if (name.isEmpty) {
      return 'Username is required';
    }

    if (name.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(name)) {
      return 'Username can contain only English letters, numbers, and underscore (_)';
    }

    return null;
  }

  String? _validateEmail(String value) {
    final email = value.trim();

    if (email.isEmpty) {
      return 'Email is required';
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  bool _validateInputs() {
    final nameError = _validateName(_nameController.text);
    final emailError = _validateEmail(_emailController.text);

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
    });

    return nameError == null && emailError == null;
  }

  Future<void> _saveProfile() async {
    final name  = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (!_validateInputs()) {
      _show('Please fix the highlighted fields');
      return;
    }

    final user = sb.auth.currentUser;
    if (user == null) {
      _show('No logged-in user');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1) تحديث جدول profiles
      final profileUpdate = await sb.from('profiles').upsert({
        'user_id': user.id,
        'display_name': name,
        'email': email,
      });

      print('=== PROFILE UPSERT RESPONSE ===');
      print(profileUpdate);
      print('================================');

      // 2) تحديث إيميل Supabase Auth نفسه
      final res = await sb.auth.updateUser(
        UserAttributes(email: email),
      );

      print('=== SUPABASE EMAIL UPDATE RESPONSE ===');
      print(res);
      print('======================================');

      if (res.user == null) {
        _show('Failed to update auth email');
      } else {
        // جلب أحدث نسخة من المستخدم (اختياري لكن مفيد للتاكيد)
        final refreshed = await sb.auth.getUser();
        debugPrint('Updated auth email: ${refreshed.user?.email}');
      }

      _show('Profile updated');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _show('Error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildField(
                  controller: _nameController,
                  hint: 'Username',
                  icon: Icons.person_outline,
                  errorText: _nameError,
                  onChanged: (value) {
                    if (_nameError != null) {
                      setState(() => _nameError = _validateName(value));
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailController,
                  hint: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (value) {
                    if (_emailError != null) {
                      setState(() => _emailError = _validateEmail(value));
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasError) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              errorText,
              style: TextStyle(
                color: _errorColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white60),
            prefixIcon: Icon(
              icon,
              color: hasError ? _errorColor : Colors.white70,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: hasError ? _errorColor : Colors.white24,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: hasError ? _errorColor : Colors.white24,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: hasError ? _errorColor : _accent,
                width: 1.4,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

}
