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

  // Son işlem şifre sıfırlama mıydı? Controller'ın state'i giriş ile
  // ortak olduğu için, başarı mesajının hangisine ait olduğunu bu
  // bayrakla ayırt ediyoruz.
  bool _sifreSifirlamaIstendi = false;

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

  void _sifremiUnuttum() {
    final email = _emailController.text.trim();
    // Sıfırlama e-postası göndermek için adres şart; kullanıcıyı boş
    // istekle Firebase'e göndermek yerine burada uyarıyoruz.
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce e-posta adresini yaz, sonra tekrar dene.'),
        ),
      );
      return;
    }

    _sifreSifirlamaIstendi = true;
    ref.read(authControllerProvider.notifier).sendPasswordReset(email);
  }

  @override
  Widget build(BuildContext context) {
    // Controller'ın durumunu (yükleniyor / başarılı / hatalı) izliyoruz.
    final authState = ref.watch(authControllerProvider);

    // ref.listen: state her DEĞİŞTİĞİNDE bir kere çalışır (build gibi tekrar
    // tekrar değil). Hata oluşunca ekranın altında bir mesaj gösteriyoruz.
    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        _sifreSifirlamaIstendi = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
      // Şifre sıfırlama başarıyla tamamlandıysa kullanıcıyı bilgilendir.
      // (Giriş başarılıysa AuthGate zaten ekranı değiştirir, mesaja gerek yok.)
      if (previous is AsyncLoading && next is AsyncData && _sifreSifirlamaIstendi) {
        _sifreSifirlamaIstendi = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama bağlantısı e-postana gönderildi.'),
          ),
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
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: authState.isLoading ? null : _sifremiUnuttum,
                    child: const Text('Şifremi unuttum'),
                  ),
                  const Divider(height: 28),
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
