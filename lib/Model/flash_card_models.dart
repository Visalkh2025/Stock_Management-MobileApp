/// One pop-up card shown when the app opens (see [FlashCardDialog]).
class FlashCardData {
  const FlashCardData({
    required this.id,
    required this.kickerKey,
    required this.headlineKey,
    required this.footerKey,
    this.badge = 'StockFlow',
    this.showOnce = false,
  });

  /// Change it for every new card. Used to remember "already seen" when
  /// [showOnce] is true.
  final String id;

  /// Small line before the badge.
  final String kickerKey;

  /// The big headline.
  final String headlineKey;

  /// Small line at the bottom right.
  final String footerKey;

  /// The green-pill style label next to the kicker.
  final String badge;

  /// false = show every time the app is opened; true = only the first time
  /// this [id] is ever shown on the phone.
  final bool showOnce;
}

class FlashCards {
  const FlashCards._();

  /// The card shown on the next app open. Set to `null` to show nothing.
  static const FlashCardData? current = FlashCardData(
    id: 'welcome-v1',
    kickerKey: 'flash_welcome_kicker',
    headlineKey: 'flash_welcome_headline',
    footerKey: 'flash_welcome_footer',
  );
}
