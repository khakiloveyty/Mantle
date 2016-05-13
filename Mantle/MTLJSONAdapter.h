//
//  MTLJSONAdapter.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLDefines.h"

@protocol MTLModel;
@protocol MTLTransformerErrorHandling;

NS_ASSUME_NONNULL_BEGIN

/// A MTLModel object that supports being parsed from and serialized to JSON.
NS_REFINED_FOR_SWIFT
@protocol MTLJSONSerializing <MTLModel>
@required

/// Specifies how to map property keys to different key paths in JSON.
///
/// Subclasses overriding this method should combine their values with those of
/// `super`.
///
/// Values in the dictionary can either be key paths in the JSON representation
/// of the receiver or an array of such key paths. If an array is used, the
/// deserialized value will be a dictionary containing all of the keys in the
/// array.
///
/// Any keys omitted will not participate in JSON serialization.
///
/// Examples
///
///     + (NSDictionary *)JSONKeyPathsByPropertyKey {
///         return @{
///             @"name": @"POI.name",
///             @"point": @[ @"latitude", @"longitude" ],
///             @"starred": @"starred"
///         };
///     }
///
/// This will map the `starred` property to `JSONDictionary[@"starred"]`, `name`
/// to `JSONDictionary[@"POI"][@"name"]` and `point` to a dictionary equivalent
/// to:
///
///     @{
///         @"latitude": JSONDictionary[@"latitude"],
///         @"longitude": JSONDictionary[@"longitude"]
///     }
///
/// Returns a dictionary mapping property keys to one or multiple JSON key paths
/// (as strings or arrays of strings).
+ (NSDictionary<NSString *, id> *)JSONKeyPathsByPropertyKey NS_SWIFT_UNAVAILABLE("Use MTLJSONSerializing.JSONKeyPaths static member");

@optional

/// Specifies how to convert a JSON value to the given property key. If
/// reversible, the transformer will also be used to convert the property value
/// back to JSON.
///
/// If the receiver implements a `+<key>JSONTransformer` method, MTLJSONAdapter
/// will use the result of that method instead.
///
/// Returns a value transformer, or nil if no transformation should be performed.
+ (nullable NSValueTransformer *)JSONTransformerForKey:(NSString *)key;

/// Overridden to parse the receiver as a different class, based on information
/// in the provided dictionary.
///
/// This is mostly useful for class clusters, where the abstract base class would
/// be passed into -[MTLJSONAdapter initWithJSONDictionary:modelClass:], but
/// a subclass should be instantiated instead.
///
/// JSONDictionary - The JSON dictionary that will be parsed.
///
/// Returns the class that should be parsed (which may be the receiver), or nil
/// to abort parsing (e.g., if the data is invalid).
+ (nullable Class)classForParsingJSONDictionary:(NSDictionary<NSString *, id> *)JSONDictionary;

@end

/// The domain for errors originating from MTLJSONAdapter.
extern NSString * const MTLJSONAdapterErrorDomain;

/// +classForParsingJSONDictionary: returned nil for the given dictionary.
extern const NSInteger MTLJSONAdapterErrorNoClassFound;

/// The provided JSONDictionary is not valid.
extern const NSInteger MTLJSONAdapterErrorInvalidJSONDictionary;

/// The model's implementation of +JSONKeyPathsByPropertyKey included a key which
/// does not actually exist in +propertyKeys.
extern const NSInteger MTLJSONAdapterErrorInvalidJSONMapping;

/// An exception was thrown and caught.
extern const NSInteger MTLJSONAdapterErrorExceptionThrown;

/// Associated with the NSException that was caught.
extern NSString * const MTLJSONAdapterThrownExceptionErrorKey;

/// Converts a MTLModel object to and from a JSON dictionary.
NS_REFINED_FOR_SWIFT
@interface MTLJSONAdapter<__covariant Model: id<MTLJSONSerializing>> : NSObject

/// Attempts to parse a JSON dictionary into a model object.
///
/// modelClass     - The MTLModel subclass to attempt to parse from the JSON.
///                  This class must conform to <MTLJSONSerializing>. This
///                  argument must not be nil.
/// JSONDictionary - A dictionary representing JSON data. This should match the
///                  format returned by NSJSONSerialization. If this argument is
///                  nil, the method returns nil.
/// error          - If not NULL, this may be set to an error that occurs during
///                  parsing or initializing an instance of `modelClass`.
///
/// Returns an instance of `modelClass` upon success, or nil if a parsing error
/// occurred.
+ (nullable __kindof Model)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary<NSString *, id> *)JSONDictionary error:(NSError **)error NS_REFINED_FOR_SWIFT;

