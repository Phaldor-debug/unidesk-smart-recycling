import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// core klasöründeki firebase provider'larına ulaşmak için (4 kez üst klasör).
import '../../../../core/providers/firebase_providers.dart';

/// StreamProvider: sürekli değişen bir veri akışını (Stream) dinler ve
/// her yeni değerde onu izleyen widget'ları otomatik yeniler.
///
/// User? = giriş yapılmışsa User nesnesi, yapılmamışsa null.
final authStateProvider = StreamProvider<User?>((ref) {
  // Önce FirebaseAuth örneğini alıyoruz (firebase_providers.dart'taki provider'dan).
  final auth = ref.watch(firebaseAuthProvider);

  // authStateChanges(): Firebase'in verdiği bir Stream.
  // Uygulama açıldığında, kullanıcı giriş yaptığında, çıkış yaptığında
  // veya oturum düştüğünde yeni bir değer yayınlar.
  return auth.authStateChanges();
});
