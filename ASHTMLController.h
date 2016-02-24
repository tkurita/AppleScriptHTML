#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

@interface ASHTMLController : NSObject {
	IBOutlet id indicator;
	IBOutlet id mainWindow;
	IBOutlet id ashtmlProcessor;
}

@property(strong) OSAScript *script;

+ (id)sharedASHTMLController;
- (void)generateCSS:(id)sender;
- (IBAction)copyToClipboard:(id)sender;
- (IBAction)saveToFile:(id)sender;
@end
