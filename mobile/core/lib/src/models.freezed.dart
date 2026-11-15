// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GeoPoint {

 double get lat; double get lng;
/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeoPointCopyWith<GeoPoint> get copyWith => _$GeoPointCopyWithImpl<GeoPoint>(this as GeoPoint, _$identity);

  /// Serializes this GeoPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GeoPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeoPoint&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GeoPoint;
  return Object.hash(runtimeType,_this.lat,_this.lng);
}

@override
String toString() {
  final _this = this as GeoPoint;
  return 'GeoPoint(lat: ${_this.lat}, lng: ${_this.lng})';
}


}

/// @nodoc
abstract mixin class $GeoPointCopyWith<$Res>  {
  factory $GeoPointCopyWith(GeoPoint value, $Res Function(GeoPoint) _then) = _$GeoPointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class _$GeoPointCopyWithImpl<$Res>
    implements $GeoPointCopyWith<$Res> {
  _$GeoPointCopyWithImpl(this._self, this._then);

  final GeoPoint _self;
  final $Res Function(GeoPoint) _then;

/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(GeoPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [GeoPoint].
extension GeoPointPatterns on GeoPoint {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeoPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeoPoint value)  $default,){
final _that = this;
switch (_that) {
case _GeoPoint():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeoPoint value)?  $default,){
final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that.lat,_that.lng);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _GeoPoint():
return $default(_that.lat,_that.lng);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeoPoint implements GeoPoint {
  const _GeoPoint({required this.lat, required this.lng});
  factory _GeoPoint.fromJson(Map<String, dynamic> json) => _$GeoPointFromJson(json);

@override final  double lat;
@override final  double lng;

/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeoPointCopyWith<_GeoPoint> get copyWith => __$GeoPointCopyWithImpl<_GeoPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeoPointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeoPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lat,lng);
}

@override
String toString() {
    return 'GeoPoint(lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$GeoPointCopyWith<$Res> implements $GeoPointCopyWith<$Res> {
  factory _$GeoPointCopyWith(_GeoPoint value, $Res Function(_GeoPoint) _then) = __$GeoPointCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class __$GeoPointCopyWithImpl<$Res>
    implements _$GeoPointCopyWith<$Res> {
  __$GeoPointCopyWithImpl(this._self, this._then);

  final _GeoPoint _self;
  final $Res Function(_GeoPoint) _then;

/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(_GeoPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$RestaurantCard {

 String get id; String get vertical; String get city; String get name; String get description; List<String> get cuisines; String get area; double get rating; int get ratingCount; bool get isOpen; bool get isAcceptingOrders; bool get isFeatured; String? get coverUrl; double? get distanceKm; int? get etaMinutes; int? get deliveryFeeKobo; bool? get deliversToLocation; bool get supportsPickup; bool get supportsDelivery; List<PromoBadge> get promotions;
/// Create a copy of RestaurantCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantCardCopyWith<RestaurantCard> get copyWith => _$RestaurantCardCopyWithImpl<RestaurantCard>(this as RestaurantCard, _$identity);

  /// Serializes this RestaurantCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RestaurantCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantCard&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.vertical, _this.vertical) || other.vertical == _this.vertical)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.cuisines, _this.cuisines)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.isOpen, _this.isOpen) || other.isOpen == _this.isOpen)&&(identical(other.isAcceptingOrders, _this.isAcceptingOrders) || other.isAcceptingOrders == _this.isAcceptingOrders)&&(identical(other.isFeatured, _this.isFeatured) || other.isFeatured == _this.isFeatured)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.etaMinutes, _this.etaMinutes) || other.etaMinutes == _this.etaMinutes)&&(identical(other.deliveryFeeKobo, _this.deliveryFeeKobo) || other.deliveryFeeKobo == _this.deliveryFeeKobo)&&(identical(other.deliversToLocation, _this.deliversToLocation) || other.deliversToLocation == _this.deliversToLocation)&&(identical(other.supportsPickup, _this.supportsPickup) || other.supportsPickup == _this.supportsPickup)&&(identical(other.supportsDelivery, _this.supportsDelivery) || other.supportsDelivery == _this.supportsDelivery)&&const DeepCollectionEquality().equals(other.promotions, _this.promotions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RestaurantCard;
  return Object.hashAll([runtimeType,_this.id,_this.vertical,_this.city,_this.name,_this.description,const DeepCollectionEquality().hash(_this.cuisines),_this.area,_this.rating,_this.ratingCount,_this.isOpen,_this.isAcceptingOrders,_this.isFeatured,_this.coverUrl,_this.distanceKm,_this.etaMinutes,_this.deliveryFeeKobo,_this.deliversToLocation,_this.supportsPickup,_this.supportsDelivery,const DeepCollectionEquality().hash(_this.promotions)]);
}

@override
String toString() {
  final _this = this as RestaurantCard;
  return 'RestaurantCard(id: ${_this.id}, vertical: ${_this.vertical}, city: ${_this.city}, name: ${_this.name}, description: ${_this.description}, cuisines: ${_this.cuisines}, area: ${_this.area}, rating: ${_this.rating}, ratingCount: ${_this.ratingCount}, isOpen: ${_this.isOpen}, isAcceptingOrders: ${_this.isAcceptingOrders}, isFeatured: ${_this.isFeatured}, coverUrl: ${_this.coverUrl}, distanceKm: ${_this.distanceKm}, etaMinutes: ${_this.etaMinutes}, deliveryFeeKobo: ${_this.deliveryFeeKobo}, deliversToLocation: ${_this.deliversToLocation}, supportsPickup: ${_this.supportsPickup}, supportsDelivery: ${_this.supportsDelivery}, promotions: ${_this.promotions})';
}


}

/// @nodoc
abstract mixin class $RestaurantCardCopyWith<$Res>  {
  factory $RestaurantCardCopyWith(RestaurantCard value, $Res Function(RestaurantCard) _then) = _$RestaurantCardCopyWithImpl;
@useResult
$Res call({
 String id, String vertical, String city, String name, String description, List<String> cuisines, String area, double rating, int ratingCount, bool isOpen, bool isAcceptingOrders, bool isFeatured, String? coverUrl, double? distanceKm, int? etaMinutes, int? deliveryFeeKobo, bool? deliversToLocation, bool supportsPickup, bool supportsDelivery, List<PromoBadge> promotions
});




}
/// @nodoc
class _$RestaurantCardCopyWithImpl<$Res>
    implements $RestaurantCardCopyWith<$Res> {
  _$RestaurantCardCopyWithImpl(this._self, this._then);

  final RestaurantCard _self;
  final $Res Function(RestaurantCard) _then;

/// Create a copy of RestaurantCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vertical = null,Object? city = null,Object? name = null,Object? description = null,Object? cuisines = null,Object? area = null,Object? rating = null,Object? ratingCount = null,Object? isOpen = null,Object? isAcceptingOrders = null,Object? isFeatured = null,Object? coverUrl = freezed,Object? distanceKm = freezed,Object? etaMinutes = freezed,Object? deliveryFeeKobo = freezed,Object? deliversToLocation = freezed,Object? supportsPickup = null,Object? supportsDelivery = null,Object? promotions = null,}) {
  return _then(RestaurantCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cuisines: null == cuisines ? _self.cuisines : cuisines // ignore: cast_nullable_to_non_nullable
as List<String>,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,isAcceptingOrders: null == isAcceptingOrders ? _self.isAcceptingOrders : isAcceptingOrders // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int?,deliveryFeeKobo: freezed == deliveryFeeKobo ? _self.deliveryFeeKobo : deliveryFeeKobo // ignore: cast_nullable_to_non_nullable
as int?,deliversToLocation: freezed == deliversToLocation ? _self.deliversToLocation : deliversToLocation // ignore: cast_nullable_to_non_nullable
as bool?,supportsPickup: null == supportsPickup ? _self.supportsPickup : supportsPickup // ignore: cast_nullable_to_non_nullable
as bool,supportsDelivery: null == supportsDelivery ? _self.supportsDelivery : supportsDelivery // ignore: cast_nullable_to_non_nullable
as bool,promotions: null == promotions ? _self.promotions : promotions // ignore: cast_nullable_to_non_nullable
as List<PromoBadge>,
  ));
}

}


/// Adds pattern-matching-related methods to [RestaurantCard].
extension RestaurantCardPatterns on RestaurantCard {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantCard() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantCard value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantCard():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantCard value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantCard() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vertical,  String city,  String name,  String description,  List<String> cuisines,  String area,  double rating,  int ratingCount,  bool isOpen,  bool isAcceptingOrders,  bool isFeatured,  String? coverUrl,  double? distanceKm,  int? etaMinutes,  int? deliveryFeeKobo,  bool? deliversToLocation,  bool supportsPickup,  bool supportsDelivery,  List<PromoBadge> promotions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantCard() when $default != null:
return $default(_that.id,_that.vertical,_that.city,_that.name,_that.description,_that.cuisines,_that.area,_that.rating,_that.ratingCount,_that.isOpen,_that.isAcceptingOrders,_that.isFeatured,_that.coverUrl,_that.distanceKm,_that.etaMinutes,_that.deliveryFeeKobo,_that.deliversToLocation,_that.supportsPickup,_that.supportsDelivery,_that.promotions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vertical,  String city,  String name,  String description,  List<String> cuisines,  String area,  double rating,  int ratingCount,  bool isOpen,  bool isAcceptingOrders,  bool isFeatured,  String? coverUrl,  double? distanceKm,  int? etaMinutes,  int? deliveryFeeKobo,  bool? deliversToLocation,  bool supportsPickup,  bool supportsDelivery,  List<PromoBadge> promotions)  $default,) {final _that = this;
switch (_that) {
case _RestaurantCard():
return $default(_that.id,_that.vertical,_that.city,_that.name,_that.description,_that.cuisines,_that.area,_that.rating,_that.ratingCount,_that.isOpen,_that.isAcceptingOrders,_that.isFeatured,_that.coverUrl,_that.distanceKm,_that.etaMinutes,_that.deliveryFeeKobo,_that.deliversToLocation,_that.supportsPickup,_that.supportsDelivery,_that.promotions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vertical,  String city,  String name,  String description,  List<String> cuisines,  String area,  double rating,  int ratingCount,  bool isOpen,  bool isAcceptingOrders,  bool isFeatured,  String? coverUrl,  double? distanceKm,  int? etaMinutes,  int? deliveryFeeKobo,  bool? deliversToLocation,  bool supportsPickup,  bool supportsDelivery,  List<PromoBadge> promotions)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantCard() when $default != null:
return $default(_that.id,_that.vertical,_that.city,_that.name,_that.description,_that.cuisines,_that.area,_that.rating,_that.ratingCount,_that.isOpen,_that.isAcceptingOrders,_that.isFeatured,_that.coverUrl,_that.distanceKm,_that.etaMinutes,_that.deliveryFeeKobo,_that.deliversToLocation,_that.supportsPickup,_that.supportsDelivery,_that.promotions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestaurantCard implements RestaurantCard {
  const _RestaurantCard({required this.id, this.vertical = 'food', this.city = 'lagos', required this.name, this.description = '',  List<String> cuisines = const <String>[], this.area = '', this.rating = 0, this.ratingCount = 0, this.isOpen = false, this.isAcceptingOrders = true, this.isFeatured = false, this.coverUrl, this.distanceKm, this.etaMinutes, this.deliveryFeeKobo, this.deliversToLocation, this.supportsPickup = true, this.supportsDelivery = true,  List<PromoBadge> promotions = const <PromoBadge>[]}): _cuisines = cuisines,_promotions = promotions;
  factory _RestaurantCard.fromJson(Map<String, dynamic> json) => _$RestaurantCardFromJson(json);

@override final  String id;
@override@JsonKey() final  String vertical;
@override@JsonKey() final  String city;
@override final  String name;
@override@JsonKey() final  String description;
 final  List<String> _cuisines;
@override@JsonKey() List<String> get cuisines {
  if (_cuisines is EqualUnmodifiableListView) return _cuisines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cuisines);
}

@override@JsonKey() final  String area;
@override@JsonKey() final  double rating;
@override@JsonKey() final  int ratingCount;
@override@JsonKey() final  bool isOpen;
@override@JsonKey() final  bool isAcceptingOrders;
@override@JsonKey() final  bool isFeatured;
@override final  String? coverUrl;
@override final  double? distanceKm;
@override final  int? etaMinutes;
@override final  int? deliveryFeeKobo;
@override final  bool? deliversToLocation;
@override@JsonKey() final  bool supportsPickup;
@override@JsonKey() final  bool supportsDelivery;
 final  List<PromoBadge> _promotions;
@override@JsonKey() List<PromoBadge> get promotions {
  if (_promotions is EqualUnmodifiableListView) return _promotions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_promotions);
}


/// Create a copy of RestaurantCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantCardCopyWith<_RestaurantCard> get copyWith => __$RestaurantCardCopyWithImpl<_RestaurantCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantCardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantCard&&(identical(other.id, id) || other.id == id)&&(identical(other.vertical, vertical) || other.vertical == vertical)&&(identical(other.city, city) || other.city == city)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.cuisines, _cuisines)&&(identical(other.area, area) || other.area == area)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.isAcceptingOrders, isAcceptingOrders) || other.isAcceptingOrders == isAcceptingOrders)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.etaMinutes, etaMinutes) || other.etaMinutes == etaMinutes)&&(identical(other.deliveryFeeKobo, deliveryFeeKobo) || other.deliveryFeeKobo == deliveryFeeKobo)&&(identical(other.deliversToLocation, deliversToLocation) || other.deliversToLocation == deliversToLocation)&&(identical(other.supportsPickup, supportsPickup) || other.supportsPickup == supportsPickup)&&(identical(other.supportsDelivery, supportsDelivery) || other.supportsDelivery == supportsDelivery)&&const DeepCollectionEquality().equals(other.promotions, _promotions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,vertical,city,name,description,const DeepCollectionEquality().hash(_cuisines),area,rating,ratingCount,isOpen,isAcceptingOrders,isFeatured,coverUrl,distanceKm,etaMinutes,deliveryFeeKobo,deliversToLocation,supportsPickup,supportsDelivery,const DeepCollectionEquality().hash(_promotions)]);
}

@override
String toString() {
    return 'RestaurantCard(id: $id, vertical: $vertical, city: $city, name: $name, description: $description, cuisines: $cuisines, area: $area, rating: $rating, ratingCount: $ratingCount, isOpen: $isOpen, isAcceptingOrders: $isAcceptingOrders, isFeatured: $isFeatured, coverUrl: $coverUrl, distanceKm: $distanceKm, etaMinutes: $etaMinutes, deliveryFeeKobo: $deliveryFeeKobo, deliversToLocation: $deliversToLocation, supportsPickup: $supportsPickup, supportsDelivery: $supportsDelivery, promotions: $promotions)';
}


}

/// @nodoc
abstract mixin class _$RestaurantCardCopyWith<$Res> implements $RestaurantCardCopyWith<$Res> {
  factory _$RestaurantCardCopyWith(_RestaurantCard value, $Res Function(_RestaurantCard) _then) = __$RestaurantCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String vertical, String city, String name, String description, List<String> cuisines, String area, double rating, int ratingCount, bool isOpen, bool isAcceptingOrders, bool isFeatured, String? coverUrl, double? distanceKm, int? etaMinutes, int? deliveryFeeKobo, bool? deliversToLocation, bool supportsPickup, bool supportsDelivery, List<PromoBadge> promotions
});




}
/// @nodoc
class __$RestaurantCardCopyWithImpl<$Res>
    implements _$RestaurantCardCopyWith<$Res> {
  __$RestaurantCardCopyWithImpl(this._self, this._then);

  final _RestaurantCard _self;
  final $Res Function(_RestaurantCard) _then;

/// Create a copy of RestaurantCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vertical = null,Object? city = null,Object? name = null,Object? description = null,Object? cuisines = null,Object? area = null,Object? rating = null,Object? ratingCount = null,Object? isOpen = null,Object? isAcceptingOrders = null,Object? isFeatured = null,Object? coverUrl = freezed,Object? distanceKm = freezed,Object? etaMinutes = freezed,Object? deliveryFeeKobo = freezed,Object? deliversToLocation = freezed,Object? supportsPickup = null,Object? supportsDelivery = null,Object? promotions = null,}) {
  return _then(_RestaurantCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cuisines: null == cuisines ? _self._cuisines : cuisines // ignore: cast_nullable_to_non_nullable
as List<String>,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,isAcceptingOrders: null == isAcceptingOrders ? _self.isAcceptingOrders : isAcceptingOrders // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int?,deliveryFeeKobo: freezed == deliveryFeeKobo ? _self.deliveryFeeKobo : deliveryFeeKobo // ignore: cast_nullable_to_non_nullable
as int?,deliversToLocation: freezed == deliversToLocation ? _self.deliversToLocation : deliversToLocation // ignore: cast_nullable_to_non_nullable
as bool?,supportsPickup: null == supportsPickup ? _self.supportsPickup : supportsPickup // ignore: cast_nullable_to_non_nullable
as bool,supportsDelivery: null == supportsDelivery ? _self.supportsDelivery : supportsDelivery // ignore: cast_nullable_to_non_nullable
as bool,promotions: null == promotions ? _self._promotions : promotions // ignore: cast_nullable_to_non_nullable
as List<PromoBadge>,
  ));
}


}


/// @nodoc
mixin _$OptionChoice {

 String get id; String get name; int get priceDeltaKobo; bool get isAvailable;
/// Create a copy of OptionChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptionChoiceCopyWith<OptionChoice> get copyWith => _$OptionChoiceCopyWithImpl<OptionChoice>(this as OptionChoice, _$identity);

  /// Serializes this OptionChoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OptionChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptionChoice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.priceDeltaKobo, _this.priceDeltaKobo) || other.priceDeltaKobo == _this.priceDeltaKobo)&&(identical(other.isAvailable, _this.isAvailable) || other.isAvailable == _this.isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OptionChoice;
  return Object.hash(runtimeType,_this.id,_this.name,_this.priceDeltaKobo,_this.isAvailable);
}

@override
String toString() {
  final _this = this as OptionChoice;
  return 'OptionChoice(id: ${_this.id}, name: ${_this.name}, priceDeltaKobo: ${_this.priceDeltaKobo}, isAvailable: ${_this.isAvailable})';
}


}

/// @nodoc
abstract mixin class $OptionChoiceCopyWith<$Res>  {
  factory $OptionChoiceCopyWith(OptionChoice value, $Res Function(OptionChoice) _then) = _$OptionChoiceCopyWithImpl;
@useResult
$Res call({
 String id, String name, int priceDeltaKobo, bool isAvailable
});




}
/// @nodoc
class _$OptionChoiceCopyWithImpl<$Res>
    implements $OptionChoiceCopyWith<$Res> {
  _$OptionChoiceCopyWithImpl(this._self, this._then);

  final OptionChoice _self;
  final $Res Function(OptionChoice) _then;

/// Create a copy of OptionChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? priceDeltaKobo = null,Object? isAvailable = null,}) {
  return _then(OptionChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceDeltaKobo: null == priceDeltaKobo ? _self.priceDeltaKobo : priceDeltaKobo // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OptionChoice].
extension OptionChoicePatterns on OptionChoice {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptionChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptionChoice() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptionChoice value)  $default,){
final _that = this;
switch (_that) {
case _OptionChoice():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptionChoice value)?  $default,){
final _that = this;
switch (_that) {
case _OptionChoice() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int priceDeltaKobo,  bool isAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptionChoice() when $default != null:
return $default(_that.id,_that.name,_that.priceDeltaKobo,_that.isAvailable);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int priceDeltaKobo,  bool isAvailable)  $default,) {final _that = this;
switch (_that) {
case _OptionChoice():
return $default(_that.id,_that.name,_that.priceDeltaKobo,_that.isAvailable);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int priceDeltaKobo,  bool isAvailable)?  $default,) {final _that = this;
switch (_that) {
case _OptionChoice() when $default != null:
return $default(_that.id,_that.name,_that.priceDeltaKobo,_that.isAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OptionChoice implements OptionChoice {
  const _OptionChoice({required this.id, required this.name, this.priceDeltaKobo = 0, this.isAvailable = true});
  factory _OptionChoice.fromJson(Map<String, dynamic> json) => _$OptionChoiceFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int priceDeltaKobo;
@override@JsonKey() final  bool isAvailable;

/// Create a copy of OptionChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptionChoiceCopyWith<_OptionChoice> get copyWith => __$OptionChoiceCopyWithImpl<_OptionChoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OptionChoiceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptionChoice&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.priceDeltaKobo, priceDeltaKobo) || other.priceDeltaKobo == priceDeltaKobo)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,priceDeltaKobo,isAvailable);
}

@override
String toString() {
    return 'OptionChoice(id: $id, name: $name, priceDeltaKobo: $priceDeltaKobo, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class _$OptionChoiceCopyWith<$Res> implements $OptionChoiceCopyWith<$Res> {
  factory _$OptionChoiceCopyWith(_OptionChoice value, $Res Function(_OptionChoice) _then) = __$OptionChoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int priceDeltaKobo, bool isAvailable
});




}
/// @nodoc
class __$OptionChoiceCopyWithImpl<$Res>
    implements _$OptionChoiceCopyWith<$Res> {
  __$OptionChoiceCopyWithImpl(this._self, this._then);

  final _OptionChoice _self;
  final $Res Function(_OptionChoice) _then;

/// Create a copy of OptionChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? priceDeltaKobo = null,Object? isAvailable = null,}) {
  return _then(_OptionChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceDeltaKobo: null == priceDeltaKobo ? _self.priceDeltaKobo : priceDeltaKobo // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OptionGroup {

 String get id; String get name; int get minSelect; int get maxSelect; List<OptionChoice> get choices;
/// Create a copy of OptionGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptionGroupCopyWith<OptionGroup> get copyWith => _$OptionGroupCopyWithImpl<OptionGroup>(this as OptionGroup, _$identity);

  /// Serializes this OptionGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OptionGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptionGroup&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.minSelect, _this.minSelect) || other.minSelect == _this.minSelect)&&(identical(other.maxSelect, _this.maxSelect) || other.maxSelect == _this.maxSelect)&&const DeepCollectionEquality().equals(other.choices, _this.choices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OptionGroup;
  return Object.hash(runtimeType,_this.id,_this.name,_this.minSelect,_this.maxSelect,const DeepCollectionEquality().hash(_this.choices));
}

@override
String toString() {
  final _this = this as OptionGroup;
  return 'OptionGroup(id: ${_this.id}, name: ${_this.name}, minSelect: ${_this.minSelect}, maxSelect: ${_this.maxSelect}, choices: ${_this.choices})';
}


}

/// @nodoc
abstract mixin class $OptionGroupCopyWith<$Res>  {
  factory $OptionGroupCopyWith(OptionGroup value, $Res Function(OptionGroup) _then) = _$OptionGroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, int minSelect, int maxSelect, List<OptionChoice> choices
});




}
/// @nodoc
class _$OptionGroupCopyWithImpl<$Res>
    implements $OptionGroupCopyWith<$Res> {
  _$OptionGroupCopyWithImpl(this._self, this._then);

  final OptionGroup _self;
  final $Res Function(OptionGroup) _then;

/// Create a copy of OptionGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? minSelect = null,Object? maxSelect = null,Object? choices = null,}) {
  return _then(OptionGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,minSelect: null == minSelect ? _self.minSelect : minSelect // ignore: cast_nullable_to_non_nullable
as int,maxSelect: null == maxSelect ? _self.maxSelect : maxSelect // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<OptionChoice>,
  ));
}

}


/// Adds pattern-matching-related methods to [OptionGroup].
extension OptionGroupPatterns on OptionGroup {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptionGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptionGroup() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptionGroup value)  $default,){
final _that = this;
switch (_that) {
case _OptionGroup():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptionGroup value)?  $default,){
final _that = this;
switch (_that) {
case _OptionGroup() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int minSelect,  int maxSelect,  List<OptionChoice> choices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptionGroup() when $default != null:
return $default(_that.id,_that.name,_that.minSelect,_that.maxSelect,_that.choices);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int minSelect,  int maxSelect,  List<OptionChoice> choices)  $default,) {final _that = this;
switch (_that) {
case _OptionGroup():
return $default(_that.id,_that.name,_that.minSelect,_that.maxSelect,_that.choices);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int minSelect,  int maxSelect,  List<OptionChoice> choices)?  $default,) {final _that = this;
switch (_that) {
case _OptionGroup() when $default != null:
return $default(_that.id,_that.name,_that.minSelect,_that.maxSelect,_that.choices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OptionGroup implements OptionGroup {
  const _OptionGroup({required this.id, required this.name, this.minSelect = 0, this.maxSelect = 1,  List<OptionChoice> choices = const <OptionChoice>[]}): _choices = choices;
  factory _OptionGroup.fromJson(Map<String, dynamic> json) => _$OptionGroupFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int minSelect;
@override@JsonKey() final  int maxSelect;
 final  List<OptionChoice> _choices;
@override@JsonKey() List<OptionChoice> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}


/// Create a copy of OptionGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptionGroupCopyWith<_OptionGroup> get copyWith => __$OptionGroupCopyWithImpl<_OptionGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OptionGroupToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptionGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.minSelect, minSelect) || other.minSelect == minSelect)&&(identical(other.maxSelect, maxSelect) || other.maxSelect == maxSelect)&&const DeepCollectionEquality().equals(other.choices, _choices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,minSelect,maxSelect,const DeepCollectionEquality().hash(_choices));
}

@override
String toString() {
    return 'OptionGroup(id: $id, name: $name, minSelect: $minSelect, maxSelect: $maxSelect, choices: $choices)';
}


}

/// @nodoc
abstract mixin class _$OptionGroupCopyWith<$Res> implements $OptionGroupCopyWith<$Res> {
  factory _$OptionGroupCopyWith(_OptionGroup value, $Res Function(_OptionGroup) _then) = __$OptionGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int minSelect, int maxSelect, List<OptionChoice> choices
});




}
/// @nodoc
class __$OptionGroupCopyWithImpl<$Res>
    implements _$OptionGroupCopyWith<$Res> {
  __$OptionGroupCopyWithImpl(this._self, this._then);

  final _OptionGroup _self;
  final $Res Function(_OptionGroup) _then;

/// Create a copy of OptionGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? minSelect = null,Object? maxSelect = null,Object? choices = null,}) {
  return _then(_OptionGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,minSelect: null == minSelect ? _self.minSelect : minSelect // ignore: cast_nullable_to_non_nullable
as int,maxSelect: null == maxSelect ? _self.maxSelect : maxSelect // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<OptionChoice>,
  ));
}


}


