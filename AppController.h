#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
    IBOutlet id recentScriptsButton;
	IBOutlet id mainWindow;
	IBOutlet id targetScriptBox;
}
- (IBAction)selectTarget:(id)sender;
- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)useScriptEditorSelection:(id)sender;

@end
