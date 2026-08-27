/// Puanla alınabilecek bir hak. Artık kod içinde SABİT değil — Firestore'daki
/// `rewards` koleksiyonundan CANLI okunuyor. Yeni bir ödül eklemek/puanını
/// değiştirmek için kod değiştirmene gerek yok, Firebase Console'dan
/// (ileride kendi admin panelinden) bir belge eklemen/düzenlemen yeterli.
class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.costPoints,
    required this.active,
  });

  final String id;
  final String title;
  final int costPoints;

  /// false ise öğrencilere gösterilmez ama geçmiş kayıtlar bozulmaz —
  /// bu yüzden belgeyi SİLMEK yerine `active: false` yapmak önerilir.
  final bool active;
}
