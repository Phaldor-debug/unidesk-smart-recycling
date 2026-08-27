import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_controller.dart';
import 'register_page.dart';

/// ConsumerStatefulWidget: hem yerel state (TextEditingController'lar) hem
/// de Riverpod provider'ları (ref) gerektiren ekranlar için kullanılır.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Form alanlarındaki metni okumamızı sağlayan controller'lar.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Form'un doğrulama (validation) durumunu yönetmek için anahtar.
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Widget ekrandan kalkarken controller'ları serbest bırakmak ZORUNLU;
    // yoksa bellek sızıntısı olur.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // Form geçerli değilse (örn. e-posta boş) hiçbir şey yapma.
    if (!_formKey.currentState!.validate()) return;

    // Controller'daki signIn metodunu çağırıyoruz. Sonucunu burada
    // beklemiyoruz (await yok) çünkü sonucu authState.watch ile,
    // aşağıdaki build() içinde zaten dinliyoruz.
    ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Controller'ın durumunu (yükleniyor / başarılı / hatalı) izliyoruz.
    final authState = ref.watch(authControllerProvider);

    // ref.listen: state her DEĞİŞTİĞİNDE bir kere çalışır (build gibi tekrar
    // tekrar değil). Hata oluşunca ekranın altında bir mesaj gösteriyoruz.
    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Geçerli bir e-posta gir'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre'),
                validator: (value) => (value == null || value.length < 6)
                    ? 'En az 6 karakter olmalı'
                    : null,
              ),
              const SizedBox(height: 24),
              // authState.isLoading true iken butonu devre dışı bırakıp
              // yerine küçük bir dönen çember gösteriyoruz.
              FilledButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Giriş Yap'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text('Hesabın yok mu? Kayıt ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
