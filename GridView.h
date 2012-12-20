/* GraphView */

#import <Cocoa/Cocoa.h>

#define DEFAULT_SAMPLETIME 10.0

@interface GridView : NSOpenGLView
{
	NSMutableArray* data;
	NSTimer* animTimer;
	
	NSLock* lock;
	float _x;
	float _y;
	BOOL _freshGrid;
	BOOL _dataChanged;
	float _sampleTime;
	
	IBOutlet NSTextField* scaleField;  //enables scaling of live window		
}
- (void)setFocusPointX:(float)x Y:(float)y;
- (id) initWithFrame:(NSRect)frame;
- (void)setData:(float)x y:(float)y;
- (void)setSampleSize:(float)sec;
- (float)timeDif:(struct timeval)timeVal1 subtract:(struct timeval)timeVal2;
- (BOOL)shouldDraw:(struct timeval)tval now:(struct timeval)now;
- (void)drawAnimation: (NSTimer*)timer;
- (void)startTimer;
- (void)stopTimer;
- (void)drawGrid;
- (void)reset;
@end
