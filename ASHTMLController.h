#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

@interface ASHTMLController : NSObject {
	OSAScript *script;
	IBOutlet id indicator;
	IBOutlet id mainWindow;
	IBOutlet id ASHTMLProcessor;
}
@property(retain) OSAScript *script;

+ (id)sharedASHTMLController;
- (void)generateCSS:(id)sender;
- (IBAction)copyToClipboard:(id)sender;
- (IBAction)saveToFile:(id)sender;
@end
