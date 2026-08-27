import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/brand_header.dart';
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

  // Şifre alanı varsayılan olarak gizli; göz ikonuyla açılıp kapanır.
  bool _sifreGizli = true;

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
      // ListView (Column değil): klavye açılınca içerik yukarı kayabilsin,
      // küçük ekranlarda taşma hatası vermesin.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          children: [
            const SizedBox(height: 20),
            const BrandHeader(subtitle: 'Geri dönüştür, puan kazan'),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) => (value == null || !value.contains('@'))
                        ? 'Geçerli bir e-posta gir'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _sifreGizli,
                    textInputAction: TextInputAction.done,
                    // Klavyedeki "bitti" tuşu da formu göndersin.
                    onFieldSubmitted: (_) => _submit(),
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
                  const SizedBox(height: 28),
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
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterPage()),
                            );
                          },
                    child: const Text('Hesabın yok mu? Kayıt ol'),
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
