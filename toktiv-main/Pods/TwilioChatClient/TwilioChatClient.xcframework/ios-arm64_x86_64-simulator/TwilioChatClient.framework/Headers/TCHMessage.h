//
//  TCHMessage.h
//  Twilio Chat Client
//
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TCHConstants.h"
#import "TCHJsonAttributes.h"

@class TCHMember;

/** Representation of a Message on a chat channel. */
__attribute__((visibility("default")))
@interface TCHMessage : NSObject

/** The unique identifier for this message. */
@property (nonatomic, copy, readonly, nullable) NSString *sid;

/** Index of Message in the Channel's messages stream.

 By design of the chat system the message indices may have arbitrary gaps between them,
 that does not necessarily mean they were deleted or otherwise modified - just that
 messages may have non-contiguous indices even if they are sent immediately one after another.

 Trying to use indices for some calculations is going to be unreliable.

 To calculate the number of unread messages it is better to use the consumption horizon API.
 See [TCHChannel getUnconsumedMessagesCountWithCompletion:] for details.
 */
@property (nonatomic, copy, readonly, nullable) NSNumber *index;

/** The identity of the author of the message. */
@property (nonatomic, copy, readonly, nullable) NSString *author;

/** The body of the message. */
@property (nonatomic, copy, readonly, nullable) NSString *body;

/** The type of the message. */
@property (nonatomic, assign, readonly) TCHMessageType messageType;

/** The media sid if this message has a multimedia attachment, otherwise nil. */
@property (nonatomic, copy, readonly, nullable) NSString *mediaSid;

/** The size of the attached media if present, otherwise 0. */
@property (nonatomic, assign, readonly) NSUInteger mediaSize;

/** The mime type of the attached media if present and specified at creation, otherwise nil. */
@property (nonatomic, copy, readonly, nullable) NSString *mediaType;

/** The suggested filename the attached media if present and specified at creation, otherwise nil. */
@property (nonatomic, copy, readonly, nullable) NSString *mediaFilename;

/** The SID of the member this message is sent by. */
@property (nonatomic, copy, readonly, nullable) NSString *memberSid;

/** The member this message is sent by. */
@property (nonatomic, copy, readonly, nullable) TCHMember *member;

/** The message creation date. */
@property (nonatomic, copy, readonly, nullable) NSString *dateCreated;

/** The message creation date as an NSDate. */
@property (nonatomic, strong, readonly, nullable) NSDate *dateCreatedAsDate;

/** The message last update date. */
@property (nonatomic, copy, readonly, nullable) NSString *dateUpdated;

/** The message last update date as an NSDate. */
@property (nonatomic, strong, readonly, nullable) NSDate *dateUpdatedAsDate;

/** The identity of the user who updated the message. */
@property (nonatomic, copy, readonly, nullable) NSString *lastUpdatedBy;

/** Update the body of this message
 
 @param body The new body for this message.
 @param completion Completion block that will specify the result of the operation.
 */
- (void)updateBody:(nonnull NSString *)body
        completion:(nullable TCHCompletion)completion;

/** Return this message's attributes.
 
 @return The developer-defined extensible attributes for this message.
 */
- (nullable TCHJsonAttributes *)attributes;

/** Set this message's attributes.
 
 @param attributes The new developer-defined extensible attributes for this message. (Supported types are NSString, NSNumber, NSArray, NSDictionary and NSNull)
 @param completion Completion block that will specify the result of the operation.
 */
- (void)setAttributes:(nullable TCHJsonAttributes *)attributes
           completion:(nullable TCHCompletion)completion;

/** Determine if the message has media content.
 
 @return A true boolean value if this message has media, false otherwise.
 */
- (BOOL)hasMedia;

/** Retrieve this message's media temporary link (if there is any media attached).
 This URL is impermanent, it expires in several minutes.
 If the link became invalid (expired), need to re-request the new one.
 It is user's responsibility to timely download media data by this link.

 @param completion Completion block that will specify the requested URL. If no completion block is specified, no operation will be executed.
 */
- (void)getMediaContentTemporaryUrlWithCompletion:(nonnull TCHStringCompletion)completion;

/** Retrieve this message's attached media, if there is any.
 
 @param mediaStream An instance of NSOutputStream you create that the media will be written to.
 @param onStarted Callback block which is called when the media download starts.
 @param onProgress Callback block which is called as download progresses with the most recent number of bytes read.
 @param onCompleted Callback block which is called upon media download completion with the media's sid if successful.
 @param completion Completion block that will specify the result of the operation.

 @deprecated See getMediaContentTemporaryUrlWithCompletion:
 */
- (void)getMediaWithOutputStream:(nonnull NSOutputStream *)mediaStream
                       onStarted:(nullable TCHMediaOnStarted)onStarted
                      onProgress:(nullable TCHMediaOnProgress)onProgress
                     onCompleted:(nullable TCHMediaOnCompleted)onCompleted
                      completion:(nullable TCHCompletion)completion
        __attribute__((deprecated("getMediaWithOutputStream: has been deprecated, please use getMediaContentTemporaryUrlWithCompletion:completion instead and download by URL")));

@end
