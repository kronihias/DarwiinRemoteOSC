#import "AppController.h"
#import <sys/time.h>

/* XXX: Convert proof of concept implementations to actual GUI friendy options*/
//#define BALANCEBOARD_TO_KEYS 1
//#define NUNCHUK_TO_KEYS 1
//#define WIIREMOTE_MOTION_TO_KEYS 1

extern char ***_NSGetArgv(void);
extern int *_NSGetArgc(void);
extern char ***_NSGetEnviron(void);
extern char **_NSGetProgname(void);

@implementation AppController

// http://google-toolbox-for-mac.googlecode.com/svn/trunk/UnitTesting/GTMUnitTestingUtilities.m (Apache	2.0 licence)
// Returns a virtual key code for a given charCode. Handles all of the
// NS*FunctionKeys as well.
static CGKeyCode GTMKeyCodeForCharCode(CGCharCode charCode) {
	// character map taken from http://classicteck.com/rbarticles/mackeyboard.php
	int characters[] = { 
		'a', 's', 'd', 'f', 'h', 'g', 'z', 'x', 'c', 'v', 256, 'b', 'q', 'w', 
		'e', 'r', 'y', 't', '1', '2', '3', '4', '6', '5', '=', '9', '7', '-', 
		'8', '0', ']', 'o', 'u', '[', 'i', 'p', '\n', 'l', 'j', '\'', 'k', ';', 
		'\\', ',', '/', 'n', 'm', '.', '\t', ' ', '`', '\b', 256, '\e' 
	};
	
	// function key map taken from 
	// file:///Developer/ADC%20Reference%20Library/documentation/Cocoa/Reference/ApplicationKit/ObjC_classic/Classes/NSEvent.html
	int functionKeys[] = { 
		// NSUpArrowFunctionKey - NSF12FunctionKey
		126, 125, 123, 124, 122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111,   
		// NSF13FunctionKey - NSF28FunctionKey
		105, 107, 113, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 
		// NSF29FunctionKey - NSScrollLockFunctionKey 
		256, 256, 256, 256, 256, 256, 256, 256, 117, 115, 256, 119, 116, 121, 256, 256, 
		// NSPauseFunctionKey - NSPrevFunctionKey
		256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256,
		// NSNextFunctionKey - NSModeSwitchFunctionKey
		256, 256, 256, 256, 256, 256, 114, 1 
	};  
	
	CGKeyCode outCode = 0;
	
	// Look in the function keys
	if (charCode >= NSUpArrowFunctionKey && charCode <= NSModeSwitchFunctionKey) {
		outCode = functionKeys[charCode - NSUpArrowFunctionKey];
	} else {
		// Look in our character map
		size_t i;
		for (i = 0; i < (sizeof(characters) / sizeof (int)); i++) {
			if (characters[i] == charCode) {
				outCode = i;
				break;
			}
		}
	}
	return outCode;
}
		

- (IBAction)doDiscovery:(id)sender
{
//	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, NO);
	[discovery start];
	[textView setString:@"Please press 1 button and 2 button simultaneously"];
	[discoverySpinner startAnimation:self];
}


- (IBAction)showHideIRWindow:(id)sender
{
	if ([irWindow isVisible]) {
		[sender setTitle:@"Show IR Info"];
		[irWindow orderOut:self];
	} else {
		[sender setTitle:@"Hide IR Info"];
		[irWindow makeKeyAndOrderFront:self];
	}
}

- (IBAction)setForceFeedbackEnabled:(id)sender
{
	[wii setForceFeedbackEnabled:[sender state]];
}

- (IBAction)setIRSensorEnabled:(id)sender
{
	[wii setIRSensorEnabled:[sender state]];
}

- (IBAction)setLEDEnabled:(id)sender
{

	[wii setLEDEnabled1:[led1 state] enabled2:[led2 state] enabled3:[led3 state] enabled4:[led4 state]];

	[wiimoteQCView setValue:[NSNumber numberWithBool:[led1 state] ] forInputKey:[NSString stringWithString:@"LED_1"]];
	[wiimoteQCView setValue:[NSNumber numberWithBool:[led2 state] ] forInputKey:[NSString stringWithString:@"LED_2"]];
	[wiimoteQCView setValue:[NSNumber numberWithBool:[led3 state] ] forInputKey:[NSString stringWithString:@"LED_3"]];
	[wiimoteQCView setValue:[NSNumber numberWithBool:[led4 state] ] forInputKey:[NSString stringWithString:@"LED_4"]];

}

/**
- (IBAction)setMouseModeEnabled:(id)sender{

	
	if ([sender state]){
		sendMouseEvent = YES;
	}else{
		CGPostMouseEvent(point, TRUE, 1, FALSE);
		isPressedAButton = NO;
		sendMouseEvent = NO;
	}
}
**/

- (IBAction)setMotionSensorsEnabled:(id)sender
{
	[wii setMotionSensorEnabled:[sender state]];
}


- (IBAction)doCalibration:(id)sender{
	
	id config = [mappingController selection];
	
	
	if ([sender tag] == 0){
		x1 = tmpAccX;
		y1 = tmpAccY;
		z1 = tmpAccZ;
	}
	
	if ([sender tag] == 1){
		x2 = tmpAccX;
		y2 = tmpAccY;
		z2 = tmpAccZ;
	}
	if ([sender tag] == 2){
		x3 = tmpAccX;
		y3 = tmpAccY;
		z3 = tmpAccZ;
	}
	x0 = (x1 + x2) / 2.0;
	y0 = (y1 + y3) / 2.0;
	z0 = (z2 + z3) / 2.0;
	
	[config setValue:[NSNumber numberWithInt:(int)x0] forKeyPath:@"wiimote.accX_zero"];
	[config setValue:[NSNumber numberWithInt:(int)y0] forKeyPath:@"wiimote.accY_zero"];
	[config setValue:[NSNumber numberWithInt:(int)z0] forKeyPath:@"wiimote.accZ_zero"];

	[config setValue:[NSNumber numberWithInt:(int)x3] forKeyPath:@"wiimote.accX_1g"];
	[config setValue:[NSNumber numberWithInt:(int)y2] forKeyPath:@"wiimote.accY_1g"];
	[config setValue:[NSNumber numberWithInt:(int)z1] forKeyPath:@"wiimote.accZ_1g"];

	
	[textView setString:[NSString stringWithFormat:@"%@\n===== x: %d  y: %d  z: %d =====", [textView string], tmpAccX, tmpAccY, tmpAccZ]];

}

- (IBAction)saveFile:(id)sender
{
	// Currently not yet recording
	if (recordToFile == NO) {				
		// Select file
		// XXX: Might want to include a file suggestion http://www.cocoabuilder.com/archive/message/cocoa/2002/8/1/56817
		savePanel = [NSSavePanel savePanel];
		[savePanel setDirectory:NSHomeDirectory()];
		int ret = [savePanel runModal];
		
		// Create file
		if (ret) {
			// Try to write csv headers
			ret = [[NSFileManager defaultManager] createFileAtPath:[savePanel filename] 
															  contents:[@"time,AccX,AccY,AccZ,pressureTR, pressureBR, pressureTL, pressureBL,rawPressureTR,rawPressureBR,rawPressureTL,rawPressureBL\n" dataUsingEncoding: NSASCIIStringEncoding] attributes:nil];
		}

		// Let's save the data succesfully selected and created file
		if (ret) {
			// Update display and status
			recordHandle = [[NSFileHandle fileHandleForWritingAtPath:[savePanel filename]] retain];
			// set to end will avoid overwriting header values ;-)
			[recordHandle seekToEndOfFile];
			
			// update display and internal state
			recordToFile = YES;
			[sender setTitle:@"Stop"];
		}
	} else {
		// Done recording, update state
		[sender setTitle:@"Start"];
		[recordHandle closeFile];
		[recordHandle release];
		recordToFile = NO;
	}
}

#pragma mark _____ OSC Callbacks
BOOL ReadOSCInts(int arglen, const void* args, int numInts, int* outInts, NSString* errorMessage)
{
	unsigned i;
	char* errorMsg;
	const char* typeString;
	const char* remainingArgs;
	char desiredTypeString[numInts + 1];
    
	typeString = args;
	
	// create the desired type string
	desiredTypeString[0] = ',';
	for (i = 0; i < numInts; i++)
		desiredTypeString[i + 1] = 'i';
    
	// make sure the arguments are correct -- strncmp returns 0 on a match
	if (strncmp(typeString, desiredTypeString, numInts + 1))
	{
		return NO;
	}
	
	// get the arguments after the type tag
	remainingArgs = OSCDataAfterAlignedString(args, args + arglen, &errorMsg);
	if (!remainingArgs)
	{
		NSLog(@"Problem with OSC reading note off arguments");
		return NO;
	}
	
	// read out the parameters
	for(i = 0 ; i < numInts; i++)
	{
		outInts[i] = ((const int*)remainingArgs)[0];
		remainingArgs += 4;
	}
	
	return YES;
}

void GetBatteryLevel(void *context, int arglen, const void *args,
                     OSCTimeTag when, NetworkReturnAddressPtr returnAddr)
{
	[context sendBatteryLevel];
}


SetForceFeedback(void *context, int arglen, const void *args,
                 OSCTimeTag when, NetworkReturnAddressPtr returnAddr)
{
	int receivedArgs[1];
	NSString* errorMessage = @"Incorrect arguments to noteOn. Arguments should be int channel, int note, int velocity";
	if (ReadOSCInts(arglen, args, 1, receivedArgs, errorMessage))
        if(receivedArgs[0]==0) {
            [context setForceFeedback:NO];
        } else {
            [context setForceFeedback:YES];
        }
}


