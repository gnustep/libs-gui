/** <title>CGPath</title>

 <abstract>C Interface to graphics drawing library</abstract>

 Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: August 2010

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#import "OPPath.h"

static NSUInteger OPNumberOfPointsForElementType(CGPathElementType type)
{
  NSUInteger numPoints;
  switch (type)
  {
    case kCGPathElementMoveToPoint:
      numPoints = 1;
      break;
    case kCGPathElementAddLineToPoint:
      numPoints = 1;
      break;
    case kCGPathElementAddQuadCurveToPoint:
      numPoints = 2;
      break;
    case kCGPathElementAddCurveToPoint:
      numPoints = 3;
      break;
    case kCGPathElementCloseSubpath:
    default:
      numPoints = 0;
      break;
  }
  return numPoints;
}

@implementation CGPath

- (id) copyWithZone: (NSZone*)zone
{
  return [self retain];
}

- (id) initWithCGPath: (CGPathRef)path
{
  if (path)
  {
    [self release];
    return [path retain];
  }
  else
  {
    self = [super init];
    return self;
  }
}

- (void)dealloc
{
  free(_elementsArray);
  [super dealloc];
}

- (NSUInteger) count
{
  return _count;
}

- (CGPathElementType) elementTypeAtIndex: (NSUInteger)index points: (CGPoint*)outPoints
{
  OPPathElement elem = _elementsArray[index];
  if (outPoints)
  {
    switch (OPNumberOfPointsForElementType(elem.type))
    {
      case 3:
        outPoints[2] = elem.points[2];
      case 2:
        outPoints[1] = elem.points[1];
      case 1:
        outPoints[0] = elem.points[0];
      case 0:
      default:
        break;
    }
  }
  return elem.type;
}

- (BOOL)isEqual:(id)otherObj
{
  if (self == otherObj)
  {
    return YES;
  }
  if (![otherObj isKindOfClass: [CGPath class]])
  {
    return NO;
  }

  CGPath *path2 = (CGPath*)otherObj;

  NSUInteger count1 = [self count];
  NSUInteger count2 = [path2 count];

  if (count1 != count2)
  {
    return NO;
  }

  for (NSUInteger i=0; i<count1; i++)
  {
    CGPoint points1[3];
    CGPoint points2[3];
    CGPathElementType type1 = [self elementTypeAtIndex: i points: points1];
    CGPathElementType type2 = [path2 elementTypeAtIndex: i points: points2];

    if (type1 != type2)
    {
      return NO;
    }

    NSUInteger numPoints = OPNumberOfPointsForElementType(type1);
    for (NSUInteger p=0; p<numPoints; p++)
    {
      if (!CGPointEqualToPoint(points1[p], points2[p]))
      {
        return NO;
      }
    }
  }
  return YES;
}

- (BOOL)isRect: (CGRect*)outRect
{
  if (_count != 5)
  {
    return NO;
  }

  if (_elementsArray[0].type != kCGPathElementMoveToPoint ||
    _elementsArray[1].type != kCGPathElementAddLineToPoint ||
    _elementsArray[2].type != kCGPathElementAddLineToPoint ||
    _elementsArray[3].type != kCGPathElementAddLineToPoint ||
    _elementsArray[4].type != kCGPathElementCloseSubpath)
  {
    return NO;
  }

  BOOL clockwise;
  if (_elementsArray[1].points[0].x == _elementsArray[0].points[0].x)
  {
    clockwise = YES;
  }
  if (_elementsArray[1].points[0].y == _elementsArray[0].points[0].y)
  {
    clockwise = NO;
  }
  else
  {
    return NO;
  }

  // Check that it is actually a rectangle
  if (clockwise)
  {
    if (_elementsArray[2].points[0].y != _elementsArray[1].points[0].y ||
        _elementsArray[3].points[0].x != _elementsArray[2].points[0].x ||
        _elementsArray[3].points[0].y != _elementsArray[0].points[0].y)
    {
      return NO;
    }
  }
  else
  {
    if (_elementsArray[2].points[0].x != _elementsArray[1].points[0].x ||
        _elementsArray[3].points[0].y != _elementsArray[2].points[0].y ||
        _elementsArray[3].points[0].x != _elementsArray[0].points[0].x)
    {
      return NO;
    }
  }

  if (outRect)
  {
    outRect->origin = _elementsArray[0].points[0];
    // FIXME: do we abs the width/height?
    outRect->size.width = _elementsArray[2].points[0].x - _elementsArray[0].points[0].x;
    outRect->size.height = _elementsArray[2].points[0].y - _elementsArray[0].points[0].y;
  }
  return YES;
}

- (void) addElementWithType: (CGPathElementType)type points: (CGPoint[])points
{
  [NSException raise: NSGenericException format: @"Attempt to modify immutable CGPath"];
}

@end


@implementation CGMutablePath

- (void) addElementWithType: (CGPathElementType)type points: (CGPoint[])points
{
  if (_elementsArray)
  {
    if (_count + 1 > _capacity)
    {
      _capacity += 32;
      _elementsArray = realloc(_elementsArray, _capacity * sizeof(OPPathElement));
    }
  }
  else
  {
    _capacity = 32;
    _elementsArray = malloc(_capacity * sizeof(OPPathElement));
  }

  _elementsArray[_count].type = type;
  switch (OPNumberOfPointsForElementType(type))
  {
    case 3:
      _elementsArray[_count].points[2] = points[2];
    case 2:
      _elementsArray[_count].points[1] = points[1];
    case 1:
      _elementsArray[_count].points[0] = points[0];
    case 0:
    default:
      break;
  }
  _count++;
}

- (id) initWithCGPath: (CGPathRef)path
{
  self = [super init];

  if ([path isKindOfClass: [CGPath class]])
  {
    _count = path->_count;
    _capacity = path->_count;
    _elementsArray = malloc(path->_count * sizeof(OPPathElement));
    if (NULL == _elementsArray)
    {
      [self release];
      return nil;
    }
    memcpy(_elementsArray, path->_elementsArray, _count * sizeof(OPPathElement));
  }

  return self;
}

- (id) copyWithZone: (NSZone*)zone
{
  return [[CGMutablePath alloc] initWithCGPath: self];
}

@end


/*
 * Functions to generate curves as approximations of circular arcs. Follows the
 * algorithm used by cairo.
 */


