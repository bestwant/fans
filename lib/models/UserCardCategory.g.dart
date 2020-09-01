// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserCardCategory.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<UserCardCategory> _$userCardCategorySerializer =
    new _$UserCardCategorySerializer();

class _$UserCardCategorySerializer
    implements StructuredSerializer<UserCardCategory> {
  @override
  final Iterable<Type> types = const [UserCardCategory, _$UserCardCategory];
  @override
  final String wireName = 'UserCardCategory';

  @override
  Iterable<Object> serialize(Serializers serializers, UserCardCategory object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      '_id',
      serializers.serialize(object.id, specifiedType: const FullType(String)),
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  UserCardCategory deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new UserCardCategoryBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case '_id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$UserCardCategory extends UserCardCategory {
  @override
  final String id;
  @override
  final String name;

  factory _$UserCardCategory(
          [void Function(UserCardCategoryBuilder) updates]) =>
      (new UserCardCategoryBuilder()..update(updates)).build();

  _$UserCardCategory._({this.id, this.name}) : super._() {
    if (id == null) {
      throw new BuiltValueNullFieldError('UserCardCategory', 'id');
    }
    if (name == null) {
      throw new BuiltValueNullFieldError('UserCardCategory', 'name');
    }
  }

  @override
  UserCardCategory rebuild(void Function(UserCardCategoryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserCardCategoryBuilder toBuilder() =>
      new UserCardCategoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserCardCategory && id == other.id && name == other.name;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, id.hashCode), name.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('UserCardCategory')
          ..add('id', id)
          ..add('name', name))
        .toString();
  }
}

class UserCardCategoryBuilder
    implements Builder<UserCardCategory, UserCardCategoryBuilder> {
  _$UserCardCategory _$v;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  UserCardCategoryBuilder();

  UserCardCategoryBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _name = _$v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserCardCategory other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$UserCardCategory;
  }

  @override
  void update(void Function(UserCardCategoryBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$UserCardCategory build() {
    final _$result = _$v ?? new _$UserCardCategory._(id: id, name: name);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
