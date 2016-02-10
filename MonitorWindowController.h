#import <Cocoa/Cocoa.h>

@interface MonitorWindowController : NSWindowController {
	IBOutlet id monitorTextView;
}
@property(retain) NSString* contentType;
@property(retain) NSString* content;

+ (id)sharedWindowController;
+ (void)setContent:(NSString *)string type:(NSString *)type;
- (void)setContent:(NSString *)string type:(NSString *)type;
- (IBAction)copyAll:(id)sender;
@end