void SetLED(void *context, int arglen, const void *args,
            OSCTimeTag when, NetworkReturnAddressPtr returnAddr)
{
	int receivedArgs[4];
	NSString* errorMessage = @"Incorrect arguments to setLED.";
	if (ReadOSCInts(arglen, args, 4, receivedArgs, errorMessage)) {
		[context setLeds:(receivedArgs[0]==0) ? NO:YES theEnabled2:(receivedArgs[1]==0) ? NO:YES theEnabled3:(receivedArgs[2]==0) ? NO:YES theEnabled4:(receivedArgs[3]==0) ? NO:YES];
	}
}


-(void)setLeds:(BOOL)theEnabled1 theEnabled2:(BOOL)theEnabled2 theEnabled3:(BOOL)theEnabled3 theEnabled4:(BOOL)theEnabled4 {
	[wii setLEDEnabled1:theEnabled1 enabled2:theEnabled2 enabled3:theEnabled3 enabled4:theEnabled4];
}


-(void)setForceFeedback:(BOOL)mode {
	[wii setForceFeedbackEnabled:mode];
}



-(void)sendBatteryLevel {
	NSLog(@"sending batterylevel");
	[port sendTo:"/wii/batterylevel" types:"f", (float)[wii batteryLevel]];	
}

- (id)init{
	
    // OSC STUFF
    //char address[16];
    address = (char*)malloc(16);
    
    portNumber = portno;
    RcvPortNumber = rcvportno;
    
	// set the address
	memset(address, 0, 16);
    strcpy(address, "127.0.0.1");
    
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *sndAddr = [standardDefaults stringForKey:@"ip"];
    NSInteger sndPort = [standardDefaults integerForKey:@"port"];
    NSInteger rcvPort = [standardDefaults integerForKey:@"rcv_port"];
    
   //NSLog (@"aString argument: %@\nanInteger argument: %d", aString, anInteger);
    
    
    // commandline arguments -> very ugly...
    
    if (sndAddr)
    {
        address = [sndAddr UTF8String];
    }
    if (sndPort)
    {
        portNumber = sndPort;
    }
    
    if (rcvPort)
    {
        RcvPortNumber = rcvPort;
    }
    

	// sending OSC port
	NSLog(@"OSC connecting to %s:%hu...", address, portNumber);
    port   = [OSCPort oscPortToAddress:address portNumber: portNumber];
	[port retain];
	[port sendTo:"/wii/connected" types:"i", 1];
    
	
	// receive OSC messages.
    NSLog(@"OSC Receiving on port %hu...", RcvPortNumber);
	portIn = [[OSCInPort alloc] initPort: RcvPortNumber];
	OSCcontainer wiiContainer = [portIn newContainerNamed: "wii"];
	[portIn newMethodNamed: "batterylevel" under: wiiContainer callback:GetBatteryLevel context: self];
	[portIn newMethodNamed: "forcefeedback" under: wiiContainer callback:SetForceFeedback context: self];
	[portIn newMethodNamed: "led" under: wiiContainer callback:SetLED context: self];
	[portIn start];
    
	modes = [[NSArray arrayWithObjects:@"Nothing", @"Key", @"\tReturn", @"\tTab", @"\tEsc", @"\tBackspace", @"\tUp", @"\tDown", @"\tLeft",@"\tRight", @"\tPage Up", @"\tPage Down", @"\tF1", @"\tF2", @"\tF3", @"\tF4", @"\tF5", @"\tF6", @"\tF7", @"\tF8", @"\tF9", @"\tF10", @"\tF11", @"\tF12", @"Left Click", @"Left Click2", @"Right Click", @"Right Click2", @"Toggle Mouse (Motion)", @"Toggle Mouse (IR)",nil] retain];

	
	id transformer = [[[WidgetsEnableTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"WidgetsEnableTransformer"];
	/**
	id transformer2 = [[[KeyCodeTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer2 forName:@"KeyCodeTransformer"];
	**/
	id transformer3 = [[[WidgetsEnableTransformer2 alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer3 forName:@"WidgetsEnableTransformer2"];

	NSSortDescriptor* descriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	configSortDescriptors = [[NSArray arrayWithObjects:descriptor, nil] retain];
	return self;
}

- (void) dealloc
{
	[wii release];
	[discovery release];
	[configSortDescriptors release];
	[super dealloc];
}

-(void)awakeFromNib{

	[[NSNotificationCenter defaultCenter] addObserver:self
											selector:@selector(expansionPortChanged:)
											name:@"WiiRemoteExpansionPortChangedNotification"
											object:nil];
	
	/**	
		Interface Builder doesn't allow vertical level meters.
		So the battery level is put in an NSView and then the view is rotated.
	**/
	[batteryLevelView setFrameRotation: 90.0];
    
    [theRemoteAddress setStringValue:[NSString stringWithFormat:@"%s", address]];
    [theRemotePort setStringValue:[NSString stringWithFormat:@"%u", portNumber]];
    [theRcvPort setStringValue:[NSString stringWithFormat:@"%u", RcvPortNumber]];
	
	mouseEventMode = 0;
	discovery = [[WiiRemoteDiscovery alloc] init];
	[discovery setDelegate:self];
//	[discovery start];
//	[discoverySpinner startAnimation:self];
	[logDrawer open];
	//[textView setString:@"Please press 1 button and 2 button simultaneously"];
   [textView setString:@"Please press Find Wiimote\n\
1) If the application is unable to find your devices please make _sure_ to\n\
   delete assosiated Wii devices from your Bluetooth Preferences screen\n\
2) Still unable? Press Find, _wait_ a few (like 5+) seconds and then try to sync\n\
3) Waiting about 15s on non-Intel systems _may_ prevent having to refind the wiimote\n\
4) If you like to use both BalanceBoard and WiiRemote make sure to sync with the BB first\n"];
	
	// By default no recording on startup
	recordToFile = NO;
	
	/* Center Of Gravity widget */
	cogRecording = NO;
	cogCalibration = NO;
	cogAjustX = 0;
	cogAjustY = 0;
	
	point.x = 0;
	point.y = 0;
	
	
	/**
	{
        NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		
		NSNumber* num = [[NSNumber alloc] initWithDouble:128.0];
		NSNumber* num2 = [[NSNumber alloc] initWithDouble:154.0];


		[defaultValues setObject:num forKey:@"x1"];
		[defaultValues setObject:num forKey:@"y1"];
		[defaultValues setObject:num2 forKey:@"z1"];

		[defaultValues setObject:num forKey:@"x2"];
		[defaultValues setObject:num2 forKey:@"y2"];
		[defaultValues setObject:num forKey:@"z2"];
		
		[defaultValues setObject:num2 forKey:@"x3"];
		[defaultValues setObject:num forKey:@"y3"];
		[defaultValues setObject:num forKey:@"z3"];
		
		[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"selection"];

        [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    }
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	x1 = [[defaults objectForKey:@"x1"] doubleValue];
	y1 = [[defaults objectForKey:@"y1"] doubleValue];
	z1 = [[defaults objectForKey:@"z1"] doubleValue];

	x2 = [[defaults objectForKey:@"x2"] doubleValue];
	y2 = [[defaults objectForKey:@"y2"] doubleValue];
	z2 = [[defaults objectForKey:@"z2"] doubleValue];
	
	x3 = [[defaults objectForKey:@"x3"] doubleValue];
	y3 = [[defaults objectForKey:@"y3"] doubleValue];
	z3 = [[defaults objectForKey:@"z3"] doubleValue];


	x0 = (x1 + x2) / 2.0;
	y0 = (y1 + y3) / 2.0;
	z0 = (z2 + z3) / 2.0;
	**/
	[cogRecordButton setNextState];
	[self setupInitialKeyMappings];		
}

- (void)expansionPortChanged:(NSNotification *)nc{

	[textView setString:[NSString stringWithFormat:@"%@\n===== Expansion port status changed. =====", [textView string]]];
	
	WiiRemote* tmpWii = (WiiRemote*)[nc object];
	
	// Check that the Wiimote reporting is the one we're connected to.
	if (![[tmpWii address] isEqualToString:[wii address]]){
		return;
	}
	
	// Set the view for the expansion port drawer.
	WiiExpansionPortType epType = [wii expansionPortType];
	switch (epType) {
		
		case WiiNunchuk:
			[epDrawer setContentView: nunchukView];
			[epDrawer open];
		break;
		
		case WiiClassicController:
			[epDrawer setContentView: ccView];
			[epDrawer open];
		break;
		
		case WiiBalanceBoard:
			[bbDrawer open];
		break;
			
		case WiiExpNotAttached:
		default:
			[epDrawer setContentView: nil];
			[epDrawer close];

		
	}
	
	if ([wii isExpansionPortAttached]){
		[wii setExpansionPortEnabled:YES];
		NSLog(@"** Expansion Port Enabled");
	} else {
		[wii setExpansionPortEnabled:NO];
		NSLog(@"** Expansion Port Disabled");
	}	
}



- (void) wiiRemoteDisconnected:(IOBluetoothDevice*)device {
	[wii release];
	wii = nil;

	[textView setString:[NSString stringWithFormat:@"%@\n===== lost connection with WiiRemote =====", [textView string]]];
    [port sendTo:"/wii/connected" types:"i", 0];
}

- (void) irPointMovedX:(float)px Y:(float)py{
	
	if (mouseEventMode != 2)
		return;
	
	BOOL haveMouse = (px > -2)?YES:NO;
	
	if (!haveMouse) {
		[graphView setIRPointX:-2 Y:-2];
        [port sendTo:"/wii/irpoint" types:"ff", -2,-2];
		return;
	} else {
		[graphView setIRPointX:px Y:py];
        [port sendTo:"/wii/irpoint" types:"ff", px,py];

	}
	
	int dispWidth = CGDisplayPixelsWide(kCGDirectMainDisplay);
	int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
	
	
	id config = [mappingController selection];
	float sens2 = [[config valueForKey:@"sensitivity2"] floatValue] * [[config valueForKey:@"sensitivity2"] floatValue];
	
	float newx = (px*1*sens2)*dispWidth + dispWidth/2;
	float newy = -(py*1*sens2)*dispWidth + dispHeight/2;
	//float scaledX = ((irData[0].x / 1024.0) * 2.0) - 1.0;
	
	if (newx < 0) newx = 0;
	if (newy < 0) newy = 0;
	if (newx >= dispWidth) newx = dispWidth-1;
	if (newy >= dispHeight) newy = dispHeight-1;
	
	float dx = newx - point.x;
	float dy = newy - point.y;
	
	float d = sqrt(dx*dx+dy*dy);

	
	
	// mouse filtering
	if (d < 20) {
		point.x = point.x * 0.9 + newx*0.1;
		point.y = point.y * 0.9 + newy*0.1;
	} else if (d < 50) {
		point.x = point.x * 0.7 + newx*0.3;
		point.y = point.y * 0.7 + newy*0.3;
	} else {
		point.x = newx;
		point.y = newy;
	}
	
	if (point.x > dispWidth)
		point.x = dispWidth - 1;
	
	if (point.y > dispHeight)
		point.y = dispHeight - 1;
	
	if (point.x < 0)
		point.x = 0;
	if (point.y < 0)
		point.y = 0;
	
	[port sendTo:"/wii/point" types:"ff", (float)point.x, (float)point.y];
	
	if (!isLeftButtonDown && !isRightButtonDown){
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventMouseMoved);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
	}else{		
		
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDragged, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventLeftMouseDragged);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);	
	}
	
} // irPointMoved

- (void) rawIRData:(IRData[4])irData {
    
    [port sendTo:"/wii/irdata" types:"ffffffffffff",
     (float)irData[0].x/1023,(float)irData[0].y/1023,(float)irData[0].s,
     (float)irData[1].x/1023,(float)irData[1].y/1023,(float)irData[1].s,
     (float)irData[2].x/1023,(float)irData[2].y/1023,(float)irData[2].s,
     (float)irData[3].x/1023,(float)irData[3].y/1023,(float)irData[3].s
     ];
    
		[irPoint1X setStringValue: [NSString stringWithFormat:@"%00X", irData[0].x]];		
		[irPoint1Y setStringValue: [NSString stringWithFormat:@"%00X", irData[0].y]];		
		[irPoint1Size setStringValue: [NSString stringWithFormat:@"%00X", irData[0].s]];		

		[irPoint2X setStringValue: [NSString stringWithFormat:@"%00X", irData[1].x]];		
		[irPoint2Y setStringValue: [NSString stringWithFormat:@"%00X", irData[1].y]];		
		[irPoint2Size setStringValue: [NSString stringWithFormat:@"%00X", irData[1].s]];		

		[irPoint3X setStringValue: [NSString stringWithFormat:@"%00X", irData[2].x]];		
		[irPoint3Y setStringValue: [NSString stringWithFormat:@"%00X", irData[2].y]];		
		[irPoint3Size setStringValue: [NSString stringWithFormat:@"%00X", irData[2].s]];		
	
		[irPoint4X setStringValue: [NSString stringWithFormat:@"%00X", irData[3].x]];		
		[irPoint4Y setStringValue: [NSString stringWithFormat:@"%00X", irData[3].y]];		
		[irPoint4Size setStringValue: [NSString stringWithFormat:@"%00X", irData[3].s]];
		
		if (irData[0].s != 0xF) {
			float scaledX = ((irData[0].x / 1024.0) * 2.0) - 1.0;
			float scaledY = ((irData[0].y / 768.0) * 1.5) - 0.75;
			float scaledSize = irData[0].s / 16.0;
			
			[irQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"Point1X"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Point1Y"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledSize] forInputKey:[NSString stringWithString:@"Point1Size"]];

			[irQCView setValue:[NSNumber numberWithBool: YES] forInputKey:[NSString stringWithString:@"Point1Enable"]];		
		} else {
			[irQCView setValue:[NSNumber numberWithBool: NO] forInputKey:[NSString stringWithString:@"Point1Enable"]];		
		}

		if (irData[1].s != 0xF) {
			float scaledX = ((irData[1].x / 1024.0) * 2.0) - 1.0;
			float scaledY = ((irData[1].y / 768.0) * 1.5) - 0.75;
			float scaledSize = irData[1].s / 16.0;
			
			[irQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"Point2X"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Point2Y"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledSize] forInputKey:[NSString stringWithString:@"Point2Size"]];

			[irQCView setValue:[NSNumber numberWithBool: YES] forInputKey:[NSString stringWithString:@"Point2Enable"]];		
		} else {
			[irQCView setValue:[NSNumber numberWithBool: NO] forInputKey:[NSString stringWithString:@"Point2Enable"]];		
		}

		if (irData[2].s != 0xF) {
			float scaledX = ((irData[2].x / 1024.0) * 2.0) - 1.0;
			float scaledY = ((irData[2].y / 768.0) * 1.5) - 0.75;
			float scaledSize = irData[2].s / 16.0;
			
			[irQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"Point3X"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Point3Y"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledSize] forInputKey:[NSString stringWithString:@"Point3Size"]];

			[irQCView setValue:[NSNumber numberWithBool: YES] forInputKey:[NSString stringWithString:@"Point3Enable"]];		
		} else {
			[irQCView setValue:[NSNumber numberWithBool: NO] forInputKey:[NSString stringWithString:@"Point3Enable"]];		
		}
		if (irData[3].s != 0xF) {
			float scaledX = ((irData[3].x / 1024.0) * 2.0) - 1.0;
			float scaledY = ((irData[3].y / 768.0) * 1.5) - 0.75;
			float scaledSize = irData[3].s / 16.0;
			
			[irQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"Point4X"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Point4Y"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledSize] forInputKey:[NSString stringWithString:@"Point4Size"]];

			[irQCView setValue:[NSNumber numberWithBool: YES] forInputKey:[NSString stringWithString:@"Point4Enable"]];		
		} else {
			[irQCView setValue:[NSNumber numberWithBool: NO] forInputKey:[NSString stringWithString:@"Point4Enable"]];		
		}
}


- (void) buttonChanged:(WiiButtonType)type isPressed:(BOOL)isPressed{
		 
	id mappings = [mappingController selection];
	id map = nil;
    int isPressedInt = (isPressed==true) ? 1:0;
	if (type == WiiRemoteAButton){
		map = [mappings valueForKeyPath:@"wiimote.a"];
		[aButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"A_Button"]];
        [port sendTo:"/wii/button/a" types:"i", isPressedInt];
		
	}else if (type == WiiRemoteBButton){
		map = [mappings valueForKeyPath:@"wiimote.b"];
		[bButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"B_Button"]];
        [port sendTo:"/wii/button/b" types:"i", isPressedInt];

	}else if (type == WiiRemoteUpButton){
		map = [mappings valueForKeyPath:@"wiimote.up"];
		[upButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Up"]];
        [port sendTo:"/wii/button/up" types:"i", isPressedInt];

	}else if (type == WiiRemoteDownButton){
		map = [mappings valueForKeyPath:@"wiimote.down"];
		[downButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Down"]];
        [port sendTo:"/wii/button/down" types:"i", isPressedInt];

	}else if (type == WiiRemoteLeftButton){
		map = [mappings valueForKeyPath:@"wiimote.left"];
		[leftButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Left"]];
        [port sendTo:"/wii/button/left" types:"i", isPressedInt];

	}else if (type == WiiRemoteRightButton){
		map = [mappings valueForKeyPath:@"wiimote.right"];
		[rightButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Right"]];
        [port sendTo:"/wii/button/right" types:"i", isPressedInt];

	}else if (type == WiiRemoteMinusButton){
		map = [mappings valueForKeyPath:@"wiimote.minus"];
		[minusButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Minus"]];
        [port sendTo:"/wii/button/minus" types:"i", isPressedInt];

	}else if (type == WiiRemotePlusButton){
		map = [mappings valueForKeyPath:@"wiimote.plus"];
		[plusButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Plus"]];
        [port sendTo:"/wii/button/plus" types:"i", isPressedInt];

	}else if (type == WiiRemoteHomeButton){
		map = [mappings valueForKeyPath:@"wiimote.home"];
		[homeButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Home"]];
        [port sendTo:"/wii/button/home" types:"i", isPressedInt];

	}else if (type == WiiRemoteOneButton){
		map = [mappings valueForKeyPath:@"wiimote.one"];
		[oneButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"One"]];
        [port sendTo:"/wii/button/one" types:"i", isPressedInt];

	}else if (type == WiiRemoteTwoButton){
		map = [mappings valueForKeyPath:@"wiimote.two"];
		[twoButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Two"]];
        [port sendTo:"/wii/button/two" types:"i", isPressedInt];

	}else if (type == WiiNunchukCButton){
		map = [mappings valueForKeyPath:@"nunchuk.c"];
		[joystickQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"CEnable"]];
        [port sendTo:"/nunchuk/button/c" types:"i", isPressedInt];

	}else if (type == WiiNunchukZButton){
		map = [mappings valueForKeyPath:@"nunchuk.z"];
		[joystickQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"ZEnable"]];
        [port sendTo:"/nunchuk/button/z" types:"i", isPressedInt];
	} 
	
	switch (type) {
		case WiiClassicControllerXButton:
			map = [mappings valueForKeyPath:@"classiccontroller.x"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"X"]];
            [port sendTo:"/classic/button/x" types:"i", isPressedInt];
		break;
	
		case WiiClassicControllerYButton:
			map = [mappings valueForKeyPath:@"classiccontroller.y"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Y"]];
            [port sendTo:"/classic/button/y" types:"i", isPressedInt];
		break;
		
		case WiiClassicControllerAButton:
			map = [mappings valueForKeyPath:@"classiccontroller.a"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"A"]];
            [port sendTo:"/classic/button/a" types:"i", isPressedInt];
		break;
		
		case WiiClassicControllerBButton:
			map = [mappings valueForKeyPath:@"classiccontroller.b"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"B"]];
            [port sendTo:"/classic/button/b" types:"i", isPressedInt];
		break;
		
		case WiiClassicControllerLButton:
			map = [mappings valueForKeyPath:@"classiccontroller.l"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"L"]];
            [port sendTo:"/classic/button/l" types:"i", isPressedInt];
		break;
		
		case WiiClassicControllerRButton:
			map = [mappings valueForKeyPath:@"classiccontroller.r"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"R"]];
            [port sendTo:"/classic/button/r" types:"i", isPressedInt];
		break;
		
		case WiiClassicControllerZLButton:
			map = [mappings valueForKeyPath:@"classiccontroller.zl"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"ZL"]];
            [port sendTo:"/classic/button/zl" types:"i", isPressedInt];
		break;

		case WiiClassicControllerZRButton:
			map = [mappings valueForKeyPath:@"classiccontroller.zr"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"ZR"]];
            [port sendTo:"/classic/button/zr" types:"i", isPressedInt];
		break;

		case WiiClassicControllerUpButton:
			map = [mappings valueForKeyPath:@"classiccontroller.up"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Up"]];
            [port sendTo:"/classic/button/up" types:"i", isPressedInt];
		break;

		case WiiClassicControllerDownButton:
			map = [mappings valueForKeyPath:@"classiccontroller.down"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Down"]];
            [port sendTo:"/classic/button/down" types:"i", isPressedInt];
		break;

		case WiiClassicControllerLeftButton:
			map = [mappings valueForKeyPath:@"classiccontroller.left"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Left"]];
            [port sendTo:"/classic/button/left" types:"i", isPressedInt];
		break;

		case WiiClassicControllerRightButton:
			map = [mappings valueForKeyPath:@"classiccontroller.right"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Right"]];
            [port sendTo:"/classic/button/right" types:"i", isPressedInt];
		break;

		case WiiClassicControllerMinusButton:
			map = [mappings valueForKeyPath:@"classiccontroller.minus"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Minus"]];
            [port sendTo:"/classic/button/minus" types:"i", isPressedInt];
		break;

		case WiiClassicControllerHomeButton:
			map = [mappings valueForKeyPath:@"classiccontroller.home"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Home"]];
            [port sendTo:"/classic/button/home" types:"i", isPressedInt];
		break;

		case WiiClassicControllerPlusButton:
			map = [mappings valueForKeyPath:@"classiccontroller.plus"];
			[ccQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Plus"]];
            [port sendTo:"/classic/button/plus" types:"i", isPressedInt];
		break;
	}
	
	/* Fetch current location to allow clicking at the current mouse pointer position, instead of 0,0 */
	int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
	
	NSPoint p = [mainWindow mouseLocationOutsideOfEventStream];
	NSRect p2 = [mainWindow frame];
	
	point.x = p.x + p2.origin.x;
	point.y = dispHeight - p.y - p2.origin.y;
	
	NSString* modeName = [modes objectAtIndex:[[map valueForKey:@"mode"] intValue] ];
	//NSLog(@"modeName: %@", modeName);
	if ([modeName isEqualToString:@"Key"]){

		[self sendModifierKeys:map isPressed:isPressed]; 
		
		char c = (char)[[map valueForKey:@"character"] characterAtIndex:0];
		short keycode = GTMKeyCodeForCharCode(c);
		[self sendKeyboardEvent:keycode keyDown:isPressed];
	}else if ([modeName isEqualToString:@"\tReturn"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:36 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tTab"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:48 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tEsc"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:53 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tBackspace"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:51 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tUp"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:126 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tDown"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:125 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tLeft"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:123 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tRight"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:124 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tPage Up"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:116 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tPage Down"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:121 keyDown:isPressed];
		
	} else if ([modeName isEqualToString:@"Left Click"]) {
		[self sendModifierKeys:map isPressed:isPressed];
		
		if (!isLeftButtonDown && isPressed){	//start dragging...
			isLeftButtonDown = YES;
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, point, kCGMouseButtonLeft);
			
			
			CGEventSetType(event, kCGEventLeftMouseDown);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);	
		} else if (isLeftButtonDown && !isPressed) {	//end dragging...

			isLeftButtonDown = NO;

			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventLeftMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
		}
				
	} else if ([modeName isEqualToString:@"Left Click2"]) {
		
		if (!isPressed)
			return;
		
		[self sendModifierKeys:map isPressed:YES];
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, point, kCGMouseButtonLeft);
		
		
		CGEventSetType(event, kCGEventLeftMouseDown);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
		
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventLeftMouseUp);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
		
		[self sendModifierKeys:map isPressed:NO];

				
	} else if ([modeName isEqualToString:@"Right Click"]) {
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		
		[self sendModifierKeys:map isPressed:isPressed];
		
		
		
		if (!isRightButtonDown && isPressed){	//start dragging...
			isRightButtonDown = YES;
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, point, kCGMouseButtonRight);
			
			
			CGEventSetType(event, kCGEventRightMouseDown);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);	
		} else if (isRightButtonDown && !isPressed) {	//end dragging...
			
			isRightButtonDown = NO;
			
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
			
			CGEventSetType(event, kCGEventRightMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
		}
		
	} else if ([modeName isEqualToString:@"Right Click2"]) {
		if (!isPressed)
			return;
		
		[self sendModifierKeys:map isPressed:YES];
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, point, kCGMouseButtonRight);
		
		
		CGEventSetType(event, kCGEventRightMouseDown);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
		
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
		
		CGEventSetType(event, kCGEventRightMouseUp);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
		
		[self sendModifierKeys:map isPressed:NO];
		
		
	} else if ([modeName isEqualToString:@"Toggle Mouse (Motion)"]) {
		
		if (isPressed)
			return;
		
		if (mouseEventMode != 1){	//Mouse mode on
			mouseEventMode = 1;
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode On (Motion Sensors) =====", [textView string]]];

		} else {						//Mouse mode off
			mouseEventMode = 0;
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
			
			CGEventSetType(event, kCGEventRightMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventLeftMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			[self sendKeyboardEvent:58 keyDown:NO];
			[self sendKeyboardEvent:56 keyDown:NO];
			[self sendKeyboardEvent:55 keyDown:NO];
			[self sendKeyboardEvent:59 keyDown:NO];
			
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode Off =====", [textView string]]];


		}
		[mouseMode selectItemAtIndex:mouseEventMode];
		
	} else if ([modeName isEqualToString:@"Toggle Mouse (IR)"]){
		
		
		if (isPressed)
			return;
		
		if (mouseEventMode != 2){	//Mouse mode on
			mouseEventMode = 2;
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode On (IR) =====", [textView string]]];

		}else{						//Mouse mode off
			mouseEventMode = 0;
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
			
			CGEventSetType(event, kCGEventRightMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventLeftMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			[self sendKeyboardEvent:58 keyDown:NO];
			[self sendKeyboardEvent:56 keyDown:NO];
			[self sendKeyboardEvent:55 keyDown:NO];
			[self sendKeyboardEvent:59 keyDown:NO];
			
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode Off =====", [textView string]]];

		}
		[mouseMode selectItemAtIndex:mouseEventMode];
	}
	
	
}

- (void) sendModifierKeys:(id)map isPressed:(BOOL)isPressed {
	if ([[map valueForKey:@"shift"] boolValue]){
		[self sendKeyboardEvent:56 keyDown:isPressed];
	}
	
	if ([[map valueForKey:@"command"] boolValue]){
		[self sendKeyboardEvent:55 keyDown:isPressed];
	}
	
	if ([[map valueForKey:@"control"] boolValue]){
		[self sendKeyboardEvent:59 keyDown:isPressed];
	}
	
	if ([[map valueForKey:@"option"] boolValue]){
		[self sendKeyboardEvent:58 keyDown:isPressed];
	}
}

- (void) analogButtonChanged:(WiiButtonType) type amount:(unsigned short) press {

	switch (type) {
		case WiiClassicControllerLButton:
			[ccAnalogL setStringValue:[NSString stringWithFormat:@"%00X", press]];
		break;

		case WiiClassicControllerRButton:
			[ccAnalogR setStringValue:[NSString stringWithFormat:@"%00X", press]];
		break;
	}
}

/* 
	My nunchuk reports joystick values from ~0x20 to ~0xE0 +/- ~5 in each axis.
	There may be calibration that can/should be performed and other nunchuks may 
	report different values and the scaling should be done using the calibrated
	values.  See http://www.wiili.org/index.php/Nunchuk#Calibration_data for more
	details.
*/
- (void) joyStickChanged:(WiiJoyStickType)type tiltX:(unsigned short)tiltX tiltY:(unsigned short)tiltY {

    unsigned short max = 0xE0;
    unsigned short center = 0x80;
    
    float shiftedX = (tiltX * 1.0) - (center * 1.0);
    float shiftedY = (tiltY * 1.0) - (center * 1.0);
    
    float scaledX = (shiftedX * 1.0) / ((max - center) * 1.0);
    float scaledY = (shiftedY * 1.0) / ((max - center) * 1.0);
    
	if (type == WiiNunchukJoyStick) {

        
        [port sendTo:"/nunchuk/joystick" types:"ff", (float)scaledX,(float)scaledY];
        
			// NSLog(@"Joystick X = %f  Y= %f", scaledX, scaledY);
			[joystickQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"X_Position"]];
			[joystickQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Y_Position"]];
		
			[joystickX setStringValue: [NSString stringWithFormat:@"%00X", tiltX]];		
			[joystickY setStringValue: [NSString stringWithFormat:@"%00X", tiltY]];		
	} else if (type == WiiClassicControllerLeftJoyStick) {

            [port sendTo:"/classic/joystick/left" types:"ff", (float)scaledX,(float)scaledY];
			[ccLeftX setStringValue: [NSString stringWithFormat:@"%00X", tiltX]];
			[ccLeftY setStringValue: [NSString stringWithFormat:@"%00X", tiltY]];
        
	} else if (type == WiiClassicControllerRightJoyStick) {
	
            [port sendTo:"/classic/joystick/right" types:"ff", (float)scaledX,(float)scaledY];
			[ccRightX setStringValue: [NSString stringWithFormat:@"%00X", tiltX]];
			[ccRightY setStringValue: [NSString stringWithFormat:@"%00X", tiltY]];
        
	}
}

- (void) allPressureChanged:(WiiPressureSensorType)type bbData:(WiiBalanceBoardGrid) bbData bbDataInKg:(WiiBalanceBoardGrid) bbDataInKg {
	//This part is for writing data to a file.  Data is scaled to local gravitational acceleration and contains absolute local times.
	
	struct tm *t;
	struct timeval tval;
	struct timezone tzone;
	
	
	gettimeofday(&tval, &tzone);
	t = localtime(&(tval.tv_sec));
	
	// Write output if record mode
	if (recordToFile) {
		[recordHandle writeData:[[NSString stringWithFormat:@"%d:%d:%d.%06d,,,,%hu,%hu,%hu,%hu,%hu,%hu,%hu,%hu\n",  
								  t->tm_hour, t->tm_min, t->tm_sec, tval.tv_usec,
								  bbDataInKg.tr, bbDataInKg.br, bbDataInKg.tl,bbDataInKg.bl,
								  bbData.tr, bbData.br, bbData.tl, bbData.bl] dataUsingEncoding:NSASCIIStringEncoding]];
	}
	
	//End of part for writing data to file.	
}



- (void) pressureChanged:(WiiPressureSensorType)type pressureTR:(float) pressureTR pressureBR:(float) pressureBR 
                                                         pressureTL:(float) pressureTL pressureBL:(float) pressureBL {
	if (type == WiiBalanceBoardPressureSensor){
		[bPressureTR setStringValue: [NSString stringWithFormat:@"%.2fkg", pressureTR]];
		[bPressureBR setStringValue: [NSString stringWithFormat:@"%.2fkg", pressureBR]];
		[bPressureTL setStringValue: [NSString stringWithFormat:@"%.2fkg", pressureTL]];
		[bPressureBL setStringValue: [NSString stringWithFormat:@"%.2fkg", pressureBL]];
		[bbQCView setValue:[NSNumber numberWithFloat: 0.1 + (pressureTR/5)] forInputKey:[NSString stringWithString:@"sizeTR"]];
		[bbQCView setValue:[NSNumber numberWithFloat: 0.1 + (pressureBR/5)] forInputKey:[NSString stringWithString:@"sizeBR"]];
		[bbQCView setValue:[NSNumber numberWithFloat: 0.1 + (pressureTL/5)] forInputKey:[NSString stringWithString:@"sizeTL"]];
		[bbQCView setValue:[NSNumber numberWithFloat: 0.1 + (pressureBL/5)] forInputKey:[NSString stringWithString:@"sizeBL"]];
		
		//This part is for writing data to a file.  Data is scaled to local gravitational acceleration and contains absolute local times.
		
		struct tm *t;
		struct timeval tval;
		struct timezone tzone;
		
		
		gettimeofday(&tval, &tzone);
		t = localtime(&(tval.tv_sec));

		/* Center Of Gravity Widget logic */
		float cog_x = (pressureTR + pressureBR) - (pressureTL + pressureBL);
		float cog_y = (pressureTL + pressureTR) - (pressureBL + pressureBR);
		float cog_weight = (pressureTR + pressureBR + pressureTL + pressureBL);
		
		/* Make sure 'dodgy' BalanceBoards are synced well */
		if (cogCalibration) {
			cogAjustX = cog_x * -1;
			cogAjustY = cog_y * -1;
			cogCalibration = NO;
			[cogTextInfo setStringValue:[NSString stringWithFormat:@"Caliberated ajust x:%.2fkg - y:%.2fkg",cogAjustX, cogAjustY]];
		}
		cog_x += cogAjustX;
		cog_y += cogAjustY;

		if (cogRecording) {
			cogSamples += 1;
			cogRawWeight += cog_weight;
			cogRawX += cog_x;
			cogRawY += cog_y;
			[cogGridView setData:cog_x y:cog_y];
			[cogWeight setStringValue:[NSString stringWithFormat:@"%.2f", cog_weight]];
		}
		[cogGridView setFocusPointX:cog_x Y:cog_y];
		
#ifdef BALANCEBOARD_TO_KEYS
		/* Little hack (Proof Of Concept) of mapping */
				
		/* As determined at the user evaluations, a fix value of deadLevel 
		 * is not the way to go, percentage based is a much smarter approch 
		 */
		const unsigned short currentWeight = pressureTR + pressureBR + pressureTL + pressureBL;
		float deadLevelLR = ((float)currentWeight / 100) * [[[mappingController selection] valueForKey:@"balanceboard.deadzone_left_right"] floatValue];
		float deadLevelTB = ((float)currentWeight / 100) * [[[mappingController selection] valueForKey:@"balanceboard.deadzone_top_bottom"] floatValue];
		/* Set minimum tresshold allowing persons to set on WiiBalanceBoard */
		deadLevelLR = (deadLevelLR < 15)?15:deadLevelLR;
		deadLevelTB = (deadLevelTB < 15)?15:deadLevelTB;

		NSLog(@"%f", deadLevelLR);
		NSLog(@"%f", deadLevelTB);

		static BOOL leftActive = FALSE;
		static BOOL rightActive = FALSE;
		static BOOL forwardActive = FALSE;
		static BOOL backwardActive = FALSE;
		
		/* Google Earth mapping */
		/* XXX: Make me dynamic */
		/* 
		 const char moveLeft = 'a';
		 const char moveRight = 'd';
		 const char moveUp = 'w';
		 const char moveDown = 's';
		 */
		/* Wonderland mapping */
		const char moveLeft = 'z';
		const char moveRight = 'x';
		const char moveUp = 'w';
		const char moveDown = 's';
		
		if ((pressureTL + pressureBL) > deadLevelLR) {
			if (!leftActive) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode(moveLeft) keyDown:YES];
				leftActive = TRUE;
			}
		} else {
			if (leftActive) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode(moveLeft) keyDown:NO];
				leftActive = FALSE;
			}
		}
		
		if ((pressureTR + pressureBR) > deadLevelLR) {
			if (!rightActive) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode(moveRight) keyDown:YES];
				rightActive = TRUE;
			}
		} else {
			if (rightActive) {
				rightActive = FALSE;
				[self sendKeyboardEvent:GTMKeyCodeForCharCode(moveRight) keyDown:NO];
			}
		}
		
		if ((pressureTR +pressureTL) > deadLevelTB) {
			if (!forwardActive) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode(moveUp) keyDown:YES];
				forwardActive = TRUE;
			}
		} else {
			if (forwardActive) {
				forwardActive = FALSE;
				[self sendKeyboardEvent:GTMKeyCodeForCharCode(moveUp) keyDown:NO];
			}
		}
		
		if ((pressureBL + pressureBR) > deadLevelTB) {
			if (!backwardActive) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode(moveDown) keyDown:YES];
				backwardActive = TRUE;
			}
		} else {
			if (backwardActive) {
				backwardActive = FALSE;
				[self sendKeyboardEvent:GTMKeyCodeForCharCode(moveDown) keyDown:NO];
			}
		}
