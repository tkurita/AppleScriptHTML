#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

@interface NSObject (ASHTMLProcessor)
- (NSString *)generateCSS;
- (NSDictionary *)copyToClipboard;
- (NSString *)pathOnScriptEditor;
- (NSDictionary *)saveToFile;
- (NSDictionary *)errorInfo;
@end

@interface ASHTMLController : NSObject {
	IBOutlet id indicator;
	IBOutlet id mainWindow;
	IBOutlet id ASHTMLProcessor;
}
@property(strong) OSAScript *script;

+ (id)sharedASHTMLController;
- (void)generateCSS:(id)sender;
- (IBAction)copyToClipboard:(id)sender;
- (IBAction)saveToFile:(id)sender;
@end
