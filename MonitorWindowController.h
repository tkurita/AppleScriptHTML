#import <Cocoa/Cocoa.h>

@interface MonitorWindowController : NSWindowController {
	IBOutlet id monitorTextView;
}
@property(strong) NSString* contentType;
@property(strong) NSString* content;

+ (id)sharedWindowController;
+ (void)setContent:(NSString *)string type:(NSString *)type;
- (void)setContent:(NSString *)string type:(NSString *)type;
- (IBAction)copyAll:(id)sender;
@end