#endif
	}
}	

- (void) accelerationChanged:(WiiAccelerationSensorType)type accX:(unsigned short)accX accY:(unsigned short)accY accZ:(unsigned short)accZ{
	
	if (type == WiiNunchukAccelerationSensor){
		// Get calibration data
        [port sendTo:"/nunchuk/acc" types:"fff", (float)accX,(float)accY,(float)accZ];
        
		WiiAccCalibData data = [wii accCalibData:WiiNunchukAccelerationSensor];
        
        
		x0 = data.accX_zero;
		x3 = data.accX_1g;
		y0 = data.accY_zero;
		y2 = data.accY_1g;
		z0 = data.accZ_zero;
		z1 = data.accZ_1g;

		double ax = (double)(accX - x0) / (x3 - x0);
		double ay = (double)(accY - y0) / (y2 - y0);
		double az = (double)(accZ - z0) / (z1 - z0) * (-1.0);
        
        //from darwiinosc
        double roll = atan(ax) * 180.0 / 3.14 * 2;
		double pitch = atan(ay) * 180.0 / 3.14 * 2;
		
		// send orientation to a remote OSC address
		[port sendTo:"/nunchuk/orientation" types:"ff", (float)roll,(float)pitch];
        
		[graphView2 setData:ax y:ay z:az];
		[NunchukX setStringValue: [NSString stringWithFormat:@"%f", ax]];	
		[NunchukY setStringValue: [NSString stringWithFormat:@"%f", ay]];	
		[NunchukZ setStringValue: [NSString stringWithFormat:@"%f", az]];	
		
#ifdef NUNCHUK_TO_KEYS
		/* Little hack (Proof Of Concept) of mapping */
		const double deadLevel = 0.5;
		const double secondLevel = 0.1;
		static BOOL upActive = FALSE;
		static BOOL downActive = FALSE;
		static BOOL turnLeftActive = FALSE;
		static BOOL turnRightActive = FALSE;
		
		static NSDate* reftimeAY = nil;
		double secondsElapsedAY = [[NSDate date] timeIntervalSinceDate:reftimeAY];	
		
		static NSDate* reftimeAX = nil;
		double secondsElapsedAX = [[NSDate date] timeIntervalSinceDate:reftimeAX];	
		
		/* upActive < -0.5 < neutral < 0.5 < downActive */
		if (ay < (deadLevel * -1)) {
			if (!upActive && (secondsElapsedAY > secondLevel)) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode('r') keyDown:YES];
				upActive = TRUE;
			}
		} else if (ay > deadLevel) {
			if (!downActive && (secondsElapsedAY > secondLevel)) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode('f') keyDown:YES];
				downActive = TRUE;
			}
		} else {
			[reftimeAY release];
			reftimeAY = [[NSDate date] retain];
			if (upActive) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode('r') keyDown:NO];
				upActive = FALSE;
			}
			if (downActive) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode('f') keyDown:NO];
				downActive = FALSE;
			}		
		}
		
		/* turnLeftActive < -0.5 < neutral < 0.5 < turnRightActive */
		if (ax < (deadLevel * -1)) {
			if (!turnLeftActive && (secondsElapsedAX > secondLevel)) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode('a') keyDown:YES];
				turnLeftActive = TRUE;
			}
		} else if (ax > deadLevel) {
			if (!turnRightActive && (secondsElapsedAX > secondLevel)) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode('d') keyDown:YES];
				turnRightActive = TRUE;
			}
		} else {
			[reftimeAX release];
			reftimeAX = [[NSDate date] retain];
			if (turnLeftActive) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode('a') keyDown:NO];
				turnLeftActive = FALSE;
			}
			if (turnRightActive) {
				[self sendKeyboardEvent:GTMKeyCodeForCharCode('d') keyDown:NO];
				turnRightActive = FALSE;
			}		
		}
