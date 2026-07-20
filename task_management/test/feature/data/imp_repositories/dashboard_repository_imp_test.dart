import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/feature/domain/entities/dashboard_entity.dart';

void main() {
  group('DashboardEntity.fromJson', () {
    test('parses all fields correctly when JSON is complete', () {
      final json = {
        'totalTasksDone': 42,
        'tasksDoneThisWeek': 7,
        'totalTasksOngoing': 15,
        'tasksToDo': 5,
        'tasksInProgress': 6,
        'tasksReview': 4,
      };

      final entity = DashboardEntity.fromJson(json);

      expect(entity.totalTasksDone, 42);
      expect(entity.tasksDoneThisWeek, 7);
      expect(entity.totalTasksOngoing, 15);
      expect(entity.tasksToDo, 5);
      expect(entity.tasksInProgress, 6);
      expect(entity.tasksReview, 4);
    });

    test('defaults all fields to 0 when JSON is empty', () {
      final entity = DashboardEntity.fromJson(<String, dynamic>{});

      expect(entity.totalTasksDone, 0);
      expect(entity.tasksDoneThisWeek, 0);
      expect(entity.totalTasksOngoing, 0);
      expect(entity.tasksToDo, 0);
      expect(entity.tasksInProgress, 0);
      expect(entity.tasksReview, 0);
    });

    test('defaults missing individual fields to 0 while keeping present ones', () {
      final json = {
        'totalTasksDone': 10,
        // tasksDoneThisWeek missing
        'totalTasksOngoing': 3,
        // tasksToDo missing
        'tasksInProgress': 2,
        // tasksReview missing
      };

      final entity = DashboardEntity.fromJson(json);

      expect(entity.totalTasksDone, 10);
      expect(entity.tasksDoneThisWeek, 0);
      expect(entity.totalTasksOngoing, 3);
      expect(entity.tasksToDo, 0);
      expect(entity.tasksInProgress, 2);
      expect(entity.tasksReview, 0);
    });

    test('treats explicit null values as missing and defaults to 0', () {
      final json = {
        'totalTasksDone': null,
        'tasksDoneThisWeek': 5,
        'totalTasksOngoing': null,
        'tasksToDo': null,
        'tasksInProgress': null,
        'tasksReview': null,
      };

      final entity = DashboardEntity.fromJson(json);

      expect(entity.totalTasksDone, 0);
      expect(entity.tasksDoneThisWeek, 5);
      expect(entity.totalTasksOngoing, 0);
      expect(entity.tasksToDo, 0);
      expect(entity.tasksInProgress, 0);
      expect(entity.tasksReview, 0);
    });

    test('handles zero values correctly (not overridden by default)', () {
      final json = {
        'totalTasksDone': 0,
        'tasksDoneThisWeek': 0,
        'totalTasksOngoing': 0,
        'tasksToDo': 0,
        'tasksInProgress': 0,
        'tasksReview': 0,
      };

      final entity = DashboardEntity.fromJson(json);

      expect(entity.totalTasksDone, 0);
      expect(entity.tasksDoneThisWeek, 0);
      expect(entity.totalTasksOngoing, 0);
      expect(entity.tasksToDo, 0);
      expect(entity.tasksInProgress, 0);
      expect(entity.tasksReview, 0);
    });

    test('ignores unrelated/extra keys in JSON', () {
      final json = {
        'totalTasksDone': 1,
        'tasksDoneThisWeek': 1,
        'totalTasksOngoing': 1,
        'tasksToDo': 1,
        'tasksInProgress': 1,
        'tasksReview': 1,
        'someUnexpectedField': 'ignored',
        'anotherOne': 999,
      };

      final entity = DashboardEntity.fromJson(json);

      expect(entity.totalTasksDone, 1);
      expect(entity.tasksReview, 1);
    });
  });

  group('DashboardEntity.copyWith', () {
    DashboardEntity baseEntity() => DashboardEntity(
          totalTasksDone: 10,
          tasksDoneThisWeek: 2,
          totalTasksOngoing: 5,
          tasksToDo: 1,
          tasksInProgress: 2,
          tasksReview: 2,
        );

    test('returns an identical copy when no arguments are passed', () {
      final original = baseEntity();
      final copy = original.copyWith();

      expect(copy.totalTasksDone, original.totalTasksDone);
      expect(copy.tasksDoneThisWeek, original.tasksDoneThisWeek);
      expect(copy.totalTasksOngoing, original.totalTasksOngoing);
      expect(copy.tasksToDo, original.tasksToDo);
      expect(copy.tasksInProgress, original.tasksInProgress);
      expect(copy.tasksReview, original.tasksReview);
    });

    test('overrides only the specified field(s)', () {
      final original = baseEntity();
      final copy = original.copyWith(totalTasksDone: 99);

      expect(copy.totalTasksDone, 99);
      expect(copy.tasksDoneThisWeek, original.tasksDoneThisWeek);
      expect(copy.totalTasksOngoing, original.totalTasksOngoing);
      expect(copy.tasksToDo, original.tasksToDo);
      expect(copy.tasksInProgress, original.tasksInProgress);
      expect(copy.tasksReview, original.tasksReview);
    });

    test('overrides multiple fields at once', () {
      final original = baseEntity();
      final copy = original.copyWith(
        tasksToDo: 20,
        tasksInProgress: 30,
        tasksReview: 40,
      );

      expect(copy.tasksToDo, 20);
      expect(copy.tasksInProgress, 30);
      expect(copy.tasksReview, 40);
      // unchanged fields
      expect(copy.totalTasksDone, original.totalTasksDone);
      expect(copy.tasksDoneThisWeek, original.tasksDoneThisWeek);
      expect(copy.totalTasksOngoing, original.totalTasksOngoing);
    });

    test('overriding with 0 actually sets the value to 0, not ignored', () {
      final original = baseEntity();
      final copy = original.copyWith(totalTasksDone: 0);

      expect(copy.totalTasksDone, 0);
    });

    test('does not mutate the original entity', () {
      final original = baseEntity();
      original.copyWith(totalTasksDone: 500);

      expect(original.totalTasksDone, 10); // unchanged
    });
  });
}