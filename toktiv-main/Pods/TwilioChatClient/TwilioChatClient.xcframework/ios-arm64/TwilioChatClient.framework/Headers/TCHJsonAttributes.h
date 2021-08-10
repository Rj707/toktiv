//
//  TCHJsonAttributes.h
//  Twilio Chat Client
//
//  Copyright (c) Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Attributes representation, can be set to Channel, User, Member or Message. */
__attribute__((visibility("default")))
@interface TCHJsonAttributes: NSObject

- (_Null_unspecified instancetype)init NS_UNAVAILABLE;
+ (_Null_unspecified instancetype)new NS_UNAVAILABLE;

/** Initialize TCHJsonAttributes with NSDictionary

@param dictionary The data to set attributes to.
 */
- (_Null_unspecified instancetype)initWithDictionary:(nonnull NSDictionary *)dictionary;
/** Initialize TCHJsonAttributes with NSArray

@param array The data to set attributes to.
 */
- (_Null_unspecified instancetype)initWithArray:(nonnull NSArray *)array;
/** Initialize TCHJsonAttributes with NSString

@param string The data to set attributes to.
 */
- (_Null_unspecified instancetype)initWithString:(nonnull NSString *)string;
/** Initialize TCHJsonAttributes with NSNumber

@param number The data to set attributes to.
 */
- (_Null_unspecified instancetype)initWithNumber:(nonnull NSNumber *)number;

/** Return true if given attributes are type of NSDictionary */
@property (readonly) BOOL isDictionary;
/** Return true if given attributes are type of NSArray */
@property (readonly) BOOL isArray;
/** Return true if given attributes are type of NSString */
@property (readonly) BOOL isString;
/** Return true if given attributes are type of NSNumber */
@property (readonly) BOOL isNumber;
/** Return true if given attributes are type of NSNull */
@property (readonly) BOOL isNull;

/** Return dictionary data of attributes if type of attributes is NSDictionary otherwise returns nil*/
@property (readonly, nullable) NSDictionary *dictionary;
/** Return array data of attributes if type of attributes is NSArray otherwise returns nil */
@property (readonly, nullable) NSArray *array;
/** Return string data of attributes if type of attributes is NSString otherwise returns nil */
@property (readonly, nullable) NSString *string;
/** Return number data of attributes if type of attributes is NSNumber otherwise returns nil */
@property (readonly, nullable) NSNumber *number;

@end