#endif	
		
		return;
	}
	
	[batteryLevel setDoubleValue:(double)[wii batteryLevel]];
	
	
	tmpAccX = accX;
	tmpAccY = accY;
	tmpAccZ = accZ;
	
    // send acceleration to a remote OSC address
	[port sendTo:"/wii/acc" types:"fff", (float)accX,(float)accY,(float)accZ];
    
    // values from the preset
    // maybe wrong?
    /*
	x0 = 128; //data.accX_zero;
	x3 = 153; //data.accX_1g;
	y0 = 129; //data.accY_zero;
	y2 = 154; //data.accY_1g;
    */
    
    
	id config = [mappingController selection];
	if ([[config valueForKey:@"manualCalibration"] boolValue]){
		x0 = [[config valueForKeyPath:@"wiimote.accX_zero"] intValue] ;
		x3 = [[config valueForKeyPath:@"wiimote.accX_1g"] intValue];
		y0 = [[config valueForKeyPath:@"wiimote.accY_zero"] intValue];
		y2 = [[config valueForKeyPath:@"wiimote.accY_1g"] intValue];
		z0 = [[config valueForKeyPath:@"wiimote.accZ_zero"] intValue];
		z1 = [[config valueForKeyPath:@"wiimote.accZ_1g"] intValue];
		
	}else{ 
		WiiAccCalibData data = [wii accCalibData:WiiRemoteAccelerationSensor];
		x0 = data.accX_zero;
		x3 = data.accX_1g;
		y0 = data.accY_zero;
		y2 = data.accY_1g;
		z0 = data.accZ_zero;
		z1 = data.accZ_1g;
	}
    
    double ax = (double)(accX - x0) / (x3 - x0);
	double ay = (double)(accY - y0) / (y2 - y0);
	double az = (double)(accZ - z0) / (z1 - z0) * (-1.0);
	
    // from darwiinosc
    double roll = atan(ax) * 180.0 / 3.14 * 2;
	double pitch = atan(ay) * 180.0 / 3.14 * 2;
    
    // send orientation to a remote OSC address
	[port sendTo:"/wii/orientation" types:"ff", (float)roll,(float)pitch];
    