/// Attempts to parse an array of JSON dictionary objects into a model objects
/// of a specific class.
///
/// modelClass - The MTLModel subclass to attempt to parse from the JSON. This
///              class must conform to <MTLJSONSerializing>. This argument must
///              not be nil.
/// JSONArray  - A array of dictionaries representing JSON data. This should
///              match the format returned by NSJSONSerialization. If this
///              argument is nil, the method returns nil.
/// error      - If not NULL, this may be set to an error that occurs during
///              parsing or initializing an any of the instances of
///              `modelClass`.
///
/// Returns an array of `modelClass` instances upon success, or nil if a parsing
/// error occurred.
+ (nullable NSArray<__kindof Model> *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray<NSDictionary<NSString *, id> *> *)JSONArray error:(NSError **)error NS_REFINED_FOR_SWIFT;

/// Converts a model into a JSON representation.
///
/// model - The model to use for JSON serialization. This argument must not be
///         nil.
/// error - If not NULL, this may be set to an error that occurs during
///         serializing.
///
/// Returns a JSON dictionary, or nil if a serialization error occurred.
+ (nullable NSDictionary<NSString *, id> *)JSONDictionaryFromModel:(Model)model error:(NSError **)error NS_REFINED_FOR_SWIFT;

/// Converts a array of models into a JSON representation.
///
/// models - The array of models to use for JSON serialization. This argument
///          must not be nil.
/// error  - If not NULL, this may be set to an error that occurs during
///          serializing.
///
/// Returns a JSON array, or nil if a serialization error occurred for any
/// model.
+ (nullable NSArray<NSDictionary<NSString *, id> *> *)JSONArrayFromModels:(NSArray<Model> *)models error:(NSError **)error NS_REFINED_FOR_SWIFT;

/// This initializer may not be used.
- (instancetype)init NS_UNAVAILABLE NS_SWIFT_NAME(init(unavailable:));

/// Initializes the receiver with a given model class.
///
/// modelClass - The MTLModel subclass to attempt to parse from the JSON and
///              back. This class must conform to <MTLJSONSerializing>. This
///              argument must not be nil.
///
/// Returns an initialized adapter.
- (instancetype)initWithModelClass:(Class)modelClass NS_REFINED_FOR_SWIFT;

/// Deserializes a model from a JSON dictionary.
///
/// The adapter will call -validate: on the model and consider it an error if the
/// validation fails.
///
/// JSONDictionary - A dictionary representing JSON data. This should match the
///                  format returned by NSJSONSerialization. This argument must
///                  not be nil.
/// error          - If not NULL, this may be set to an error that occurs during
///                  deserializing or validation.
///
/// Returns a model object, or nil if a deserialization error occurred or the
/// model did not validate successfully.
- (nullable __kindof Model)modelFromJSONDictionary:(NSDictionary<NSString *, id> *)JSONDictionary error:(NSError **)error NS_REFINED_FOR_SWIFT;

/// Serializes a model into JSON.
///
/// model - The model to use for JSON serialization. This argument must not be
///         nil.
/// error - If not NULL, this may be set to an error that occurs during
///         serializing.
///
/// Returns a model object, or nil if a serialization error occurred.
- (nullable NSDictionary<NSString *, id> *)JSONDictionaryFromModel:(Model)model error:(NSError **)error NS_REFINED_FOR_SWIFT;

/// Filters the property keys used to serialize a given model.
///
/// propertyKeys - The property keys for which `model` provides a mapping.
/// model        - The model being serialized.
///
/// Subclasses may override this method to determine which property keys should
/// be used when serializing `model`. For instance, this method can be used to
/// create more efficient updates of server-side resources.
///
/// The default implementation simply returns `propertyKeys`.
///
/// Returns a subset of propertyKeys that should be serialized for a given
/// model.
- (NSSet<NSString *> *)serializablePropertyKeys:(NSSet<NSString *> *)propertyKeys forModel:(Model)model NS_REFINED_FOR_SWIFT;

