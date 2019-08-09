#import "BookmarkToPathTransformer.h"
#import "NSUserDefaultsExtensions.h"

@implementation BookmarkToPathTransformer
+ (Class)transformedValueClass
{
    return [NSArray class];
}


+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(NSArray *)value
{
    if (!value) return nil;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:value.count];
    NSEnumerator *enumerator = [value objectEnumerator];
    [array addObject:[enumerator nextObject]];
    for (NSData *bmdata in enumerator) {
        BOOL is_stale = NO;
        NSError *error = nil;
        NSURL *an_url = [NSURL URLByResolvingBookmarkData:bmdata
                                           options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithSecurityScope
                                     relativeToURL:nil
                               bookmarkDataIsStale:&is_stale
                                             error:&error];
        if (!(is_stale || error)) {
            [array addObject:an_url.path];
        } else {
            [[NSUserDefaults standardUserDefaults] removeFromHistory:bmdata
                                                              forKey:@"RecentScriptBookmarks"];
        }
    }
    return array;
}
@end
