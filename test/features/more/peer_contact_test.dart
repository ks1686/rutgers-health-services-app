import 'package:cwc_health_app/features/more/peer_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a contact needs a name and a phone or a reach method', () {
    expect(
      PeerContact.tryCreate(id: '1', name: '  ', phone: '555', reach: 'text'),
      isNull,
    );
    expect(
      PeerContact.tryCreate(id: '1', name: 'Sam', phone: ' ', reach: ' '),
      isNull,
    );

    final byPhone = PeerContact.tryCreate(
      id: '1',
      name: ' Sam ',
      phone: ' (732) 555-0100 ',
    );
    expect(byPhone?.name, 'Sam');
    expect(byPhone?.phone, '(732) 555-0100');
    expect(byPhone?.reach, isEmpty);

    final byReach = PeerContact.tryCreate(
      id: '2',
      name: 'Alex',
      reach: ' In person at the center ',
    );
    expect(byReach?.phone, isEmpty);
    expect(byReach?.reach, 'In person at the center');
  });

  test('saved contacts round-trip and skip blank rows', () {
    final saved = [
      PeerContact.tryCreate(id: '1', name: 'Sam', phone: '7325550100')!,
      PeerContact.tryCreate(id: '2', name: 'Alex', reach: 'Text')!,
    ];
    expect(peerContactsFromStored(peerContactsToStored(saved)), saved);
    expect(peerContactsFromStored(null), isEmpty);
    expect(peerContactsFromStored(''), isEmpty);
    expect(peerContactsFromStored('not-json'), isEmpty);
    expect(
      peerContactsFromStored(
        '[{"id":"x","name":" ","phone":"","reach":""},{"id":"y","name":"Sam"}]',
      ),
      isEmpty,
    );
  });
}