//This part is for writing data to a file.  Data is scaled to local gravitational acceleration and contains absolute local times.
	
	struct tm *t;
	struct timeval tval;
	struct timezone tzone;
	
	
	gettimeofday(&tval, &tzone);
	t = localtime(&(tval.tv_sec));
	
	// Write output if record mode
	if (recordToFile) {
		[recordHandle writeData:[[NSString stringWithFormat:@"%d:%d:%d.%06d,%f,%f,%f,,,,,,,,\n",  
								  t->tm_hour, t->tm_min, t->tm_sec, tval.tv_usec, ax, ay, az] dataUsingEncoding:NSASCIIStringEncoding]];
	}
	
//End of part for writing data to file.
//Send same data to graphing window for live viewing and to text box to see values.
	
	[graphView setData:ax y:ay z:az];
	[WiimoteX setStringValue: [NSString stringWithFormat:@"%f", ax]];		
	[WiimoteY setStringValue: [NSString stringWithFormat:@"%f", ay]];		
	[WiimoteZ setStringValue: [NSString stringWithFormat:@"%f", az]];		
	
//End sending to live view.

#ifdef WIIREMOTE_MOTION_TO_KEYS
	/* Little hack (Proof Of Concept) of mapping */
	const double deadLevel = 0.5;
	const double secondLevel = 0.1;
	static BOOL upActive = FALSE;
	static BOOL downActive = FALSE;
	static BOOL turnLeftActive = FALSE;
	static BOOL turnRightActive = FALSE;
	
	static NSDate* reftimeAY = nil;
	double secondsElapsedAY = [[NSDate date] timeIntervalSinceDate:reftimeAY];	
	
	static NSDate* reftimeAX = nil;
	double secondsElapsedAX = [[NSDate date] timeIntervalSinceDate:reftimeAX];	
	
	/* upActive < -0.5 < neutral < 0.5 < downActive */
	if (ay < (deadLevel * -1)) {
		if (!upActive && (secondsElapsedAY > secondLevel)) {
			[self sendKeyboardEvent:GTMKeyCodeForCharCode('r') keyDown:YES];
			upActive = TRUE;
		}
	} else if (ay > deadLevel) {
		if (!downActive && (secondsElapsedAY > secondLevel)) {
			[self sendKeyboardEvent:GTMKeyCodeForCharCode('f') keyDown:YES];
			downActive = TRUE;
		}
	} else {
		[reftimeAY release];
		reftimeAY = [[NSDate date] retain];
		if (upActive) {
			[self sendKeyboardEvent:GTMKeyCodeForCharCode('r') keyDown:NO];
			upActive = FALSE;
		}
		if (downActive) {
			[self sendKeyboardEvent:GTMKeyCodeForCharCode('f') keyDown:NO];
			downActive = FALSE;
		}		
	}

	/* turnLeftActive < -0.5 < neutral < 0.5 < turnRightActive */
	if (ax < (deadLevel * -1)) {
		if (!turnLeftActive && (secondsElapsedAX > secondLevel)) {
			[self sendKeyboardEvent:GTMKeyCodeForCharCode('a') keyDown:YES];
			turnLeftActive = TRUE;
		}
	} else if (ax > deadLevel) {
		if (!turnRightActive && (secondsElapsedAX > secondLevel)) {
			[self sendKeyboardEvent:GTMKeyCodeForCharCode('d') keyDown:YES];
			turnRightActive = TRUE;
		}
	} else {
		[reftimeAX release];
		reftimeAX = [[NSDate date] retain];
		if (turnLeftActive) {
			[self sendKeyboardEvent:GTMKeyCodeForCharCode('a') keyDown:NO];
			turnLeftActive = FALSE;
		}
		if (turnRightActive) {
			[self sendKeyboardEvent:GTMKeyCodeForCharCode('d') keyDown:NO];
			turnRightActive = FALSE;
		}		
	}