/// @nodoc
mixin _$MenuItem {

 String get id; String get restaurantId; String get name; String get description; int get priceKobo; String get kind; List<String> get allergens; List<String> get dietary; int get serves; int get spiceLevel; bool get isAvailable; List<String> get optionGroupIds; String? get unitLabel;
/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuItemCopyWith<MenuItem> get copyWith => _$MenuItemCopyWithImpl<MenuItem>(this as MenuItem, _$identity);

  /// Serializes this MenuItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MenuItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.restaurantId, _this.restaurantId) || other.restaurantId == _this.restaurantId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.priceKobo, _this.priceKobo) || other.priceKobo == _this.priceKobo)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.allergens, _this.allergens)&&const DeepCollectionEquality().equals(other.dietary, _this.dietary)&&(identical(other.serves, _this.serves) || other.serves == _this.serves)&&(identical(other.spiceLevel, _this.spiceLevel) || other.spiceLevel == _this.spiceLevel)&&(identical(other.isAvailable, _this.isAvailable) || other.isAvailable == _this.isAvailable)&&const DeepCollectionEquality().equals(other.optionGroupIds, _this.optionGroupIds)&&(identical(other.unitLabel, _this.unitLabel) || other.unitLabel == _this.unitLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MenuItem;
  return Object.hash(runtimeType,_this.id,_this.restaurantId,_this.name,_this.description,_this.priceKobo,_this.kind,const DeepCollectionEquality().hash(_this.allergens),const DeepCollectionEquality().hash(_this.dietary),_this.serves,_this.spiceLevel,_this.isAvailable,const DeepCollectionEquality().hash(_this.optionGroupIds),_this.unitLabel);
}

@override
String toString() {
  final _this = this as MenuItem;
  return 'MenuItem(id: ${_this.id}, restaurantId: ${_this.restaurantId}, name: ${_this.name}, description: ${_this.description}, priceKobo: ${_this.priceKobo}, kind: ${_this.kind}, allergens: ${_this.allergens}, dietary: ${_this.dietary}, serves: ${_this.serves}, spiceLevel: ${_this.spiceLevel}, isAvailable: ${_this.isAvailable}, optionGroupIds: ${_this.optionGroupIds}, unitLabel: ${_this.unitLabel})';
}


}

/// @nodoc
abstract mixin class $MenuItemCopyWith<$Res>  {
  factory $MenuItemCopyWith(MenuItem value, $Res Function(MenuItem) _then) = _$MenuItemCopyWithImpl;
@useResult
$Res call({
 String id, String restaurantId, String name, String description, int priceKobo, String kind, List<String> allergens, List<String> dietary, int serves, int spiceLevel, bool isAvailable, List<String> optionGroupIds, String? unitLabel
});




}
/// @nodoc
class _$MenuItemCopyWithImpl<$Res>
    implements $MenuItemCopyWith<$Res> {
  _$MenuItemCopyWithImpl(this._self, this._then);

  final MenuItem _self;
  final $Res Function(MenuItem) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? restaurantId = null,Object? name = null,Object? description = null,Object? priceKobo = null,Object? kind = null,Object? allergens = null,Object? dietary = null,Object? serves = null,Object? spiceLevel = null,Object? isAvailable = null,Object? optionGroupIds = null,Object? unitLabel = freezed,}) {
  return _then(MenuItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priceKobo: null == priceKobo ? _self.priceKobo : priceKobo // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,dietary: null == dietary ? _self.dietary : dietary // ignore: cast_nullable_to_non_nullable
as List<String>,serves: null == serves ? _self.serves : serves // ignore: cast_nullable_to_non_nullable
as int,spiceLevel: null == spiceLevel ? _self.spiceLevel : spiceLevel // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,optionGroupIds: null == optionGroupIds ? _self.optionGroupIds : optionGroupIds // ignore: cast_nullable_to_non_nullable
as List<String>,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuItem].
extension MenuItemPatterns on MenuItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuItem value)  $default,){
final _that = this;
switch (_that) {
case _MenuItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuItem value)?  $default,){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String restaurantId,  String name,  String description,  int priceKobo,  String kind,  List<String> allergens,  List<String> dietary,  int serves,  int spiceLevel,  bool isAvailable,  List<String> optionGroupIds,  String? unitLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.id,_that.restaurantId,_that.name,_that.description,_that.priceKobo,_that.kind,_that.allergens,_that.dietary,_that.serves,_that.spiceLevel,_that.isAvailable,_that.optionGroupIds,_that.unitLabel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String restaurantId,  String name,  String description,  int priceKobo,  String kind,  List<String> allergens,  List<String> dietary,  int serves,  int spiceLevel,  bool isAvailable,  List<String> optionGroupIds,  String? unitLabel)  $default,) {final _that = this;
switch (_that) {
case _MenuItem():
return $default(_that.id,_that.restaurantId,_that.name,_that.description,_that.priceKobo,_that.kind,_that.allergens,_that.dietary,_that.serves,_that.spiceLevel,_that.isAvailable,_that.optionGroupIds,_that.unitLabel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String restaurantId,  String name,  String description,  int priceKobo,  String kind,  List<String> allergens,  List<String> dietary,  int serves,  int spiceLevel,  bool isAvailable,  List<String> optionGroupIds,  String? unitLabel)?  $default,) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.id,_that.restaurantId,_that.name,_that.description,_that.priceKobo,_that.kind,_that.allergens,_that.dietary,_that.serves,_that.spiceLevel,_that.isAvailable,_that.optionGroupIds,_that.unitLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuItem implements MenuItem {
  const _MenuItem({required this.id, required this.restaurantId, required this.name, this.description = '', required this.priceKobo, this.kind = 'main',  List<String> allergens = const <String>[],  List<String> dietary = const <String>[], this.serves = 1, this.spiceLevel = 0, this.isAvailable = true,  List<String> optionGroupIds = const <String>[], this.unitLabel}): _allergens = allergens,_dietary = dietary,_optionGroupIds = optionGroupIds;
  factory _MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);

@override final  String id;
@override final  String restaurantId;
@override final  String name;
@override@JsonKey() final  String description;
@override final  int priceKobo;
@override@JsonKey() final  String kind;
 final  List<String> _allergens;
@override@JsonKey() List<String> get allergens {
  if (_allergens is EqualUnmodifiableListView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allergens);
}

 final  List<String> _dietary;
@override@JsonKey() List<String> get dietary {
  if (_dietary is EqualUnmodifiableListView) return _dietary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietary);
}

@override@JsonKey() final  int serves;
@override@JsonKey() final  int spiceLevel;
@override@JsonKey() final  bool isAvailable;
 final  List<String> _optionGroupIds;
@override@JsonKey() List<String> get optionGroupIds {
  if (_optionGroupIds is EqualUnmodifiableListView) return _optionGroupIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_optionGroupIds);
}

@override final  String? unitLabel;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuItemCopyWith<_MenuItem> get copyWith => __$MenuItemCopyWithImpl<_MenuItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuItem&&(identical(other.id, id) || other.id == id)&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.priceKobo, priceKobo) || other.priceKobo == priceKobo)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.allergens, _allergens)&&const DeepCollectionEquality().equals(other.dietary, _dietary)&&(identical(other.serves, serves) || other.serves == serves)&&(identical(other.spiceLevel, spiceLevel) || other.spiceLevel == spiceLevel)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&const DeepCollectionEquality().equals(other.optionGroupIds, _optionGroupIds)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,restaurantId,name,description,priceKobo,kind,const DeepCollectionEquality().hash(_allergens),const DeepCollectionEquality().hash(_dietary),serves,spiceLevel,isAvailable,const DeepCollectionEquality().hash(_optionGroupIds),unitLabel);
}

@override
String toString() {
    return 'MenuItem(id: $id, restaurantId: $restaurantId, name: $name, description: $description, priceKobo: $priceKobo, kind: $kind, allergens: $allergens, dietary: $dietary, serves: $serves, spiceLevel: $spiceLevel, isAvailable: $isAvailable, optionGroupIds: $optionGroupIds, unitLabel: $unitLabel)';
}


}

/// @nodoc
abstract mixin class _$MenuItemCopyWith<$Res> implements $MenuItemCopyWith<$Res> {
  factory _$MenuItemCopyWith(_MenuItem value, $Res Function(_MenuItem) _then) = __$MenuItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String restaurantId, String name, String description, int priceKobo, String kind, List<String> allergens, List<String> dietary, int serves, int spiceLevel, bool isAvailable, List<String> optionGroupIds, String? unitLabel
});




}
/// @nodoc
class __$MenuItemCopyWithImpl<$Res>
    implements _$MenuItemCopyWith<$Res> {
  __$MenuItemCopyWithImpl(this._self, this._then);

  final _MenuItem _self;
  final $Res Function(_MenuItem) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? restaurantId = null,Object? name = null,Object? description = null,Object? priceKobo = null,Object? kind = null,Object? allergens = null,Object? dietary = null,Object? serves = null,Object? spiceLevel = null,Object? isAvailable = null,Object? optionGroupIds = null,Object? unitLabel = freezed,}) {
  return _then(_MenuItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priceKobo: null == priceKobo ? _self.priceKobo : priceKobo // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,dietary: null == dietary ? _self._dietary : dietary // ignore: cast_nullable_to_non_nullable
as List<String>,serves: null == serves ? _self.serves : serves // ignore: cast_nullable_to_non_nullable
as int,spiceLevel: null == spiceLevel ? _self.spiceLevel : spiceLevel // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,optionGroupIds: null == optionGroupIds ? _self._optionGroupIds : optionGroupIds // ignore: cast_nullable_to_non_nullable
as List<String>,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MenuCategory {

 String get id; String get name;
/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuCategoryCopyWith<MenuCategory> get copyWith => _$MenuCategoryCopyWithImpl<MenuCategory>(this as MenuCategory, _$identity);

  /// Serializes this MenuCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MenuCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuCategory&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MenuCategory;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as MenuCategory;
  return 'MenuCategory(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $MenuCategoryCopyWith<$Res>  {
  factory $MenuCategoryCopyWith(MenuCategory value, $Res Function(MenuCategory) _then) = _$MenuCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$MenuCategoryCopyWithImpl<$Res>
    implements $MenuCategoryCopyWith<$Res> {
  _$MenuCategoryCopyWithImpl(this._self, this._then);

  final MenuCategory _self;
  final $Res Function(MenuCategory) _then;

/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(MenuCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuCategory].
extension MenuCategoryPatterns on MenuCategory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuCategory value)  $default,){
final _that = this;
switch (_that) {
case _MenuCategory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuCategory value)?  $default,){
final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that.id,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _MenuCategory():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuCategory implements MenuCategory {
  const _MenuCategory({required this.id, required this.name});
  factory _MenuCategory.fromJson(Map<String, dynamic> json) => _$MenuCategoryFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuCategoryCopyWith<_MenuCategory> get copyWith => __$MenuCategoryCopyWithImpl<_MenuCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'MenuCategory(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$MenuCategoryCopyWith<$Res> implements $MenuCategoryCopyWith<$Res> {
  factory _$MenuCategoryCopyWith(_MenuCategory value, $Res Function(_MenuCategory) _then) = __$MenuCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$MenuCategoryCopyWithImpl<$Res>
    implements _$MenuCategoryCopyWith<$Res> {
  __$MenuCategoryCopyWithImpl(this._self, this._then);

  final _MenuCategory _self;
  final $Res Function(_MenuCategory) _then;

/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_MenuCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MenuSection {

 MenuCategory get category; List<MenuItem> get items;
/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuSectionCopyWith<MenuSection> get copyWith => _$MenuSectionCopyWithImpl<MenuSection>(this as MenuSection, _$identity);

  /// Serializes this MenuSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MenuSection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuSection&&(identical(other.category, _this.category) || other.category == _this.category)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MenuSection;
  return Object.hash(runtimeType,_this.category,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as MenuSection;
  return 'MenuSection(category: ${_this.category}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $MenuSectionCopyWith<$Res>  {
  factory $MenuSectionCopyWith(MenuSection value, $Res Function(MenuSection) _then) = _$MenuSectionCopyWithImpl;
@useResult
$Res call({
 MenuCategory category, List<MenuItem> items
});


$MenuCategoryCopyWith<$Res> get category;

}
/// @nodoc
class _$MenuSectionCopyWithImpl<$Res>
    implements $MenuSectionCopyWith<$Res> {
  _$MenuSectionCopyWithImpl(this._self, this._then);

  final MenuSection _self;
  final $Res Function(MenuSection) _then;

/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? items = null,}) {
  return _then(MenuSection(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MenuCategory,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MenuItem>,
  ));
}
/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuCategoryCopyWith<$Res> get category {
  
  return $MenuCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [MenuSection].
extension MenuSectionPatterns on MenuSection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuSection value)  $default,){
final _that = this;
switch (_that) {
case _MenuSection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuSection value)?  $default,){
final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MenuCategory category,  List<MenuItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that.category,_that.items);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MenuCategory category,  List<MenuItem> items)  $default,) {final _that = this;
switch (_that) {
case _MenuSection():
return $default(_that.category,_that.items);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MenuCategory category,  List<MenuItem> items)?  $default,) {final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that.category,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuSection implements MenuSection {
  const _MenuSection({required this.category,  List<MenuItem> items = const <MenuItem>[]}): _items = items;
  factory _MenuSection.fromJson(Map<String, dynamic> json) => _$MenuSectionFromJson(json);

@override final  MenuCategory category;
 final  List<MenuItem> _items;
@override@JsonKey() List<MenuItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuSectionCopyWith<_MenuSection> get copyWith => __$MenuSectionCopyWithImpl<_MenuSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuSectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuSection&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,category,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'MenuSection(category: $category, items: $items)';
}


}

/// @nodoc
abstract mixin class _$MenuSectionCopyWith<$Res> implements $MenuSectionCopyWith<$Res> {
  factory _$MenuSectionCopyWith(_MenuSection value, $Res Function(_MenuSection) _then) = __$MenuSectionCopyWithImpl;
@override @useResult
$Res call({
 MenuCategory category, List<MenuItem> items
});


@override $MenuCategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$MenuSectionCopyWithImpl<$Res>
    implements _$MenuSectionCopyWith<$Res> {
  __$MenuSectionCopyWithImpl(this._self, this._then);

  final _MenuSection _self;
  final $Res Function(_MenuSection) _then;

/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? items = null,}) {
  return _then(_MenuSection(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MenuCategory,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MenuItem>,
  ));
}

/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuCategoryCopyWith<$Res> get category {
  
  return $MenuCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// @nodoc
mixin _$RestaurantDetail {

 RestaurantCard get restaurant; String get address; int get avgPrepMinutes; List<MenuSection> get sections; Map<String, OptionGroup> get optionGroups;
/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantDetailCopyWith<RestaurantDetail> get copyWith => _$RestaurantDetailCopyWithImpl<RestaurantDetail>(this as RestaurantDetail, _$identity);

  /// Serializes this RestaurantDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RestaurantDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantDetail&&(identical(other.restaurant, _this.restaurant) || other.restaurant == _this.restaurant)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.avgPrepMinutes, _this.avgPrepMinutes) || other.avgPrepMinutes == _this.avgPrepMinutes)&&const DeepCollectionEquality().equals(other.sections, _this.sections)&&const DeepCollectionEquality().equals(other.optionGroups, _this.optionGroups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RestaurantDetail;
  return Object.hash(runtimeType,_this.restaurant,_this.address,_this.avgPrepMinutes,const DeepCollectionEquality().hash(_this.sections),const DeepCollectionEquality().hash(_this.optionGroups));
}

@override
String toString() {
  final _this = this as RestaurantDetail;
  return 'RestaurantDetail(restaurant: ${_this.restaurant}, address: ${_this.address}, avgPrepMinutes: ${_this.avgPrepMinutes}, sections: ${_this.sections}, optionGroups: ${_this.optionGroups})';
}


}

/// @nodoc
abstract mixin class $RestaurantDetailCopyWith<$Res>  {
  factory $RestaurantDetailCopyWith(RestaurantDetail value, $Res Function(RestaurantDetail) _then) = _$RestaurantDetailCopyWithImpl;
@useResult
$Res call({
 RestaurantCard restaurant, String address, int avgPrepMinutes, List<MenuSection> sections, Map<String, OptionGroup> optionGroups
});


$RestaurantCardCopyWith<$Res> get restaurant;

}
/// @nodoc
class _$RestaurantDetailCopyWithImpl<$Res>
    implements $RestaurantDetailCopyWith<$Res> {
  _$RestaurantDetailCopyWithImpl(this._self, this._then);

  final RestaurantDetail _self;
  final $Res Function(RestaurantDetail) _then;

/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? restaurant = null,Object? address = null,Object? avgPrepMinutes = null,Object? sections = null,Object? optionGroups = null,}) {
  return _then(RestaurantDetail(
restaurant: null == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as RestaurantCard,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,avgPrepMinutes: null == avgPrepMinutes ? _self.avgPrepMinutes : avgPrepMinutes // ignore: cast_nullable_to_non_nullable
as int,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<MenuSection>,optionGroups: null == optionGroups ? _self.optionGroups : optionGroups // ignore: cast_nullable_to_non_nullable
as Map<String, OptionGroup>,
  ));
}
/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RestaurantCardCopyWith<$Res> get restaurant {
  
  return $RestaurantCardCopyWith<$Res>(_self.restaurant, (value) {
    return _then(_self.copyWith(restaurant: value));
  });
}
}


/// Adds pattern-matching-related methods to [RestaurantDetail].
extension RestaurantDetailPatterns on RestaurantDetail {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantDetail() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantDetail value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantDetail():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantDetail value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantDetail() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RestaurantCard restaurant,  String address,  int avgPrepMinutes,  List<MenuSection> sections,  Map<String, OptionGroup> optionGroups)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantDetail() when $default != null:
return $default(_that.restaurant,_that.address,_that.avgPrepMinutes,_that.sections,_that.optionGroups);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RestaurantCard restaurant,  String address,  int avgPrepMinutes,  List<MenuSection> sections,  Map<String, OptionGroup> optionGroups)  $default,) {final _that = this;
switch (_that) {
case _RestaurantDetail():
return $default(_that.restaurant,_that.address,_that.avgPrepMinutes,_that.sections,_that.optionGroups);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RestaurantCard restaurant,  String address,  int avgPrepMinutes,  List<MenuSection> sections,  Map<String, OptionGroup> optionGroups)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantDetail() when $default != null:
return $default(_that.restaurant,_that.address,_that.avgPrepMinutes,_that.sections,_that.optionGroups);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestaurantDetail implements RestaurantDetail {
  const _RestaurantDetail({required this.restaurant, this.address = '', this.avgPrepMinutes = 20,  List<MenuSection> sections = const <MenuSection>[],  Map<String, OptionGroup> optionGroups = const <String, OptionGroup>{}}): _sections = sections,_optionGroups = optionGroups;
  factory _RestaurantDetail.fromJson(Map<String, dynamic> json) => _$RestaurantDetailFromJson(json);

@override final  RestaurantCard restaurant;
@override@JsonKey() final  String address;
@override@JsonKey() final  int avgPrepMinutes;
 final  List<MenuSection> _sections;
@override@JsonKey() List<MenuSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

 final  Map<String, OptionGroup> _optionGroups;
@override@JsonKey() Map<String, OptionGroup> get optionGroups {
  if (_optionGroups is EqualUnmodifiableMapView) return _optionGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_optionGroups);
}


/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantDetailCopyWith<_RestaurantDetail> get copyWith => __$RestaurantDetailCopyWithImpl<_RestaurantDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantDetail&&(identical(other.restaurant, restaurant) || other.restaurant == restaurant)&&(identical(other.address, address) || other.address == address)&&(identical(other.avgPrepMinutes, avgPrepMinutes) || other.avgPrepMinutes == avgPrepMinutes)&&const DeepCollectionEquality().equals(other.sections, _sections)&&const DeepCollectionEquality().equals(other.optionGroups, _optionGroups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,restaurant,address,avgPrepMinutes,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_optionGroups));
}

@override
String toString() {
    return 'RestaurantDetail(restaurant: $restaurant, address: $address, avgPrepMinutes: $avgPrepMinutes, sections: $sections, optionGroups: $optionGroups)';
}


}

/// @nodoc
abstract mixin class _$RestaurantDetailCopyWith<$Res> implements $RestaurantDetailCopyWith<$Res> {
  factory _$RestaurantDetailCopyWith(_RestaurantDetail value, $Res Function(_RestaurantDetail) _then) = __$RestaurantDetailCopyWithImpl;
@override @useResult
$Res call({
 RestaurantCard restaurant, String address, int avgPrepMinutes, List<MenuSection> sections, Map<String, OptionGroup> optionGroups
});


@override $RestaurantCardCopyWith<$Res> get restaurant;

}
/// @nodoc
class __$RestaurantDetailCopyWithImpl<$Res>
    implements _$RestaurantDetailCopyWith<$Res> {
  __$RestaurantDetailCopyWithImpl(this._self, this._then);

  final _RestaurantDetail _self;
  final $Res Function(_RestaurantDetail) _then;

/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? restaurant = null,Object? address = null,Object? avgPrepMinutes = null,Object? sections = null,Object? optionGroups = null,}) {
  return _then(_RestaurantDetail(
restaurant: null == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as RestaurantCard,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,avgPrepMinutes: null == avgPrepMinutes ? _self.avgPrepMinutes : avgPrepMinutes // ignore: cast_nullable_to_non_nullable
as int,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<MenuSection>,optionGroups: null == optionGroups ? _self._optionGroups : optionGroups // ignore: cast_nullable_to_non_nullable
as Map<String, OptionGroup>,
  ));
}

/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RestaurantCardCopyWith<$Res> get restaurant {
  
  return $RestaurantCardCopyWith<$Res>(_self.restaurant, (value) {
    return _then(_self.copyWith(restaurant: value));
  });
}
}


/// @nodoc
mixin _$OptionSelection {

 String get groupId; List<String> get choiceIds;
/// Create a copy of OptionSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptionSelectionCopyWith<OptionSelection> get copyWith => _$OptionSelectionCopyWithImpl<OptionSelection>(this as OptionSelection, _$identity);

  /// Serializes this OptionSelection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OptionSelection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptionSelection&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&const DeepCollectionEquality().equals(other.choiceIds, _this.choiceIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OptionSelection;
  return Object.hash(runtimeType,_this.groupId,const DeepCollectionEquality().hash(_this.choiceIds));
}

@override
String toString() {
  final _this = this as OptionSelection;
  return 'OptionSelection(groupId: ${_this.groupId}, choiceIds: ${_this.choiceIds})';
}


}

