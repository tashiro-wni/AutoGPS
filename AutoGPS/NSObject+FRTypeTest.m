#import "NSObject+FRTypeTest.h"

@implementation NSObject (FRTypeTest)

- (BOOL)fr_isNSString
{
    return [self isKindOfClass:[NSString class]];
}

- (BOOL)fr_isNSArray
{
    return [self isKindOfClass:[NSArray class]];
}

- (BOOL)fr_isNSDictionary
{
    return [self isKindOfClass:[NSDictionary class]];
}

- (BOOL)fr_isNSNumber
{
    return [self isKindOfClass:[NSNumber class]];
}

- (BOOL)fr_isNSNull
{
    return [self isKindOfClass:[NSNull class]];
}

@end
