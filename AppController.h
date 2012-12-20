/* AppController */

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <QuartzComposer/QCView.h>
// #import <WiiRemote/Mii.h>
#import <OSCPort.h>
#import <OSCInPort.h>
#import <OSC-string-help.h>
#import <WiiRemote/WiiRemote.h>
#import <WiiRemote/WiiRemoteDiscovery.h>
#import "GraphView.h"
#import "GridView.h"
#import "PreferenceWindow.h"
#import "WidgetsEnableTransformer.h"
#import "WidgetsEnableTransformer2.h"

#import "KeyConfiguration_AppDelegate.h"

#define portno 5600
#define rcvportno 5601

@class PreferenceWindow;

@interface AppController : NSObject
{
	IBOutlet KeyConfiguration_AppDelegate* appDelegate;
	IBOutlet NSArrayController* mappingController;
	NSArray* modes;
	NSArray* configSortDescriptors;
    NSString* oscRemoteAddress;
	NSArray* oscPort;
    
	IBOutlet NSProgressIndicator *discoverySpinner;
    IBOutlet NSDrawer *logDrawer;
	IBOutlet NSDrawer *epDrawer;
	IBOutlet NSDrawer *bbDrawer;
    IBOutlet GraphView *graphView;
	IBOutlet GraphView *graphView2;
    IBOutlet NSTextView *textView;
	IBOutlet NSButton* led1;
	IBOutlet NSButton* led2;
	IBOutlet NSButton* led3;
	IBOutlet NSButton* led4;
	IBOutlet NSWindow* mainWindow;
	IBOutlet PreferenceWindow* preferenceWindow;
	IBOutlet NSWindow* enterNameWindow;
	IBOutlet NSWindow* irWindow;
	
	IBOutlet NSButton* upButton;
	IBOutlet NSButton* downButton;
	IBOutlet NSButton* leftButton;
	IBOutlet NSButton* rightButton;
	IBOutlet NSButton* aButton;
	IBOutlet NSButton* bButton;
	IBOutlet NSButton* minusButton;
	IBOutlet NSButton* plusButton;
	IBOutlet NSButton* homeButton;
	IBOutlet NSButton* oneButton;
	IBOutlet NSButton* twoButton;
	
	IBOutlet NSPopUpButton* mouseMode;
	
	IBOutlet NSView* nunchukView;
	IBOutlet NSView* ccView;

	IBOutlet NSView* batteryLevelView;
	IBOutlet NSLevelIndicator* batteryLevel;
    IBOutlet NSTextField* theRemoteAddress;
	IBOutlet NSTextField* theRemotePort;
    IBOutlet NSTextField* theRcvPort;
    
	IBOutlet QCView* wiimoteQCView;
	IBOutlet QCView* joystickQCView;
	IBOutlet QCView* irQCView;
	IBOutlet QCView* ccQCView;
	IBOutlet QCView* bbQCView;

	IBOutlet NSTextField* newNameField;
	
	IBOutlet NSTextField* WiimoteX;
	IBOutlet NSTextField* WiimoteY;
	IBOutlet NSTextField* WiimoteZ;
	
	IBOutlet NSTextField* NunchukX;
	IBOutlet NSTextField* NunchukY;
	IBOutlet NSTextField* NunchukZ;
	
	IBOutlet NSTextField* joystickX;
	IBOutlet NSTextField* joystickY;
	
	IBOutlet NSTextField* ccLeftX;
	IBOutlet NSTextField* ccLeftY;
	IBOutlet NSTextField* ccRightX;
	IBOutlet NSTextField* ccRightY;
	IBOutlet NSTextField* ccAnalogL;
	IBOutlet NSTextField* ccAnalogR;
	
	IBOutlet NSTextField* irPoint1X;
	IBOutlet NSTextField* irPoint1Y;
	IBOutlet NSTextField* irPoint1Size;

	IBOutlet NSTextField* irPoint2X;
	IBOutlet NSTextField* irPoint2Y;
	IBOutlet NSTextField* irPoint2Size;

	IBOutlet NSTextField* irPoint3X;
	IBOutlet NSTextField* irPoint3Y;
	IBOutlet NSTextField* irPoint3Size;

