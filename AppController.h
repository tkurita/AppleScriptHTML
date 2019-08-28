#import <Cocoa/Cocoa.h>

typedef enum
{
    FileSelected,
    ScriptEditorSelection,
    ClipboardContents,
    DropScriptFile
} TargetMode;

@interface AppController : NSObject {
    IBOutlet NSButton *recentScriptsButton;
	IBOutlet id mainWindow;
	IBOutlet id targetScriptBox;
	IBOutlet id scriptLinkTitleComboBox;
    IBOutlet NSMenuItem *checkForUpdatesMenuItem;
    IBOutlet NSMenuItem *donationMenuItem;
    IBOutlet NSButton *scriptEditorSelectionButton;
    IBOutlet NSButton *selectButton;
}
- (IBAction)selectTarget:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)useScriptEditorSelection:(id)sender;
- (IBAction)useFileName:(id)sender;
- (IBAction)useClipboardContents:(id)sender;
- (IBAction)showMonitorWindow:(id)sender;
- (IBAction)showSettingWindow:(id)sender;
- (IBAction)makeDonation:(id)sender;

- (void)selectTargetWithCompletionHandler:(void (^)(BOOL result))handler;

#if !SANDBOX
@property (nonatomic ,strong) id updater;
#endif

@end
