#import "GraphView.h"
#import <OpenGL/OpenGL.h> 
#import <OpenGL/gl.h> 
#import <OpenGL/glu.h> 
#import "GraphPoint.h"
#import <sys/time.h>


@implementation GraphView

- (void)awakeFromNib{
	lock  = [[NSLock alloc] init];
	datax = [[NSMutableArray array] retain];
	datay = [[NSMutableArray array] retain];
	dataz = [[NSMutableArray array] retain];
	_freshGrid = TRUE;
}

- (void) resizeView : (NSRect) rect { 
	glViewport( (GLint) rect.origin.x  , (GLint) rect.origin.y, 
				(GLint) rect.size.width, (GLint) rect.size.height ); 

} 

- (void)setIRPointX:(float)x Y:(float)y{
	_x = x;
	_y = y;
}

- (id) initWithFrame : (NSRect) frameRect{
	
	_x = _y = -2;
	
	NSOpenGLPixelFormatAttribute attr[] = { 
		NSOpenGLPFADoubleBuffer, 
		NSOpenGLPFAAccelerated , 
		NSOpenGLPFAStencilSize , 32,
		NSOpenGLPFAColorSize   , 32,
		NSOpenGLPFADepthSize   , 32,
		0
	};
	
	NSOpenGLPixelFormat* pFormat; 
	pFormat = [ [ [ NSOpenGLPixelFormat alloc ] initWithAttributes : attr ] autorelease ]; 
	self = [ super initWithFrame : frameRect pixelFormat : pFormat ];
	[ [ self openGLContext ] makeCurrentContext ];
	glClearColor( 1.0, 1.0, 1.0, 1.0 );
	[self display];
	return( self ); 
}

-(void)startTimer{
	animTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(drawAnimation:) userInfo:nil repeats:YES];

}

- (void)stopTimer{
	[animTimer invalidate];
}

- (void) drawAnimation: (NSTimer*)timer{
	[self display];
}

- (void) drawGrid{
	glClearColor(1.0, 1.0, 1.0, 1.0);
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	
	// Draw a grid in gray and black before drawing data so the grid will be under the data.
	// This creates the horizontal lines for the grid.
	glBegin (GL_LINE_STRIP);
	{
		int i;
		glColor4f(0.7, 0.7, 0.7, 1.0);
		for (i = 0; i < 10; i++){
			float test = sin(i * 3.14159265358979);
			float x = 1.1 * test / fabs(test);
			float y = i * 0.2 - 1.0;
			glVertex2f(x, y);
			glVertex2f(-x, y);
		}
	}
	glEnd();
	
	// This creates stable vertical lines for the grid.
	glBegin (GL_LINE_STRIP);
	{
		int i;
		glColor4f(0.7, 0.7, 0.7, 1.0);
		for (i = 0; i < 10; i++){
			float test = sin(i * 3.14159265358979);
			float y = 1.1 * test / fabs(test);
			float x = i * 0.2 - 1.0;
			glVertex2f(x, y);
			glVertex2f(x, -y);
		}
	}
	glEnd();
	
	// This makes the two axes black instead of gray.
	glBegin (GL_LINE_STRIP);		//Draw a double line so the axis is a little thicker than other lines.
	{
		glColor4f(0.0, 0.0, 0.0, 1.0);
		float x1 = 0.001;
		float y = 1.1;
		glVertex2f(x1, y);
		glVertex2f(x1, -y);
		float x2 = -0.001;
		glVertex2f(x2, -y);
		glVertex2f(x2, y);
	}
	glEnd();
	
	glBegin (GL_LINE_STRIP);		//Draw a double line so the axis is a little thicker than other lines.
	{
		glColor4f(0.0, 0.0, 0.0, 1.0);
		float y1 = 0.01;
		float x = 1.1;
		glVertex2f(x, y1);
		glVertex2f(-x, y1);
		float y2 = -0.01;
		glVertex2f(-x, y2);
		glVertex2f(x, y2);
	}
	glEnd();
	
}