	IBOutlet NSTextField* irPoint4X;
	IBOutlet NSTextField* irPoint4Y;
	IBOutlet NSTextField* irPoint4Size;
	
	IBOutlet NSTextField* bPressureTR;	
	IBOutlet NSTextField* bPressureBR;	
	IBOutlet NSTextField* bPressureTL;	
	IBOutlet NSTextField* bPressureBL;

//enable recording of data	
	IBOutlet NSButton* recordButton;  
	NSMutableString* recordData;
	NSSavePanel* savePanel;
	BOOL recordToFile;
	NSFileHandle* recordHandle;
	
	WiiRemoteDiscovery *discovery;
	WiiRemote* wii;
    OSCPort* port;
	OSCInPort* portIn;
	CGPoint point;
    
    char* address;
	
    unsigned short	portNumber;
    unsigned short	RcvPortNumber;
    
    
	//BOOL isPressedBButton, isPressedAButton, isPressedHomeButton, isPressedUpButton, isPressedDownButton, isPressedLeftButton, isPressedRightButton, isPressedOneButton, isPressedTwoButton, isPressedPlusButton, isPressedMinusButton;
	
	BOOL isLeftButtonDown, isRightButtonDown;
	
	int mouseEventMode;
	int x1, x2, x3, y1, y2, y3, z1, z2, z3;
	int x0, y0, z0;
	unsigned short tmpAccX, tmpAccY, tmpAccZ;
	
	WiiJoyStickCalibData nunchukJsCalib;
	WiiAccCalibData wiiAccCalib, nunchukAccCalib;
	
	/* Center of Gravity Widget */
	IBOutlet GridView* cogGridView;
	IBOutlet NSWindow* cogWindow;
	IBOutlet NSButton* cogPlaybackButton;
	IBOutlet NSButton* cogRecordButton;
	IBOutlet NSTextField* cogRecordDelay;
	IBOutlet NSButton* cogResetButton;
	IBOutlet NSTextField* cogSampleSize;
	IBOutlet NSButton* cogSampleSizeButton;	
	IBOutlet NSTextField* cogTextInfo;
	IBOutlet NSTextField* cogRecordTime;
	IBOutlet NSTextField* cogWeight;
	BOOL cogRecording;
	BOOL cogCalibration;
	float cogAjustX;
	float cogAjustY;
	float cogRecordedTime;
	float cogRawX;
	float cogRawY;
	float cogSamples;
	float cogRawWeight;
	NSTimer* cogRecordTimer;

}

- (void)setupInitialKeyMappings;

- (IBAction)doCalibration:(id)sender;
- (IBAction)setForceFeedbackEnabled:(id)sender;
- (IBAction)setIRSensorEnabled:(id)sender;
- (IBAction)setLEDEnabled:(id)sender;
- (IBAction)setMotionSensorsEnabled:(id)sender;
- (IBAction)setMouseModeEnabled:(id)sender;
- (IBAction)openKeyConfiguration:(id)sender;
- (IBAction)addConfiguration:(id)sender;
- (IBAction)deleteConfiguration:(id)sender;
- (IBAction)enterSaveName:(id)sender;
- (IBAction)cancelEnterSaveName:(id)sender;
- (IBAction)saveFile:(id)sender;
- (IBAction)doDiscovery:(id)sender;

/* Center of Gravity widget */
- (void) cogStartRecord;
- (void) cogStopRecord;
- (void) cogRecordTimerUpdate:(NSTimer*)timer;
- (void) cogRecordDelayTimerUpdate:(NSTimer *)timer;
- (IBAction)cogCalibrate:(id)sender;
- (IBAction)cogRecord:(id)sender;
- (IBAction)cogReset:(id)sender;
- (IBAction)cogEnableSampleSize:(id)sender;


- (void)sendKeyboardEvent:(CGKeyCode)keyCode keyDown:(BOOL)keyDown;

// - (void)gotMiiData: (Mii*)m at:(int)slot;
- (IBAction)showHideIRWindow:(id)sender;

- (void) sendModifierKeys:(id)map isPressed:(BOOL)isPressed;

- (NSManagedObject*)createNewConfigration:(NSString*)name;


#pragma mark -
#pragma mark WiiRemoteDiscovery delegates

- (void) willStartWiimoteConnections;
@end
