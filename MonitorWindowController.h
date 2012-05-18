#import <Cocoa/Cocoa.h>

@interface MonitorWindowController : NSWindowController {
	IBOutlet id monitorTextView;
	NSString *contentType;
}
@property(retain) NSString* contentType;
+ (id)sharedWindowController;
+ (void)setContent:(NSString *)string type:(NSString *)type;
- (void)setContent:(NSString *)string type:(NSString *)type;

@end