- (void) drawRect : (NSRect) rect{
	[self resizeView: rect];
	struct timeval tval;
	struct timezone tzone;
	gettimeofday(&tval, &tzone);
	float scale = [scaleField floatValue];
	
	if (_freshGrid) {
		[self drawGrid];
		glFinish();
		_freshGrid = FALSE;
	}
	
	while( [datax count] && [datay count] && [dataz count] && ![self shouldDraw:[[datax objectAtIndex:0] timeValue] now:tval]){
		[datax removeObjectAtIndex: 0];
		[datay removeObjectAtIndex: 0];
		[dataz removeObjectAtIndex: 0];
	}
	
	if (![datax count] || ![datay count] || ![dataz count])
		return;

	[self drawGrid];
	
//Now we're plotting data.
			
	glBegin (GL_LINE_STRIP);
	{
		int i;
		glColor4f(1.0, 0.0, 0.0, 1.0);			//red
		for (i = 0; i < [datax count]; i++){
			GraphPoint* p = [datax objectAtIndex:i];
			float y = [p value] / scale;
			float x = [self timeDif:[p timeValue] subtract:tval]/5 + 1.0;
			glVertex2f(x, y);
		}	
	}
	glEnd();
	
	glBegin (GL_LINE_STRIP);
	{
		int i;
		glColor4f(0.0, 1.0, 0.0, 1.0);			//green
		for (i = 0; i < [datay count]; i++){
			GraphPoint* p = [datay objectAtIndex:i];
			float y = [p value] / scale;
			float x = [self timeDif:[p timeValue] subtract:tval]/5 + 1.0;
			glVertex2f(x, y);
		}		
	}
	glEnd();
	
	glBegin (GL_LINE_STRIP);
	{
		int i;
		glColor4f(0.0, 0.0, 1.0, 1.0);			//blue
		for (i = 0; i < [dataz count]; i++){
			GraphPoint* p = [dataz objectAtIndex:i];
			float y = [p value] / scale;
			float x = [self timeDif:[p timeValue] subtract:tval]/5 + 1.0;
			glVertex2f(x, y);
		}
	}
	glEnd();
	
	if (_x > -2){
		glColor4f(1.0, 1.0, 0.0, 1.0);
		glRectf( _x - 0.05* (rect.size.height / rect.size.width), _y - 0.05, _x + 0.05 * (rect.size.height / rect.size.width), _y + 0.05 );
	}

	
	glFinish();
	[[self openGLContext] flushBuffer];
	
}

- (float)timeDif:(struct timeval)timeVal1 subtract:(struct timeval)timeVal2{
	float dif = (float)(timeVal1.tv_sec - timeVal2.tv_sec) + (float)(timeVal1.tv_usec - timeVal2.tv_usec) / (float)1000000.0;
	
	return dif;
}

- (BOOL)shouldDraw:(struct timeval)tval now:(struct timeval)now {
	double dif = now.tv_sec - tval.tv_sec + (double)(now.tv_usec - tval.tv_usec) / 1000000.0;
	
	if (dif > SAMPLETIME){
		return NO;
	}else{
		return YES;
	}
	
}


-(void)setData:(float)x y:(float)y z:(float)z{
	struct timeval tval;
	struct timezone tzone;
	gettimeofday(&tval, &tzone);
	
	GraphPoint* pointX = [[GraphPoint alloc] initWithValue:(float)x time:tval];
	GraphPoint* pointY = [[GraphPoint alloc] initWithValue:(float)y time:tval];
	GraphPoint* pointZ = [[GraphPoint alloc] initWithValue:(float)z time:tval];
	
	[datax addObject:pointX];
	[datay addObject:pointY];
	[dataz addObject:pointZ];
	[pointX release];
	[pointY release];
	[pointZ release];

}



@end
