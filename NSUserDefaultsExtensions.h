#import <Cocoa/Cocoa.h>


@interface NSUserDefaults (NSUserDefaultsExtensions) 

- (void)addToHistory:(id)value forKey:(NSString *)key;
- (void)addToHistory:(id)value forKey:(NSString *)key emptyFirst:(BOOL)emptyFirst;
- (void)removeFromHistory:(id)value forKey:(NSString *)key;
- (void)removeFromHistoryAtIndex:(NSInteger)index forKey:(NSString *)key;
- (id)objectInHistoryAtIndex:(NSInteger)index forKey:(NSString *)key;

@end