/*
 * The values in this table come from cairo's cairo-arc.c. We use them to get
 * simliar appearance for arcs drawn by cairo itself and those added to CGPaths.
 * The values apply for (M_PI / (index + 1)).
 */
static CGFloat approximationErrorTable[] = {
  0.0185185185185185036127,
  0.000272567143730179811158,
  2.38647043651461047433e-05,
  4.2455377443222443279e-06 ,
  1.11281001494389081528e-06,
  3.72662000942734705475e-07,
  1.47783685574284411325e-07,
  6.63240432022601149057e-08,
  3.2715520137536980553e-08,
  1.73863223499021216974e-08,
  9.81410988043554039085e-09,
};

static NSUInteger approximationErrorTableCount = 11;

static inline CGFloat
_OPPathArcAxisLengthForRadiusByApplyingTransform(CGFloat radius,
  const CGAffineTransform *m)
{
  if (NULL == m)
  {
    return radius;
  }
  CGFloat i = ((m->a * m->a) + (m->b * m->b));
  CGFloat j = ((m->c * m->c) + (m->d * m->d));
  CGFloat f = (0.5 * (i + j));
  CGFloat g = (0.5 * (i - j));
  CGFloat h = ((m->a * m->c) + (m->b * m->d));

  //TODO: Maybe provide hypot() for non C99 compliant compilers?
  return (radius * sqrt(f + hypot(g, h)));
}


static inline CGFloat
_OPPathArcErrorForAngle(CGFloat angle)
{
  // This formula is also used for error computation in cairo:
  return 2.0/27.0 * pow (sin (angle / 4), 6) / pow (cos (angle / 4), 2);
}

// Hopefully the compiler will specialize this for tolerance == 0.1 (default):
static inline CGFloat
_OPPathArcMaxAngleForTolerance(CGFloat tolerance)
{
  CGFloat angle = 0;
  CGFloat error = 0;
  NSUInteger index = 0;

  for (index = 0; index < approximationErrorTableCount; index++)
  {
    if (approximationErrorTable[index] < tolerance)
	{
		return (M_PI / (index + 1));
	}
  }
  // Increment to get rid of the offset:
  index++;
  do
  {
    angle = (M_PI / index++);
	error = _OPPathArcErrorForAngle(angle);
  } while (error > tolerance);
  return 0;
}

NSUInteger
_OPPathRequiredArcSegments(CGFloat angle,
  CGFloat radius,
  const CGAffineTransform *m)
{
  // Transformation can turn the circle arc into the arc of an ellipse, we need
  // its major axis.
  CGFloat majorAxis = _OPPathArcAxisLengthForRadiusByApplyingTransform(radius, m);
  CGFloat maxAngle = _OPPathArcMaxAngleForTolerance((OPPathArcDefaultTolerance / majorAxis));

  return ceil((fabs(angle) / maxAngle));
}