#endif //WIIREMOTE_MOTION_TO_KEYS
	
	if (mouseEventMode != 1)	//Must be after graph and file data or they don't happen if Wii doesn't control mouse.
	return;
	
	
	//double roll = atan(ax) * 180.0 / 3.14 * 2;
	//double pitch = atan(ay) * 180.0 / 3.14 * 2;
    roll = atan(ax) * 180.0 / 3.14 * 2;
    pitch = atan(ay) * 180.0 / 3.14 * 2;
    
	int dispWidth = CGDisplayPixelsWide(kCGDirectMainDisplay);
	int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
	
	
	NSPoint p = [mainWindow mouseLocationOutsideOfEventStream];
	NSRect p2 = [mainWindow frame];
	
	point.x = p.x + p2.origin.x;
	point.y = dispHeight - p.y - p2.origin.y;
	
	float sens1 = [[config valueForKey:@"sensitivity1"] floatValue] * [[config valueForKey:@"sensitivity1"] floatValue];
	
	if (roll < -15)
		point.x -= 2 * sens1;
	if (roll < -45)
		point.x -= 4 * sens1;
	if (roll < -75)
		point.x -= 6 * sens1;
	
	if (roll > 15)
		point.x += 2 * sens1;
	if (roll > 45)
		point.x += 4 * sens1;
	if (roll > 75)
		point.x += 6 * sens1;
	
	// pitch -	-90 = vertical, IR port up
	//			  0 = horizontal, A-button up.
	//			 90 = vertical, IR port down
	
	// The "natural" hand position for the wiimote is ~ -40 up. 
	
	if (pitch < -50)
		point.y -= 2 * sens1;
	if (pitch < -60)
		point.y -= 4 * sens1;
	if (pitch < -80)
		point.y -= 6 * sens1;
	
	if (pitch > -15)
		point.y += 2 * sens1;
	if (pitch > -5)
		point.y += 4 * sens1;
	if (pitch > 15)
		point.y += 6 * sens1; 
	
	
	if (point.x < 0)
		point.x = 0;
	if (point.y < 0)
		point.y = 0;
	
	if (point.x > dispWidth)
		point.x = dispWidth - 1;
	
	if (point.y > dispHeight)
		point.y = dispHeight - 1;
	
    // send point to a remote OSC address.
	// point is not absolute but the difference of the current position and
	// the previous position.
	[port sendTo:"/wii/point" types:"ff", (float)point.x, (float)point.y];
    
	
	if (!isLeftButtonDown && !isRightButtonDown){
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventMouseMoved);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
	}else{		
		
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDragged, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventLeftMouseDragged);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);	
	}
	
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:[[NSNumber alloc] initWithDouble:x1] forKey:@"x1"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:y1] forKey:@"y1"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:z1] forKey:@"z1"];
	
	[defaults setObject:[[NSNumber alloc] initWithDouble:x2] forKey:@"x2"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:y2] forKey:@"y2"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:z2] forKey:@"z2"];
	
	[defaults setObject:[[NSNumber alloc] initWithDouble:x3] forKey:@"x3"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:y3] forKey:@"y3"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:z3] forKey:@"z3"];
	
	
	[defaults setObject:[[NSNumber alloc] initWithInt:[mappingController selectionIndex]] forKey:@"selection"];

	
	[graphView stopTimer];
	[graphView2 stopTimer];
	[cogGridView stopTimer];
	[wii closeConnection];
	
	[appDelegate saveAction:nil];
	
    [portIn stop];
	return NSTerminateNow;
}


