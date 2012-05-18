#import <Cocoa/Cocoa.h>


@interface PreferencesWindowController : NSWindowController {

}

+ (id)sharedPreferencesWindowController;
- (IBAction)generateCSS:(id)sender;
@end
