// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_category_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTransactionCategoryModelCollection on Isar {
  IsarCollection<TransactionCategoryModel> get transactionCategoryModels =>
      this.collection();
}

const TransactionCategoryModelSchema = CollectionSchema(
  name: r'TransactionCategoryModel',
  id: -6417989001909456064,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isDefault': PropertySchema(
      id: 1,
      name: r'isDefault',
      type: IsarType.bool,
    ),
    r'nameEn': PropertySchema(id: 2, name: r'nameEn', type: IsarType.string),
    r'namePtBr': PropertySchema(
      id: 3,
      name: r'namePtBr',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 4,
      name: r'type',
      type: IsarType.string,
      enumMap: _TransactionCategoryModeltypeEnumValueMap,
    ),
  },

  estimateSize: _transactionCategoryModelEstimateSize,
  serialize: _transactionCategoryModelSerialize,
  deserialize: _transactionCategoryModelDeserialize,
  deserializeProp: _transactionCategoryModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _transactionCategoryModelGetId,
  getLinks: _transactionCategoryModelGetLinks,
  attach: _transactionCategoryModelAttach,
  version: '3.3.2',
);

int _transactionCategoryModelEstimateSize(
  TransactionCategoryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.nameEn;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.namePtBr.length * 3;
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _transactionCategoryModelSerialize(
  TransactionCategoryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeBool(offsets[1], object.isDefault);
  writer.writeString(offsets[2], object.nameEn);
  writer.writeString(offsets[3], object.namePtBr);
  writer.writeString(offsets[4], object.type.name);
}

TransactionCategoryModel _transactionCategoryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TransactionCategoryModel();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.isDefault = reader.readBool(offsets[1]);
  object.nameEn = reader.readStringOrNull(offsets[2]);
  object.namePtBr = reader.readString(offsets[3]);
  object.type =
      _TransactionCategoryModeltypeValueEnumMap[reader.readStringOrNull(
        offsets[4],
      )] ??
      TransactionType.income;
  return object;
}

P _transactionCategoryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (_TransactionCategoryModeltypeValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              TransactionType.income)
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TransactionCategoryModeltypeEnumValueMap = {
  r'income': r'income',
  r'expense': r'expense',
};
const _TransactionCategoryModeltypeValueEnumMap = {
  r'income': TransactionType.income,
  r'expense': TransactionType.expense,
};

Id _transactionCategoryModelGetId(TransactionCategoryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _transactionCategoryModelGetLinks(
  TransactionCategoryModel object,
) {
  return [];
}

void _transactionCategoryModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  TransactionCategoryModel object,
) {
  object.id = id;
}

extension TransactionCategoryModelQueryWhereSort
    on
        QueryBuilder<
          TransactionCategoryModel,
          TransactionCategoryModel,
          QWhere
        > {
  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TransactionCategoryModelQueryWhere
    on
        QueryBuilder<
          TransactionCategoryModel,
          TransactionCategoryModel,
          QWhereClause
        > {
  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterWhereClause
  >
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

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterWhereClause
  >
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
}

extension TransactionCategoryModelQueryFilter
    on
        QueryBuilder<
          TransactionCategoryModel,
          TransactionCategoryModel,
          QFilterCondition
        > {
  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
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
    TransactionCategoryModel,
    TransactionCategoryModel,
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
    TransactionCategoryModel,
    TransactionCategoryModel,
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
    TransactionCategoryModel,
    TransactionCategoryModel,
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
    TransactionCategoryModel,
    TransactionCategoryModel,
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
    TransactionCategoryModel,
    TransactionCategoryModel,
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
    TransactionCategoryModel,
    TransactionCategoryModel,
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
    TransactionCategoryModel,
    TransactionCategoryModel,
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
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  isDefaultEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDefault', value: value),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'nameEn'),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'nameEn'),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nameEn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nameEn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nameEn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nameEn',
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
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nameEn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nameEn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nameEn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nameEn',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nameEn', value: ''),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  nameEnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nameEn', value: ''),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'namePtBr',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'namePtBr',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'namePtBr',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'namePtBr',
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
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'namePtBr',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'namePtBr',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'namePtBr',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'namePtBr',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'namePtBr', value: ''),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  namePtBrIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'namePtBr', value: ''),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeEqualTo(TransactionType value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeGreaterThan(
    TransactionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeLessThan(
    TransactionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeBetween(
    TransactionType lower,
    TransactionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
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
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<
    TransactionCategoryModel,
    TransactionCategoryModel,
    QAfterFilterCondition
  >
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }
}

extension TransactionCategoryModelQueryObject
    on
        QueryBuilder<
          TransactionCategoryModel,
          TransactionCategoryModel,
          QFilterCondition
        > {}

extension TransactionCategoryModelQueryLinks
    on
        QueryBuilder<
          TransactionCategoryModel,
          TransactionCategoryModel,
          QFilterCondition
        > {}

extension TransactionCategoryModelQuerySortBy
    on
        QueryBuilder<
          TransactionCategoryModel,
          TransactionCategoryModel,
          QSortBy
        > {
  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByNameEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByNameEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.desc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByNamePtBr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namePtBr', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByNamePtBrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namePtBr', Sort.desc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension TransactionCategoryModelQuerySortThenBy
    on
        QueryBuilder<
          TransactionCategoryModel,
          TransactionCategoryModel,
          QSortThenBy
        > {
  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByNameEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByNameEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.desc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByNamePtBr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namePtBr', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByNamePtBrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namePtBr', Sort.desc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QAfterSortBy>
  thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension TransactionCategoryModelQueryWhereDistinct
    on
        QueryBuilder<
          TransactionCategoryModel,
          TransactionCategoryModel,
          QDistinct
        > {
  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QDistinct>
  distinctByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDefault');
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QDistinct>
  distinctByNameEn({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameEn', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QDistinct>
  distinctByNamePtBr({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'namePtBr', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionCategoryModel, QDistinct>
  distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension TransactionCategoryModelQueryProperty
    on
        QueryBuilder<
          TransactionCategoryModel,
          TransactionCategoryModel,
          QQueryProperty
        > {
  QueryBuilder<TransactionCategoryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TransactionCategoryModel, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TransactionCategoryModel, bool, QQueryOperations>
  isDefaultProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDefault');
    });
  }

  QueryBuilder<TransactionCategoryModel, String?, QQueryOperations>
  nameEnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameEn');
    });
  }

  QueryBuilder<TransactionCategoryModel, String, QQueryOperations>
  namePtBrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'namePtBr');
    });
  }

  QueryBuilder<TransactionCategoryModel, TransactionType, QQueryOperations>
  typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
