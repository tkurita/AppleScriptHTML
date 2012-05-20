#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
    IBOutlet id recentScriptsButton;
	IBOutlet id mainWindow;
	IBOutlet id targetScriptBox;
	IBOutlet id scriptLinkTitleComboBox;
}
- (IBAction)selectTarget:(id)sender;
- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)useScriptEditorSelection:(id)sender;
- (IBAction)useFileName:(id)sender;
- (IBAction)showMonitorWindow:(id)sender;
- (IBAction)showSettingWindow:(id)sender;

@end
