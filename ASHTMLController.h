#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

@interface ASHTMLController : NSObject {
	__weak IBOutlet NSProgressIndicator *indicator;
	__weak IBOutlet id mainWindow;
	__weak IBOutlet id ashtmlProcessor;
}

@property(nonatomic, strong) OSAScript *script;

+ (id)sharedASHTMLController;
- (void)generateCSS:(id)sender;
- (IBAction)copyToClipboard:(id)sender;
- (IBAction)saveToFile:(id)sender;

@end
