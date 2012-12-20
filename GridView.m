#import "GridView.h"
#import <OpenGL/OpenGL.h> 
#import <OpenGL/gl.h> 
#import <OpenGL/glu.h> 
#import "GraphPoint.h"
#import <sys/time.h>


@implementation GridView

- (void)awakeFromNib{
	lock  = [[NSLock alloc] init];
	data = [[NSMutableArray array] retain];
	_freshGrid = TRUE;
	_dataChanged = FALSE;
	_x = _y = FLT_MIN;
	_sampleTime = DEFAULT_SAMPLETIME;
	[self startTimer];

}

- (void) resizeView : (NSRect) rect { 
	glViewport( (GLint) rect.origin.x  , (GLint) rect.origin.y, 
				(GLint) rect.size.width, (GLint) rect.size.height ); 
	[self drawGrid];

} 

- (void)setFocusPointX:(float)x Y:(float)y{
	_x = x;
	_y = y;
	_dataChanged = TRUE;
}

- (id) initWithFrame : (NSRect) frameRect{
	/* Hack used FLT_MIN as value, meaning not yet set */
	
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
	if (animTimer != nil) {
		[animTimer invalidate];
		animTimer = nil;
	}
}

- (void) drawAnimation: (NSTimer*)timer{
	/* Only redraw if needed */
	if (_dataChanged) {
		[self display];
		_dataChanged = FALSE;
	}
}

/* Grid drawing, apart from the logic */
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
	glBegin (GL_QUADS);		//Draw a box so the axis is a little thicker than other lines.
	{
		glColor4f(0.0, 0.0, 0.0, 1.0);
		float x1 = 0.01;
		float y = 1.1;
		glVertex2f(x1, y);
		glVertex2f(x1, -y);
		float x2 = -0.01;
		glVertex2f(x2, -y);
		glVertex2f(x2, y);
	}
	glEnd();
	
	glBegin (GL_QUADS);		//Draw a box so the axis is a little thicker than other lines.
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
	const float scale = [scaleField floatValue];
	float pointsize = 0.01;

	/* Make sure to draw grid on initial load */
	if (_freshGrid) {
		[self drawGrid];
		_freshGrid = FALSE;
		glFinish();
	}
	
	/* Get rid of the old values */
	while( [data count] && ![self shouldDraw:[[data objectAtIndex:0] timeValue] now:tval]){
		[data removeObjectAtIndex: 0];
	}
	
	[self drawGrid];
	
	/* Now we're plotting data. */
	{
		int i;
		for (i = 0; i < [data count]; i++){
			GraphPoint* p = [data objectAtIndex:i];
			float x = [p getX] / scale;
			float y = [p getY] / scale;
			
			/* Different colours depending on the 'age' of the point */
			float age = rand() / RAND_MAX;
			glColor4f(1.0, 0.0, 0.0, age);			//redish
			glRectf( x - pointsize* (rect.size.height / rect.size.width), y - pointsize, x + pointsize * (rect.size.height / rect.size.width), y + pointsize );
		}	
	}
	
	if (_x != FLT_MIN) {
		/* XXX: Do something pretty with fixed focus point */
		glColor4f(0.0, 0.0, 1.0, 0.5);			//yellow
		pointsize *= 2;
		glRectf((_x / scale) - pointsize * (rect.size.height / rect.size.width), (_y /scale) - pointsize, (_x /scale) + pointsize * (rect.size.height / rect.size.width), (_y /scale) + pointsize );	
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
	
	if (dif > _sampleTime){
		return NO;
	}else{
		return YES;
	}
	
}


-(void)setData:(float)x y:(float)y {
	struct timeval tval;
	struct timezone tzone;
	gettimeofday(&tval, &tzone);
	
	GraphPoint* point = [[GraphPoint alloc] initWithCoordX:x Y:y time:tval];
	
	[data addObject:point];
	[point release];
	_dataChanged = TRUE;

}

-(void)reset {
	[self stopTimer];
	[self awakeFromNib];
	[self display];
	
}

- (void)setSampleSize:(float)sec {
	_sampleTime = sec;
}
@end
