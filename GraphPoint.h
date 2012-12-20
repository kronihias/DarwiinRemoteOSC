//
//  GraphPoint.h
//  DarwiinRemote
//
//  Created by KIMURA Hiroaki on 06/05/29.
//  Copyright 2006 KIMURA Hiroaki. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GraphPoint : NSObject {
	
	struct timeval tval;
	//float tval;
	float value;
	float x;
	float y;

}

- (id)initWithCoordX:(float)_x Y:(float) _y time:(struct timeval)_tval;
- (id)initWithValue:(float)_value time:(struct timeval)_tval;
- (float)value;
- (struct timeval)timeValue;
- (float)getX;
- (float)getY;

@end
