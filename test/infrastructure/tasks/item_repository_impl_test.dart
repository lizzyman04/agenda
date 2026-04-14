import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/tasks/item_dao.dart';
import 'package:agenda/data/tasks/item_mapper.dart';
import 'package:agenda/data/tasks/item_model.dart' as data;
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart' as domain;
import 'package:agenda/domain/tasks/recurrence_engine.dart';
import 'package:agenda/infrastructure/tasks/item_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockItemDao extends Mock implements ItemDao {}

class MockItemMapper extends Mock implements ItemMapper {}

class MockRecurrenceEngine extends Mock implements RecurrenceEngine {}

class FakeItem extends Fake implements Item {}

class FakeItemModel extends Fake implements data.ItemModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeItem());
    registerFallbackValue(FakeItemModel());
  });

  late MockItemDao mockDao;
  late MockItemMapper mockMapper;
  late MockRecurrenceEngine mockEngine;
  late ItemRepositoryImpl repository;

  final now = DateTime(2024, 6, 15);

  Item makeItem({
    int id = 1,
    domain.ItemType type = domain.ItemType.task,
    int? parentId,
  }) {
    return Item(
      id: id,
      type: type,
      title: 'Test Item',
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
    );
  }

  data.ItemModel makeModel({int id = 1}) {
    return data.ItemModel()
      ..id = id
      ..type = data.ItemType.task
      ..title = 'Test Item'
      ..createdAt = now
      ..updatedAt = now;
  }

  setUp(() {
    mockDao = MockItemDao();
    mockMapper = MockItemMapper();
    mockEngine = MockRecurrenceEngine();
    repository = ItemRepositoryImpl(mockDao, mockMapper, mockEngine);
  });

  group('ItemRepositoryImpl', () {
    group('createItem', () {
      test('calls dao.save() and returns Success<Item>', () async {
        final item = makeItem();
        final model = makeModel();
        final savedModel = makeModel(id: 99);
        final savedItem = makeItem(id: 99);

        when(() => mockMapper.toModel(any())).thenReturn(model);
        when(() => mockDao.save(any())).thenAnswer((_) async => 99);
        when(() => mockDao.findById(99)).thenAnswer((_) async => savedModel);
        when(() => mockMapper.toDomain(savedModel)).thenReturn(savedItem);

        final result = await repository.createItem(item);

        expect(result, isA<Success<Item>>());
        expect((result as Success<Item>).value.id, 99);
        verify(() => mockDao.save(any())).called(1);
      });

      test(
          'with parentId pointing to non-project type '
          'returns Err(ValidationFailure)', () async {
        final projectItem = makeItem(id: 5);
        final childItem = makeItem(parentId: 5);
        final projectModel = makeModel(id: 5);

        when(() => mockDao.findById(5)).thenAnswer((_) async => projectModel);
        when(() => mockMapper.toDomain(projectModel)).thenReturn(projectItem);

        final result = await repository.createItem(childItem);

        expect(result, isA<Err<Item>>());
        final err = result as Err<Item>;
        expect(err.failure, isA<ValidationFailure>());
      });
    });

    group('softDelete', () {
      test('calls dao.softDelete() with correct id', () async {
        final model = makeModel();
        final item = makeItem();

        when(() => mockDao.softDelete(1)).thenAnswer((_) async {});
        when(() => mockDao.findById(1)).thenAnswer((_) async => model);
        when(() => mockMapper.toDomain(model)).thenReturn(item);

        await repository.softDelete(1);

        verify(() => mockDao.softDelete(1)).called(1);
      });
    });

    group('restoreItem', () {
      test('calls dao.restoreItem() with correct id', () async {
        final model = makeModel();
        final item = makeItem();

        when(() => mockDao.restoreItem(1)).thenAnswer((_) async {});
        when(() => mockDao.findById(1)).thenAnswer((_) async => model);
        when(() => mockMapper.toDomain(model)).thenReturn(item);

        await repository.restoreItem(1);

        verify(() => mockDao.restoreItem(1)).called(1);
      });
    });

    group('searchByTitle', () {
      test('delegates to dao.searchByTitle()', () async {
        final model = makeModel();
        final item = makeItem();

        when(() => mockDao.searchByTitle('task'))
            .thenAnswer((_) async => [model]);
        when(() => mockMapper.toDomain(model)).thenReturn(item);

        final result = await repository.searchByTitle('task');

        expect(result, isA<Success<List<Item>>>());
        verify(() => mockDao.searchByTitle('task')).called(1);
      });
    });
  });
}
