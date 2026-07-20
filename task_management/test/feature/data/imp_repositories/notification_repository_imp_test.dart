import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/feature/domain/entities/notification_entity.dart';

void main() {
  group('NotificationEntity.fromJson', () {
    test('parses all fields correctly when JSON is complete', () {
      final json = {
        'id': 'notif_1',
        'userId': 'user_1',
        'type': 'comment',
        'message': 'Someone commented on your task',
        'isRead': true,
        'relatedId': 'task_1',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final entity = NotificationEntity.fromJson(json);

      expect(entity.id, 'notif_1');
      expect(entity.userId, 'user_1');
      expect(entity.type, 'comment');
      expect(entity.message, 'Someone commented on your task');
      expect(entity.isRead, true);
      expect(entity.relatedId, 'task_1');
      expect(entity.createdAt, DateTime.parse('2024-01-01T12:00:00.000Z').toLocal());
    });

    test('throws when "id" is missing (no null-safety fallback in source)', () {
      final json = {
        'userId': 'user_1',
        'type': 'comment',
        'message': 'hello',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      // `json['id']` is assigned directly to a non-nullable String field
      // with no `?? ''` fallback, so this throws a TypeError at runtime.
      expect(() => NotificationEntity.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('defaults userId, type, message to empty string when missing', () {
      final json = {
        'id': 'notif_1',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final entity = NotificationEntity.fromJson(json);

      expect(entity.userId, '');
      expect(entity.type, '');
      expect(entity.message, '');
    });

    test('defaults isRead to false when missing', () {
      final json = {
        'id': 'notif_1',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final entity = NotificationEntity.fromJson(json);

      expect(entity.isRead, false);
    });

    test('preserves isRead: true when explicitly set', () {
      final json = {
        'id': 'notif_1',
        'isRead': true,
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final entity = NotificationEntity.fromJson(json);

      expect(entity.isRead, true);
    });

    test('relatedId is null when missing', () {
      final json = {
        'id': 'notif_1',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final entity = NotificationEntity.fromJson(json);

      expect(entity.relatedId, isNull);
    });

    test('relatedId is preserved when present', () {
      final json = {
        'id': 'notif_1',
        'relatedId': 'task_42',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final entity = NotificationEntity.fromJson(json);

      expect(entity.relatedId, 'task_42');
    });

    test('defaults createdAt to now (approximately) when missing', () {
      final before = DateTime.now();
      final entity = NotificationEntity.fromJson({'id': 'notif_1'});
      final after = DateTime.now();

      expect(
        entity.createdAt.isAfter(before.subtract(const Duration(seconds: 1))) &&
            entity.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('parses createdAt correctly when the string already ends with "Z"', () {
      final json = {
        'id': 'notif_1',
        'createdAt': '2024-06-15T08:30:00.000Z',
      };

      final entity = NotificationEntity.fromJson(json);

      expect(entity.createdAt, DateTime.parse('2024-06-15T08:30:00.000Z').toLocal());
    });

    test('appends "Z" and parses correctly when the string does not end with "Z"', () {
      final json = {
        'id': 'notif_1',
        'createdAt': '2024-06-15T08:30:00.000', // no trailing Z
      };

      final entity = NotificationEntity.fromJson(json);

      expect(entity.createdAt, DateTime.parse('2024-06-15T08:30:00.000Z').toLocal());
    });

    test('createdAt result is always in local time (per .toLocal() call)', () {
      final json = {
        'id': 'notif_1',
        'createdAt': '2024-06-15T08:30:00.000Z',
      };

      final entity = NotificationEntity.fromJson(json);

      expect(entity.createdAt.isUtc, false);
    });
  });

  group('NotificationEntity.copyWith', () {
    NotificationEntity baseEntity() => NotificationEntity(
          id: 'notif_1',
          userId: 'user_1',
          type: 'comment',
          message: 'Original message',
          isRead: false,
          relatedId: 'task_1',
          createdAt: DateTime(2024, 1, 1),
        );

    test('returns an identical copy when no arguments are passed', () {
      final original = baseEntity();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.userId, original.userId);
      expect(copy.type, original.type);
      expect(copy.message, original.message);
      expect(copy.isRead, original.isRead);
      expect(copy.relatedId, original.relatedId);
      expect(copy.createdAt, original.createdAt);
    });

    test('overrides only the specified field(s)', () {
      final original = baseEntity();
      final copy = original.copyWith(isRead: true);

      expect(copy.isRead, true);
      expect(copy.id, original.id);
      expect(copy.message, original.message);
    });

    test('overrides multiple fields at once', () {
      final original = baseEntity();
      final newDate = DateTime(2025, 5, 5);
      final copy = original.copyWith(
        message: 'Updated message',
        isRead: true,
        createdAt: newDate,
      );

      expect(copy.message, 'Updated message');
      expect(copy.isRead, true);
      expect(copy.createdAt, newDate);
      // unchanged fields
      expect(copy.id, original.id);
      expect(copy.userId, original.userId);
      expect(copy.type, original.type);
      expect(copy.relatedId, original.relatedId);
    });

    test('does not mutate the original entity', () {
      final original = baseEntity();
      original.copyWith(message: 'Should not affect original');

      expect(original.message, 'Original message');
    });

    test('cannot clear relatedId to null via copyWith (known limitation: "?? this.x" pattern)', () {
      final original = baseEntity(); // relatedId = 'task_1'
      final copy = original.copyWith(relatedId: null);

      // Passing `null` explicitly is indistinguishable from omitting the
      // argument entirely with this copyWith style, so relatedId stays 'task_1'.
      expect(copy.relatedId, 'task_1');
    });
  });

  group('NotificationEntity equality & hashCode', () {
    test('two entities with the same id are equal, even if other fields differ', () {
      final a = NotificationEntity(
        id: 'same_id',
        userId: 'user_1',
        type: 'comment',
        message: 'Message A',
        createdAt: DateTime(2024, 1, 1),
      );
      final b = NotificationEntity(
        id: 'same_id',
        userId: 'user_2',
        type: 'like',
        message: 'Message B',
        isRead: true,
        createdAt: DateTime(2025, 5, 5),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('two entities with different ids are not equal', () {
      final a = NotificationEntity(
        id: 'id_1',
        userId: 'user_1',
        type: 'comment',
        message: 'Same message',
        createdAt: DateTime(2024, 1, 1),
      );
      final b = NotificationEntity(
        id: 'id_2',
        userId: 'user_1',
        type: 'comment',
        message: 'Same message',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(a, isNot(equals(b)));
    });

    test('an entity is equal to itself (identical)', () {
      final a = NotificationEntity(
        id: 'id_1',
        userId: 'user_1',
        type: 'comment',
        message: 'msg',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(a, equals(a));
    });

    test('is not equal to an object of a different type', () {
      final a = NotificationEntity(
        id: 'id_1',
        userId: 'user_1',
        type: 'comment',
        message: 'msg',
        createdAt: DateTime(2024, 1, 1),
      );

      // ignore: unrelated_type_equality_checks
      expect(a == 'id_1', false);
    });
  });

  group('NotificationEntity.toString', () {
    test('includes id, type, and isRead', () {
      final entity = NotificationEntity(
        id: 'notif_99',
        userId: 'user_1',
        type: 'mention',
        message: 'msg',
        isRead: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final str = entity.toString();

      expect(str, contains('notif_99'));
      expect(str, contains('mention'));
      expect(str, contains('true'));
    });
  });
}