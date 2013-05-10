#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

@interface NSObject (ASHTMLProcessor)
- (NSString *)generateCSS;
- (NSDictionary *)copyToClipboard;
- (NSString *)pathOnScriptEditor;
- (NSDictionary *)saveToFile;
@end

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
