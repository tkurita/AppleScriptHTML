#import "NSUserDefaultsExtensions.h"


@implementation NSUserDefaults (NSUserDefaultsExtensions)

- (void)addToScriptLinkTitleHistory:(NSString *)value
{
    [self addToHistory:value forKey:@"ScriptLinkTitleHistory"];
}

- (void)addToScriptLinkTitleHistoryInMainThread:(NSString *)value
{
    [self performSelectorOnMainThread:@selector(addToScriptLinkTitleHistory:)
                           withObject:value waitUntilDone:NO];
}

- (void)addToHistory:(id)value forKey:(NSString *)key emptyFirst:(BOOL)emptyFirst
{
	if (!value) return;
	
	NSMutableArray *a_history = [self objectForKey:key];
	
	if (a_history == nil) {
		if (emptyFirst) {
			a_history = [NSMutableArray arrayWithObject:@""];
		} else {
			a_history = [NSMutableArray arrayWithCapacity:1];
        }
	}
	else {
		if ([a_history containsObject:value]) {
			return;
		}
		a_history = [a_history mutableCopy];
	}
    
    unsigned int ins_index;
    if (emptyFirst) {
        ins_index = 1;
    } else {
        ins_index = 0;
    }

	[a_history insertObject:value atIndex:ins_index];
	NSInteger history_max = [self integerForKey:@"HistoryMax"];

	if ([a_history count] > history_max) {
		[a_history removeLastObject];
	}
	[self setObject:a_history forKey:key];
}

- (void)addToHistory:(id)value forKey:(NSString *)key
{
	[self addToHistory:value forKey:key emptyFirst:NO];
}

- (void)removeFromHistory:(id)value forKey:(NSString *)key
{
	if (!value) return;
	
	NSMutableArray *a_history = [self objectForKey:key];
	if (!a_history) return;
	if ([a_history containsObject:value]) {
		a_history = [a_history mutableCopy];
		[a_history removeObject:value];
		[self setObject:a_history forKey:key];
	}
	
}
@end
