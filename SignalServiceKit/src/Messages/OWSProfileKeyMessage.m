//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

#import "OWSProfileKeyMessage.h"
#import "ProfileManagerProtocol.h"
#import "ProtoUtils.h"
#import "SSKEnvironment.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation OWSProfileKeyMessage

- (instancetype)initWithTimestamp:(uint64_t)timestamp inThread:(TSThread *)thread
{
    TSOutgoingMessageBuilder *messageBuilder = [[TSOutgoingMessageBuilder alloc] initWithThread:thread];
    messageBuilder.timestamp = timestamp;
    return [super initOutgoingMessageWithBuilder:messageBuilder];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

- (BOOL)shouldBeSaved
{
    return NO;
}

- (BOOL)shouldSyncTranscript
{
    return NO;
}

- (nullable SSKProtoDataMessage *)buildDataMessage:(SignalServiceAddress *_Nullable)address
                                            thread:(TSThread *)thread
                                       transaction:(SDSAnyReadTransaction *)transaction
{
    OWSAssertDebug(thread != nil);

    SSKProtoDataMessageBuilder *_Nullable builder = [self dataMessageBuilderWithThread:thread transaction:transaction];
    if (!builder) {
        OWSFailDebug(@"could not build protobuf.");
        return nil;
    }
    [builder setTimestamp:self.timestamp];
    [ProtoUtils addLocalProfileKeyToDataMessageBuilder:builder];
    [builder setFlags:SSKProtoDataMessageFlagsProfileKeyUpdate];

    if (address.isValid) {
        // Once we've shared our profile key with a user (perhaps due to being
        // a member of a whitelisted group), make sure they're whitelisted.
        id<ProfileManagerProtocol> profileManager = SSKEnvironment.shared.profileManager;
        [profileManager addUserToProfileWhitelist:address];
    }

    NSError *error;
    SSKProtoDataMessage *_Nullable dataProto = [builder buildAndReturnError:&error];
    if (error || !dataProto) {
        OWSFailDebug(@"could not build protobuf: %@", error);
        return nil;
    }
    return dataProto;
}

@end

NS_ASSUME_NONNULL_END
