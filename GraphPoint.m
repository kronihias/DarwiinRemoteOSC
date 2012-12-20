//
//  GraphPoint.m
//  DarwiinRemote
//
//  Created by KIMURA Hiroaki on 06/05/29.
//  Copyright 2006 KIMURA Hiroaki. All rights reserved.
//

#import "GraphPoint.h"


@implementation GraphPoint

- (id)initWithValue:(float)_value time:(struct timeval)_tval{
	value = _value;
	tval = _tval;
	
	/* Bogus values to keep view consistant */
	x = _value;
	y = _tval.tv_sec;
	
	return self;
}

- (id)initWithCoordX:(float)_x Y:(float) _y time:(struct timeval)_tval{
	x = _x;
	y = _y;
	
	/* Bogus values to keep view consistant */
	value = _y;
	tval = _tval;
	
	return self;
}

- (float) getX {
	return x;
}

- (float) getY {
	return y;
}

- (float) value {
	return value;
}
- (struct timeval)timeValue{
	return tval;
}


@end
