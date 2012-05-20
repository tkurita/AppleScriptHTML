#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

@interface ASHTMLController : NSObject {
	OSAScript *script;
}
@property(retain) OSAScript *script;

+ (id)sharedASHTMLController;
- (void)generateCSS:(id)sender;

@end