- (void)sendKeyboardEvent:(CGKeyCode)keyCode keyDown:(BOOL)keyDown{
	CFRelease(CGEventCreate(NULL));		
	// this is Tiger's bug.
	//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
	
	
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, keyCode, keyDown);
	CGEventPost(kCGHIDEventTap, event);
	CFRelease(event);
	usleep(10000);
}


- (IBAction)openKeyConfiguration:(id)sender{
	//[keyConfigWindow setKeyTitle:[sender title]];

	NSManagedObjectContext * context  = [appDelegate managedObjectContext];

	[context commitEditing];



	[NSApp beginSheet:preferenceWindow
	   modalForWindow:mainWindow
        modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
	
}

- (IBAction)cogEnableSampleSize:(id)sender {
	if ([cogSampleSizeButton state] == NSOnState) {
		[cogSampleSize setEnabled:YES];
	} else {
		[cogSampleSize setEnabled:NO];
	}
}

- (void) cogStartRecord{
	cogRecording = YES;
	cogSamples = cogRawWeight = cogRawX = cogRawY = 0;
	[cogRecordButton setTitle:@"Stop Recording"];
	[cogTextInfo setStringValue:@"Recording 0:00:00 ..."];
	cogRecordedTime = 0;
	cogRecordTimer = [NSTimer scheduledTimerWithTimeInterval:1 
													  target:self selector:@selector(cogRecordTimerUpdate:) 
													userInfo:nil repeats:YES];
	
	[cogGridView reset];
	if ([cogSampleSizeButton state] == NSOnState) {
		[cogGridView setSampleSize:[cogSampleSize floatValue]];
	} else {
		[cogGridView setSampleSize:[cogRecordTime floatValue]];
	}
}

- (void) cogStopRecord{
	//XXX: average displacement values
	if (cogRecordTimer != nil) {
		[cogRecordTimer invalidate];
		cogRecordTimer = nil;
	}
	cogRecording = NO;
	[cogGridView stopTimer];
	[cogRecordButton setTitle:@"Start Recording"];
	
	/* Displacement is displayed kind of special, namely as percentage of the weight. 
	 * Basically it shows how many weight you are putting on one side of your body extra.
	 */
	float cog_avg_weight = cogRawWeight / cogSamples;
	float cog_displacement_x = (cogRawX / cogSamples) / cog_avg_weight * 100; 
	float cog_displacement_y = (cogRawY / cogSamples) / cog_avg_weight * 100;

	[cogTextInfo setStringValue:[NSString stringWithFormat:@"Average displacement X:%.2f%%     Y:%.2f%%",cog_displacement_x, cog_displacement_y]];	
}

- (void) cogRecordTimerUpdate:(NSTimer *)timer{
	cogRecordedTime += [timer timeInterval];
	[cogTextInfo setStringValue:[NSString stringWithFormat:@"Recording 0:00:%02.0f...",cogRecordedTime]];
	 if (cogRecordedTime >= [cogRecordTime floatValue]) {
		 [self cogStopRecord];
	 }
}	

- (void) cogRecordDelayTimerUpdate:(NSTimer *)timer{
	cogRecordedTime -= [timer timeInterval];
	[cogTextInfo setStringValue:[NSString stringWithFormat:@"Recording in %.0f sec...",cogRecordedTime]];
	if (cogRecordedTime <= 0) {
		[cogRecordTimer invalidate];
		cogRecordTimer = nil;
		[self cogStartRecord];
	}
}	
	 
- (IBAction)cogRecord:(id)sender{
	if (cogRecording == NO) {
		cogRecordedTime = [cogRecordDelay floatValue];
		/* Kick the record self timer, allowing the user to step on and get relaxed */
		if ([cogRecordDelay floatValue] > 0) {
			cogRecordTimer = [NSTimer scheduledTimerWithTimeInterval:1 
							target:self selector:@selector(cogRecordDelayTimerUpdate:) 
							userInfo:nil repeats:YES];			
		} else {
			[self cogStartRecord];
		}
	} else {
		[self cogStopRecord];
	}
}

- (IBAction)cogReset:(id)sender{
	cogAjustX = 0;
	cogAjustY = 0;
	[self cogStopRecord];
	[cogGridView reset];
	[cogTextInfo setStringValue:@"Reset - Press record to start..."];

}

- (IBAction)cogCalibrate:(id)sender{
	cogCalibration = YES;
	[cogTextInfo setStringValue:@"Calibrating..."];
}


- (void)setupInitialKeyMappings{
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];
	NSManagedObjectModel   * model    = [appDelegate managedObjectModel];
	NSDictionary           * entities = [model entitiesByName];
	NSEntityDescription    * entity   = [entities valueForKey:@"KeyMapping"];
	
	NSFetchRequest* fetch = [[NSFetchRequest alloc] init];
	NSError* error;
	
	[fetch setEntity:entity];
	
	NSArray* results = [context executeFetchRequest:fetch error:&error];
	if ([results count] > 0){
		return;
	}
	
	
	NSManagedObject* config = [self createNewConfigration:@"Apple Remote"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.up.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.up.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.up.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.up.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:6] forKeyPath:@"wiimote.up.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.down.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.down.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.down.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.down.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:7] forKeyPath:@"wiimote.down.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.left.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.left.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.left.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.left.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:8] forKeyPath:@"wiimote.left.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.right.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.right.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.right.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.right.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:9] forKeyPath:@"wiimote.right.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.a.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.a.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.a.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.a.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:12] forKeyPath:@"wiimote.a.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.b.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.b.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.b.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.b.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:2] forKeyPath:@"wiimote.b.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:YES] forKeyPath:@"wiimote.plus.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.plus.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.plus.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.plus.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:9] forKeyPath:@"wiimote.plus.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:YES] forKeyPath:@"wiimote.minus.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.minus.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.minus.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.minus.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:8] forKeyPath:@"wiimote.minus.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:YES] forKeyPath:@"wiimote.home.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.home.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.home.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.home.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:4] forKeyPath:@"wiimote.home.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.one.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.one.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.one.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.one.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:16] forKeyPath:@"wiimote.one.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:17] forKeyPath:@"wiimote.two.mode"];
	
	// Nunchuk
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"nunchuk.c.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"nunchuk.c.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"nunchuk.c.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"nunchuk.c.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"nunchuk.c.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"nunchuk.z.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"nunchuk.z.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"nunchuk.z.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"nunchuk.z.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"nunchuk.z.mode"];
	
	// Classic Controller
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.up.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.up.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.up.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.up.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.up.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.left.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.left.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.left.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.left.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.left.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.right.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.right.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.right.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.right.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.right.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.down.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.down.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.down.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.down.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.down.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.a.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.a.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.a.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.a.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.a.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.b.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.b.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.b.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.b.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.b.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.x.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.x.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.x.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.x.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.x.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.y.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.y.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.y.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.y.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.y.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.l.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.l.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.l.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.l.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.l.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.r.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.r.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.r.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.r.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.r.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.zl.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.zl.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.zl.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.zl.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.zl.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.zr.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.zr.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.zr.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.zr.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.zr.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.minus.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.minus.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.minus.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.minus.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.minus.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.home.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.home.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.home.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.home.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.home.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.plus.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.plus.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.plus.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"classiccontroller.plus.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:1] forKeyPath:@"classiccontroller.plus.mode"];

	[appDelegate saveAction:nil];
	
}

