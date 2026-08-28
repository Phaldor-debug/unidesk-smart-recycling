import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/brand_header.dart';
import '../providers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _sifreGizli = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
      // Kayıt başarılı olunca (hata yok, yükleniyor değil) bu ekranı kapat.
      // AuthGate zaten oturumu dinliyor, otomatik olarak ana ekrana geçecek.
      if (previous is AsyncLoading && next is AsyncData) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        // Başlık yok: marka başlığı zaten gövdede duruyor, tekrar olmasın.
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          children: [
            const BrandHeader(subtitle: 'Hesabını oluştur, hemen başla'),
            const SizedBox(height: 36),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => (value == null || value.trim().length < 3)
                        ? 'Adını ve soyadını gir'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return 'Geçerli bir e-posta gir';
                      }
                      // Öğrenci doğrulaması: AppConstants'ta izinli uzantı
                      // tanımlıysa sadece o uzantılar kayıt olabilir.
                      if (!AppConstants.epostaUygunMu(value)) {
                        final uzantilar =
                            AppConstants.izinliEpostaUzantilari.map((u) => '@$u').join(', ');
                        return 'Sadece okul e-postasıyla kayıt olabilirsin ($uzantilar)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _sifreGizli,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_sifreGizli
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        tooltip: _sifreGizli ? 'Şifreyi göster' : 'Şifreyi gizle',
                        onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
                      ),
                    ),
                    validator: (value) => (value == null || value.length < 6)
                        ? 'En az 6 karakter olmalı'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _sifreGizli,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Şifre (tekrar)',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    // Bu alan sadece diğer alanla eşleşip eşleşmediğine bakar,
                    // Firebase'e hiç gitmez — kullanıcıya anında geri bildirim verir.
                    validator: (value) => (value != _passwordController.text)
                        ? 'Şifreler eşleşmiyor'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kayıt Ol'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
