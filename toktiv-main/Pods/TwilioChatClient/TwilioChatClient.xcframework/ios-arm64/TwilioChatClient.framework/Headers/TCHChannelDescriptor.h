//
//  TCHChannelDescriptor.h
//  Twilio Chat Client
//
//  Copyright (c) 2018 Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TCHConstants.h"
#import "TCHJsonAttributes.h"

/** A snaphshot of a publicly available channel.  The data and counts on this object are not updated
beyond initial fetch so should not be cached long term. */
__attribute__((visibility("default")))
@interface TCHChannelDescriptor : NSObject

/** The unique identifier for this channel. */
@property (nonatomic, copy, readonly, nullable) NSString *sid;

/** The friendly name for this channel. */
@property (nonatomic, copy, readonly, nullable) NSString *friendlyName;

/** The unique name for this channel. */
@property (nonatomic, copy, readonly, nullable) NSString *uniqueName;

/** The timestamp the channel was created as an NSDate. */
@property (nonatomic, strong, readonly, nullable) NSDate *dateCreated;

/** The identity of the channel's creator. */
@property (nonatomic, copy, readonly, nullable) NSString *createdBy;

/** The timestamp the channel was last updated as an NSDate. */
@property (nonatomic, strong, readonly, nullable) NSDate *dateUpdated;

/** Return this channel's attributes.
 
 @return The developer-defined extensible attributes for this channel.
 */
- (nullable TCHJsonAttributes *)attributes;

/** The number of messages on this channel.
 
 @return The requested count.
 */
- (NSUInteger)messagesCount;

/** The number of members on this channel.
 
 @return The requested count.
 */
- (NSUInteger)membersCount;

/** The number of unconsumed messages on this channel for the current user.
  See [TCHChannel getUnconsumedMessagesCountWithCompletion:]
  and https://www.twilio.com/docs/chat/consumption-horizon for more info.

 @return The requested count or null if last consumed message index has not been set.
 */
- (nullable NSNumber *)unconsumedMessagesCount;

/** Obtains the full channel object for this channel descriptor.
 
 @param completion Completion block that will specify the result of the operation and a reference to the channel.
 */
- (void)channelWithCompletion:(nonnull TCHChannelCompletion)completion;

@end