- (void)sheetDidEnd:(NSWindow *)sheetWin returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];

	if (returnCode == 1){
		[context commitEditing];
		[appDelegate saveAction:nil];
	}else{
		//[context discardEditing];
		[context rollback];
	}
	
	
	[sheetWin close];
}


- (IBAction)addConfiguration:(id)sender{
	int result = [NSApp runModalForWindow:enterNameWindow];
	[enterNameWindow close];
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];

	if (result == 1){
		id config = [self createNewConfigration:[newNameField stringValue]];
		[mappingController setSelectsInsertedObjects:YES];
		[mappingController addObject:config];
		
		//[context insertObject:config];
		
		[context commitEditing];
	}

}

- (NSManagedObject*)createNewConfigration:(NSString*)name{
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];
	NSManagedObject* config = [NSEntityDescription insertNewObjectForEntityForName:@"KeyConfiguration" inManagedObjectContext: context];
	NSManagedObject* wiimote = [NSEntityDescription insertNewObjectForEntityForName:@"Wiimote" inManagedObjectContext: context];
	NSManagedObject* nunchuk = [NSEntityDescription insertNewObjectForEntityForName:@"Nunchuk" inManagedObjectContext: context];
	NSManagedObject* classicController = [NSEntityDescription insertNewObjectForEntityForName:@"ClassicController" inManagedObjectContext: context];
	NSManagedObject* balancBoard = [NSEntityDescription insertNewObjectForEntityForName:@"BalanceBoard" inManagedObjectContext: context];

	// Wiimote 
	NSManagedObject* one = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* two = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* a = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* b = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* minus = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* plus = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* home = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* up = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* down = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* left = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* right = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	
	[wiimote setValue:one forKey:@"one"];
	[wiimote setValue:two forKey:@"two"];
	[wiimote setValue:a forKey:@"a"];
	[wiimote setValue:b forKey:@"b"];
	[wiimote setValue:minus forKey:@"minus"];
	[wiimote setValue:home forKey:@"home"];
	[wiimote setValue:plus forKey:@"plus"];
	[wiimote setValue:up forKey:@"up"];
	[wiimote setValue:down forKey:@"down"];
	[wiimote setValue:left forKey:@"left"];
	[wiimote setValue:right forKey:@"right"];
	
	// Nunchuk
	NSManagedObject* n_c = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* n_z = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];

	[nunchuk setValue:n_c forKey:@"c"];
	[nunchuk setValue:n_z forKey:@"z"];
	
	// Classic Controller
	NSManagedObject* cc_a = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_b = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_minus = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_plus = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_home = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_up = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_down = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_left = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_right = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	
	NSManagedObject* cc_x = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_y = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_l = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_r = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_zl = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* cc_zr = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	
	[classicController setValue:cc_a forKey:@"a"];
	[classicController setValue:cc_b forKey:@"b"];
	[classicController setValue:cc_x forKey:@"x"];
	[classicController setValue:cc_y forKey:@"y"];
	[classicController setValue:cc_minus forKey:@"minus"];
	[classicController setValue:cc_home forKey:@"home"];
	[classicController setValue:cc_plus forKey:@"plus"];
	[classicController setValue:cc_up forKey:@"up"];
	[classicController setValue:cc_down forKey:@"down"];
	[classicController setValue:cc_left forKey:@"left"];
	[classicController setValue:cc_right forKey:@"right"];
	[classicController setValue:cc_l forKey:@"l"];
	[classicController setValue:cc_r forKey:@"r"];
	[classicController setValue:cc_zl forKey:@"zl"];
	[classicController setValue:cc_zr forKey:@"zr"];
	
	// Devices
	[config setValue:wiimote forKey:@"wiimote"];
	[config setValue:nunchuk forKey:@"nunchuk"];
	[config setValue:classicController forKey:@"classiccontroller"];
	[config setValue:balancBoard forKey:@"balanceboard"];
	[config setValue:name forKey:@"name"];
	
	return config;
}


- (IBAction)enterSaveName:(id)sender{
    // OK button is pushed
	
	if ([[newNameField stringValue] length] == 0){
		return;
	}
	
    [NSApp stopModalWithCode:1];
}

- (IBAction)cancelEnterSaveName:(id)sender{
	// Cancel button is pushed
    [NSApp stopModalWithCode:0];

}

- (IBAction)deleteConfiguration:(id)sender{
	if ([[mappingController arrangedObjects] count] <= 1){
		return;
	}
	
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];
	[mappingController removeObjectAtArrangedObjectIndex:[mappingController selectionIndex]];
	[context commitEditing];

}

- (IBAction)setMouseModeEnabled:(id)sender{
	mouseEventMode = [sender indexOfSelectedItem];
	
	switch(mouseEventMode){
		case 0:
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
			
			CGEventSetType(event, kCGEventRightMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
			
			event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventLeftMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			[self sendKeyboardEvent:58 keyDown:NO];
			[self sendKeyboardEvent:56 keyDown:NO];
			[self sendKeyboardEvent:55 keyDown:NO];
			[self sendKeyboardEvent:59 keyDown:NO];
			
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode Off =====", [textView string]]];
			break;
		case 1:
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode On (Motion Sensors) =====", [textView string]]];
			break;
		case 2:
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode On (IR Sensor) =====", [textView string]]];
			
	}
}

/*
- (IBAction)getMii: (id)sender
{
       NSLog(@"Requesting Mii...");
       [wii getMii:0];
}

- (void)gotMiiData: (Mii*)m at:(int)slot
{
       Mii mii = *m;

       NSLog(@"Got Mii named %@ ", mii.creatorName);
       NSLog(@" at %@",slot);

       // save Mii binary file
       NSData* miiData = [NSData dataWithBytes:(void*)m length: MII_DATA_SIZE];
       NSSavePanel* theSavePanel = [NSSavePanel new];
       [theSavePanel setPrompt:NSLocalizedString(@"Save", @"Save")];
       if (NSFileHandlingPanelOKButton == [theSavePanel runModalForDirectory:NULL file:@"Untitled.mii"]) {
               NSURL *selectedFileURL = [theSavePanel URL];
               [miiData writeToURL:selectedFileURL atomically:NO];
       }
}
*/

#pragma mark -
#pragma mark WiiRemoteDiscovery delegates

- (void) WiiRemoteDiscoveryError:(int)code {
	[discoverySpinner stopAnimation:self];
	[textView setString:[NSString stringWithFormat:@"%@\n===== WiiRemoteDiscovery error.  If clicking Find Wiimote gives this error, try System Preferences > Bluetooth > Devices, delete Nintendo. (%d) =====", [textView string], code]];
    [port sendTo:"/wii/connected" types:"i", 0];
}

- (void) willStartWiimoteConnections {
	[textView setString:[NSString stringWithFormat:@"%@\n===== WiiRemote discovered.  Opening connection. =====", [textView string]]];
}

- (void) WiiRemoteDiscovered:(WiiRemote*)wiimote {
	
	//	[discovery stop];
	[port sendTo:"/wii/connected" types:"i", 1];
	// the wiimote must be retained because the discovery provides us with an autoreleased object
	wii = [wiimote retain];
	[wiimote setDelegate:self];
	
	[textView setString:[NSString stringWithFormat:@"%@\n===== Connected to WiiRemote =====", [textView string]]];
	[discoverySpinner stopAnimation:self];
	
	[wiimote setLEDEnabled1:YES enabled2:NO enabled3:NO enabled4:NO];
	[wiimoteQCView setValue:[NSNumber numberWithBool:[led1 state] ] forInputKey:[NSString stringWithString:@"LED_1"]];

	[wiimote setMotionSensorEnabled:YES];
//	[wiimote setIRSensorEnabled:YES];

	[graphView startTimer];
	[graphView2 startTimer];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[mappingController setSelectionIndex:[[defaults objectForKey:@"selection"] intValue]];
}

- (IBAction)setRemoteAddress:(id)sender{
    
    if ([[theRemoteAddress stringValue] length] == 0){
		return;
	}
	
	NSString *addressInput = [theRemoteAddress stringValue];
	NSNumber *portInput = [NSNumber numberWithInt:[theRemotePort intValue]];
	int myRemotePort = [portInput intValue];
	
	NSNumber *portRcv = [NSNumber numberWithInt:[theRcvPort intValue]];
	short myRcvPort = [portRcv intValue];
    
	const char *temp = [addressInput fileSystemRepresentation];
	int len = strlen(temp);
	char myAddress[len+1];
	strcpy(myAddress, temp);
	
	[textView setString:[NSString stringWithFormat:@"%@\n===== changing remote address to %s : %u =====", [textView string], myAddress, myRemotePort]];
    [textView setString:[NSString stringWithFormat:@"%@\n===== changed receive port to %u =====", [textView string], myRcvPort]];
	
	port   = [OSCPort oscPortToAddress:myAddress portNumber: myRemotePort];
	[port retain];
	[port sendTo:"/wii/connected" types:"i", 1];
    
    //[portIn stop];

	// receive OSC messages. crashing if i want to change it!
    //portIn = [[OSCInPort alloc] initPort: 5601];
    /*
	OSCcontainer wiiContainer = [portIn newContainerNamed: "wii"];
	[portIn newMethodNamed: "batterylevel" under: wiiContainer callback:GetBatteryLevel context: self];
	[portIn newMethodNamed: "forcefeedback" under: wiiContainer callback:SetForceFeedback context: self];
	[portIn newMethodNamed: "led" under: wiiContainer callback:SetLED context: self];
     */
	//[portIn start];

    
}


@end