/// @nodoc
abstract mixin class $OptionSelectionCopyWith<$Res>  {
  factory $OptionSelectionCopyWith(OptionSelection value, $Res Function(OptionSelection) _then) = _$OptionSelectionCopyWithImpl;
@useResult
$Res call({
 String groupId, List<String> choiceIds
});




}
/// @nodoc
class _$OptionSelectionCopyWithImpl<$Res>
    implements $OptionSelectionCopyWith<$Res> {
  _$OptionSelectionCopyWithImpl(this._self, this._then);

  final OptionSelection _self;
  final $Res Function(OptionSelection) _then;

/// Create a copy of OptionSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? choiceIds = null,}) {
  return _then(OptionSelection(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,choiceIds: null == choiceIds ? _self.choiceIds : choiceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [OptionSelection].
extension OptionSelectionPatterns on OptionSelection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptionSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptionSelection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptionSelection value)  $default,){
final _that = this;
switch (_that) {
case _OptionSelection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptionSelection value)?  $default,){
final _that = this;
switch (_that) {
case _OptionSelection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  List<String> choiceIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptionSelection() when $default != null:
return $default(_that.groupId,_that.choiceIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  List<String> choiceIds)  $default,) {final _that = this;
switch (_that) {
case _OptionSelection():
return $default(_that.groupId,_that.choiceIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  List<String> choiceIds)?  $default,) {final _that = this;
switch (_that) {
case _OptionSelection() when $default != null:
return $default(_that.groupId,_that.choiceIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OptionSelection implements OptionSelection {
  const _OptionSelection({required this.groupId,  List<String> choiceIds = const <String>[]}): _choiceIds = choiceIds;
  factory _OptionSelection.fromJson(Map<String, dynamic> json) => _$OptionSelectionFromJson(json);

@override final  String groupId;
 final  List<String> _choiceIds;
@override@JsonKey() List<String> get choiceIds {
  if (_choiceIds is EqualUnmodifiableListView) return _choiceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choiceIds);
}


/// Create a copy of OptionSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptionSelectionCopyWith<_OptionSelection> get copyWith => __$OptionSelectionCopyWithImpl<_OptionSelection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OptionSelectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptionSelection&&(identical(other.groupId, groupId) || other.groupId == groupId)&&const DeepCollectionEquality().equals(other.choiceIds, _choiceIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,groupId,const DeepCollectionEquality().hash(_choiceIds));
}

@override
String toString() {
    return 'OptionSelection(groupId: $groupId, choiceIds: $choiceIds)';
}


}

/// @nodoc
abstract mixin class _$OptionSelectionCopyWith<$Res> implements $OptionSelectionCopyWith<$Res> {
  factory _$OptionSelectionCopyWith(_OptionSelection value, $Res Function(_OptionSelection) _then) = __$OptionSelectionCopyWithImpl;
@override @useResult
$Res call({
 String groupId, List<String> choiceIds
});




}
/// @nodoc
class __$OptionSelectionCopyWithImpl<$Res>
    implements _$OptionSelectionCopyWith<$Res> {
  __$OptionSelectionCopyWithImpl(this._self, this._then);

  final _OptionSelection _self;
  final $Res Function(_OptionSelection) _then;

/// Create a copy of OptionSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? choiceIds = null,}) {
  return _then(_OptionSelection(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,choiceIds: null == choiceIds ? _self._choiceIds : choiceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$CartLine {

 String get itemId; int get quantity; List<OptionSelection> get selections; String? get notes;
/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartLineCopyWith<CartLine> get copyWith => _$CartLineCopyWithImpl<CartLine>(this as CartLine, _$identity);

  /// Serializes this CartLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CartLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartLine&&(identical(other.itemId, _this.itemId) || other.itemId == _this.itemId)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&const DeepCollectionEquality().equals(other.selections, _this.selections)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CartLine;
  return Object.hash(runtimeType,_this.itemId,_this.quantity,const DeepCollectionEquality().hash(_this.selections),_this.notes);
}

@override
String toString() {
  final _this = this as CartLine;
  return 'CartLine(itemId: ${_this.itemId}, quantity: ${_this.quantity}, selections: ${_this.selections}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $CartLineCopyWith<$Res>  {
  factory $CartLineCopyWith(CartLine value, $Res Function(CartLine) _then) = _$CartLineCopyWithImpl;
@useResult
$Res call({
 String itemId, int quantity, List<OptionSelection> selections, String? notes
});




}
/// @nodoc
class _$CartLineCopyWithImpl<$Res>
    implements $CartLineCopyWith<$Res> {
  _$CartLineCopyWithImpl(this._self, this._then);

  final CartLine _self;
  final $Res Function(CartLine) _then;

/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? quantity = null,Object? selections = null,Object? notes = freezed,}) {
  return _then(CartLine(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selections: null == selections ? _self.selections : selections // ignore: cast_nullable_to_non_nullable
as List<OptionSelection>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CartLine].
extension CartLinePatterns on CartLine {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartLine value)  $default,){
final _that = this;
switch (_that) {
case _CartLine():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartLine value)?  $default,){
final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  int quantity,  List<OptionSelection> selections,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that.itemId,_that.quantity,_that.selections,_that.notes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  int quantity,  List<OptionSelection> selections,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _CartLine():
return $default(_that.itemId,_that.quantity,_that.selections,_that.notes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  int quantity,  List<OptionSelection> selections,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that.itemId,_that.quantity,_that.selections,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartLine implements CartLine {
  const _CartLine({required this.itemId, required this.quantity,  List<OptionSelection> selections = const <OptionSelection>[], this.notes}): _selections = selections;
  factory _CartLine.fromJson(Map<String, dynamic> json) => _$CartLineFromJson(json);

@override final  String itemId;
@override final  int quantity;
 final  List<OptionSelection> _selections;
@override@JsonKey() List<OptionSelection> get selections {
  if (_selections is EqualUnmodifiableListView) return _selections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selections);
}

@override final  String? notes;

/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartLineCopyWith<_CartLine> get copyWith => __$CartLineCopyWithImpl<_CartLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartLine&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other.selections, _selections)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,itemId,quantity,const DeepCollectionEquality().hash(_selections),notes);
}

@override
String toString() {
    return 'CartLine(itemId: $itemId, quantity: $quantity, selections: $selections, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$CartLineCopyWith<$Res> implements $CartLineCopyWith<$Res> {
  factory _$CartLineCopyWith(_CartLine value, $Res Function(_CartLine) _then) = __$CartLineCopyWithImpl;
@override @useResult
$Res call({
 String itemId, int quantity, List<OptionSelection> selections, String? notes
});




}
/// @nodoc
class __$CartLineCopyWithImpl<$Res>
    implements _$CartLineCopyWith<$Res> {
  __$CartLineCopyWithImpl(this._self, this._then);

  final _CartLine _self;
  final $Res Function(_CartLine) _then;

/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? quantity = null,Object? selections = null,Object? notes = freezed,}) {
  return _then(_CartLine(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selections: null == selections ? _self._selections : selections // ignore: cast_nullable_to_non_nullable
as List<OptionSelection>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DeliveryAddress {

 String? get label; String get line1; String? get area; String get city; String get state; GeoPoint get location; String? get instructions; String? get contactPhone;
/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<DeliveryAddress> get copyWith => _$DeliveryAddressCopyWithImpl<DeliveryAddress>(this as DeliveryAddress, _$identity);

  /// Serializes this DeliveryAddress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeliveryAddress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryAddress&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.line1, _this.line1) || other.line1 == _this.line1)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.instructions, _this.instructions) || other.instructions == _this.instructions)&&(identical(other.contactPhone, _this.contactPhone) || other.contactPhone == _this.contactPhone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeliveryAddress;
  return Object.hash(runtimeType,_this.label,_this.line1,_this.area,_this.city,_this.state,_this.location,_this.instructions,_this.contactPhone);
}

@override
String toString() {
  final _this = this as DeliveryAddress;
  return 'DeliveryAddress(label: ${_this.label}, line1: ${_this.line1}, area: ${_this.area}, city: ${_this.city}, state: ${_this.state}, location: ${_this.location}, instructions: ${_this.instructions}, contactPhone: ${_this.contactPhone})';
}


}

/// @nodoc
abstract mixin class $DeliveryAddressCopyWith<$Res>  {
  factory $DeliveryAddressCopyWith(DeliveryAddress value, $Res Function(DeliveryAddress) _then) = _$DeliveryAddressCopyWithImpl;
@useResult
$Res call({
 String? label, String line1, String? area, String city, String state, GeoPoint location, String? instructions, String? contactPhone
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$DeliveryAddressCopyWithImpl<$Res>
    implements $DeliveryAddressCopyWith<$Res> {
  _$DeliveryAddressCopyWithImpl(this._self, this._then);

  final DeliveryAddress _self;
  final $Res Function(DeliveryAddress) _then;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = freezed,Object? line1 = null,Object? area = freezed,Object? city = null,Object? state = null,Object? location = null,Object? instructions = freezed,Object? contactPhone = freezed,}) {
  return _then(DeliveryAddress(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeliveryAddress].
extension DeliveryAddressPatterns on DeliveryAddress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryAddress value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryAddress():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryAddress value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? label,  String line1,  String? area,  String city,  String state,  GeoPoint location,  String? instructions,  String? contactPhone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that.label,_that.line1,_that.area,_that.city,_that.state,_that.location,_that.instructions,_that.contactPhone);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? label,  String line1,  String? area,  String city,  String state,  GeoPoint location,  String? instructions,  String? contactPhone)  $default,) {final _that = this;
switch (_that) {
case _DeliveryAddress():
return $default(_that.label,_that.line1,_that.area,_that.city,_that.state,_that.location,_that.instructions,_that.contactPhone);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? label,  String line1,  String? area,  String city,  String state,  GeoPoint location,  String? instructions,  String? contactPhone)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that.label,_that.line1,_that.area,_that.city,_that.state,_that.location,_that.instructions,_that.contactPhone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryAddress implements DeliveryAddress {
  const _DeliveryAddress({this.label, required this.line1, this.area, this.city = 'Lagos', this.state = 'Lagos', required this.location, this.instructions, this.contactPhone});
  factory _DeliveryAddress.fromJson(Map<String, dynamic> json) => _$DeliveryAddressFromJson(json);

@override final  String? label;
@override final  String line1;
@override final  String? area;
@override@JsonKey() final  String city;
@override@JsonKey() final  String state;
@override final  GeoPoint location;
@override final  String? instructions;
@override final  String? contactPhone;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryAddressCopyWith<_DeliveryAddress> get copyWith => __$DeliveryAddressCopyWithImpl<_DeliveryAddress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryAddressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryAddress&&(identical(other.label, label) || other.label == label)&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.area, area) || other.area == area)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.location, location) || other.location == location)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label,line1,area,city,state,location,instructions,contactPhone);
}

@override
String toString() {
    return 'DeliveryAddress(label: $label, line1: $line1, area: $area, city: $city, state: $state, location: $location, instructions: $instructions, contactPhone: $contactPhone)';
}


}

/// @nodoc
abstract mixin class _$DeliveryAddressCopyWith<$Res> implements $DeliveryAddressCopyWith<$Res> {
  factory _$DeliveryAddressCopyWith(_DeliveryAddress value, $Res Function(_DeliveryAddress) _then) = __$DeliveryAddressCopyWithImpl;
@override @useResult
$Res call({
 String? label, String line1, String? area, String city, String state, GeoPoint location, String? instructions, String? contactPhone
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$DeliveryAddressCopyWithImpl<$Res>
    implements _$DeliveryAddressCopyWith<$Res> {
  __$DeliveryAddressCopyWithImpl(this._self, this._then);

  final _DeliveryAddress _self;
  final $Res Function(_DeliveryAddress) _then;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = freezed,Object? line1 = null,Object? area = freezed,Object? city = null,Object? state = null,Object? location = null,Object? instructions = freezed,Object? contactPhone = freezed,}) {
  return _then(_DeliveryAddress(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$PricedLine {

 String get itemId; String get name; int get quantity; int get lineTotalKobo; List<String> get selectionLabels;
/// Create a copy of PricedLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PricedLineCopyWith<PricedLine> get copyWith => _$PricedLineCopyWithImpl<PricedLine>(this as PricedLine, _$identity);

  /// Serializes this PricedLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PricedLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PricedLine&&(identical(other.itemId, _this.itemId) || other.itemId == _this.itemId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.lineTotalKobo, _this.lineTotalKobo) || other.lineTotalKobo == _this.lineTotalKobo)&&const DeepCollectionEquality().equals(other.selectionLabels, _this.selectionLabels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PricedLine;
  return Object.hash(runtimeType,_this.itemId,_this.name,_this.quantity,_this.lineTotalKobo,const DeepCollectionEquality().hash(_this.selectionLabels));
}

@override
String toString() {
  final _this = this as PricedLine;
  return 'PricedLine(itemId: ${_this.itemId}, name: ${_this.name}, quantity: ${_this.quantity}, lineTotalKobo: ${_this.lineTotalKobo}, selectionLabels: ${_this.selectionLabels})';
}


}

/// @nodoc
abstract mixin class $PricedLineCopyWith<$Res>  {
  factory $PricedLineCopyWith(PricedLine value, $Res Function(PricedLine) _then) = _$PricedLineCopyWithImpl;
@useResult
$Res call({
 String itemId, String name, int quantity, int lineTotalKobo, List<String> selectionLabels
});




}
/// @nodoc
class _$PricedLineCopyWithImpl<$Res>
    implements $PricedLineCopyWith<$Res> {
  _$PricedLineCopyWithImpl(this._self, this._then);

  final PricedLine _self;
  final $Res Function(PricedLine) _then;

/// Create a copy of PricedLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? name = null,Object? quantity = null,Object? lineTotalKobo = null,Object? selectionLabels = null,}) {
  return _then(PricedLine(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,lineTotalKobo: null == lineTotalKobo ? _self.lineTotalKobo : lineTotalKobo // ignore: cast_nullable_to_non_nullable
as int,selectionLabels: null == selectionLabels ? _self.selectionLabels : selectionLabels // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PricedLine].
extension PricedLinePatterns on PricedLine {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PricedLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PricedLine() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PricedLine value)  $default,){
final _that = this;
switch (_that) {
case _PricedLine():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PricedLine value)?  $default,){
final _that = this;
switch (_that) {
case _PricedLine() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String name,  int quantity,  int lineTotalKobo,  List<String> selectionLabels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PricedLine() when $default != null:
return $default(_that.itemId,_that.name,_that.quantity,_that.lineTotalKobo,_that.selectionLabels);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String name,  int quantity,  int lineTotalKobo,  List<String> selectionLabels)  $default,) {final _that = this;
switch (_that) {
case _PricedLine():
return $default(_that.itemId,_that.name,_that.quantity,_that.lineTotalKobo,_that.selectionLabels);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String name,  int quantity,  int lineTotalKobo,  List<String> selectionLabels)?  $default,) {final _that = this;
switch (_that) {
case _PricedLine() when $default != null:
return $default(_that.itemId,_that.name,_that.quantity,_that.lineTotalKobo,_that.selectionLabels);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PricedLine implements PricedLine {
  const _PricedLine({required this.itemId, required this.name, required this.quantity, required this.lineTotalKobo,  List<String> selectionLabels = const <String>[]}): _selectionLabels = selectionLabels;
  factory _PricedLine.fromJson(Map<String, dynamic> json) => _$PricedLineFromJson(json);

@override final  String itemId;
@override final  String name;
@override final  int quantity;
@override final  int lineTotalKobo;
 final  List<String> _selectionLabels;
@override@JsonKey() List<String> get selectionLabels {
  if (_selectionLabels is EqualUnmodifiableListView) return _selectionLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectionLabels);
}


/// Create a copy of PricedLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PricedLineCopyWith<_PricedLine> get copyWith => __$PricedLineCopyWithImpl<_PricedLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PricedLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PricedLine&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.lineTotalKobo, lineTotalKobo) || other.lineTotalKobo == lineTotalKobo)&&const DeepCollectionEquality().equals(other.selectionLabels, _selectionLabels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,itemId,name,quantity,lineTotalKobo,const DeepCollectionEquality().hash(_selectionLabels));
}

@override
String toString() {
    return 'PricedLine(itemId: $itemId, name: $name, quantity: $quantity, lineTotalKobo: $lineTotalKobo, selectionLabels: $selectionLabels)';
}


}

/// @nodoc
abstract mixin class _$PricedLineCopyWith<$Res> implements $PricedLineCopyWith<$Res> {
  factory _$PricedLineCopyWith(_PricedLine value, $Res Function(_PricedLine) _then) = __$PricedLineCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String name, int quantity, int lineTotalKobo, List<String> selectionLabels
});




}
/// @nodoc
class __$PricedLineCopyWithImpl<$Res>
    implements _$PricedLineCopyWith<$Res> {
  __$PricedLineCopyWithImpl(this._self, this._then);

  final _PricedLine _self;
  final $Res Function(_PricedLine) _then;

/// Create a copy of PricedLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? name = null,Object? quantity = null,Object? lineTotalKobo = null,Object? selectionLabels = null,}) {
  return _then(_PricedLine(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,lineTotalKobo: null == lineTotalKobo ? _self.lineTotalKobo : lineTotalKobo // ignore: cast_nullable_to_non_nullable
as int,selectionLabels: null == selectionLabels ? _self._selectionLabels : selectionLabels // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$PriceBreakdown {

 int get subtotalKobo; int get deliveryFeeKobo; int get serviceFeeKobo; int get smallOrderFeeKobo; int get vatKobo; int get discountKobo; int get totalKobo; String? get voucherCode;
/// Create a copy of PriceBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<PriceBreakdown> get copyWith => _$PriceBreakdownCopyWithImpl<PriceBreakdown>(this as PriceBreakdown, _$identity);

  /// Serializes this PriceBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PriceBreakdown;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceBreakdown&&(identical(other.subtotalKobo, _this.subtotalKobo) || other.subtotalKobo == _this.subtotalKobo)&&(identical(other.deliveryFeeKobo, _this.deliveryFeeKobo) || other.deliveryFeeKobo == _this.deliveryFeeKobo)&&(identical(other.serviceFeeKobo, _this.serviceFeeKobo) || other.serviceFeeKobo == _this.serviceFeeKobo)&&(identical(other.smallOrderFeeKobo, _this.smallOrderFeeKobo) || other.smallOrderFeeKobo == _this.smallOrderFeeKobo)&&(identical(other.vatKobo, _this.vatKobo) || other.vatKobo == _this.vatKobo)&&(identical(other.discountKobo, _this.discountKobo) || other.discountKobo == _this.discountKobo)&&(identical(other.totalKobo, _this.totalKobo) || other.totalKobo == _this.totalKobo)&&(identical(other.voucherCode, _this.voucherCode) || other.voucherCode == _this.voucherCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PriceBreakdown;
  return Object.hash(runtimeType,_this.subtotalKobo,_this.deliveryFeeKobo,_this.serviceFeeKobo,_this.smallOrderFeeKobo,_this.vatKobo,_this.discountKobo,_this.totalKobo,_this.voucherCode);
}

@override
String toString() {
  final _this = this as PriceBreakdown;
  return 'PriceBreakdown(subtotalKobo: ${_this.subtotalKobo}, deliveryFeeKobo: ${_this.deliveryFeeKobo}, serviceFeeKobo: ${_this.serviceFeeKobo}, smallOrderFeeKobo: ${_this.smallOrderFeeKobo}, vatKobo: ${_this.vatKobo}, discountKobo: ${_this.discountKobo}, totalKobo: ${_this.totalKobo}, voucherCode: ${_this.voucherCode})';
}


}

/// @nodoc
abstract mixin class $PriceBreakdownCopyWith<$Res>  {
  factory $PriceBreakdownCopyWith(PriceBreakdown value, $Res Function(PriceBreakdown) _then) = _$PriceBreakdownCopyWithImpl;
@useResult
$Res call({
 int subtotalKobo, int deliveryFeeKobo, int serviceFeeKobo, int smallOrderFeeKobo, int vatKobo, int discountKobo, int totalKobo, String? voucherCode
});




}
/// @nodoc
class _$PriceBreakdownCopyWithImpl<$Res>
    implements $PriceBreakdownCopyWith<$Res> {
  _$PriceBreakdownCopyWithImpl(this._self, this._then);

  final PriceBreakdown _self;
  final $Res Function(PriceBreakdown) _then;

/// Create a copy of PriceBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subtotalKobo = null,Object? deliveryFeeKobo = null,Object? serviceFeeKobo = null,Object? smallOrderFeeKobo = null,Object? vatKobo = null,Object? discountKobo = null,Object? totalKobo = null,Object? voucherCode = freezed,}) {
  return _then(PriceBreakdown(
subtotalKobo: null == subtotalKobo ? _self.subtotalKobo : subtotalKobo // ignore: cast_nullable_to_non_nullable
as int,deliveryFeeKobo: null == deliveryFeeKobo ? _self.deliveryFeeKobo : deliveryFeeKobo // ignore: cast_nullable_to_non_nullable
as int,serviceFeeKobo: null == serviceFeeKobo ? _self.serviceFeeKobo : serviceFeeKobo // ignore: cast_nullable_to_non_nullable
as int,smallOrderFeeKobo: null == smallOrderFeeKobo ? _self.smallOrderFeeKobo : smallOrderFeeKobo // ignore: cast_nullable_to_non_nullable
as int,vatKobo: null == vatKobo ? _self.vatKobo : vatKobo // ignore: cast_nullable_to_non_nullable
as int,discountKobo: null == discountKobo ? _self.discountKobo : discountKobo // ignore: cast_nullable_to_non_nullable
as int,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,voucherCode: freezed == voucherCode ? _self.voucherCode : voucherCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceBreakdown].
extension PriceBreakdownPatterns on PriceBreakdown {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceBreakdown() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _PriceBreakdown():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _PriceBreakdown() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int subtotalKobo,  int deliveryFeeKobo,  int serviceFeeKobo,  int smallOrderFeeKobo,  int vatKobo,  int discountKobo,  int totalKobo,  String? voucherCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceBreakdown() when $default != null:
return $default(_that.subtotalKobo,_that.deliveryFeeKobo,_that.serviceFeeKobo,_that.smallOrderFeeKobo,_that.vatKobo,_that.discountKobo,_that.totalKobo,_that.voucherCode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int subtotalKobo,  int deliveryFeeKobo,  int serviceFeeKobo,  int smallOrderFeeKobo,  int vatKobo,  int discountKobo,  int totalKobo,  String? voucherCode)  $default,) {final _that = this;
switch (_that) {
case _PriceBreakdown():
return $default(_that.subtotalKobo,_that.deliveryFeeKobo,_that.serviceFeeKobo,_that.smallOrderFeeKobo,_that.vatKobo,_that.discountKobo,_that.totalKobo,_that.voucherCode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int subtotalKobo,  int deliveryFeeKobo,  int serviceFeeKobo,  int smallOrderFeeKobo,  int vatKobo,  int discountKobo,  int totalKobo,  String? voucherCode)?  $default,) {final _that = this;
switch (_that) {
case _PriceBreakdown() when $default != null:
return $default(_that.subtotalKobo,_that.deliveryFeeKobo,_that.serviceFeeKobo,_that.smallOrderFeeKobo,_that.vatKobo,_that.discountKobo,_that.totalKobo,_that.voucherCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceBreakdown implements PriceBreakdown {
  const _PriceBreakdown({required this.subtotalKobo, this.deliveryFeeKobo = 0, this.serviceFeeKobo = 0, this.smallOrderFeeKobo = 0, this.vatKobo = 0, this.discountKobo = 0, required this.totalKobo, this.voucherCode});
  factory _PriceBreakdown.fromJson(Map<String, dynamic> json) => _$PriceBreakdownFromJson(json);

@override final  int subtotalKobo;
@override@JsonKey() final  int deliveryFeeKobo;
@override@JsonKey() final  int serviceFeeKobo;
@override@JsonKey() final  int smallOrderFeeKobo;
@override@JsonKey() final  int vatKobo;
@override@JsonKey() final  int discountKobo;
@override final  int totalKobo;
@override final  String? voucherCode;

/// Create a copy of PriceBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceBreakdownCopyWith<_PriceBreakdown> get copyWith => __$PriceBreakdownCopyWithImpl<_PriceBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceBreakdown&&(identical(other.subtotalKobo, subtotalKobo) || other.subtotalKobo == subtotalKobo)&&(identical(other.deliveryFeeKobo, deliveryFeeKobo) || other.deliveryFeeKobo == deliveryFeeKobo)&&(identical(other.serviceFeeKobo, serviceFeeKobo) || other.serviceFeeKobo == serviceFeeKobo)&&(identical(other.smallOrderFeeKobo, smallOrderFeeKobo) || other.smallOrderFeeKobo == smallOrderFeeKobo)&&(identical(other.vatKobo, vatKobo) || other.vatKobo == vatKobo)&&(identical(other.discountKobo, discountKobo) || other.discountKobo == discountKobo)&&(identical(other.totalKobo, totalKobo) || other.totalKobo == totalKobo)&&(identical(other.voucherCode, voucherCode) || other.voucherCode == voucherCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,subtotalKobo,deliveryFeeKobo,serviceFeeKobo,smallOrderFeeKobo,vatKobo,discountKobo,totalKobo,voucherCode);
}

@override
String toString() {
    return 'PriceBreakdown(subtotalKobo: $subtotalKobo, deliveryFeeKobo: $deliveryFeeKobo, serviceFeeKobo: $serviceFeeKobo, smallOrderFeeKobo: $smallOrderFeeKobo, vatKobo: $vatKobo, discountKobo: $discountKobo, totalKobo: $totalKobo, voucherCode: $voucherCode)';
}


}

/// @nodoc
abstract mixin class _$PriceBreakdownCopyWith<$Res> implements $PriceBreakdownCopyWith<$Res> {
  factory _$PriceBreakdownCopyWith(_PriceBreakdown value, $Res Function(_PriceBreakdown) _then) = __$PriceBreakdownCopyWithImpl;
@override @useResult
$Res call({
 int subtotalKobo, int deliveryFeeKobo, int serviceFeeKobo, int smallOrderFeeKobo, int vatKobo, int discountKobo, int totalKobo, String? voucherCode
});




}
/// @nodoc
class __$PriceBreakdownCopyWithImpl<$Res>
    implements _$PriceBreakdownCopyWith<$Res> {
  __$PriceBreakdownCopyWithImpl(this._self, this._then);

  final _PriceBreakdown _self;
  final $Res Function(_PriceBreakdown) _then;

/// Create a copy of PriceBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subtotalKobo = null,Object? deliveryFeeKobo = null,Object? serviceFeeKobo = null,Object? smallOrderFeeKobo = null,Object? vatKobo = null,Object? discountKobo = null,Object? totalKobo = null,Object? voucherCode = freezed,}) {
  return _then(_PriceBreakdown(
subtotalKobo: null == subtotalKobo ? _self.subtotalKobo : subtotalKobo // ignore: cast_nullable_to_non_nullable
as int,deliveryFeeKobo: null == deliveryFeeKobo ? _self.deliveryFeeKobo : deliveryFeeKobo // ignore: cast_nullable_to_non_nullable
as int,serviceFeeKobo: null == serviceFeeKobo ? _self.serviceFeeKobo : serviceFeeKobo // ignore: cast_nullable_to_non_nullable
as int,smallOrderFeeKobo: null == smallOrderFeeKobo ? _self.smallOrderFeeKobo : smallOrderFeeKobo // ignore: cast_nullable_to_non_nullable
as int,vatKobo: null == vatKobo ? _self.vatKobo : vatKobo // ignore: cast_nullable_to_non_nullable
as int,discountKobo: null == discountKobo ? _self.discountKobo : discountKobo // ignore: cast_nullable_to_non_nullable
as int,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,voucherCode: freezed == voucherCode ? _self.voucherCode : voucherCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Quote {

 String get id; String get restaurantName; List<PricedLine> get lines; PriceBreakdown get breakdown; String get fulfillment; int get etaMinutes; DateTime get estimatedDeliveryAt; DateTime get expiresAt;
/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteCopyWith<Quote> get copyWith => _$QuoteCopyWithImpl<Quote>(this as Quote, _$identity);

  /// Serializes this Quote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Quote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Quote&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.restaurantName, _this.restaurantName) || other.restaurantName == _this.restaurantName)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&(identical(other.breakdown, _this.breakdown) || other.breakdown == _this.breakdown)&&(identical(other.fulfillment, _this.fulfillment) || other.fulfillment == _this.fulfillment)&&(identical(other.etaMinutes, _this.etaMinutes) || other.etaMinutes == _this.etaMinutes)&&(identical(other.estimatedDeliveryAt, _this.estimatedDeliveryAt) || other.estimatedDeliveryAt == _this.estimatedDeliveryAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Quote;
  return Object.hash(runtimeType,_this.id,_this.restaurantName,const DeepCollectionEquality().hash(_this.lines),_this.breakdown,_this.fulfillment,_this.etaMinutes,_this.estimatedDeliveryAt,_this.expiresAt);
}

@override
String toString() {
  final _this = this as Quote;
  return 'Quote(id: ${_this.id}, restaurantName: ${_this.restaurantName}, lines: ${_this.lines}, breakdown: ${_this.breakdown}, fulfillment: ${_this.fulfillment}, etaMinutes: ${_this.etaMinutes}, estimatedDeliveryAt: ${_this.estimatedDeliveryAt}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $QuoteCopyWith<$Res>  {
  factory $QuoteCopyWith(Quote value, $Res Function(Quote) _then) = _$QuoteCopyWithImpl;
@useResult
$Res call({
 String id, String restaurantName, List<PricedLine> lines, PriceBreakdown breakdown, String fulfillment, int etaMinutes, DateTime estimatedDeliveryAt, DateTime expiresAt
});


$PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class _$QuoteCopyWithImpl<$Res>
    implements $QuoteCopyWith<$Res> {
  _$QuoteCopyWithImpl(this._self, this._then);

  final Quote _self;
  final $Res Function(Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? restaurantName = null,Object? lines = null,Object? breakdown = null,Object? fulfillment = null,Object? etaMinutes = null,Object? estimatedDeliveryAt = null,Object? expiresAt = null,}) {
  return _then(Quote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<PricedLine>,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,etaMinutes: null == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int,estimatedDeliveryAt: null == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// Adds pattern-matching-related methods to [Quote].
extension QuotePatterns on Quote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Quote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Quote value)  $default,){
final _that = this;
switch (_that) {
case _Quote():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Quote value)?  $default,){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String restaurantName,  List<PricedLine> lines,  PriceBreakdown breakdown,  String fulfillment,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.restaurantName,_that.lines,_that.breakdown,_that.fulfillment,_that.etaMinutes,_that.estimatedDeliveryAt,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String restaurantName,  List<PricedLine> lines,  PriceBreakdown breakdown,  String fulfillment,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _Quote():
return $default(_that.id,_that.restaurantName,_that.lines,_that.breakdown,_that.fulfillment,_that.etaMinutes,_that.estimatedDeliveryAt,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String restaurantName,  List<PricedLine> lines,  PriceBreakdown breakdown,  String fulfillment,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.restaurantName,_that.lines,_that.breakdown,_that.fulfillment,_that.etaMinutes,_that.estimatedDeliveryAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Quote implements Quote {
  const _Quote({required this.id, required this.restaurantName,  List<PricedLine> lines = const <PricedLine>[], required this.breakdown, required this.fulfillment, required this.etaMinutes, required this.estimatedDeliveryAt, required this.expiresAt}): _lines = lines;
  factory _Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);

@override final  String id;
@override final  String restaurantName;
 final  List<PricedLine> _lines;
@override@JsonKey() List<PricedLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  PriceBreakdown breakdown;
@override final  String fulfillment;
@override final  int etaMinutes;
@override final  DateTime estimatedDeliveryAt;
@override final  DateTime expiresAt;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteCopyWith<_Quote> get copyWith => __$QuoteCopyWithImpl<_Quote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Quote&&(identical(other.id, id) || other.id == id)&&(identical(other.restaurantName, restaurantName) || other.restaurantName == restaurantName)&&const DeepCollectionEquality().equals(other.lines, _lines)&&(identical(other.breakdown, breakdown) || other.breakdown == breakdown)&&(identical(other.fulfillment, fulfillment) || other.fulfillment == fulfillment)&&(identical(other.etaMinutes, etaMinutes) || other.etaMinutes == etaMinutes)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,restaurantName,const DeepCollectionEquality().hash(_lines),breakdown,fulfillment,etaMinutes,estimatedDeliveryAt,expiresAt);
}

@override
String toString() {
    return 'Quote(id: $id, restaurantName: $restaurantName, lines: $lines, breakdown: $breakdown, fulfillment: $fulfillment, etaMinutes: $etaMinutes, estimatedDeliveryAt: $estimatedDeliveryAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$QuoteCopyWith<$Res> implements $QuoteCopyWith<$Res> {
  factory _$QuoteCopyWith(_Quote value, $Res Function(_Quote) _then) = __$QuoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String restaurantName, List<PricedLine> lines, PriceBreakdown breakdown, String fulfillment, int etaMinutes, DateTime estimatedDeliveryAt, DateTime expiresAt
});


@override $PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class __$QuoteCopyWithImpl<$Res>
    implements _$QuoteCopyWith<$Res> {
  __$QuoteCopyWithImpl(this._self, this._then);

  final _Quote _self;
  final $Res Function(_Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? restaurantName = null,Object? lines = null,Object? breakdown = null,Object? fulfillment = null,Object? etaMinutes = null,Object? estimatedDeliveryAt = null,Object? expiresAt = null,}) {
  return _then(_Quote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<PricedLine>,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,etaMinutes: null == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int,estimatedDeliveryAt: null == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// @nodoc
mixin _$OrderProgress {

 int get step; int get totalSteps; String get label;
/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderProgressCopyWith<OrderProgress> get copyWith => _$OrderProgressCopyWithImpl<OrderProgress>(this as OrderProgress, _$identity);

  /// Serializes this OrderProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OrderProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderProgress&&(identical(other.step, _this.step) || other.step == _this.step)&&(identical(other.totalSteps, _this.totalSteps) || other.totalSteps == _this.totalSteps)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OrderProgress;
  return Object.hash(runtimeType,_this.step,_this.totalSteps,_this.label);
}

@override
String toString() {
  final _this = this as OrderProgress;
  return 'OrderProgress(step: ${_this.step}, totalSteps: ${_this.totalSteps}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $OrderProgressCopyWith<$Res>  {
  factory $OrderProgressCopyWith(OrderProgress value, $Res Function(OrderProgress) _then) = _$OrderProgressCopyWithImpl;
@useResult
$Res call({
 int step, int totalSteps, String label
});




}
/// @nodoc
class _$OrderProgressCopyWithImpl<$Res>
    implements $OrderProgressCopyWith<$Res> {
  _$OrderProgressCopyWithImpl(this._self, this._then);

  final OrderProgress _self;
  final $Res Function(OrderProgress) _then;

/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? totalSteps = null,Object? label = null,}) {
  return _then(OrderProgress(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,totalSteps: null == totalSteps ? _self.totalSteps : totalSteps // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderProgress].
extension OrderProgressPatterns on OrderProgress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderProgress value)  $default,){
final _that = this;
switch (_that) {
case _OrderProgress():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderProgress value)?  $default,){
final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int step,  int totalSteps,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that.step,_that.totalSteps,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int step,  int totalSteps,  String label)  $default,) {final _that = this;
switch (_that) {
case _OrderProgress():
return $default(_that.step,_that.totalSteps,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int step,  int totalSteps,  String label)?  $default,) {final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that.step,_that.totalSteps,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderProgress implements OrderProgress {
  const _OrderProgress({required this.step, this.totalSteps = 5, required this.label});
  factory _OrderProgress.fromJson(Map<String, dynamic> json) => _$OrderProgressFromJson(json);

@override final  int step;
@override@JsonKey() final  int totalSteps;
@override final  String label;

/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderProgressCopyWith<_OrderProgress> get copyWith => __$OrderProgressCopyWithImpl<_OrderProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderProgressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderProgress&&(identical(other.step, step) || other.step == step)&&(identical(other.totalSteps, totalSteps) || other.totalSteps == totalSteps)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,step,totalSteps,label);
}

@override
String toString() {
    return 'OrderProgress(step: $step, totalSteps: $totalSteps, label: $label)';
}


}

/// @nodoc
abstract mixin class _$OrderProgressCopyWith<$Res> implements $OrderProgressCopyWith<$Res> {
  factory _$OrderProgressCopyWith(_OrderProgress value, $Res Function(_OrderProgress) _then) = __$OrderProgressCopyWithImpl;
@override @useResult
$Res call({
 int step, int totalSteps, String label
});




}
/// @nodoc
class __$OrderProgressCopyWithImpl<$Res>
    implements _$OrderProgressCopyWith<$Res> {
  __$OrderProgressCopyWithImpl(this._self, this._then);

  final _OrderProgress _self;
  final $Res Function(_OrderProgress) _then;

/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? totalSteps = null,Object? label = null,}) {
  return _then(_OrderProgress(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,totalSteps: null == totalSteps ? _self.totalSteps : totalSteps // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Order {

 String get id; String get shortCode; String get vertical; String get status; String get restaurantName; String get fulfillment; List<PricedLine> get lines; PriceBreakdown? get breakdown; DeliveryAddress? get deliveryAddress; OrderProgress? get progress; String? get riderName; String? get customerName; String? get restaurantAddress; GeoPoint? get restaurantLocation; DateTime? get estimatedDeliveryAt; DateTime? get readyAt; DateTime? get createdAt; int? get riderPayKobo; bool get reviewed; ParcelDetails? get parcel; int get refundTotalKobo;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Order;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.shortCode, _this.shortCode) || other.shortCode == _this.shortCode)&&(identical(other.vertical, _this.vertical) || other.vertical == _this.vertical)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.restaurantName, _this.restaurantName) || other.restaurantName == _this.restaurantName)&&(identical(other.fulfillment, _this.fulfillment) || other.fulfillment == _this.fulfillment)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&(identical(other.breakdown, _this.breakdown) || other.breakdown == _this.breakdown)&&(identical(other.deliveryAddress, _this.deliveryAddress) || other.deliveryAddress == _this.deliveryAddress)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.riderName, _this.riderName) || other.riderName == _this.riderName)&&(identical(other.customerName, _this.customerName) || other.customerName == _this.customerName)&&(identical(other.restaurantAddress, _this.restaurantAddress) || other.restaurantAddress == _this.restaurantAddress)&&(identical(other.restaurantLocation, _this.restaurantLocation) || other.restaurantLocation == _this.restaurantLocation)&&(identical(other.estimatedDeliveryAt, _this.estimatedDeliveryAt) || other.estimatedDeliveryAt == _this.estimatedDeliveryAt)&&(identical(other.readyAt, _this.readyAt) || other.readyAt == _this.readyAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.riderPayKobo, _this.riderPayKobo) || other.riderPayKobo == _this.riderPayKobo)&&(identical(other.reviewed, _this.reviewed) || other.reviewed == _this.reviewed)&&(identical(other.parcel, _this.parcel) || other.parcel == _this.parcel)&&(identical(other.refundTotalKobo, _this.refundTotalKobo) || other.refundTotalKobo == _this.refundTotalKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Order;
  return Object.hashAll([runtimeType,_this.id,_this.shortCode,_this.vertical,_this.status,_this.restaurantName,_this.fulfillment,const DeepCollectionEquality().hash(_this.lines),_this.breakdown,_this.deliveryAddress,_this.progress,_this.riderName,_this.customerName,_this.restaurantAddress,_this.restaurantLocation,_this.estimatedDeliveryAt,_this.readyAt,_this.createdAt,_this.riderPayKobo,_this.reviewed,_this.parcel,_this.refundTotalKobo]);
}

@override
String toString() {
  final _this = this as Order;
  return 'Order(id: ${_this.id}, shortCode: ${_this.shortCode}, vertical: ${_this.vertical}, status: ${_this.status}, restaurantName: ${_this.restaurantName}, fulfillment: ${_this.fulfillment}, lines: ${_this.lines}, breakdown: ${_this.breakdown}, deliveryAddress: ${_this.deliveryAddress}, progress: ${_this.progress}, riderName: ${_this.riderName}, customerName: ${_this.customerName}, restaurantAddress: ${_this.restaurantAddress}, restaurantLocation: ${_this.restaurantLocation}, estimatedDeliveryAt: ${_this.estimatedDeliveryAt}, readyAt: ${_this.readyAt}, createdAt: ${_this.createdAt}, riderPayKobo: ${_this.riderPayKobo}, reviewed: ${_this.reviewed}, parcel: ${_this.parcel}, refundTotalKobo: ${_this.refundTotalKobo})';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String id, String shortCode, String vertical, String status, String restaurantName, String fulfillment, List<PricedLine> lines, PriceBreakdown? breakdown, DeliveryAddress? deliveryAddress, OrderProgress? progress, String? riderName, String? customerName, String? restaurantAddress, GeoPoint? restaurantLocation, DateTime? estimatedDeliveryAt, DateTime? readyAt, DateTime? createdAt, int? riderPayKobo, bool reviewed, ParcelDetails? parcel, int refundTotalKobo
});


$PriceBreakdownCopyWith<$Res>? get breakdown;$DeliveryAddressCopyWith<$Res>? get deliveryAddress;$OrderProgressCopyWith<$Res>? get progress;$GeoPointCopyWith<$Res>? get restaurantLocation;$ParcelDetailsCopyWith<$Res>? get parcel;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shortCode = null,Object? vertical = null,Object? status = null,Object? restaurantName = null,Object? fulfillment = null,Object? lines = null,Object? breakdown = freezed,Object? deliveryAddress = freezed,Object? progress = freezed,Object? riderName = freezed,Object? customerName = freezed,Object? restaurantAddress = freezed,Object? restaurantLocation = freezed,Object? estimatedDeliveryAt = freezed,Object? readyAt = freezed,Object? createdAt = freezed,Object? riderPayKobo = freezed,Object? reviewed = null,Object? parcel = freezed,Object? refundTotalKobo = null,}) {
  return _then(Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shortCode: null == shortCode ? _self.shortCode : shortCode // ignore: cast_nullable_to_non_nullable
as String,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<PricedLine>,breakdown: freezed == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as DeliveryAddress?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as OrderProgress?,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,restaurantAddress: freezed == restaurantAddress ? _self.restaurantAddress : restaurantAddress // ignore: cast_nullable_to_non_nullable
as String?,restaurantLocation: freezed == restaurantLocation ? _self.restaurantLocation : restaurantLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readyAt: freezed == readyAt ? _self.readyAt : readyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,riderPayKobo: freezed == riderPayKobo ? _self.riderPayKobo : riderPayKobo // ignore: cast_nullable_to_non_nullable
as int?,reviewed: null == reviewed ? _self.reviewed : reviewed // ignore: cast_nullable_to_non_nullable
as bool,parcel: freezed == parcel ? _self.parcel : parcel // ignore: cast_nullable_to_non_nullable
as ParcelDetails?,refundTotalKobo: null == refundTotalKobo ? _self.refundTotalKobo : refundTotalKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res>? get breakdown {
    if (_self.breakdown == null) {
    return null;
  }

  return $PriceBreakdownCopyWith<$Res>(_self.breakdown!, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res>? get deliveryAddress {
    if (_self.deliveryAddress == null) {
    return null;
  }

  return $DeliveryAddressCopyWith<$Res>(_self.deliveryAddress!, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $OrderProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get restaurantLocation {
    if (_self.restaurantLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.restaurantLocation!, (value) {
    return _then(_self.copyWith(restaurantLocation: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<$Res>? get parcel {
    if (_self.parcel == null) {
    return null;
  }

  return $ParcelDetailsCopyWith<$Res>(_self.parcel!, (value) {
    return _then(_self.copyWith(parcel: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String shortCode,  String vertical,  String status,  String restaurantName,  String fulfillment,  List<PricedLine> lines,  PriceBreakdown? breakdown,  DeliveryAddress? deliveryAddress,  OrderProgress? progress,  String? riderName,  String? customerName,  String? restaurantAddress,  GeoPoint? restaurantLocation,  DateTime? estimatedDeliveryAt,  DateTime? readyAt,  DateTime? createdAt,  int? riderPayKobo,  bool reviewed,  ParcelDetails? parcel,  int refundTotalKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.shortCode,_that.vertical,_that.status,_that.restaurantName,_that.fulfillment,_that.lines,_that.breakdown,_that.deliveryAddress,_that.progress,_that.riderName,_that.customerName,_that.restaurantAddress,_that.restaurantLocation,_that.estimatedDeliveryAt,_that.readyAt,_that.createdAt,_that.riderPayKobo,_that.reviewed,_that.parcel,_that.refundTotalKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String shortCode,  String vertical,  String status,  String restaurantName,  String fulfillment,  List<PricedLine> lines,  PriceBreakdown? breakdown,  DeliveryAddress? deliveryAddress,  OrderProgress? progress,  String? riderName,  String? customerName,  String? restaurantAddress,  GeoPoint? restaurantLocation,  DateTime? estimatedDeliveryAt,  DateTime? readyAt,  DateTime? createdAt,  int? riderPayKobo,  bool reviewed,  ParcelDetails? parcel,  int refundTotalKobo)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.shortCode,_that.vertical,_that.status,_that.restaurantName,_that.fulfillment,_that.lines,_that.breakdown,_that.deliveryAddress,_that.progress,_that.riderName,_that.customerName,_that.restaurantAddress,_that.restaurantLocation,_that.estimatedDeliveryAt,_that.readyAt,_that.createdAt,_that.riderPayKobo,_that.reviewed,_that.parcel,_that.refundTotalKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String shortCode,  String vertical,  String status,  String restaurantName,  String fulfillment,  List<PricedLine> lines,  PriceBreakdown? breakdown,  DeliveryAddress? deliveryAddress,  OrderProgress? progress,  String? riderName,  String? customerName,  String? restaurantAddress,  GeoPoint? restaurantLocation,  DateTime? estimatedDeliveryAt,  DateTime? readyAt,  DateTime? createdAt,  int? riderPayKobo,  bool reviewed,  ParcelDetails? parcel,  int refundTotalKobo)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.shortCode,_that.vertical,_that.status,_that.restaurantName,_that.fulfillment,_that.lines,_that.breakdown,_that.deliveryAddress,_that.progress,_that.riderName,_that.customerName,_that.restaurantAddress,_that.restaurantLocation,_that.estimatedDeliveryAt,_that.readyAt,_that.createdAt,_that.riderPayKobo,_that.reviewed,_that.parcel,_that.refundTotalKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Order implements Order {
  const _Order({required this.id, required this.shortCode, this.vertical = 'food', required this.status, required this.restaurantName, this.fulfillment = 'delivery',  List<PricedLine> lines = const <PricedLine>[], this.breakdown, this.deliveryAddress, this.progress, this.riderName, this.customerName, this.restaurantAddress, this.restaurantLocation, this.estimatedDeliveryAt, this.readyAt, this.createdAt, this.riderPayKobo, this.reviewed = false, this.parcel, this.refundTotalKobo = 0}): _lines = lines;
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

@override final  String id;
@override final  String shortCode;
@override@JsonKey() final  String vertical;
@override final  String status;
@override final  String restaurantName;
@override@JsonKey() final  String fulfillment;
 final  List<PricedLine> _lines;
@override@JsonKey() List<PricedLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  PriceBreakdown? breakdown;
@override final  DeliveryAddress? deliveryAddress;
@override final  OrderProgress? progress;
@override final  String? riderName;
@override final  String? customerName;
@override final  String? restaurantAddress;
@override final  GeoPoint? restaurantLocation;
@override final  DateTime? estimatedDeliveryAt;
@override final  DateTime? readyAt;
@override final  DateTime? createdAt;
@override final  int? riderPayKobo;
@override@JsonKey() final  bool reviewed;
@override final  ParcelDetails? parcel;
@override@JsonKey() final  int refundTotalKobo;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.shortCode, shortCode) || other.shortCode == shortCode)&&(identical(other.vertical, vertical) || other.vertical == vertical)&&(identical(other.status, status) || other.status == status)&&(identical(other.restaurantName, restaurantName) || other.restaurantName == restaurantName)&&(identical(other.fulfillment, fulfillment) || other.fulfillment == fulfillment)&&const DeepCollectionEquality().equals(other.lines, _lines)&&(identical(other.breakdown, breakdown) || other.breakdown == breakdown)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.riderName, riderName) || other.riderName == riderName)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.restaurantAddress, restaurantAddress) || other.restaurantAddress == restaurantAddress)&&(identical(other.restaurantLocation, restaurantLocation) || other.restaurantLocation == restaurantLocation)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt)&&(identical(other.readyAt, readyAt) || other.readyAt == readyAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.riderPayKobo, riderPayKobo) || other.riderPayKobo == riderPayKobo)&&(identical(other.reviewed, reviewed) || other.reviewed == reviewed)&&(identical(other.parcel, parcel) || other.parcel == parcel)&&(identical(other.refundTotalKobo, refundTotalKobo) || other.refundTotalKobo == refundTotalKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,shortCode,vertical,status,restaurantName,fulfillment,const DeepCollectionEquality().hash(_lines),breakdown,deliveryAddress,progress,riderName,customerName,restaurantAddress,restaurantLocation,estimatedDeliveryAt,readyAt,createdAt,riderPayKobo,reviewed,parcel,refundTotalKobo]);
}

@override
String toString() {
    return 'Order(id: $id, shortCode: $shortCode, vertical: $vertical, status: $status, restaurantName: $restaurantName, fulfillment: $fulfillment, lines: $lines, breakdown: $breakdown, deliveryAddress: $deliveryAddress, progress: $progress, riderName: $riderName, customerName: $customerName, restaurantAddress: $restaurantAddress, restaurantLocation: $restaurantLocation, estimatedDeliveryAt: $estimatedDeliveryAt, readyAt: $readyAt, createdAt: $createdAt, riderPayKobo: $riderPayKobo, reviewed: $reviewed, parcel: $parcel, refundTotalKobo: $refundTotalKobo)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String shortCode, String vertical, String status, String restaurantName, String fulfillment, List<PricedLine> lines, PriceBreakdown? breakdown, DeliveryAddress? deliveryAddress, OrderProgress? progress, String? riderName, String? customerName, String? restaurantAddress, GeoPoint? restaurantLocation, DateTime? estimatedDeliveryAt, DateTime? readyAt, DateTime? createdAt, int? riderPayKobo, bool reviewed, ParcelDetails? parcel, int refundTotalKobo
});


@override $PriceBreakdownCopyWith<$Res>? get breakdown;@override $DeliveryAddressCopyWith<$Res>? get deliveryAddress;@override $OrderProgressCopyWith<$Res>? get progress;@override $GeoPointCopyWith<$Res>? get restaurantLocation;@override $ParcelDetailsCopyWith<$Res>? get parcel;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shortCode = null,Object? vertical = null,Object? status = null,Object? restaurantName = null,Object? fulfillment = null,Object? lines = null,Object? breakdown = freezed,Object? deliveryAddress = freezed,Object? progress = freezed,Object? riderName = freezed,Object? customerName = freezed,Object? restaurantAddress = freezed,Object? restaurantLocation = freezed,Object? estimatedDeliveryAt = freezed,Object? readyAt = freezed,Object? createdAt = freezed,Object? riderPayKobo = freezed,Object? reviewed = null,Object? parcel = freezed,Object? refundTotalKobo = null,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shortCode: null == shortCode ? _self.shortCode : shortCode // ignore: cast_nullable_to_non_nullable
as String,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<PricedLine>,breakdown: freezed == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as DeliveryAddress?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as OrderProgress?,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,restaurantAddress: freezed == restaurantAddress ? _self.restaurantAddress : restaurantAddress // ignore: cast_nullable_to_non_nullable
as String?,restaurantLocation: freezed == restaurantLocation ? _self.restaurantLocation : restaurantLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readyAt: freezed == readyAt ? _self.readyAt : readyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,riderPayKobo: freezed == riderPayKobo ? _self.riderPayKobo : riderPayKobo // ignore: cast_nullable_to_non_nullable
as int?,reviewed: null == reviewed ? _self.reviewed : reviewed // ignore: cast_nullable_to_non_nullable
as bool,parcel: freezed == parcel ? _self.parcel : parcel // ignore: cast_nullable_to_non_nullable
as ParcelDetails?,refundTotalKobo: null == refundTotalKobo ? _self.refundTotalKobo : refundTotalKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res>? get breakdown {
    if (_self.breakdown == null) {
    return null;
  }

  return $PriceBreakdownCopyWith<$Res>(_self.breakdown!, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res>? get deliveryAddress {
    if (_self.deliveryAddress == null) {
    return null;
  }

  return $DeliveryAddressCopyWith<$Res>(_self.deliveryAddress!, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $OrderProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get restaurantLocation {
    if (_self.restaurantLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.restaurantLocation!, (value) {
    return _then(_self.copyWith(restaurantLocation: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<$Res>? get parcel {
    if (_self.parcel == null) {
    return null;
  }

  return $ParcelDetailsCopyWith<$Res>(_self.parcel!, (value) {
    return _then(_self.copyWith(parcel: value));
  });
}
}


/// @nodoc
mixin _$CheckoutResult {

 String get orderId; String get reference; String get authorizationUrl; int get amountKobo; String get provider;
/// Create a copy of CheckoutResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutResultCopyWith<CheckoutResult> get copyWith => _$CheckoutResultCopyWithImpl<CheckoutResult>(this as CheckoutResult, _$identity);

  /// Serializes this CheckoutResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CheckoutResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutResult&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.authorizationUrl, _this.authorizationUrl) || other.authorizationUrl == _this.authorizationUrl)&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo)&&(identical(other.provider, _this.provider) || other.provider == _this.provider));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CheckoutResult;
  return Object.hash(runtimeType,_this.orderId,_this.reference,_this.authorizationUrl,_this.amountKobo,_this.provider);
}

@override
String toString() {
  final _this = this as CheckoutResult;
  return 'CheckoutResult(orderId: ${_this.orderId}, reference: ${_this.reference}, authorizationUrl: ${_this.authorizationUrl}, amountKobo: ${_this.amountKobo}, provider: ${_this.provider})';
}


}

/// @nodoc
abstract mixin class $CheckoutResultCopyWith<$Res>  {
  factory $CheckoutResultCopyWith(CheckoutResult value, $Res Function(CheckoutResult) _then) = _$CheckoutResultCopyWithImpl;
@useResult
$Res call({
 String orderId, String reference, String authorizationUrl, int amountKobo, String provider
});




}
/// @nodoc
class _$CheckoutResultCopyWithImpl<$Res>
    implements $CheckoutResultCopyWith<$Res> {
  _$CheckoutResultCopyWithImpl(this._self, this._then);

  final CheckoutResult _self;
  final $Res Function(CheckoutResult) _then;

/// Create a copy of CheckoutResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? reference = null,Object? authorizationUrl = null,Object? amountKobo = null,Object? provider = null,}) {
  return _then(CheckoutResult(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,authorizationUrl: null == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutResult].
extension CheckoutResultPatterns on CheckoutResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutResult value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutResult value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String reference,  String authorizationUrl,  int amountKobo,  String provider)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutResult() when $default != null:
return $default(_that.orderId,_that.reference,_that.authorizationUrl,_that.amountKobo,_that.provider);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String reference,  String authorizationUrl,  int amountKobo,  String provider)  $default,) {final _that = this;
switch (_that) {
case _CheckoutResult():
return $default(_that.orderId,_that.reference,_that.authorizationUrl,_that.amountKobo,_that.provider);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String reference,  String authorizationUrl,  int amountKobo,  String provider)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutResult() when $default != null:
return $default(_that.orderId,_that.reference,_that.authorizationUrl,_that.amountKobo,_that.provider);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutResult implements CheckoutResult {
  const _CheckoutResult({required this.orderId, required this.reference, required this.authorizationUrl, required this.amountKobo, required this.provider});
  factory _CheckoutResult.fromJson(Map<String, dynamic> json) => _$CheckoutResultFromJson(json);

@override final  String orderId;
@override final  String reference;
@override final  String authorizationUrl;
@override final  int amountKobo;
@override final  String provider;

/// Create a copy of CheckoutResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutResultCopyWith<_CheckoutResult> get copyWith => __$CheckoutResultCopyWithImpl<_CheckoutResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutResult&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl)&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo)&&(identical(other.provider, provider) || other.provider == provider));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,orderId,reference,authorizationUrl,amountKobo,provider);
}

@override
String toString() {
    return 'CheckoutResult(orderId: $orderId, reference: $reference, authorizationUrl: $authorizationUrl, amountKobo: $amountKobo, provider: $provider)';
}


}

/// @nodoc
abstract mixin class _$CheckoutResultCopyWith<$Res> implements $CheckoutResultCopyWith<$Res> {
  factory _$CheckoutResultCopyWith(_CheckoutResult value, $Res Function(_CheckoutResult) _then) = __$CheckoutResultCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String reference, String authorizationUrl, int amountKobo, String provider
});




}
/// @nodoc
class __$CheckoutResultCopyWithImpl<$Res>
    implements _$CheckoutResultCopyWith<$Res> {
  __$CheckoutResultCopyWithImpl(this._self, this._then);

  final _CheckoutResult _self;
  final $Res Function(_CheckoutResult) _then;

/// Create a copy of CheckoutResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? reference = null,Object? authorizationUrl = null,Object? amountKobo = null,Object? provider = null,}) {
  return _then(_CheckoutResult(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,authorizationUrl: null == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Tracking {

 String get status; String? get riderName; GeoPoint? get riderLocation; int? get etaMinutes; DateTime? get estimatedDeliveryAt;
/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackingCopyWith<Tracking> get copyWith => _$TrackingCopyWithImpl<Tracking>(this as Tracking, _$identity);

  /// Serializes this Tracking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Tracking;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tracking&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.riderName, _this.riderName) || other.riderName == _this.riderName)&&(identical(other.riderLocation, _this.riderLocation) || other.riderLocation == _this.riderLocation)&&(identical(other.etaMinutes, _this.etaMinutes) || other.etaMinutes == _this.etaMinutes)&&(identical(other.estimatedDeliveryAt, _this.estimatedDeliveryAt) || other.estimatedDeliveryAt == _this.estimatedDeliveryAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Tracking;
  return Object.hash(runtimeType,_this.status,_this.riderName,_this.riderLocation,_this.etaMinutes,_this.estimatedDeliveryAt);
}

@override
String toString() {
  final _this = this as Tracking;
  return 'Tracking(status: ${_this.status}, riderName: ${_this.riderName}, riderLocation: ${_this.riderLocation}, etaMinutes: ${_this.etaMinutes}, estimatedDeliveryAt: ${_this.estimatedDeliveryAt})';
}


}

/// @nodoc
abstract mixin class $TrackingCopyWith<$Res>  {
  factory $TrackingCopyWith(Tracking value, $Res Function(Tracking) _then) = _$TrackingCopyWithImpl;
@useResult
$Res call({
 String status, String? riderName, GeoPoint? riderLocation, int? etaMinutes, DateTime? estimatedDeliveryAt
});


$GeoPointCopyWith<$Res>? get riderLocation;

}
/// @nodoc
class _$TrackingCopyWithImpl<$Res>
    implements $TrackingCopyWith<$Res> {
  _$TrackingCopyWithImpl(this._self, this._then);

  final Tracking _self;
  final $Res Function(Tracking) _then;

/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? riderName = freezed,Object? riderLocation = freezed,Object? etaMinutes = freezed,Object? estimatedDeliveryAt = freezed,}) {
  return _then(Tracking(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,riderLocation: freezed == riderLocation ? _self.riderLocation : riderLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get riderLocation {
    if (_self.riderLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.riderLocation!, (value) {
    return _then(_self.copyWith(riderLocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [Tracking].
extension TrackingPatterns on Tracking {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tracking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tracking() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tracking value)  $default,){
final _that = this;
switch (_that) {
case _Tracking():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tracking value)?  $default,){
final _that = this;
switch (_that) {
case _Tracking() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? riderName,  GeoPoint? riderLocation,  int? etaMinutes,  DateTime? estimatedDeliveryAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tracking() when $default != null:
return $default(_that.status,_that.riderName,_that.riderLocation,_that.etaMinutes,_that.estimatedDeliveryAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? riderName,  GeoPoint? riderLocation,  int? etaMinutes,  DateTime? estimatedDeliveryAt)  $default,) {final _that = this;
switch (_that) {
case _Tracking():
return $default(_that.status,_that.riderName,_that.riderLocation,_that.etaMinutes,_that.estimatedDeliveryAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? riderName,  GeoPoint? riderLocation,  int? etaMinutes,  DateTime? estimatedDeliveryAt)?  $default,) {final _that = this;
switch (_that) {
case _Tracking() when $default != null:
return $default(_that.status,_that.riderName,_that.riderLocation,_that.etaMinutes,_that.estimatedDeliveryAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Tracking implements Tracking {
  const _Tracking({required this.status, this.riderName, this.riderLocation, this.etaMinutes, this.estimatedDeliveryAt});
  factory _Tracking.fromJson(Map<String, dynamic> json) => _$TrackingFromJson(json);

@override final  String status;
@override final  String? riderName;
@override final  GeoPoint? riderLocation;
@override final  int? etaMinutes;
@override final  DateTime? estimatedDeliveryAt;

/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackingCopyWith<_Tracking> get copyWith => __$TrackingCopyWithImpl<_Tracking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tracking&&(identical(other.status, status) || other.status == status)&&(identical(other.riderName, riderName) || other.riderName == riderName)&&(identical(other.riderLocation, riderLocation) || other.riderLocation == riderLocation)&&(identical(other.etaMinutes, etaMinutes) || other.etaMinutes == etaMinutes)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,riderName,riderLocation,etaMinutes,estimatedDeliveryAt);
}

@override
String toString() {
    return 'Tracking(status: $status, riderName: $riderName, riderLocation: $riderLocation, etaMinutes: $etaMinutes, estimatedDeliveryAt: $estimatedDeliveryAt)';
}


}

/// @nodoc
abstract mixin class _$TrackingCopyWith<$Res> implements $TrackingCopyWith<$Res> {
  factory _$TrackingCopyWith(_Tracking value, $Res Function(_Tracking) _then) = __$TrackingCopyWithImpl;
@override @useResult
$Res call({
 String status, String? riderName, GeoPoint? riderLocation, int? etaMinutes, DateTime? estimatedDeliveryAt
});


@override $GeoPointCopyWith<$Res>? get riderLocation;

}
/// @nodoc
class __$TrackingCopyWithImpl<$Res>
    implements _$TrackingCopyWith<$Res> {
  __$TrackingCopyWithImpl(this._self, this._then);

  final _Tracking _self;
  final $Res Function(_Tracking) _then;

/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? riderName = freezed,Object? riderLocation = freezed,Object? etaMinutes = freezed,Object? estimatedDeliveryAt = freezed,}) {
  return _then(_Tracking(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,riderLocation: freezed == riderLocation ? _self.riderLocation : riderLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get riderLocation {
    if (_self.riderLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.riderLocation!, (value) {
    return _then(_self.copyWith(riderLocation: value));
  });
}
}


/// @nodoc
mixin _$DeliveryOffer {

 String get id; String get orderId; String get restaurantName; double get distanceToRestaurantKm; int get payoutKobo; DateTime get expiresAt; GeoPoint get pickup; GeoPoint? get dropoff; String? get dropoffArea;
/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryOfferCopyWith<DeliveryOffer> get copyWith => _$DeliveryOfferCopyWithImpl<DeliveryOffer>(this as DeliveryOffer, _$identity);

  /// Serializes this DeliveryOffer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeliveryOffer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryOffer&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.restaurantName, _this.restaurantName) || other.restaurantName == _this.restaurantName)&&(identical(other.distanceToRestaurantKm, _this.distanceToRestaurantKm) || other.distanceToRestaurantKm == _this.distanceToRestaurantKm)&&(identical(other.payoutKobo, _this.payoutKobo) || other.payoutKobo == _this.payoutKobo)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.pickup, _this.pickup) || other.pickup == _this.pickup)&&(identical(other.dropoff, _this.dropoff) || other.dropoff == _this.dropoff)&&(identical(other.dropoffArea, _this.dropoffArea) || other.dropoffArea == _this.dropoffArea));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeliveryOffer;
  return Object.hash(runtimeType,_this.id,_this.orderId,_this.restaurantName,_this.distanceToRestaurantKm,_this.payoutKobo,_this.expiresAt,_this.pickup,_this.dropoff,_this.dropoffArea);
}

@override
String toString() {
  final _this = this as DeliveryOffer;
  return 'DeliveryOffer(id: ${_this.id}, orderId: ${_this.orderId}, restaurantName: ${_this.restaurantName}, distanceToRestaurantKm: ${_this.distanceToRestaurantKm}, payoutKobo: ${_this.payoutKobo}, expiresAt: ${_this.expiresAt}, pickup: ${_this.pickup}, dropoff: ${_this.dropoff}, dropoffArea: ${_this.dropoffArea})';
}


}

/// @nodoc
abstract mixin class $DeliveryOfferCopyWith<$Res>  {
  factory $DeliveryOfferCopyWith(DeliveryOffer value, $Res Function(DeliveryOffer) _then) = _$DeliveryOfferCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String restaurantName, double distanceToRestaurantKm, int payoutKobo, DateTime expiresAt, GeoPoint pickup, GeoPoint? dropoff, String? dropoffArea
});


$GeoPointCopyWith<$Res> get pickup;$GeoPointCopyWith<$Res>? get dropoff;

}
/// @nodoc
class _$DeliveryOfferCopyWithImpl<$Res>
    implements $DeliveryOfferCopyWith<$Res> {
  _$DeliveryOfferCopyWithImpl(this._self, this._then);

  final DeliveryOffer _self;
  final $Res Function(DeliveryOffer) _then;

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? restaurantName = null,Object? distanceToRestaurantKm = null,Object? payoutKobo = null,Object? expiresAt = null,Object? pickup = null,Object? dropoff = freezed,Object? dropoffArea = freezed,}) {
  return _then(DeliveryOffer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,distanceToRestaurantKm: null == distanceToRestaurantKm ? _self.distanceToRestaurantKm : distanceToRestaurantKm // ignore: cast_nullable_to_non_nullable
as double,payoutKobo: null == payoutKobo ? _self.payoutKobo : payoutKobo // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: freezed == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint?,dropoffArea: freezed == dropoffArea ? _self.dropoffArea : dropoffArea // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get dropoff {
    if (_self.dropoff == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.dropoff!, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeliveryOffer].
extension DeliveryOfferPatterns on DeliveryOffer {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryOffer value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryOffer():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryOffer value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String restaurantName,  double distanceToRestaurantKm,  int payoutKobo,  DateTime expiresAt,  GeoPoint pickup,  GeoPoint? dropoff,  String? dropoffArea)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that.id,_that.orderId,_that.restaurantName,_that.distanceToRestaurantKm,_that.payoutKobo,_that.expiresAt,_that.pickup,_that.dropoff,_that.dropoffArea);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String restaurantName,  double distanceToRestaurantKm,  int payoutKobo,  DateTime expiresAt,  GeoPoint pickup,  GeoPoint? dropoff,  String? dropoffArea)  $default,) {final _that = this;
switch (_that) {
case _DeliveryOffer():
return $default(_that.id,_that.orderId,_that.restaurantName,_that.distanceToRestaurantKm,_that.payoutKobo,_that.expiresAt,_that.pickup,_that.dropoff,_that.dropoffArea);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String restaurantName,  double distanceToRestaurantKm,  int payoutKobo,  DateTime expiresAt,  GeoPoint pickup,  GeoPoint? dropoff,  String? dropoffArea)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that.id,_that.orderId,_that.restaurantName,_that.distanceToRestaurantKm,_that.payoutKobo,_that.expiresAt,_that.pickup,_that.dropoff,_that.dropoffArea);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryOffer implements DeliveryOffer {
  const _DeliveryOffer({required this.id, required this.orderId, required this.restaurantName, required this.distanceToRestaurantKm, required this.payoutKobo, required this.expiresAt, required this.pickup, this.dropoff, this.dropoffArea});
  factory _DeliveryOffer.fromJson(Map<String, dynamic> json) => _$DeliveryOfferFromJson(json);

@override final  String id;
@override final  String orderId;
@override final  String restaurantName;
@override final  double distanceToRestaurantKm;
@override final  int payoutKobo;
@override final  DateTime expiresAt;
@override final  GeoPoint pickup;
@override final  GeoPoint? dropoff;
@override final  String? dropoffArea;

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryOfferCopyWith<_DeliveryOffer> get copyWith => __$DeliveryOfferCopyWithImpl<_DeliveryOffer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryOfferToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.restaurantName, restaurantName) || other.restaurantName == restaurantName)&&(identical(other.distanceToRestaurantKm, distanceToRestaurantKm) || other.distanceToRestaurantKm == distanceToRestaurantKm)&&(identical(other.payoutKobo, payoutKobo) || other.payoutKobo == payoutKobo)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.dropoffArea, dropoffArea) || other.dropoffArea == dropoffArea));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,orderId,restaurantName,distanceToRestaurantKm,payoutKobo,expiresAt,pickup,dropoff,dropoffArea);
}

@override
String toString() {
    return 'DeliveryOffer(id: $id, orderId: $orderId, restaurantName: $restaurantName, distanceToRestaurantKm: $distanceToRestaurantKm, payoutKobo: $payoutKobo, expiresAt: $expiresAt, pickup: $pickup, dropoff: $dropoff, dropoffArea: $dropoffArea)';
}


}

/// @nodoc
abstract mixin class _$DeliveryOfferCopyWith<$Res> implements $DeliveryOfferCopyWith<$Res> {
  factory _$DeliveryOfferCopyWith(_DeliveryOffer value, $Res Function(_DeliveryOffer) _then) = __$DeliveryOfferCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String restaurantName, double distanceToRestaurantKm, int payoutKobo, DateTime expiresAt, GeoPoint pickup, GeoPoint? dropoff, String? dropoffArea
});


@override $GeoPointCopyWith<$Res> get pickup;@override $GeoPointCopyWith<$Res>? get dropoff;

}
/// @nodoc
class __$DeliveryOfferCopyWithImpl<$Res>
    implements _$DeliveryOfferCopyWith<$Res> {
  __$DeliveryOfferCopyWithImpl(this._self, this._then);

  final _DeliveryOffer _self;
  final $Res Function(_DeliveryOffer) _then;

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? restaurantName = null,Object? distanceToRestaurantKm = null,Object? payoutKobo = null,Object? expiresAt = null,Object? pickup = null,Object? dropoff = freezed,Object? dropoffArea = freezed,}) {
  return _then(_DeliveryOffer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,distanceToRestaurantKm: null == distanceToRestaurantKm ? _self.distanceToRestaurantKm : distanceToRestaurantKm // ignore: cast_nullable_to_non_nullable
as double,payoutKobo: null == payoutKobo ? _self.payoutKobo : payoutKobo // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: freezed == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint?,dropoffArea: freezed == dropoffArea ? _self.dropoffArea : dropoffArea // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get dropoff {
    if (_self.dropoff == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.dropoff!, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// @nodoc
mixin _$RiderProfile {

 String get uid; String get name; String get vehicle; String get status; bool get isOnline; double get rating; List<String> get activeOrderIds; int get completedDeliveries;
/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiderProfileCopyWith<RiderProfile> get copyWith => _$RiderProfileCopyWithImpl<RiderProfile>(this as RiderProfile, _$identity);

  /// Serializes this RiderProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RiderProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiderProfile&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.vehicle, _this.vehicle) || other.vehicle == _this.vehicle)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.isOnline, _this.isOnline) || other.isOnline == _this.isOnline)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&const DeepCollectionEquality().equals(other.activeOrderIds, _this.activeOrderIds)&&(identical(other.completedDeliveries, _this.completedDeliveries) || other.completedDeliveries == _this.completedDeliveries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RiderProfile;
  return Object.hash(runtimeType,_this.uid,_this.name,_this.vehicle,_this.status,_this.isOnline,_this.rating,const DeepCollectionEquality().hash(_this.activeOrderIds),_this.completedDeliveries);
}

@override
String toString() {
  final _this = this as RiderProfile;
  return 'RiderProfile(uid: ${_this.uid}, name: ${_this.name}, vehicle: ${_this.vehicle}, status: ${_this.status}, isOnline: ${_this.isOnline}, rating: ${_this.rating}, activeOrderIds: ${_this.activeOrderIds}, completedDeliveries: ${_this.completedDeliveries})';
}


}

/// @nodoc
abstract mixin class $RiderProfileCopyWith<$Res>  {
  factory $RiderProfileCopyWith(RiderProfile value, $Res Function(RiderProfile) _then) = _$RiderProfileCopyWithImpl;
@useResult
$Res call({
 String uid, String name, String vehicle, String status, bool isOnline, double rating, List<String> activeOrderIds, int completedDeliveries
});




}
/// @nodoc
class _$RiderProfileCopyWithImpl<$Res>
    implements $RiderProfileCopyWith<$Res> {
  _$RiderProfileCopyWithImpl(this._self, this._then);

  final RiderProfile _self;
  final $Res Function(RiderProfile) _then;

/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? name = null,Object? vehicle = null,Object? status = null,Object? isOnline = null,Object? rating = null,Object? activeOrderIds = null,Object? completedDeliveries = null,}) {
  return _then(RiderProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,vehicle: null == vehicle ? _self.vehicle : vehicle // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,activeOrderIds: null == activeOrderIds ? _self.activeOrderIds : activeOrderIds // ignore: cast_nullable_to_non_nullable
as List<String>,completedDeliveries: null == completedDeliveries ? _self.completedDeliveries : completedDeliveries // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RiderProfile].
extension RiderProfilePatterns on RiderProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiderProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiderProfile value)  $default,){
final _that = this;
switch (_that) {
case _RiderProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiderProfile value)?  $default,){
final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String name,  String vehicle,  String status,  bool isOnline,  double rating,  List<String> activeOrderIds,  int completedDeliveries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that.uid,_that.name,_that.vehicle,_that.status,_that.isOnline,_that.rating,_that.activeOrderIds,_that.completedDeliveries);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String name,  String vehicle,  String status,  bool isOnline,  double rating,  List<String> activeOrderIds,  int completedDeliveries)  $default,) {final _that = this;
switch (_that) {
case _RiderProfile():
return $default(_that.uid,_that.name,_that.vehicle,_that.status,_that.isOnline,_that.rating,_that.activeOrderIds,_that.completedDeliveries);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String name,  String vehicle,  String status,  bool isOnline,  double rating,  List<String> activeOrderIds,  int completedDeliveries)?  $default,) {final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that.uid,_that.name,_that.vehicle,_that.status,_that.isOnline,_that.rating,_that.activeOrderIds,_that.completedDeliveries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RiderProfile implements RiderProfile {
  const _RiderProfile({required this.uid, required this.name, this.vehicle = 'motorcycle', this.status = 'pending', this.isOnline = false, this.rating = 5,  List<String> activeOrderIds = const <String>[], this.completedDeliveries = 0}): _activeOrderIds = activeOrderIds;
  factory _RiderProfile.fromJson(Map<String, dynamic> json) => _$RiderProfileFromJson(json);

@override final  String uid;
@override final  String name;
@override@JsonKey() final  String vehicle;
@override@JsonKey() final  String status;
@override@JsonKey() final  bool isOnline;
@override@JsonKey() final  double rating;
 final  List<String> _activeOrderIds;
@override@JsonKey() List<String> get activeOrderIds {
  if (_activeOrderIds is EqualUnmodifiableListView) return _activeOrderIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeOrderIds);
}

@override@JsonKey() final  int completedDeliveries;

/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiderProfileCopyWith<_RiderProfile> get copyWith => __$RiderProfileCopyWithImpl<_RiderProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiderProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiderProfile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name)&&(identical(other.vehicle, vehicle) || other.vehicle == vehicle)&&(identical(other.status, status) || other.status == status)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.activeOrderIds, _activeOrderIds)&&(identical(other.completedDeliveries, completedDeliveries) || other.completedDeliveries == completedDeliveries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uid,name,vehicle,status,isOnline,rating,const DeepCollectionEquality().hash(_activeOrderIds),completedDeliveries);
}

@override
String toString() {
    return 'RiderProfile(uid: $uid, name: $name, vehicle: $vehicle, status: $status, isOnline: $isOnline, rating: $rating, activeOrderIds: $activeOrderIds, completedDeliveries: $completedDeliveries)';
}


}

/// @nodoc
abstract mixin class _$RiderProfileCopyWith<$Res> implements $RiderProfileCopyWith<$Res> {
  factory _$RiderProfileCopyWith(_RiderProfile value, $Res Function(_RiderProfile) _then) = __$RiderProfileCopyWithImpl;
@override @useResult
$Res call({
 String uid, String name, String vehicle, String status, bool isOnline, double rating, List<String> activeOrderIds, int completedDeliveries
});




}
/// @nodoc
class __$RiderProfileCopyWithImpl<$Res>
    implements _$RiderProfileCopyWith<$Res> {
  __$RiderProfileCopyWithImpl(this._self, this._then);

  final _RiderProfile _self;
  final $Res Function(_RiderProfile) _then;

/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? name = null,Object? vehicle = null,Object? status = null,Object? isOnline = null,Object? rating = null,Object? activeOrderIds = null,Object? completedDeliveries = null,}) {
  return _then(_RiderProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,vehicle: null == vehicle ? _self.vehicle : vehicle // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,activeOrderIds: null == activeOrderIds ? _self._activeOrderIds : activeOrderIds // ignore: cast_nullable_to_non_nullable
as List<String>,completedDeliveries: null == completedDeliveries ? _self.completedDeliveries : completedDeliveries // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Earnings {

 int get balanceKobo; int get pendingPayoutsKobo; int get availableKobo; int get deliveriesCompleted; int get earnedLast7DaysKobo;
/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningsCopyWith<Earnings> get copyWith => _$EarningsCopyWithImpl<Earnings>(this as Earnings, _$identity);

  /// Serializes this Earnings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Earnings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Earnings&&(identical(other.balanceKobo, _this.balanceKobo) || other.balanceKobo == _this.balanceKobo)&&(identical(other.pendingPayoutsKobo, _this.pendingPayoutsKobo) || other.pendingPayoutsKobo == _this.pendingPayoutsKobo)&&(identical(other.availableKobo, _this.availableKobo) || other.availableKobo == _this.availableKobo)&&(identical(other.deliveriesCompleted, _this.deliveriesCompleted) || other.deliveriesCompleted == _this.deliveriesCompleted)&&(identical(other.earnedLast7DaysKobo, _this.earnedLast7DaysKobo) || other.earnedLast7DaysKobo == _this.earnedLast7DaysKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Earnings;
  return Object.hash(runtimeType,_this.balanceKobo,_this.pendingPayoutsKobo,_this.availableKobo,_this.deliveriesCompleted,_this.earnedLast7DaysKobo);
}

@override
String toString() {
  final _this = this as Earnings;
  return 'Earnings(balanceKobo: ${_this.balanceKobo}, pendingPayoutsKobo: ${_this.pendingPayoutsKobo}, availableKobo: ${_this.availableKobo}, deliveriesCompleted: ${_this.deliveriesCompleted}, earnedLast7DaysKobo: ${_this.earnedLast7DaysKobo})';
}


}

/// @nodoc
abstract mixin class $EarningsCopyWith<$Res>  {
  factory $EarningsCopyWith(Earnings value, $Res Function(Earnings) _then) = _$EarningsCopyWithImpl;
@useResult
$Res call({
 int balanceKobo, int pendingPayoutsKobo, int availableKobo, int deliveriesCompleted, int earnedLast7DaysKobo
});




}
/// @nodoc
class _$EarningsCopyWithImpl<$Res>
    implements $EarningsCopyWith<$Res> {
  _$EarningsCopyWithImpl(this._self, this._then);

  final Earnings _self;
  final $Res Function(Earnings) _then;

/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balanceKobo = null,Object? pendingPayoutsKobo = null,Object? availableKobo = null,Object? deliveriesCompleted = null,Object? earnedLast7DaysKobo = null,}) {
  return _then(Earnings(
balanceKobo: null == balanceKobo ? _self.balanceKobo : balanceKobo // ignore: cast_nullable_to_non_nullable
as int,pendingPayoutsKobo: null == pendingPayoutsKobo ? _self.pendingPayoutsKobo : pendingPayoutsKobo // ignore: cast_nullable_to_non_nullable
as int,availableKobo: null == availableKobo ? _self.availableKobo : availableKobo // ignore: cast_nullable_to_non_nullable
as int,deliveriesCompleted: null == deliveriesCompleted ? _self.deliveriesCompleted : deliveriesCompleted // ignore: cast_nullable_to_non_nullable
as int,earnedLast7DaysKobo: null == earnedLast7DaysKobo ? _self.earnedLast7DaysKobo : earnedLast7DaysKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Earnings].
extension EarningsPatterns on Earnings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Earnings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Earnings value)  $default,){
final _that = this;
switch (_that) {
case _Earnings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Earnings value)?  $default,){
final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int balanceKobo,  int pendingPayoutsKobo,  int availableKobo,  int deliveriesCompleted,  int earnedLast7DaysKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that.balanceKobo,_that.pendingPayoutsKobo,_that.availableKobo,_that.deliveriesCompleted,_that.earnedLast7DaysKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int balanceKobo,  int pendingPayoutsKobo,  int availableKobo,  int deliveriesCompleted,  int earnedLast7DaysKobo)  $default,) {final _that = this;
switch (_that) {
case _Earnings():
return $default(_that.balanceKobo,_that.pendingPayoutsKobo,_that.availableKobo,_that.deliveriesCompleted,_that.earnedLast7DaysKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int balanceKobo,  int pendingPayoutsKobo,  int availableKobo,  int deliveriesCompleted,  int earnedLast7DaysKobo)?  $default,) {final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that.balanceKobo,_that.pendingPayoutsKobo,_that.availableKobo,_that.deliveriesCompleted,_that.earnedLast7DaysKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Earnings implements Earnings {
  const _Earnings({required this.balanceKobo, required this.pendingPayoutsKobo, required this.availableKobo, required this.deliveriesCompleted, required this.earnedLast7DaysKobo});
  factory _Earnings.fromJson(Map<String, dynamic> json) => _$EarningsFromJson(json);

@override final  int balanceKobo;
@override final  int pendingPayoutsKobo;
@override final  int availableKobo;
@override final  int deliveriesCompleted;
@override final  int earnedLast7DaysKobo;

/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarningsCopyWith<_Earnings> get copyWith => __$EarningsCopyWithImpl<_Earnings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EarningsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Earnings&&(identical(other.balanceKobo, balanceKobo) || other.balanceKobo == balanceKobo)&&(identical(other.pendingPayoutsKobo, pendingPayoutsKobo) || other.pendingPayoutsKobo == pendingPayoutsKobo)&&(identical(other.availableKobo, availableKobo) || other.availableKobo == availableKobo)&&(identical(other.deliveriesCompleted, deliveriesCompleted) || other.deliveriesCompleted == deliveriesCompleted)&&(identical(other.earnedLast7DaysKobo, earnedLast7DaysKobo) || other.earnedLast7DaysKobo == earnedLast7DaysKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,balanceKobo,pendingPayoutsKobo,availableKobo,deliveriesCompleted,earnedLast7DaysKobo);
}

@override
String toString() {
    return 'Earnings(balanceKobo: $balanceKobo, pendingPayoutsKobo: $pendingPayoutsKobo, availableKobo: $availableKobo, deliveriesCompleted: $deliveriesCompleted, earnedLast7DaysKobo: $earnedLast7DaysKobo)';
}


}

/// @nodoc
abstract mixin class _$EarningsCopyWith<$Res> implements $EarningsCopyWith<$Res> {
  factory _$EarningsCopyWith(_Earnings value, $Res Function(_Earnings) _then) = __$EarningsCopyWithImpl;
@override @useResult
$Res call({
 int balanceKobo, int pendingPayoutsKobo, int availableKobo, int deliveriesCompleted, int earnedLast7DaysKobo
});




}
/// @nodoc
class __$EarningsCopyWithImpl<$Res>
    implements _$EarningsCopyWith<$Res> {
  __$EarningsCopyWithImpl(this._self, this._then);

  final _Earnings _self;
  final $Res Function(_Earnings) _then;

/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balanceKobo = null,Object? pendingPayoutsKobo = null,Object? availableKobo = null,Object? deliveriesCompleted = null,Object? earnedLast7DaysKobo = null,}) {
  return _then(_Earnings(
balanceKobo: null == balanceKobo ? _self.balanceKobo : balanceKobo // ignore: cast_nullable_to_non_nullable
as int,pendingPayoutsKobo: null == pendingPayoutsKobo ? _self.pendingPayoutsKobo : pendingPayoutsKobo // ignore: cast_nullable_to_non_nullable
as int,availableKobo: null == availableKobo ? _self.availableKobo : availableKobo // ignore: cast_nullable_to_non_nullable
as int,deliveriesCompleted: null == deliveriesCompleted ? _self.deliveriesCompleted : deliveriesCompleted // ignore: cast_nullable_to_non_nullable
as int,earnedLast7DaysKobo: null == earnedLast7DaysKobo ? _self.earnedLast7DaysKobo : earnedLast7DaysKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ChatApproval {

 String get tool; String get toolCallId; Map<String, dynamic> get preview;
/// Create a copy of ChatApproval
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatApprovalCopyWith<ChatApproval> get copyWith => _$ChatApprovalCopyWithImpl<ChatApproval>(this as ChatApproval, _$identity);

  /// Serializes this ChatApproval to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatApproval;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatApproval&&(identical(other.tool, _this.tool) || other.tool == _this.tool)&&(identical(other.toolCallId, _this.toolCallId) || other.toolCallId == _this.toolCallId)&&const DeepCollectionEquality().equals(other.preview, _this.preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatApproval;
  return Object.hash(runtimeType,_this.tool,_this.toolCallId,const DeepCollectionEquality().hash(_this.preview));
}

@override
String toString() {
  final _this = this as ChatApproval;
  return 'ChatApproval(tool: ${_this.tool}, toolCallId: ${_this.toolCallId}, preview: ${_this.preview})';
}


}

/// @nodoc
abstract mixin class $ChatApprovalCopyWith<$Res>  {
  factory $ChatApprovalCopyWith(ChatApproval value, $Res Function(ChatApproval) _then) = _$ChatApprovalCopyWithImpl;
@useResult
$Res call({
 String tool, String toolCallId, Map<String, dynamic> preview
});




}
/// @nodoc
class _$ChatApprovalCopyWithImpl<$Res>
    implements $ChatApprovalCopyWith<$Res> {
  _$ChatApprovalCopyWithImpl(this._self, this._then);

  final ChatApproval _self;
  final $Res Function(ChatApproval) _then;

/// Create a copy of ChatApproval
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tool = null,Object? toolCallId = null,Object? preview = null,}) {
  return _then(ChatApproval(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatApproval].
extension ChatApprovalPatterns on ChatApproval {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatApproval value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatApproval() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatApproval value)  $default,){
final _that = this;
switch (_that) {
case _ChatApproval():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatApproval value)?  $default,){
final _that = this;
switch (_that) {
case _ChatApproval() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tool,  String toolCallId,  Map<String, dynamic> preview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatApproval() when $default != null:
return $default(_that.tool,_that.toolCallId,_that.preview);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tool,  String toolCallId,  Map<String, dynamic> preview)  $default,) {final _that = this;
switch (_that) {
case _ChatApproval():
return $default(_that.tool,_that.toolCallId,_that.preview);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tool,  String toolCallId,  Map<String, dynamic> preview)?  $default,) {final _that = this;
switch (_that) {
case _ChatApproval() when $default != null:
return $default(_that.tool,_that.toolCallId,_that.preview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatApproval implements ChatApproval {
  const _ChatApproval({required this.tool, required this.toolCallId,  Map<String, dynamic> preview = const <String, dynamic>{}}): _preview = preview;
  factory _ChatApproval.fromJson(Map<String, dynamic> json) => _$ChatApprovalFromJson(json);

@override final  String tool;
@override final  String toolCallId;
 final  Map<String, dynamic> _preview;
@override@JsonKey() Map<String, dynamic> get preview {
  if (_preview is EqualUnmodifiableMapView) return _preview;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_preview);
}


/// Create a copy of ChatApproval
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatApprovalCopyWith<_ChatApproval> get copyWith => __$ChatApprovalCopyWithImpl<_ChatApproval>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatApprovalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatApproval&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.preview, _preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tool,toolCallId,const DeepCollectionEquality().hash(_preview));
}

@override
String toString() {
    return 'ChatApproval(tool: $tool, toolCallId: $toolCallId, preview: $preview)';
}


}

/// @nodoc
abstract mixin class _$ChatApprovalCopyWith<$Res> implements $ChatApprovalCopyWith<$Res> {
  factory _$ChatApprovalCopyWith(_ChatApproval value, $Res Function(_ChatApproval) _then) = __$ChatApprovalCopyWithImpl;
@override @useResult
$Res call({
 String tool, String toolCallId, Map<String, dynamic> preview
});




}
/// @nodoc
class __$ChatApprovalCopyWithImpl<$Res>
    implements _$ChatApprovalCopyWith<$Res> {
  __$ChatApprovalCopyWithImpl(this._self, this._then);

  final _ChatApproval _self;
  final $Res Function(_ChatApproval) _then;

/// Create a copy of ChatApproval
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tool = null,Object? toolCallId = null,Object? preview = null,}) {
  return _then(_ChatApproval(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,preview: null == preview ? _self._preview : preview // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$ChatResponse {

 String get threadId; String get status; String? get reply; String? get agent; List<Map<String, dynamic>> get cards; ChatApproval? get approval;
/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatResponseCopyWith<ChatResponse> get copyWith => _$ChatResponseCopyWithImpl<ChatResponse>(this as ChatResponse, _$identity);

  /// Serializes this ChatResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatResponse&&(identical(other.threadId, _this.threadId) || other.threadId == _this.threadId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reply, _this.reply) || other.reply == _this.reply)&&(identical(other.agent, _this.agent) || other.agent == _this.agent)&&const DeepCollectionEquality().equals(other.cards, _this.cards)&&(identical(other.approval, _this.approval) || other.approval == _this.approval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatResponse;
  return Object.hash(runtimeType,_this.threadId,_this.status,_this.reply,_this.agent,const DeepCollectionEquality().hash(_this.cards),_this.approval);
}

@override
String toString() {
  final _this = this as ChatResponse;
  return 'ChatResponse(threadId: ${_this.threadId}, status: ${_this.status}, reply: ${_this.reply}, agent: ${_this.agent}, cards: ${_this.cards}, approval: ${_this.approval})';
}


}

/// @nodoc
abstract mixin class $ChatResponseCopyWith<$Res>  {
  factory $ChatResponseCopyWith(ChatResponse value, $Res Function(ChatResponse) _then) = _$ChatResponseCopyWithImpl;
@useResult
$Res call({
 String threadId, String status, String? reply, String? agent, List<Map<String, dynamic>> cards, ChatApproval? approval
});


$ChatApprovalCopyWith<$Res>? get approval;

}
/// @nodoc
class _$ChatResponseCopyWithImpl<$Res>
    implements $ChatResponseCopyWith<$Res> {
  _$ChatResponseCopyWithImpl(this._self, this._then);

  final ChatResponse _self;
  final $Res Function(ChatResponse) _then;

/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? threadId = null,Object? status = null,Object? reply = freezed,Object? agent = freezed,Object? cards = null,Object? approval = freezed,}) {
  return _then(ChatResponse(
threadId: null == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String?,agent: freezed == agent ? _self.agent : agent // ignore: cast_nullable_to_non_nullable
as String?,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,approval: freezed == approval ? _self.approval : approval // ignore: cast_nullable_to_non_nullable
as ChatApproval?,
  ));
}
/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatApprovalCopyWith<$Res>? get approval {
    if (_self.approval == null) {
    return null;
  }

  return $ChatApprovalCopyWith<$Res>(_self.approval!, (value) {
    return _then(_self.copyWith(approval: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatResponse].
extension ChatResponsePatterns on ChatResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatResponse value)  $default,){
final _that = this;
switch (_that) {
case _ChatResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ChatResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String threadId,  String status,  String? reply,  String? agent,  List<Map<String, dynamic>> cards,  ChatApproval? approval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatResponse() when $default != null:
return $default(_that.threadId,_that.status,_that.reply,_that.agent,_that.cards,_that.approval);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String threadId,  String status,  String? reply,  String? agent,  List<Map<String, dynamic>> cards,  ChatApproval? approval)  $default,) {final _that = this;
switch (_that) {
case _ChatResponse():
return $default(_that.threadId,_that.status,_that.reply,_that.agent,_that.cards,_that.approval);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String threadId,  String status,  String? reply,  String? agent,  List<Map<String, dynamic>> cards,  ChatApproval? approval)?  $default,) {final _that = this;
switch (_that) {
case _ChatResponse() when $default != null:
return $default(_that.threadId,_that.status,_that.reply,_that.agent,_that.cards,_that.approval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatResponse implements ChatResponse {
  const _ChatResponse({required this.threadId, required this.status, this.reply, this.agent,  List<Map<String, dynamic>> cards = const <Map<String, dynamic>>[], this.approval}): _cards = cards;
  factory _ChatResponse.fromJson(Map<String, dynamic> json) => _$ChatResponseFromJson(json);

@override final  String threadId;
@override final  String status;
@override final  String? reply;
@override final  String? agent;
 final  List<Map<String, dynamic>> _cards;
@override@JsonKey() List<Map<String, dynamic>> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

@override final  ChatApproval? approval;

/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatResponseCopyWith<_ChatResponse> get copyWith => __$ChatResponseCopyWithImpl<_ChatResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatResponse&&(identical(other.threadId, threadId) || other.threadId == threadId)&&(identical(other.status, status) || other.status == status)&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.agent, agent) || other.agent == agent)&&const DeepCollectionEquality().equals(other.cards, _cards)&&(identical(other.approval, approval) || other.approval == approval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,threadId,status,reply,agent,const DeepCollectionEquality().hash(_cards),approval);
}

@override
String toString() {
    return 'ChatResponse(threadId: $threadId, status: $status, reply: $reply, agent: $agent, cards: $cards, approval: $approval)';
}


}

/// @nodoc
abstract mixin class _$ChatResponseCopyWith<$Res> implements $ChatResponseCopyWith<$Res> {
  factory _$ChatResponseCopyWith(_ChatResponse value, $Res Function(_ChatResponse) _then) = __$ChatResponseCopyWithImpl;
@override @useResult
$Res call({
 String threadId, String status, String? reply, String? agent, List<Map<String, dynamic>> cards, ChatApproval? approval
});


@override $ChatApprovalCopyWith<$Res>? get approval;

}
/// @nodoc
class __$ChatResponseCopyWithImpl<$Res>
    implements _$ChatResponseCopyWith<$Res> {
  __$ChatResponseCopyWithImpl(this._self, this._then);

  final _ChatResponse _self;
  final $Res Function(_ChatResponse) _then;

/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? threadId = null,Object? status = null,Object? reply = freezed,Object? agent = freezed,Object? cards = null,Object? approval = freezed,}) {
  return _then(_ChatResponse(
threadId: null == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String?,agent: freezed == agent ? _self.agent : agent // ignore: cast_nullable_to_non_nullable
as String?,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,approval: freezed == approval ? _self.approval : approval // ignore: cast_nullable_to_non_nullable
as ChatApproval?,
  ));
}

/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatApprovalCopyWith<$Res>? get approval {
    if (_self.approval == null) {
    return null;
  }

  return $ChatApprovalCopyWith<$Res>(_self.approval!, (value) {
    return _then(_self.copyWith(approval: value));
  });
}
}


/// @nodoc
mixin _$PromoBadge {

 String get code; String get label;
/// Create a copy of PromoBadge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoBadgeCopyWith<PromoBadge> get copyWith => _$PromoBadgeCopyWithImpl<PromoBadge>(this as PromoBadge, _$identity);

  /// Serializes this PromoBadge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PromoBadge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromoBadge&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PromoBadge;
  return Object.hash(runtimeType,_this.code,_this.label);
}

@override
String toString() {
  final _this = this as PromoBadge;
  return 'PromoBadge(code: ${_this.code}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $PromoBadgeCopyWith<$Res>  {
  factory $PromoBadgeCopyWith(PromoBadge value, $Res Function(PromoBadge) _then) = _$PromoBadgeCopyWithImpl;
@useResult
$Res call({
 String code, String label
});




}
/// @nodoc
class _$PromoBadgeCopyWithImpl<$Res>
    implements $PromoBadgeCopyWith<$Res> {
  _$PromoBadgeCopyWithImpl(this._self, this._then);

  final PromoBadge _self;
  final $Res Function(PromoBadge) _then;

/// Create a copy of PromoBadge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? label = null,}) {
  return _then(PromoBadge(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PromoBadge].
extension PromoBadgePatterns on PromoBadge {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromoBadge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromoBadge() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromoBadge value)  $default,){
final _that = this;
switch (_that) {
case _PromoBadge():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromoBadge value)?  $default,){
final _that = this;
switch (_that) {
case _PromoBadge() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromoBadge() when $default != null:
return $default(_that.code,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String label)  $default,) {final _that = this;
switch (_that) {
case _PromoBadge():
return $default(_that.code,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String label)?  $default,) {final _that = this;
switch (_that) {
case _PromoBadge() when $default != null:
return $default(_that.code,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PromoBadge implements PromoBadge {
  const _PromoBadge({required this.code, required this.label});
  factory _PromoBadge.fromJson(Map<String, dynamic> json) => _$PromoBadgeFromJson(json);

@override final  String code;
@override final  String label;

/// Create a copy of PromoBadge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoBadgeCopyWith<_PromoBadge> get copyWith => __$PromoBadgeCopyWithImpl<_PromoBadge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PromoBadgeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromoBadge&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,label);
}

@override
String toString() {
    return 'PromoBadge(code: $code, label: $label)';
}


}

/// @nodoc
abstract mixin class _$PromoBadgeCopyWith<$Res> implements $PromoBadgeCopyWith<$Res> {
  factory _$PromoBadgeCopyWith(_PromoBadge value, $Res Function(_PromoBadge) _then) = __$PromoBadgeCopyWithImpl;
@override @useResult
$Res call({
 String code, String label
});




}
/// @nodoc
class __$PromoBadgeCopyWithImpl<$Res>
    implements _$PromoBadgeCopyWith<$Res> {
  __$PromoBadgeCopyWithImpl(this._self, this._then);

  final _PromoBadge _self;
  final $Res Function(_PromoBadge) _then;

/// Create a copy of PromoBadge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? label = null,}) {
  return _then(_PromoBadge(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ServiceInfo {

 String get id; String get name; String get tagline; bool get available; int? get merchants; List<String> get options; List<String> get comingSoon; List<String> get cities;
/// Create a copy of ServiceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceInfoCopyWith<ServiceInfo> get copyWith => _$ServiceInfoCopyWithImpl<ServiceInfo>(this as ServiceInfo, _$identity);

  /// Serializes this ServiceInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ServiceInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceInfo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.tagline, _this.tagline) || other.tagline == _this.tagline)&&(identical(other.available, _this.available) || other.available == _this.available)&&(identical(other.merchants, _this.merchants) || other.merchants == _this.merchants)&&const DeepCollectionEquality().equals(other.options, _this.options)&&const DeepCollectionEquality().equals(other.comingSoon, _this.comingSoon)&&const DeepCollectionEquality().equals(other.cities, _this.cities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ServiceInfo;
  return Object.hash(runtimeType,_this.id,_this.name,_this.tagline,_this.available,_this.merchants,const DeepCollectionEquality().hash(_this.options),const DeepCollectionEquality().hash(_this.comingSoon),const DeepCollectionEquality().hash(_this.cities));
}

@override
String toString() {
  final _this = this as ServiceInfo;
  return 'ServiceInfo(id: ${_this.id}, name: ${_this.name}, tagline: ${_this.tagline}, available: ${_this.available}, merchants: ${_this.merchants}, options: ${_this.options}, comingSoon: ${_this.comingSoon}, cities: ${_this.cities})';
}


}

/// @nodoc
abstract mixin class $ServiceInfoCopyWith<$Res>  {
  factory $ServiceInfoCopyWith(ServiceInfo value, $Res Function(ServiceInfo) _then) = _$ServiceInfoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String tagline, bool available, int? merchants, List<String> options, List<String> comingSoon, List<String> cities
});




}
/// @nodoc
class _$ServiceInfoCopyWithImpl<$Res>
    implements $ServiceInfoCopyWith<$Res> {
  _$ServiceInfoCopyWithImpl(this._self, this._then);

  final ServiceInfo _self;
  final $Res Function(ServiceInfo) _then;

/// Create a copy of ServiceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tagline = null,Object? available = null,Object? merchants = freezed,Object? options = null,Object? comingSoon = null,Object? cities = null,}) {
  return _then(ServiceInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,merchants: freezed == merchants ? _self.merchants : merchants // ignore: cast_nullable_to_non_nullable
as int?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,comingSoon: null == comingSoon ? _self.comingSoon : comingSoon // ignore: cast_nullable_to_non_nullable
as List<String>,cities: null == cities ? _self.cities : cities // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceInfo].
extension ServiceInfoPatterns on ServiceInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceInfo value)  $default,){
final _that = this;
switch (_that) {
case _ServiceInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String tagline,  bool available,  int? merchants,  List<String> options,  List<String> comingSoon,  List<String> cities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceInfo() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.available,_that.merchants,_that.options,_that.comingSoon,_that.cities);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String tagline,  bool available,  int? merchants,  List<String> options,  List<String> comingSoon,  List<String> cities)  $default,) {final _that = this;
switch (_that) {
case _ServiceInfo():
return $default(_that.id,_that.name,_that.tagline,_that.available,_that.merchants,_that.options,_that.comingSoon,_that.cities);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String tagline,  bool available,  int? merchants,  List<String> options,  List<String> comingSoon,  List<String> cities)?  $default,) {final _that = this;
switch (_that) {
case _ServiceInfo() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.available,_that.merchants,_that.options,_that.comingSoon,_that.cities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceInfo implements ServiceInfo {
  const _ServiceInfo({required this.id, required this.name, this.tagline = '', this.available = true, this.merchants,  List<String> options = const <String>[],  List<String> comingSoon = const <String>[],  List<String> cities = const <String>[]}): _options = options,_comingSoon = comingSoon,_cities = cities;
  factory _ServiceInfo.fromJson(Map<String, dynamic> json) => _$ServiceInfoFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String tagline;
@override@JsonKey() final  bool available;
@override final  int? merchants;
 final  List<String> _options;
@override@JsonKey() List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

 final  List<String> _comingSoon;
@override@JsonKey() List<String> get comingSoon {
  if (_comingSoon is EqualUnmodifiableListView) return _comingSoon;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comingSoon);
}

 final  List<String> _cities;
@override@JsonKey() List<String> get cities {
  if (_cities is EqualUnmodifiableListView) return _cities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cities);
}


/// Create a copy of ServiceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceInfoCopyWith<_ServiceInfo> get copyWith => __$ServiceInfoCopyWithImpl<_ServiceInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.available, available) || other.available == available)&&(identical(other.merchants, merchants) || other.merchants == merchants)&&const DeepCollectionEquality().equals(other.options, _options)&&const DeepCollectionEquality().equals(other.comingSoon, _comingSoon)&&const DeepCollectionEquality().equals(other.cities, _cities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,tagline,available,merchants,const DeepCollectionEquality().hash(_options),const DeepCollectionEquality().hash(_comingSoon),const DeepCollectionEquality().hash(_cities));
}

@override
String toString() {
    return 'ServiceInfo(id: $id, name: $name, tagline: $tagline, available: $available, merchants: $merchants, options: $options, comingSoon: $comingSoon, cities: $cities)';
}


}

/// @nodoc
abstract mixin class _$ServiceInfoCopyWith<$Res> implements $ServiceInfoCopyWith<$Res> {
  factory _$ServiceInfoCopyWith(_ServiceInfo value, $Res Function(_ServiceInfo) _then) = __$ServiceInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String tagline, bool available, int? merchants, List<String> options, List<String> comingSoon, List<String> cities
});




}
/// @nodoc
class __$ServiceInfoCopyWithImpl<$Res>
    implements _$ServiceInfoCopyWith<$Res> {
  __$ServiceInfoCopyWithImpl(this._self, this._then);

  final _ServiceInfo _self;
  final $Res Function(_ServiceInfo) _then;

/// Create a copy of ServiceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tagline = null,Object? available = null,Object? merchants = freezed,Object? options = null,Object? comingSoon = null,Object? cities = null,}) {
  return _then(_ServiceInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,merchants: freezed == merchants ? _self.merchants : merchants // ignore: cast_nullable_to_non_nullable
as int?,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,comingSoon: null == comingSoon ? _self._comingSoon : comingSoon // ignore: cast_nullable_to_non_nullable
as List<String>,cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$BrowseCategory {

 String get id; String get name; String get emoji; int get merchants;
/// Create a copy of BrowseCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrowseCategoryCopyWith<BrowseCategory> get copyWith => _$BrowseCategoryCopyWithImpl<BrowseCategory>(this as BrowseCategory, _$identity);

  /// Serializes this BrowseCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BrowseCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrowseCategory&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.emoji, _this.emoji) || other.emoji == _this.emoji)&&(identical(other.merchants, _this.merchants) || other.merchants == _this.merchants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BrowseCategory;
  return Object.hash(runtimeType,_this.id,_this.name,_this.emoji,_this.merchants);
}

@override
String toString() {
  final _this = this as BrowseCategory;
  return 'BrowseCategory(id: ${_this.id}, name: ${_this.name}, emoji: ${_this.emoji}, merchants: ${_this.merchants})';
}


}

/// @nodoc
abstract mixin class $BrowseCategoryCopyWith<$Res>  {
  factory $BrowseCategoryCopyWith(BrowseCategory value, $Res Function(BrowseCategory) _then) = _$BrowseCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String emoji, int merchants
});




}
/// @nodoc
class _$BrowseCategoryCopyWithImpl<$Res>
    implements $BrowseCategoryCopyWith<$Res> {
  _$BrowseCategoryCopyWithImpl(this._self, this._then);

  final BrowseCategory _self;
  final $Res Function(BrowseCategory) _then;

/// Create a copy of BrowseCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? merchants = null,}) {
  return _then(BrowseCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,merchants: null == merchants ? _self.merchants : merchants // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BrowseCategory].
extension BrowseCategoryPatterns on BrowseCategory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrowseCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrowseCategory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrowseCategory value)  $default,){
final _that = this;
switch (_that) {
case _BrowseCategory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrowseCategory value)?  $default,){
final _that = this;
switch (_that) {
case _BrowseCategory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  int merchants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrowseCategory() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.merchants);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  int merchants)  $default,) {final _that = this;
switch (_that) {
case _BrowseCategory():
return $default(_that.id,_that.name,_that.emoji,_that.merchants);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String emoji,  int merchants)?  $default,) {final _that = this;
switch (_that) {
case _BrowseCategory() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.merchants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BrowseCategory implements BrowseCategory {
  const _BrowseCategory({required this.id, required this.name, this.emoji = '', this.merchants = 0});
  factory _BrowseCategory.fromJson(Map<String, dynamic> json) => _$BrowseCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String emoji;
@override@JsonKey() final  int merchants;

/// Create a copy of BrowseCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrowseCategoryCopyWith<_BrowseCategory> get copyWith => __$BrowseCategoryCopyWithImpl<_BrowseCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BrowseCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrowseCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.merchants, merchants) || other.merchants == merchants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,emoji,merchants);
}

@override
String toString() {
    return 'BrowseCategory(id: $id, name: $name, emoji: $emoji, merchants: $merchants)';
}


}

/// @nodoc
abstract mixin class _$BrowseCategoryCopyWith<$Res> implements $BrowseCategoryCopyWith<$Res> {
  factory _$BrowseCategoryCopyWith(_BrowseCategory value, $Res Function(_BrowseCategory) _then) = __$BrowseCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String emoji, int merchants
});




}
/// @nodoc
class __$BrowseCategoryCopyWithImpl<$Res>
    implements _$BrowseCategoryCopyWith<$Res> {
  __$BrowseCategoryCopyWithImpl(this._self, this._then);

  final _BrowseCategory _self;
  final $Res Function(_BrowseCategory) _then;

/// Create a copy of BrowseCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? merchants = null,}) {
  return _then(_BrowseCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,merchants: null == merchants ? _self.merchants : merchants // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlaceArea {

 String get name; String get city; double get lat; double get lng;
/// Create a copy of PlaceArea
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceAreaCopyWith<PlaceArea> get copyWith => _$PlaceAreaCopyWithImpl<PlaceArea>(this as PlaceArea, _$identity);

  /// Serializes this PlaceArea to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlaceArea;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceArea&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlaceArea;
  return Object.hash(runtimeType,_this.name,_this.city,_this.lat,_this.lng);
}

@override
String toString() {
  final _this = this as PlaceArea;
  return 'PlaceArea(name: ${_this.name}, city: ${_this.city}, lat: ${_this.lat}, lng: ${_this.lng})';
}


}

/// @nodoc
abstract mixin class $PlaceAreaCopyWith<$Res>  {
  factory $PlaceAreaCopyWith(PlaceArea value, $Res Function(PlaceArea) _then) = _$PlaceAreaCopyWithImpl;
@useResult
$Res call({
 String name, String city, double lat, double lng
});




}
/// @nodoc
class _$PlaceAreaCopyWithImpl<$Res>
    implements $PlaceAreaCopyWith<$Res> {
  _$PlaceAreaCopyWithImpl(this._self, this._then);

  final PlaceArea _self;
  final $Res Function(PlaceArea) _then;

/// Create a copy of PlaceArea
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? city = null,Object? lat = null,Object? lng = null,}) {
  return _then(PlaceArea(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaceArea].
extension PlaceAreaPatterns on PlaceArea {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceArea value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceArea() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceArea value)  $default,){
final _that = this;
switch (_that) {
case _PlaceArea():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceArea value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceArea() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String city,  double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceArea() when $default != null:
return $default(_that.name,_that.city,_that.lat,_that.lng);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String city,  double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _PlaceArea():
return $default(_that.name,_that.city,_that.lat,_that.lng);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String city,  double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _PlaceArea() when $default != null:
return $default(_that.name,_that.city,_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceArea implements PlaceArea {
  const _PlaceArea({required this.name, required this.city, required this.lat, required this.lng});
  factory _PlaceArea.fromJson(Map<String, dynamic> json) => _$PlaceAreaFromJson(json);

@override final  String name;
@override final  String city;
@override final  double lat;
@override final  double lng;

/// Create a copy of PlaceArea
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceAreaCopyWith<_PlaceArea> get copyWith => __$PlaceAreaCopyWithImpl<_PlaceArea>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceAreaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceArea&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,city,lat,lng);
}

@override
String toString() {
    return 'PlaceArea(name: $name, city: $city, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$PlaceAreaCopyWith<$Res> implements $PlaceAreaCopyWith<$Res> {
  factory _$PlaceAreaCopyWith(_PlaceArea value, $Res Function(_PlaceArea) _then) = __$PlaceAreaCopyWithImpl;
@override @useResult
$Res call({
 String name, String city, double lat, double lng
});




}
/// @nodoc
class __$PlaceAreaCopyWithImpl<$Res>
    implements _$PlaceAreaCopyWith<$Res> {
  __$PlaceAreaCopyWithImpl(this._self, this._then);

  final _PlaceArea _self;
  final $Res Function(_PlaceArea) _then;

/// Create a copy of PlaceArea
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? city = null,Object? lat = null,Object? lng = null,}) {
  return _then(_PlaceArea(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ParcelStop {

 String get name; String get phone; String get line1; String? get area; String get city; GeoPoint get location; String? get instructions;
/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<ParcelStop> get copyWith => _$ParcelStopCopyWithImpl<ParcelStop>(this as ParcelStop, _$identity);

  /// Serializes this ParcelStop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParcelStop;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParcelStop&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.line1, _this.line1) || other.line1 == _this.line1)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.instructions, _this.instructions) || other.instructions == _this.instructions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParcelStop;
  return Object.hash(runtimeType,_this.name,_this.phone,_this.line1,_this.area,_this.city,_this.location,_this.instructions);
}

@override
String toString() {
  final _this = this as ParcelStop;
  return 'ParcelStop(name: ${_this.name}, phone: ${_this.phone}, line1: ${_this.line1}, area: ${_this.area}, city: ${_this.city}, location: ${_this.location}, instructions: ${_this.instructions})';
}


}

/// @nodoc
abstract mixin class $ParcelStopCopyWith<$Res>  {
  factory $ParcelStopCopyWith(ParcelStop value, $Res Function(ParcelStop) _then) = _$ParcelStopCopyWithImpl;
@useResult
$Res call({
 String name, String phone, String line1, String? area, String city, GeoPoint location, String? instructions
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$ParcelStopCopyWithImpl<$Res>
    implements $ParcelStopCopyWith<$Res> {
  _$ParcelStopCopyWithImpl(this._self, this._then);

  final ParcelStop _self;
  final $Res Function(ParcelStop) _then;

/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = null,Object? line1 = null,Object? area = freezed,Object? city = null,Object? location = null,Object? instructions = freezed,}) {
  return _then(ParcelStop(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [ParcelStop].
extension ParcelStopPatterns on ParcelStop {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParcelStop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParcelStop() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParcelStop value)  $default,){
final _that = this;
switch (_that) {
case _ParcelStop():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParcelStop value)?  $default,){
final _that = this;
switch (_that) {
case _ParcelStop() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phone,  String line1,  String? area,  String city,  GeoPoint location,  String? instructions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParcelStop() when $default != null:
return $default(_that.name,_that.phone,_that.line1,_that.area,_that.city,_that.location,_that.instructions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phone,  String line1,  String? area,  String city,  GeoPoint location,  String? instructions)  $default,) {final _that = this;
switch (_that) {
case _ParcelStop():
return $default(_that.name,_that.phone,_that.line1,_that.area,_that.city,_that.location,_that.instructions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phone,  String line1,  String? area,  String city,  GeoPoint location,  String? instructions)?  $default,) {final _that = this;
switch (_that) {
case _ParcelStop() when $default != null:
return $default(_that.name,_that.phone,_that.line1,_that.area,_that.city,_that.location,_that.instructions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParcelStop implements ParcelStop {
  const _ParcelStop({required this.name, required this.phone, required this.line1, this.area, this.city = 'Lagos', required this.location, this.instructions});
  factory _ParcelStop.fromJson(Map<String, dynamic> json) => _$ParcelStopFromJson(json);

@override final  String name;
@override final  String phone;
@override final  String line1;
@override final  String? area;
@override@JsonKey() final  String city;
@override final  GeoPoint location;
@override final  String? instructions;

/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParcelStopCopyWith<_ParcelStop> get copyWith => __$ParcelStopCopyWithImpl<_ParcelStop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParcelStopToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParcelStop&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.area, area) || other.area == area)&&(identical(other.city, city) || other.city == city)&&(identical(other.location, location) || other.location == location)&&(identical(other.instructions, instructions) || other.instructions == instructions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,phone,line1,area,city,location,instructions);
}

@override
String toString() {
    return 'ParcelStop(name: $name, phone: $phone, line1: $line1, area: $area, city: $city, location: $location, instructions: $instructions)';
}


}

/// @nodoc
abstract mixin class _$ParcelStopCopyWith<$Res> implements $ParcelStopCopyWith<$Res> {
  factory _$ParcelStopCopyWith(_ParcelStop value, $Res Function(_ParcelStop) _then) = __$ParcelStopCopyWithImpl;
@override @useResult
$Res call({
 String name, String phone, String line1, String? area, String city, GeoPoint location, String? instructions
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$ParcelStopCopyWithImpl<$Res>
    implements _$ParcelStopCopyWith<$Res> {
  __$ParcelStopCopyWithImpl(this._self, this._then);

  final _ParcelStop _self;
  final $Res Function(_ParcelStop) _then;

/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = null,Object? line1 = null,Object? area = freezed,Object? city = null,Object? location = null,Object? instructions = freezed,}) {
  return _then(_ParcelStop(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$ParcelDetails {

 ParcelStop get pickup; ParcelStop get dropoff; String get size; String get category; String get description; String get city;
/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<ParcelDetails> get copyWith => _$ParcelDetailsCopyWithImpl<ParcelDetails>(this as ParcelDetails, _$identity);

  /// Serializes this ParcelDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParcelDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParcelDetails&&(identical(other.pickup, _this.pickup) || other.pickup == _this.pickup)&&(identical(other.dropoff, _this.dropoff) || other.dropoff == _this.dropoff)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.city, _this.city) || other.city == _this.city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParcelDetails;
  return Object.hash(runtimeType,_this.pickup,_this.dropoff,_this.size,_this.category,_this.description,_this.city);
}

@override
String toString() {
  final _this = this as ParcelDetails;
  return 'ParcelDetails(pickup: ${_this.pickup}, dropoff: ${_this.dropoff}, size: ${_this.size}, category: ${_this.category}, description: ${_this.description}, city: ${_this.city})';
}


}

/// @nodoc
abstract mixin class $ParcelDetailsCopyWith<$Res>  {
  factory $ParcelDetailsCopyWith(ParcelDetails value, $Res Function(ParcelDetails) _then) = _$ParcelDetailsCopyWithImpl;
@useResult
$Res call({
 ParcelStop pickup, ParcelStop dropoff, String size, String category, String description, String city
});


$ParcelStopCopyWith<$Res> get pickup;$ParcelStopCopyWith<$Res> get dropoff;

}
/// @nodoc
class _$ParcelDetailsCopyWithImpl<$Res>
    implements $ParcelDetailsCopyWith<$Res> {
  _$ParcelDetailsCopyWithImpl(this._self, this._then);

  final ParcelDetails _self;
  final $Res Function(ParcelDetails) _then;

/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pickup = null,Object? dropoff = null,Object? size = null,Object? category = null,Object? description = null,Object? city = null,}) {
  return _then(ParcelDetails(
pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as ParcelStop,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as ParcelStop,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<$Res> get pickup {
  
  return $ParcelStopCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<$Res> get dropoff {
  
  return $ParcelStopCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// Adds pattern-matching-related methods to [ParcelDetails].
extension ParcelDetailsPatterns on ParcelDetails {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParcelDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParcelDetails() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParcelDetails value)  $default,){
final _that = this;
switch (_that) {
case _ParcelDetails():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParcelDetails value)?  $default,){
final _that = this;
switch (_that) {
case _ParcelDetails() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ParcelStop pickup,  ParcelStop dropoff,  String size,  String category,  String description,  String city)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParcelDetails() when $default != null:
return $default(_that.pickup,_that.dropoff,_that.size,_that.category,_that.description,_that.city);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ParcelStop pickup,  ParcelStop dropoff,  String size,  String category,  String description,  String city)  $default,) {final _that = this;
switch (_that) {
case _ParcelDetails():
return $default(_that.pickup,_that.dropoff,_that.size,_that.category,_that.description,_that.city);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ParcelStop pickup,  ParcelStop dropoff,  String size,  String category,  String description,  String city)?  $default,) {final _that = this;
switch (_that) {
case _ParcelDetails() when $default != null:
return $default(_that.pickup,_that.dropoff,_that.size,_that.category,_that.description,_that.city);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParcelDetails implements ParcelDetails {
  const _ParcelDetails({required this.pickup, required this.dropoff, this.size = 'small', this.category = 'other', this.description = '', this.city = 'lagos'});
  factory _ParcelDetails.fromJson(Map<String, dynamic> json) => _$ParcelDetailsFromJson(json);

@override final  ParcelStop pickup;
@override final  ParcelStop dropoff;
@override@JsonKey() final  String size;
@override@JsonKey() final  String category;
@override@JsonKey() final  String description;
@override@JsonKey() final  String city;

/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParcelDetailsCopyWith<_ParcelDetails> get copyWith => __$ParcelDetailsCopyWithImpl<_ParcelDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParcelDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParcelDetails&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.size, size) || other.size == size)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,pickup,dropoff,size,category,description,city);
}

@override
String toString() {
    return 'ParcelDetails(pickup: $pickup, dropoff: $dropoff, size: $size, category: $category, description: $description, city: $city)';
}


}

/// @nodoc
abstract mixin class _$ParcelDetailsCopyWith<$Res> implements $ParcelDetailsCopyWith<$Res> {
  factory _$ParcelDetailsCopyWith(_ParcelDetails value, $Res Function(_ParcelDetails) _then) = __$ParcelDetailsCopyWithImpl;
@override @useResult
$Res call({
 ParcelStop pickup, ParcelStop dropoff, String size, String category, String description, String city
});


@override $ParcelStopCopyWith<$Res> get pickup;@override $ParcelStopCopyWith<$Res> get dropoff;

}
/// @nodoc
class __$ParcelDetailsCopyWithImpl<$Res>
    implements _$ParcelDetailsCopyWith<$Res> {
  __$ParcelDetailsCopyWithImpl(this._self, this._then);

  final _ParcelDetails _self;
  final $Res Function(_ParcelDetails) _then;

/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pickup = null,Object? dropoff = null,Object? size = null,Object? category = null,Object? description = null,Object? city = null,}) {
  return _then(_ParcelDetails(
pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as ParcelStop,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as ParcelStop,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<$Res> get pickup {
  
  return $ParcelStopCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<$Res> get dropoff {
  
  return $ParcelStopCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// @nodoc
mixin _$ParcelQuote {

 String get id; ParcelDetails get details; PriceBreakdown get breakdown; double get distanceKm; int get etaMinutes; DateTime get estimatedDeliveryAt; DateTime? get scheduledFor; DateTime get expiresAt;
/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParcelQuoteCopyWith<ParcelQuote> get copyWith => _$ParcelQuoteCopyWithImpl<ParcelQuote>(this as ParcelQuote, _$identity);

  /// Serializes this ParcelQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParcelQuote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParcelQuote&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.details, _this.details) || other.details == _this.details)&&(identical(other.breakdown, _this.breakdown) || other.breakdown == _this.breakdown)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.etaMinutes, _this.etaMinutes) || other.etaMinutes == _this.etaMinutes)&&(identical(other.estimatedDeliveryAt, _this.estimatedDeliveryAt) || other.estimatedDeliveryAt == _this.estimatedDeliveryAt)&&(identical(other.scheduledFor, _this.scheduledFor) || other.scheduledFor == _this.scheduledFor)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParcelQuote;
  return Object.hash(runtimeType,_this.id,_this.details,_this.breakdown,_this.distanceKm,_this.etaMinutes,_this.estimatedDeliveryAt,_this.scheduledFor,_this.expiresAt);
}

@override
String toString() {
  final _this = this as ParcelQuote;
  return 'ParcelQuote(id: ${_this.id}, details: ${_this.details}, breakdown: ${_this.breakdown}, distanceKm: ${_this.distanceKm}, etaMinutes: ${_this.etaMinutes}, estimatedDeliveryAt: ${_this.estimatedDeliveryAt}, scheduledFor: ${_this.scheduledFor}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $ParcelQuoteCopyWith<$Res>  {
  factory $ParcelQuoteCopyWith(ParcelQuote value, $Res Function(ParcelQuote) _then) = _$ParcelQuoteCopyWithImpl;
@useResult
$Res call({
 String id, ParcelDetails details, PriceBreakdown breakdown, double distanceKm, int etaMinutes, DateTime estimatedDeliveryAt, DateTime? scheduledFor, DateTime expiresAt
});


$ParcelDetailsCopyWith<$Res> get details;$PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class _$ParcelQuoteCopyWithImpl<$Res>
    implements $ParcelQuoteCopyWith<$Res> {
  _$ParcelQuoteCopyWithImpl(this._self, this._then);

  final ParcelQuote _self;
  final $Res Function(ParcelQuote) _then;

/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? details = null,Object? breakdown = null,Object? distanceKm = null,Object? etaMinutes = null,Object? estimatedDeliveryAt = null,Object? scheduledFor = freezed,Object? expiresAt = null,}) {
  return _then(ParcelQuote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as ParcelDetails,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,etaMinutes: null == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int,estimatedDeliveryAt: null == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledFor: freezed == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<$Res> get details {
  
  return $ParcelDetailsCopyWith<$Res>(_self.details, (value) {
    return _then(_self.copyWith(details: value));
  });
}/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// Adds pattern-matching-related methods to [ParcelQuote].
extension ParcelQuotePatterns on ParcelQuote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParcelQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParcelQuote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParcelQuote value)  $default,){
final _that = this;
switch (_that) {
case _ParcelQuote():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParcelQuote value)?  $default,){
final _that = this;
switch (_that) {
case _ParcelQuote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ParcelDetails details,  PriceBreakdown breakdown,  double distanceKm,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime? scheduledFor,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParcelQuote() when $default != null:
return $default(_that.id,_that.details,_that.breakdown,_that.distanceKm,_that.etaMinutes,_that.estimatedDeliveryAt,_that.scheduledFor,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ParcelDetails details,  PriceBreakdown breakdown,  double distanceKm,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime? scheduledFor,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ParcelQuote():
return $default(_that.id,_that.details,_that.breakdown,_that.distanceKm,_that.etaMinutes,_that.estimatedDeliveryAt,_that.scheduledFor,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ParcelDetails details,  PriceBreakdown breakdown,  double distanceKm,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime? scheduledFor,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ParcelQuote() when $default != null:
return $default(_that.id,_that.details,_that.breakdown,_that.distanceKm,_that.etaMinutes,_that.estimatedDeliveryAt,_that.scheduledFor,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParcelQuote implements ParcelQuote {
  const _ParcelQuote({required this.id, required this.details, required this.breakdown, required this.distanceKm, required this.etaMinutes, required this.estimatedDeliveryAt, this.scheduledFor, required this.expiresAt});
  factory _ParcelQuote.fromJson(Map<String, dynamic> json) => _$ParcelQuoteFromJson(json);

@override final  String id;
@override final  ParcelDetails details;
@override final  PriceBreakdown breakdown;
@override final  double distanceKm;
@override final  int etaMinutes;
@override final  DateTime estimatedDeliveryAt;
@override final  DateTime? scheduledFor;
@override final  DateTime expiresAt;

/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParcelQuoteCopyWith<_ParcelQuote> get copyWith => __$ParcelQuoteCopyWithImpl<_ParcelQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParcelQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParcelQuote&&(identical(other.id, id) || other.id == id)&&(identical(other.details, details) || other.details == details)&&(identical(other.breakdown, breakdown) || other.breakdown == breakdown)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.etaMinutes, etaMinutes) || other.etaMinutes == etaMinutes)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt)&&(identical(other.scheduledFor, scheduledFor) || other.scheduledFor == scheduledFor)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,details,breakdown,distanceKm,etaMinutes,estimatedDeliveryAt,scheduledFor,expiresAt);
}

@override
String toString() {
    return 'ParcelQuote(id: $id, details: $details, breakdown: $breakdown, distanceKm: $distanceKm, etaMinutes: $etaMinutes, estimatedDeliveryAt: $estimatedDeliveryAt, scheduledFor: $scheduledFor, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ParcelQuoteCopyWith<$Res> implements $ParcelQuoteCopyWith<$Res> {
  factory _$ParcelQuoteCopyWith(_ParcelQuote value, $Res Function(_ParcelQuote) _then) = __$ParcelQuoteCopyWithImpl;
@override @useResult
$Res call({
 String id, ParcelDetails details, PriceBreakdown breakdown, double distanceKm, int etaMinutes, DateTime estimatedDeliveryAt, DateTime? scheduledFor, DateTime expiresAt
});


@override $ParcelDetailsCopyWith<$Res> get details;@override $PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class __$ParcelQuoteCopyWithImpl<$Res>
    implements _$ParcelQuoteCopyWith<$Res> {
  __$ParcelQuoteCopyWithImpl(this._self, this._then);

  final _ParcelQuote _self;
  final $Res Function(_ParcelQuote) _then;

/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? details = null,Object? breakdown = null,Object? distanceKm = null,Object? etaMinutes = null,Object? estimatedDeliveryAt = null,Object? scheduledFor = freezed,Object? expiresAt = null,}) {
  return _then(_ParcelQuote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as ParcelDetails,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,etaMinutes: null == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int,estimatedDeliveryAt: null == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledFor: freezed == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<$Res> get details {
  
  return $ParcelDetailsCopyWith<$Res>(_self.details, (value) {
    return _then(_self.copyWith(details: value));
  });
}/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// @nodoc
mixin _$VerticalSpend {

 int get orders; int get spentKobo;
/// Create a copy of VerticalSpend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerticalSpendCopyWith<VerticalSpend> get copyWith => _$VerticalSpendCopyWithImpl<VerticalSpend>(this as VerticalSpend, _$identity);

  /// Serializes this VerticalSpend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VerticalSpend;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerticalSpend&&(identical(other.orders, _this.orders) || other.orders == _this.orders)&&(identical(other.spentKobo, _this.spentKobo) || other.spentKobo == _this.spentKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VerticalSpend;
  return Object.hash(runtimeType,_this.orders,_this.spentKobo);
}

@override
String toString() {
  final _this = this as VerticalSpend;
  return 'VerticalSpend(orders: ${_this.orders}, spentKobo: ${_this.spentKobo})';
}


}

/// @nodoc
abstract mixin class $VerticalSpendCopyWith<$Res>  {
  factory $VerticalSpendCopyWith(VerticalSpend value, $Res Function(VerticalSpend) _then) = _$VerticalSpendCopyWithImpl;
@useResult
$Res call({
 int orders, int spentKobo
});




}
/// @nodoc
class _$VerticalSpendCopyWithImpl<$Res>
    implements $VerticalSpendCopyWith<$Res> {
  _$VerticalSpendCopyWithImpl(this._self, this._then);

  final VerticalSpend _self;
  final $Res Function(VerticalSpend) _then;

/// Create a copy of VerticalSpend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orders = null,Object? spentKobo = null,}) {
  return _then(VerticalSpend(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,spentKobo: null == spentKobo ? _self.spentKobo : spentKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VerticalSpend].
extension VerticalSpendPatterns on VerticalSpend {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerticalSpend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerticalSpend() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerticalSpend value)  $default,){
final _that = this;
switch (_that) {
case _VerticalSpend():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerticalSpend value)?  $default,){
final _that = this;
switch (_that) {
case _VerticalSpend() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int orders,  int spentKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerticalSpend() when $default != null:
return $default(_that.orders,_that.spentKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int orders,  int spentKobo)  $default,) {final _that = this;
switch (_that) {
case _VerticalSpend():
return $default(_that.orders,_that.spentKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int orders,  int spentKobo)?  $default,) {final _that = this;
switch (_that) {
case _VerticalSpend() when $default != null:
return $default(_that.orders,_that.spentKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerticalSpend implements VerticalSpend {
  const _VerticalSpend({this.orders = 0, this.spentKobo = 0});
  factory _VerticalSpend.fromJson(Map<String, dynamic> json) => _$VerticalSpendFromJson(json);

@override@JsonKey() final  int orders;
@override@JsonKey() final  int spentKobo;

/// Create a copy of VerticalSpend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerticalSpendCopyWith<_VerticalSpend> get copyWith => __$VerticalSpendCopyWithImpl<_VerticalSpend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerticalSpendToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerticalSpend&&(identical(other.orders, orders) || other.orders == orders)&&(identical(other.spentKobo, spentKobo) || other.spentKobo == spentKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,orders,spentKobo);
}

@override
String toString() {
    return 'VerticalSpend(orders: $orders, spentKobo: $spentKobo)';
}


}

/// @nodoc
abstract mixin class _$VerticalSpendCopyWith<$Res> implements $VerticalSpendCopyWith<$Res> {
  factory _$VerticalSpendCopyWith(_VerticalSpend value, $Res Function(_VerticalSpend) _then) = __$VerticalSpendCopyWithImpl;
@override @useResult
$Res call({
 int orders, int spentKobo
});




}
/// @nodoc
class __$VerticalSpendCopyWithImpl<$Res>
    implements _$VerticalSpendCopyWith<$Res> {
  __$VerticalSpendCopyWithImpl(this._self, this._then);

  final _VerticalSpend _self;
  final $Res Function(_VerticalSpend) _then;

/// Create a copy of VerticalSpend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orders = null,Object? spentKobo = null,}) {
  return _then(_VerticalSpend(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,spentKobo: null == spentKobo ? _self.spentKobo : spentKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FavouriteMerchant {

 String get id; String get name; int get orders;
/// Create a copy of FavouriteMerchant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavouriteMerchantCopyWith<FavouriteMerchant> get copyWith => _$FavouriteMerchantCopyWithImpl<FavouriteMerchant>(this as FavouriteMerchant, _$identity);

  /// Serializes this FavouriteMerchant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FavouriteMerchant;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavouriteMerchant&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.orders, _this.orders) || other.orders == _this.orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavouriteMerchant;
  return Object.hash(runtimeType,_this.id,_this.name,_this.orders);
}

@override
String toString() {
  final _this = this as FavouriteMerchant;
  return 'FavouriteMerchant(id: ${_this.id}, name: ${_this.name}, orders: ${_this.orders})';
}


}

/// @nodoc
abstract mixin class $FavouriteMerchantCopyWith<$Res>  {
  factory $FavouriteMerchantCopyWith(FavouriteMerchant value, $Res Function(FavouriteMerchant) _then) = _$FavouriteMerchantCopyWithImpl;
@useResult
$Res call({
 String id, String name, int orders
});




}
/// @nodoc
class _$FavouriteMerchantCopyWithImpl<$Res>
    implements $FavouriteMerchantCopyWith<$Res> {
  _$FavouriteMerchantCopyWithImpl(this._self, this._then);

  final FavouriteMerchant _self;
  final $Res Function(FavouriteMerchant) _then;

/// Create a copy of FavouriteMerchant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? orders = null,}) {
  return _then(FavouriteMerchant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FavouriteMerchant].
extension FavouriteMerchantPatterns on FavouriteMerchant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavouriteMerchant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavouriteMerchant() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavouriteMerchant value)  $default,){
final _that = this;
switch (_that) {
case _FavouriteMerchant():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavouriteMerchant value)?  $default,){
final _that = this;
switch (_that) {
case _FavouriteMerchant() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int orders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavouriteMerchant() when $default != null:
return $default(_that.id,_that.name,_that.orders);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int orders)  $default,) {final _that = this;
switch (_that) {
case _FavouriteMerchant():
return $default(_that.id,_that.name,_that.orders);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int orders)?  $default,) {final _that = this;
switch (_that) {
case _FavouriteMerchant() when $default != null:
return $default(_that.id,_that.name,_that.orders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavouriteMerchant implements FavouriteMerchant {
  const _FavouriteMerchant({required this.id, required this.name, this.orders = 0});
  factory _FavouriteMerchant.fromJson(Map<String, dynamic> json) => _$FavouriteMerchantFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int orders;

/// Create a copy of FavouriteMerchant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavouriteMerchantCopyWith<_FavouriteMerchant> get copyWith => __$FavouriteMerchantCopyWithImpl<_FavouriteMerchant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavouriteMerchantToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavouriteMerchant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.orders, orders) || other.orders == orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,orders);
}

@override
String toString() {
    return 'FavouriteMerchant(id: $id, name: $name, orders: $orders)';
}


}

/// @nodoc
abstract mixin class _$FavouriteMerchantCopyWith<$Res> implements $FavouriteMerchantCopyWith<$Res> {
  factory _$FavouriteMerchantCopyWith(_FavouriteMerchant value, $Res Function(_FavouriteMerchant) _then) = __$FavouriteMerchantCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int orders
});




}
/// @nodoc
class __$FavouriteMerchantCopyWithImpl<$Res>
    implements _$FavouriteMerchantCopyWith<$Res> {
  __$FavouriteMerchantCopyWithImpl(this._self, this._then);

  final _FavouriteMerchant _self;
  final $Res Function(_FavouriteMerchant) _then;

/// Create a copy of FavouriteMerchant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? orders = null,}) {
  return _then(_FavouriteMerchant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$OrderSummary {

 int get ordersCount; int get completedCount; int get inProgressCount; int get totalSpentKobo; int get thisMonthSpentKobo; int get refundedKobo; Map<String, VerticalSpend> get byVertical; FavouriteMerchant? get favouriteMerchant;
/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderSummaryCopyWith<OrderSummary> get copyWith => _$OrderSummaryCopyWithImpl<OrderSummary>(this as OrderSummary, _$identity);

  /// Serializes this OrderSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OrderSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderSummary&&(identical(other.ordersCount, _this.ordersCount) || other.ordersCount == _this.ordersCount)&&(identical(other.completedCount, _this.completedCount) || other.completedCount == _this.completedCount)&&(identical(other.inProgressCount, _this.inProgressCount) || other.inProgressCount == _this.inProgressCount)&&(identical(other.totalSpentKobo, _this.totalSpentKobo) || other.totalSpentKobo == _this.totalSpentKobo)&&(identical(other.thisMonthSpentKobo, _this.thisMonthSpentKobo) || other.thisMonthSpentKobo == _this.thisMonthSpentKobo)&&(identical(other.refundedKobo, _this.refundedKobo) || other.refundedKobo == _this.refundedKobo)&&const DeepCollectionEquality().equals(other.byVertical, _this.byVertical)&&(identical(other.favouriteMerchant, _this.favouriteMerchant) || other.favouriteMerchant == _this.favouriteMerchant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OrderSummary;
  return Object.hash(runtimeType,_this.ordersCount,_this.completedCount,_this.inProgressCount,_this.totalSpentKobo,_this.thisMonthSpentKobo,_this.refundedKobo,const DeepCollectionEquality().hash(_this.byVertical),_this.favouriteMerchant);
}

@override
String toString() {
  final _this = this as OrderSummary;
  return 'OrderSummary(ordersCount: ${_this.ordersCount}, completedCount: ${_this.completedCount}, inProgressCount: ${_this.inProgressCount}, totalSpentKobo: ${_this.totalSpentKobo}, thisMonthSpentKobo: ${_this.thisMonthSpentKobo}, refundedKobo: ${_this.refundedKobo}, byVertical: ${_this.byVertical}, favouriteMerchant: ${_this.favouriteMerchant})';
}


}

/// @nodoc
abstract mixin class $OrderSummaryCopyWith<$Res>  {
  factory $OrderSummaryCopyWith(OrderSummary value, $Res Function(OrderSummary) _then) = _$OrderSummaryCopyWithImpl;
@useResult
$Res call({
 int ordersCount, int completedCount, int inProgressCount, int totalSpentKobo, int thisMonthSpentKobo, int refundedKobo, Map<String, VerticalSpend> byVertical, FavouriteMerchant? favouriteMerchant
});


$FavouriteMerchantCopyWith<$Res>? get favouriteMerchant;

}
/// @nodoc
class _$OrderSummaryCopyWithImpl<$Res>
    implements $OrderSummaryCopyWith<$Res> {
  _$OrderSummaryCopyWithImpl(this._self, this._then);

  final OrderSummary _self;
  final $Res Function(OrderSummary) _then;

/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ordersCount = null,Object? completedCount = null,Object? inProgressCount = null,Object? totalSpentKobo = null,Object? thisMonthSpentKobo = null,Object? refundedKobo = null,Object? byVertical = null,Object? favouriteMerchant = freezed,}) {
  return _then(OrderSummary(
ordersCount: null == ordersCount ? _self.ordersCount : ordersCount // ignore: cast_nullable_to_non_nullable
as int,completedCount: null == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int,inProgressCount: null == inProgressCount ? _self.inProgressCount : inProgressCount // ignore: cast_nullable_to_non_nullable
as int,totalSpentKobo: null == totalSpentKobo ? _self.totalSpentKobo : totalSpentKobo // ignore: cast_nullable_to_non_nullable
as int,thisMonthSpentKobo: null == thisMonthSpentKobo ? _self.thisMonthSpentKobo : thisMonthSpentKobo // ignore: cast_nullable_to_non_nullable
as int,refundedKobo: null == refundedKobo ? _self.refundedKobo : refundedKobo // ignore: cast_nullable_to_non_nullable
as int,byVertical: null == byVertical ? _self.byVertical : byVertical // ignore: cast_nullable_to_non_nullable
as Map<String, VerticalSpend>,favouriteMerchant: freezed == favouriteMerchant ? _self.favouriteMerchant : favouriteMerchant // ignore: cast_nullable_to_non_nullable
as FavouriteMerchant?,
  ));
}
/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FavouriteMerchantCopyWith<$Res>? get favouriteMerchant {
    if (_self.favouriteMerchant == null) {
    return null;
  }

  return $FavouriteMerchantCopyWith<$Res>(_self.favouriteMerchant!, (value) {
    return _then(_self.copyWith(favouriteMerchant: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderSummary].
extension OrderSummaryPatterns on OrderSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderSummary value)  $default,){
final _that = this;
switch (_that) {
case _OrderSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderSummary value)?  $default,){
final _that = this;
switch (_that) {
case _OrderSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ordersCount,  int completedCount,  int inProgressCount,  int totalSpentKobo,  int thisMonthSpentKobo,  int refundedKobo,  Map<String, VerticalSpend> byVertical,  FavouriteMerchant? favouriteMerchant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderSummary() when $default != null:
return $default(_that.ordersCount,_that.completedCount,_that.inProgressCount,_that.totalSpentKobo,_that.thisMonthSpentKobo,_that.refundedKobo,_that.byVertical,_that.favouriteMerchant);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ordersCount,  int completedCount,  int inProgressCount,  int totalSpentKobo,  int thisMonthSpentKobo,  int refundedKobo,  Map<String, VerticalSpend> byVertical,  FavouriteMerchant? favouriteMerchant)  $default,) {final _that = this;
switch (_that) {
case _OrderSummary():
return $default(_that.ordersCount,_that.completedCount,_that.inProgressCount,_that.totalSpentKobo,_that.thisMonthSpentKobo,_that.refundedKobo,_that.byVertical,_that.favouriteMerchant);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ordersCount,  int completedCount,  int inProgressCount,  int totalSpentKobo,  int thisMonthSpentKobo,  int refundedKobo,  Map<String, VerticalSpend> byVertical,  FavouriteMerchant? favouriteMerchant)?  $default,) {final _that = this;
switch (_that) {
case _OrderSummary() when $default != null:
return $default(_that.ordersCount,_that.completedCount,_that.inProgressCount,_that.totalSpentKobo,_that.thisMonthSpentKobo,_that.refundedKobo,_that.byVertical,_that.favouriteMerchant);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderSummary implements OrderSummary {
  const _OrderSummary({this.ordersCount = 0, this.completedCount = 0, this.inProgressCount = 0, this.totalSpentKobo = 0, this.thisMonthSpentKobo = 0, this.refundedKobo = 0,  Map<String, VerticalSpend> byVertical = const <String, VerticalSpend>{}, this.favouriteMerchant}): _byVertical = byVertical;
  factory _OrderSummary.fromJson(Map<String, dynamic> json) => _$OrderSummaryFromJson(json);

@override@JsonKey() final  int ordersCount;
@override@JsonKey() final  int completedCount;
@override@JsonKey() final  int inProgressCount;
@override@JsonKey() final  int totalSpentKobo;
@override@JsonKey() final  int thisMonthSpentKobo;
@override@JsonKey() final  int refundedKobo;
 final  Map<String, VerticalSpend> _byVertical;
@override@JsonKey() Map<String, VerticalSpend> get byVertical {
  if (_byVertical is EqualUnmodifiableMapView) return _byVertical;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byVertical);
}

@override final  FavouriteMerchant? favouriteMerchant;

/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderSummaryCopyWith<_OrderSummary> get copyWith => __$OrderSummaryCopyWithImpl<_OrderSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderSummary&&(identical(other.ordersCount, ordersCount) || other.ordersCount == ordersCount)&&(identical(other.completedCount, completedCount) || other.completedCount == completedCount)&&(identical(other.inProgressCount, inProgressCount) || other.inProgressCount == inProgressCount)&&(identical(other.totalSpentKobo, totalSpentKobo) || other.totalSpentKobo == totalSpentKobo)&&(identical(other.thisMonthSpentKobo, thisMonthSpentKobo) || other.thisMonthSpentKobo == thisMonthSpentKobo)&&(identical(other.refundedKobo, refundedKobo) || other.refundedKobo == refundedKobo)&&const DeepCollectionEquality().equals(other.byVertical, _byVertical)&&(identical(other.favouriteMerchant, favouriteMerchant) || other.favouriteMerchant == favouriteMerchant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ordersCount,completedCount,inProgressCount,totalSpentKobo,thisMonthSpentKobo,refundedKobo,const DeepCollectionEquality().hash(_byVertical),favouriteMerchant);
}

@override
String toString() {
    return 'OrderSummary(ordersCount: $ordersCount, completedCount: $completedCount, inProgressCount: $inProgressCount, totalSpentKobo: $totalSpentKobo, thisMonthSpentKobo: $thisMonthSpentKobo, refundedKobo: $refundedKobo, byVertical: $byVertical, favouriteMerchant: $favouriteMerchant)';
}


}

/// @nodoc
abstract mixin class _$OrderSummaryCopyWith<$Res> implements $OrderSummaryCopyWith<$Res> {
  factory _$OrderSummaryCopyWith(_OrderSummary value, $Res Function(_OrderSummary) _then) = __$OrderSummaryCopyWithImpl;
@override @useResult
$Res call({
 int ordersCount, int completedCount, int inProgressCount, int totalSpentKobo, int thisMonthSpentKobo, int refundedKobo, Map<String, VerticalSpend> byVertical, FavouriteMerchant? favouriteMerchant
});


@override $FavouriteMerchantCopyWith<$Res>? get favouriteMerchant;

}
/// @nodoc
class __$OrderSummaryCopyWithImpl<$Res>
    implements _$OrderSummaryCopyWith<$Res> {
  __$OrderSummaryCopyWithImpl(this._self, this._then);

  final _OrderSummary _self;
  final $Res Function(_OrderSummary) _then;

/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ordersCount = null,Object? completedCount = null,Object? inProgressCount = null,Object? totalSpentKobo = null,Object? thisMonthSpentKobo = null,Object? refundedKobo = null,Object? byVertical = null,Object? favouriteMerchant = freezed,}) {
  return _then(_OrderSummary(
ordersCount: null == ordersCount ? _self.ordersCount : ordersCount // ignore: cast_nullable_to_non_nullable
as int,completedCount: null == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int,inProgressCount: null == inProgressCount ? _self.inProgressCount : inProgressCount // ignore: cast_nullable_to_non_nullable
as int,totalSpentKobo: null == totalSpentKobo ? _self.totalSpentKobo : totalSpentKobo // ignore: cast_nullable_to_non_nullable
as int,thisMonthSpentKobo: null == thisMonthSpentKobo ? _self.thisMonthSpentKobo : thisMonthSpentKobo // ignore: cast_nullable_to_non_nullable
as int,refundedKobo: null == refundedKobo ? _self.refundedKobo : refundedKobo // ignore: cast_nullable_to_non_nullable
as int,byVertical: null == byVertical ? _self._byVertical : byVertical // ignore: cast_nullable_to_non_nullable
as Map<String, VerticalSpend>,favouriteMerchant: freezed == favouriteMerchant ? _self.favouriteMerchant : favouriteMerchant // ignore: cast_nullable_to_non_nullable
as FavouriteMerchant?,
  ));
}

/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FavouriteMerchantCopyWith<$Res>? get favouriteMerchant {
    if (_self.favouriteMerchant == null) {
    return null;
  }

  return $FavouriteMerchantCopyWith<$Res>(_self.favouriteMerchant!, (value) {
    return _then(_self.copyWith(favouriteMerchant: value));
  });
}
}


/// @nodoc
mixin _$SupportContacts {

 String get whatsapp; String get phone; String get email; String get hours; bool get placeholders;
/// Create a copy of SupportContacts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportContactsCopyWith<SupportContacts> get copyWith => _$SupportContactsCopyWithImpl<SupportContacts>(this as SupportContacts, _$identity);

  /// Serializes this SupportContacts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SupportContacts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportContacts&&(identical(other.whatsapp, _this.whatsapp) || other.whatsapp == _this.whatsapp)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.hours, _this.hours) || other.hours == _this.hours)&&(identical(other.placeholders, _this.placeholders) || other.placeholders == _this.placeholders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupportContacts;
  return Object.hash(runtimeType,_this.whatsapp,_this.phone,_this.email,_this.hours,_this.placeholders);
}

@override
String toString() {
  final _this = this as SupportContacts;
  return 'SupportContacts(whatsapp: ${_this.whatsapp}, phone: ${_this.phone}, email: ${_this.email}, hours: ${_this.hours}, placeholders: ${_this.placeholders})';
}


}

/// @nodoc
abstract mixin class $SupportContactsCopyWith<$Res>  {
  factory $SupportContactsCopyWith(SupportContacts value, $Res Function(SupportContacts) _then) = _$SupportContactsCopyWithImpl;
@useResult
$Res call({
 String whatsapp, String phone, String email, String hours, bool placeholders
});




}
/// @nodoc
class _$SupportContactsCopyWithImpl<$Res>
    implements $SupportContactsCopyWith<$Res> {
  _$SupportContactsCopyWithImpl(this._self, this._then);

  final SupportContacts _self;
  final $Res Function(SupportContacts) _then;

/// Create a copy of SupportContacts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? whatsapp = null,Object? phone = null,Object? email = null,Object? hours = null,Object? placeholders = null,}) {
  return _then(SupportContacts(
whatsapp: null == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as String,placeholders: null == placeholders ? _self.placeholders : placeholders // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportContacts].
extension SupportContactsPatterns on SupportContacts {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportContacts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportContacts() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportContacts value)  $default,){
final _that = this;
switch (_that) {
case _SupportContacts():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportContacts value)?  $default,){
final _that = this;
switch (_that) {
case _SupportContacts() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String whatsapp,  String phone,  String email,  String hours,  bool placeholders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportContacts() when $default != null:
return $default(_that.whatsapp,_that.phone,_that.email,_that.hours,_that.placeholders);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String whatsapp,  String phone,  String email,  String hours,  bool placeholders)  $default,) {final _that = this;
switch (_that) {
case _SupportContacts():
return $default(_that.whatsapp,_that.phone,_that.email,_that.hours,_that.placeholders);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String whatsapp,  String phone,  String email,  String hours,  bool placeholders)?  $default,) {final _that = this;
switch (_that) {
case _SupportContacts() when $default != null:
return $default(_that.whatsapp,_that.phone,_that.email,_that.hours,_that.placeholders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportContacts implements SupportContacts {
  const _SupportContacts({this.whatsapp = '', this.phone = '', this.email = '', this.hours = '', this.placeholders = true});
  factory _SupportContacts.fromJson(Map<String, dynamic> json) => _$SupportContactsFromJson(json);

@override@JsonKey() final  String whatsapp;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String email;
@override@JsonKey() final  String hours;
@override@JsonKey() final  bool placeholders;

/// Create a copy of SupportContacts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportContactsCopyWith<_SupportContacts> get copyWith => __$SupportContactsCopyWithImpl<_SupportContacts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportContactsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportContacts&&(identical(other.whatsapp, whatsapp) || other.whatsapp == whatsapp)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.placeholders, placeholders) || other.placeholders == placeholders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,whatsapp,phone,email,hours,placeholders);
}

@override
String toString() {
    return 'SupportContacts(whatsapp: $whatsapp, phone: $phone, email: $email, hours: $hours, placeholders: $placeholders)';
}


}

/// @nodoc
abstract mixin class _$SupportContactsCopyWith<$Res> implements $SupportContactsCopyWith<$Res> {
  factory _$SupportContactsCopyWith(_SupportContacts value, $Res Function(_SupportContacts) _then) = __$SupportContactsCopyWithImpl;
@override @useResult
$Res call({
 String whatsapp, String phone, String email, String hours, bool placeholders
});




}
/// @nodoc
class __$SupportContactsCopyWithImpl<$Res>
    implements _$SupportContactsCopyWith<$Res> {
  __$SupportContactsCopyWithImpl(this._self, this._then);

  final _SupportContacts _self;
  final $Res Function(_SupportContacts) _then;

/// Create a copy of SupportContacts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? whatsapp = null,Object? phone = null,Object? email = null,Object? hours = null,Object? placeholders = null,}) {
  return _then(_SupportContacts(
whatsapp: null == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as String,placeholders: null == placeholders ? _self.placeholders : placeholders // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
