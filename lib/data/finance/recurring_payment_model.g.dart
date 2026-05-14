// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_payment_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRecurringPaymentModelCollection on Isar {
  IsarCollection<RecurringPaymentModel> get recurringPaymentModels =>
      this.collection();
}

const RecurringPaymentModelSchema = CollectionSchema(
  name: r'RecurringPaymentModel',
  id: 3174572233865325734,
  properties: {
    r'amountCents': PropertySchema(
      id: 0,
      name: r'amountCents',
      type: IsarType.long,
    ),
    r'categoryId': PropertySchema(
      id: 1,
      name: r'categoryId',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'cycle': PropertySchema(
      id: 3,
      name: r'cycle',
      type: IsarType.string,
      enumMap: _RecurringPaymentModelcycleEnumValueMap,
    ),
    r'deletedAt': PropertySchema(
      id: 4,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'isActive': PropertySchema(id: 5, name: r'isActive', type: IsarType.bool),
    r'nextDueDate': PropertySchema(
      id: 6,
      name: r'nextDueDate',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(id: 7, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _recurringPaymentModelEstimateSize,
  serialize: _recurringPaymentModelSerialize,
  deserialize: _recurringPaymentModelDeserialize,
  deserializeProp: _recurringPaymentModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'nextDueDate': IndexSchema(
      id: -1749684646791026574,
      name: r'nextDueDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nextDueDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'deletedAt': IndexSchema(
      id: -8969437169173379604,
      name: r'deletedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deletedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _recurringPaymentModelGetId,
  getLinks: _recurringPaymentModelGetLinks,
  attach: _recurringPaymentModelAttach,
  version: '3.3.2',
);

int _recurringPaymentModelEstimateSize(
  RecurringPaymentModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cycle.name.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _recurringPaymentModelSerialize(
  RecurringPaymentModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amountCents);
  writer.writeLong(offsets[1], object.categoryId);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.cycle.name);
  writer.writeDateTime(offsets[4], object.deletedAt);
  writer.writeBool(offsets[5], object.isActive);
  writer.writeDateTime(offsets[6], object.nextDueDate);
  writer.writeString(offsets[7], object.title);
  writer.writeDateTime(offsets[8], object.updatedAt);
}

RecurringPaymentModel _recurringPaymentModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RecurringPaymentModel();
  object.amountCents = reader.readLong(offsets[0]);
  object.categoryId = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.cycle =
      _RecurringPaymentModelcycleValueEnumMap[reader.readStringOrNull(
        offsets[3],
      )] ??
      RecurringCycle.daily;
  object.deletedAt = reader.readDateTimeOrNull(offsets[4]);
  object.id = id;
  object.isActive = reader.readBool(offsets[5]);
  object.nextDueDate = reader.readDateTime(offsets[6]);
  object.title = reader.readString(offsets[7]);
  object.updatedAt = reader.readDateTime(offsets[8]);
  return object;
}

P _recurringPaymentModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (_RecurringPaymentModelcycleValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              RecurringCycle.daily)
          as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RecurringPaymentModelcycleEnumValueMap = {
  r'daily': r'daily',
  r'weekly': r'weekly',
  r'biweekly': r'biweekly',
  r'monthly': r'monthly',
  r'quarterly': r'quarterly',
  r'yearly': r'yearly',
};
const _RecurringPaymentModelcycleValueEnumMap = {
  r'daily': RecurringCycle.daily,
  r'weekly': RecurringCycle.weekly,
  r'biweekly': RecurringCycle.biweekly,
  r'monthly': RecurringCycle.monthly,
  r'quarterly': RecurringCycle.quarterly,
  r'yearly': RecurringCycle.yearly,
};

Id _recurringPaymentModelGetId(RecurringPaymentModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _recurringPaymentModelGetLinks(
  RecurringPaymentModel object,
) {
  return [];
}

void _recurringPaymentModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  RecurringPaymentModel object,
) {
  object.id = id;
}

extension RecurringPaymentModelQueryWhereSort
    on QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QWhere> {
  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhere>
  anyNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'nextDueDate'),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhere>
  anyDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deletedAt'),
      );
    });
  }
}

