// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "BGDatabase.h"

@implementation BGDatabase

+ (NSString *)keyForBurstIdentifier:(NSString *)burstIdentifier {
    return [NSString stringWithFormat:@"burstInfo-%@", burstIdentifier];
    
}

+ (BGBurstInfo *)burstInfoForBurstIdentifier:(NSString *)burstIdentifier {
    NSString *key = [self keyForBurstIdentifier:burstIdentifier];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults objectForKey:key];
    return dictionary ? [[BGBurstInfo alloc] initWithDictionary:dictionary] : nil;
}

+ (void)saveBurstInfo:(BGBurstInfo *)burstInfo {
    NSString *key = [self keyForBurstIdentifier:burstInfo.burstIdentifier];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:burstInfo.dictionaryRepresentation forKey:key];
    [defaults synchronize];
}

@end
