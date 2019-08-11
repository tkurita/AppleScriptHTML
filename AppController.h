#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
    IBOutlet id recentScriptsButton;
	IBOutlet id mainWindow;
	IBOutlet id targetScriptBox;
	IBOutlet id scriptLinkTitleComboBox;
    IBOutlet NSMenuItem *checkForUpdatesMenuItem;
    IBOutlet NSMenuItem *donationMenuItem;
}
- (IBAction)selectTarget:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)useScriptEditorSelection:(id)sender;
- (IBAction)useFileName:(id)sender;
- (IBAction)useClipboardContents:(id)sender;
- (IBAction)showMonitorWindow:(id)sender;
- (IBAction)showSettingWindow:(id)sender;
- (IBAction)makeDonation:(id)sender;

#if !SANDBOX
@property (nonatomic ,strong) id updater;
#endif

@end