extension RecurringPaymentModelQueryWhere
    on
        QueryBuilder<
          RecurringPaymentModel,
          RecurringPaymentModel,
          QWhereClause
        > {
  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  nextDueDateEqualTo(DateTime nextDueDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'nextDueDate',
          value: [nextDueDate],
        ),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  nextDueDateNotEqualTo(DateTime nextDueDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nextDueDate',
                lower: [],
                upper: [nextDueDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nextDueDate',
                lower: [nextDueDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nextDueDate',
                lower: [nextDueDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nextDueDate',
                lower: [],
                upper: [nextDueDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  nextDueDateGreaterThan(DateTime nextDueDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'nextDueDate',
          lower: [nextDueDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  nextDueDateLessThan(DateTime nextDueDate, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'nextDueDate',
          lower: [],
          upper: [nextDueDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  nextDueDateBetween(
    DateTime lowerNextDueDate,
    DateTime upperNextDueDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'nextDueDate',
          lower: [lowerNextDueDate],
          includeLower: includeLower,
          upper: [upperNextDueDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deletedAt', value: [null]),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  deletedAtEqualTo(DateTime? deletedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deletedAt', value: [deletedAt]),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  deletedAtNotEqualTo(DateTime? deletedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [],
                upper: [deletedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [deletedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [deletedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [],
                upper: [deletedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  deletedAtGreaterThan(DateTime? deletedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [deletedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  deletedAtLessThan(DateTime? deletedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [],
          upper: [deletedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterWhereClause>
  deletedAtBetween(
    DateTime? lowerDeletedAt,
    DateTime? upperDeletedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [lowerDeletedAt],
          includeLower: includeLower,
          upper: [upperDeletedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RecurringPaymentModelQueryFilter
    on
        QueryBuilder<
          RecurringPaymentModel,
          RecurringPaymentModel,
          QFilterCondition
        > {
  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  amountCentsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'amountCents', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  amountCentsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amountCents',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  amountCentsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amountCents',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  amountCentsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amountCents',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  categoryIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'categoryId', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  categoryIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'categoryId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  categoryIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'categoryId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  categoryIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'categoryId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleEqualTo(RecurringCycle value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cycle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleGreaterThan(
    RecurringCycle value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cycle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleLessThan(
    RecurringCycle value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cycle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleBetween(
    RecurringCycle lower,
    RecurringCycle upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cycle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cycle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cycle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cycle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cycle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cycle', value: ''),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  cycleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cycle', value: ''),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedAt', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  deletedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  deletedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deletedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isActive', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  nextDueDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nextDueDate', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  nextDueDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nextDueDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  nextDueDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nextDueDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  nextDueDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nextDueDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    RecurringPaymentModel,
    RecurringPaymentModel,
    QAfterFilterCondition
  >
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RecurringPaymentModelQueryObject
    on
        QueryBuilder<
          RecurringPaymentModel,
          RecurringPaymentModel,
          QFilterCondition
        > {}

extension RecurringPaymentModelQueryLinks
    on
        QueryBuilder<
          RecurringPaymentModel,
          RecurringPaymentModel,
          QFilterCondition
        > {}

extension RecurringPaymentModelQuerySortBy
    on QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QSortBy> {
  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByAmountCents() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountCents', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByAmountCentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountCents', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycle', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByCycleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycle', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByNextDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension RecurringPaymentModelQuerySortThenBy
    on QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QSortThenBy> {
  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByAmountCents() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountCents', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByAmountCentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountCents', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycle', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByCycleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycle', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByNextDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension RecurringPaymentModelQueryWhereDistinct
    on QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct> {
  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct>
  distinctByAmountCents() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountCents');
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct>
  distinctByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId');
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct>
  distinctByCycle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cycle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct>
  distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct>
  distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct>
  distinctByNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextDueDate');
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringPaymentModel, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension RecurringPaymentModelQueryProperty
    on
        QueryBuilder<
          RecurringPaymentModel,
          RecurringPaymentModel,
          QQueryProperty
        > {
  QueryBuilder<RecurringPaymentModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RecurringPaymentModel, int, QQueryOperations>
  amountCentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountCents');
    });
  }

  QueryBuilder<RecurringPaymentModel, int, QQueryOperations>
  categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<RecurringPaymentModel, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<RecurringPaymentModel, RecurringCycle, QQueryOperations>
  cycleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cycle');
    });
  }

  QueryBuilder<RecurringPaymentModel, DateTime?, QQueryOperations>
  deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<RecurringPaymentModel, bool, QQueryOperations>
  isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<RecurringPaymentModel, DateTime, QQueryOperations>
  nextDueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextDueDate');
    });
  }

  QueryBuilder<RecurringPaymentModel, String, QQueryOperations>
  titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<RecurringPaymentModel, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