/// An optional value transformer that should be used for properties of the given
/// class.
///
/// A value transformer returned by the model's +JSONTransformerForKey: method
/// is given precedence over the one returned by this method.
///
/// The default implementation invokes `+<class>JSONTransformer` on the
/// receiver if it's implemented. It supports NSURL conversion through
/// +NSURLJSONTransformer.
///
/// modelClass - The class of the property to serialize. This property must not be
///              nil.
///
/// Returns a value transformer or nil if no transformation should be used.
+ (nullable NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)modelClass;

/// A value transformer that should be used for a properties of the given
/// primitive type.
///
/// If `objCType` matches @encode(id), the value transformer returned by
/// +transformerForModelPropertiesOfClass: is used instead.
///
/// The default implementation transforms properties that match @encode(BOOL)
/// using the MTLBooleanValueTransformerName transformer.
///
/// objCType - The type encoding for the value of this property. This is the type
///            as it would be returned by the @encode() directive.
///
/// Returns a value transformer or nil if no transformation should be used.
+ (nullable NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType;

@end

@interface MTLJSONAdapter (ValueTransformers)

/// Creates a reversible transformer to convert a JSON dictionary into a MTLModel
/// object, and vice-versa.
///
/// modelClass - The MTLModel subclass to attempt to parse from the JSON. This
///              class must conform to <MTLJSONSerializing>. This argument must
///              not be nil.
///
/// Returns a reversible transformer which uses the class of the receiver for
/// transforming values back and forth.
+ (NSValueTransformer *)dictionaryTransformerWithModelClass:(Class)modelClass NS_SWIFT_UNAVAILABLE("Use MTLJSONAdapter.dictionaryTransformer(forType:)");

/// Creates a reversible transformer to convert an array of JSON dictionaries
/// into an array of MTLModel objects, and vice-versa.
///
/// modelClass - The MTLModel subclass to attempt to parse from each JSON
///              dictionary. This class must conform to <MTLJSONSerializing>.
///              This argument must not be nil.
///
/// Returns a reversible transformer which uses the class of the receiver for
/// transforming array elements back and forth.
+ (NSValueTransformer *)arrayTransformerWithModelClass:(Class)modelClass NS_SWIFT_UNAVAILABLE("Use MTLJSONAdapter.arrayTransformer(forType:)");

/// This value transformer is used by MTLJSONAdapter to automatically convert
/// NSURL properties to JSON strings and vice versa.
+ (NSValueTransformer *)NSURLJSONTransformer NS_SWIFT_UNAVAILABLE("Use MTLJSONAdapter.URLTransformer()");

@end

@class MTLModel;

@interface MTLJSONAdapter (Deprecated)

@property (nonatomic, strong, readonly) id<MTLJSONSerializing> model MANTLE_UNAVAILABLE("Replaced by -modelFromJSONDictionary:error:");

+ (nullable NSArray<NSDictionary<NSString *, id> *> *)JSONArrayFromModels:(NSArray *)models MANTLE_DEPRECATED("Replaced by +JSONArrayFromModels:error:");

+ (nullable NSDictionary<NSString *, id> *)JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)model MANTLE_DEPRECATED("Replaced by +JSONDictionaryFromModel:error:");

- (nullable NSDictionary<NSString *, id> *)JSONDictionary MANTLE_UNAVAILABLE("Replaced by -JSONDictionaryFromModel:error:");
- (null_unspecified NSString *)JSONKeyPathForPropertyKey:(NSString *)key MANTLE_UNAVAILABLE("Replaced by -serializablePropertyKeys:forModel:");
- (nullable id)initWithJSONDictionary:(NSDictionary<NSString *, id> *)JSONDictionary modelClass:(Class)modelClass error:(NSError **)error MANTLE_UNAVAILABLE("Replaced by -initWithModelClass:");
- (nullable id)initWithModel:(id<MTLJSONSerializing>)model MANTLE_UNAVAILABLE("Replaced by -initWithModelClass:");
- (nullable NSDictionary<NSString *, id> *)serializeToJSONDictionary:(NSError **)error MANTLE_UNAVAILABLE("Replaced by -JSONDictionaryFromModel:error:");

@end

NS_ASSUME_NONNULL_END
