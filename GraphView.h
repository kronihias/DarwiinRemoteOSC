/* GraphView */

#import <Cocoa/Cocoa.h>

#define SAMPLETIME 10.0

@interface GraphView : NSOpenGLView
{
	NSMutableArray* datax;
	NSMutableArray* datay;
	NSMutableArray* dataz;
	NSTimer* animTimer;
	
	NSLock* lock;
	float _x;
	float _y;
	BOOL _freshGrid;

	IBOutlet NSTextField* scaleField;  //enables scaling of live window		
}
- (void)setIRPointX:(float)x Y:(float)y;
- (id) initWithFrame:(NSRect)frame;
- (void)setData:(float)x y:(float)y z:(float)z;
- (float)timeDif:(struct timeval)timeVal1 subtract:(struct timeval)timeVal2;
- (BOOL)shouldDraw:(struct timeval)tval now:(struct timeval)now;
- (void) drawAnimation: (NSTimer*)timer;
- (void) startTimer;
- (void) stopTimer;
- (void) drawGrid;
@end
