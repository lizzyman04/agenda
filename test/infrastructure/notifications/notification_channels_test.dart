import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/infrastructure/notifications/gateway/notification_channels.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every kind maps to its own versioned channel id', () {
    final ids = NotificationKind.values.map(channelIdFor).toSet();

    expect(ids, hasLength(8));
    expect(ids, hasLength(NotificationKind.values.length));
    for (final id in ids) {
      expect(id, startsWith('agenda_'));
      expect(id, endsWith('_v1'));
    }
  });

  for (final code in ['en', 'pt', null]) {
    test('androidChannels names all eight channels for locale $code', () {
      final channels = androidChannels(notificationL10n(code));

      expect(channels, hasLength(8));
      expect(channels.map((c) => c.id).toSet(), hasLength(8));
      for (final channel in channels) {
        expect(channel.name, isNotEmpty);
        expect(channel.description, isNotEmpty);
      }
    });
  }

  test('quotes use default importance, every other channel high', () {
    final channels = androidChannels(notificationL10n('en'));
    final byId = {for (final c in channels) c.id: c};

    for (final kind in NotificationKind.values) {
      final expected =
          kind == NotificationKind.motivationalQuote
              ? Importance.defaultImportance
              : Importance.high;
      expect(byId[channelIdFor(kind)]!.importance, expected, reason: kind.name);
    }
  });

  test('English and PT-BR channel names differ', () {
    final en = androidChannels(notificationL10n('en')).first.name;
    final pt = androidChannels(notificationL10n('pt')).first.name;

    expect(en, isNot(pt));
  });

  test('details are private on the lock screen and match the channel', () {
    final l10n = notificationL10n('en');
    for (final kind in NotificationKind.values) {
      final details = detailsFor(kind, l10n);
      final android = details.android!;

      expect(android.visibility, NotificationVisibility.private);
      expect(android.channelId, channelIdFor(kind));
      expect(android.groupKey, 'agenda_${kind.code}');
      expect(details.iOS!.threadIdentifier, kind.code);
      expect(details.iOS!.presentAlert, isTrue);
      expect(details.iOS!.presentSound, isTrue);
    }
  });
}
