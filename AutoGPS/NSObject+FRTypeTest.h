#import <Foundation/Foundation.h>

@interface NSObject (FRTypeTest)
- (BOOL)fr_isNSString;
- (BOOL)fr_isNSArray;
- (BOOL)fr_isNSDictionary;
- (BOOL)fr_isNSNumber;
- (BOOL)fr_isNSNull;
@end
