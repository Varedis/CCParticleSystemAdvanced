#import "CCParticleSystemAdvanced.h"

@implementation CCParticleSystemAdvanced

@synthesize active = _active, duration = _duration;
@synthesize sourcePosition = _sourcePosition, posVar = _posVar;
@synthesize particleCount = _particleCount;
@synthesize life = _life, lifeVar = _lifeVar;
@synthesize angle = _angle, angleVar = _angleVar;
@synthesize startSpin = _startSpin, startSpinVar = _startSpinVar;
@synthesize endSpin = _endSpin, endSpinVar = _endSpinVar;
@synthesize emissionRate = _emissionRate;
@synthesize startSize = _startSize, startSizeVar = _startSizeVar;
@synthesize endSize = _endSize, endSizeVar = _endSizeVar;
@synthesize opacityModifyRGB = _opacityModifyRGB;
@synthesize blendFunc = _blendFunc;
@synthesize positionType = _positionType;
@synthesize autoRemoveOnFinish = _autoRemoveOnFinish;
@synthesize emitterMode = _emitterMode;
@synthesize atlasIndex = _atlasIndex;
@synthesize totalParticles = _totalParticles;

@synthesize looping = _looping;
@synthesize startDelay = _startDelay;
@synthesize emitterType = _emitterType, emitterRadius = _emitterRadius, emitterWidth = _emitterWidth, emitterHeight = _emitterHeight;

-(NSUInteger) getMaxParticles
{
    NSUInteger amount = ceil([[_dict valueForKey:@"emissionRate"] floatValue] * [[_dict valueForKey:@"duration"] floatValue]);
    
    NSUInteger maxParticles = [[_dict valueForKey:@"maxParticles"] intValue];
    
    if(amount > maxParticles)
        amount = maxParticles;
    
    return amount;
}

-(id) initWithDictionary:(NSDictionary *)dictionary
{   
    _dict = [dictionary retain];
//    TODO: Figure out looping
    
    _looping = [[dictionary valueForKey:@"looping"] unsignedIntegerValue];
    
    NSUInteger maxParticles = [self getMaxParticles];
    
    _emitterType = [[dictionary valueForKey:@"emitterType"] intValue];
    
	// self, not super
	if ((self=[self initWithTotalParticles:maxParticles] ) )
	{
		// angle
		_angle = [[dictionary valueForKey:@"angle"] floatValue];
		_angleVar = [[dictionary valueForKey:@"angleVariance"] floatValue];
        
		// duration
		_duration = [[dictionary valueForKey:@"duration"] floatValue];
        
		// blend function
		_blendFunc.src = [[dictionary valueForKey:@"blendFuncSource"] intValue];
		_blendFunc.dst = [[dictionary valueForKey:@"blendFuncDestination"] intValue];

        // position
        float x = [[dictionary valueForKey:@"sourcePositionx"] floatValue];
		float y = [[dictionary valueForKey:@"sourcePositiony"] floatValue];
		self.position = ccp(x,y);
		_posVar.x = [[dictionary valueForKey:@"sourcePositionVariancex"] floatValue];
		_posVar.y = [[dictionary valueForKey:@"sourcePositionVariancey"] floatValue];
        
		// Spinning
		_startSpin = [[dictionary valueForKey:@"rotationStart"] floatValue];
		_startSpinVar = [[dictionary valueForKey:@"rotationStartVariance"] floatValue];
		_endSpin = [[dictionary valueForKey:@"rotationEnd"] floatValue];
		_endSpinVar = [[dictionary valueForKey:@"rotationEndVariance"] floatValue];
        _useSameRotation = [[dictionary valueForKey:@"sameRotation"] unsignedIntegerValue];
        
        _emitterMode = kCCParticleModeGravity;
        
		// Mode A: Gravity + tangential accel + radial accel
        // gravity
        _mode.A.gravity.x = [[dictionary valueForKey:@"gravityx"] floatValue];
        _mode.A.gravity.y = [[dictionary valueForKey:@"gravityy"] floatValue];
        
        //
        // speed
        _mode.A.speed = [[dictionary valueForKey:@"speed"] floatValue];
        _mode.A.speedVar = [[dictionary valueForKey:@"speedVariance"] floatValue];
        
        // radial acceleration
        _mode.A.radialAccel = [[dictionary valueForKey:@"radialAcceleration"] floatValue];
        _mode.A.radialAccelVar = [[dictionary valueForKey:@"radialAccelVariance"] floatValue];
        _mode.A.tangentialAccel = [[dictionary valueForKey:@"tangentialAcceleration"] floatValue];
        _mode.A.tangentialAccelVar = [[dictionary valueForKey:@"tangentialAccelVariance"] floatValue];
                
		// life span
		_life = [[dictionary valueForKey:@"particleLifespan"] floatValue];
		_lifeVar = [[dictionary valueForKey:@"particleLifespanVariance"] floatValue];
        
		// emission Rate
        _emissionRate = [[dictionary valueForKey:@"emissionRate"] floatValue];
        
        sizeOverTime = [[dictionary objectForKey:@"sizeOverLifetime"] retain];
        colorOverTime = [[dictionary objectForKey:@"colorOverLifetime"] retain];
        
        _startDelay = [[dictionary valueForKey:@"startDelay"] floatValue];
        
        _emitterRadius = [[dictionary valueForKey:@"emitterRadius"] floatValue];
        
        _emitterWidth = [[dictionary valueForKey:@"emitterWidth"] floatValue];
        _emitterHeight = [[dictionary valueForKey:@"emitterHeight"] floatValue];
        
        _opacityModifyRGB = NO;
	}
    
    return self;
}

-(id) initWithTotalParticles:(NSUInteger) numberOfParticles
{
    if((self = [super init]))
    {
        _totalParticles = numberOfParticles;
        
		_particles = calloc( _totalParticles, sizeof(rCCParticle) );
        
		if( ! _particles ) {
			CCLOG(@"Particle system: not enough memory");
			[self release];
			return nil;
		}
        _allocatedParticles = numberOfParticles;
        
		if (_batchNode)
		{
			for (int i = 0; i < _totalParticles; i++)
			{
				_particles[i].atlasIndex=i;
			}
		}
        
		// default, active
		_active = YES;
        
		// default blend function
		_blendFunc = (ccBlendFunc) { CC_BLEND_SRC, CC_BLEND_DST };
        
		// default movement type;
		_positionType = kCCPositionTypeFree;
        
		// by default be in mode A:
		_emitterMode = kCCParticleModeGravity;
        
		_autoRemoveOnFinish = NO;
        
		// Optimization: compile updateParticle method
		_updateParticleSel = @selector(updateQuadWithParticle:newPosition:);
		_updateParticleAdvancedImp = (CC_UPDATE_PARTICLE_ADVANCED_IMP) [self methodForSelector:_updateParticleSel];
        
		//for batchNode
		_transformSystemDirty = NO;
        
		// update after action in run!
		[self scheduleUpdateWithPriority:1];
    }
    return self;
}

-(void) dealloc
{
    // Since the scheduler retains the "target (in this case the ParticleSystem)
	// it is not needed to call "unscheduleUpdate" here. In fact, it will be called in "cleanup"
//	[self unscheduleUpdate];
    
    free( _particles );
    
	[_texture release];
    
    
    [sizeOverTime release];
    sizeOverTime = nil;
    
    [colorOverTime release];
    colorOverTime = nil;
    
    [super dealloc];
}

-(void) initParticle: (rCCParticle*) particle
{
	//CGPoint currentPosition = position_;
	// timeToLive
	// no negative life. prevent division by 0
	particle->timeToLive = _life + _lifeVar * CCRANDOM_MINUS1_1();
	particle->timeToLive = MAX(0, particle->timeToLive);
    
    particle->totalTimeToLive = particle->timeToLive;
    
	// position
	particle->pos.x = _sourcePosition.x;
	particle->pos.y = _sourcePosition.y;
    
	// size
    float startS = _startSize + _startSizeVar * CCRANDOM_MINUS1_1();
    startS = MAX(0, startS); // No negative value
    startS *= CC_CONTENT_SCALE_FACTOR();
    
    particle->size = startS;
    if( _endSize == kCCParticleStartSizeEqualToEndSize )
        particle->deltaSize = 0;
    else {
        float endS = _endSize + _endSizeVar * CCRANDOM_MINUS1_1();
        endS = MAX(0, endS);	// No negative values
        endS *= CC_CONTENT_SCALE_FACTOR();
        particle->deltaSize = (endS - startS) / particle->timeToLive;
    }
    
	// rotation
	float startA = _startSpin + _startSpinVar * CCRANDOM_MINUS1_1();
    float endA = 0.0f;
    if(_useSameRotation)
        endA = startA;
    else
        endA = _endSpin + _endSpinVar * CCRANDOM_MINUS1_1();
	particle->rotation = startA;
	particle->deltaRotation = (endA - startA) / particle->timeToLive;
    
    // Position
    switch (_emitterType) {
        case kEmitterTypePoint:
        {
            if( _positionType == kCCPositionTypeFree )
                particle->startPos = [self convertToWorldSpace:CGPointZero];
            else if( _positionType == kCCPositionTypeRelative )
                particle->startPos = _position;
            break;
        }
        case kEmitterTypeCircle:
        {
            float radius = _emitterRadius;
            float xPos = 0.0f;
            float yPos = 0.0f;
            BOOL isInCircle = false;
            while(!isInCircle)
            {
                xPos = -radius + (CCRANDOM_0_1() * (radius * 2));
                yPos = -radius + (CCRANDOM_0_1() * (radius * 2));
                
                if(pow(xPos, 2) + pow(yPos, 2) < pow(radius, 2))
                {
                    isInCircle = true;
                }
            }
            if( _positionType == kCCPositionTypeFree )
                particle->startPos = [self convertToWorldSpace:ccp(xPos, yPos)];
            else if( _positionType == kCCPositionTypeRelative )
                particle->startPos = ccp(xPos + _position.x, yPos + _position.y);
            
            break;
        }
        case kEmitterTypeBox:
        {
            float width = _emitterWidth;
            float height = _emitterHeight;
            
            float xPos = -(width/2) + CCRANDOM_0_1() * width;
            float yPos = -(height/2) + CCRANDOM_0_1() * height;
            
            
            if( _positionType == kCCPositionTypeFree )
                particle->startPos = [self convertToWorldSpace:ccp(xPos, yPos)];
            else if( _positionType == kCCPositionTypeRelative )
                particle->startPos = ccp(xPos + _position.x, yPos + _position.y);
            
            break;
        }
        default:
            break;
    }
    
	// direction
	float a = CC_DEGREES_TO_RADIANS( _angle + _angleVar * CCRANDOM_MINUS1_1() );
    
	// Mode Gravity: A
    CGPoint v = {cosf( a ), sinf( a )};
    float s = _mode.A.speed + _mode.A.speedVar * CCRANDOM_MINUS1_1();
    
    // direction
    particle->mode.A.dir = ccpMult( v, s );
    
    // radial accel
    particle->mode.A.radialAccel = _mode.A.radialAccel + _mode.A.radialAccelVar * CCRANDOM_MINUS1_1();
    
    // tangential accel
    particle->mode.A.tangentialAccel = _mode.A.tangentialAccel + _mode.A.tangentialAccelVar * CCRANDOM_MINUS1_1();
}

-(BOOL) addParticle
{
	if( [self isFull] )
		return NO;
    
	rCCParticle * particle = &_particles[ _particleCount ];
    
	[self initParticle: particle];
	_particleCount++;
    
	return YES;
}

-(void) stopSystem
{
	_active = NO;
	_elapsed = _duration;
	_emitCounter = 0;
}

-(void) resetSystem
{
	_active = YES;
	_elapsed = 0;
	for(_particleIdx = 0; _particleIdx < _particleCount; ++_particleIdx) {
		rCCParticle *p = &_particles[_particleIdx];
		p->timeToLive = 0;
	}
    
}

-(BOOL) isFull
{
	return (_particleCount == _totalParticles);
}

#pragma mark ParticleSystem - MainLoop

-(void) update:(ccTime)dt
{
    CC_PROFILER_START_CATEGORY(kCCProfilerCategoryParticles , @"CCParticleSystem - update");
    
    if( _active && _emissionRate ) {
		float rate = 1.0f / _emissionRate;
        
		//issue #1201, prevent bursts of particles, due to too high emitCounter
        _elapsed += dt;
        
        if(_elapsed >= _startDelay)
        {
            if (_particleCount < _totalParticles)
                _emitCounter += dt;
            
            while( _particleCount < _totalParticles && _emitCounter > rate ) {
                [self addParticle];
                _emitCounter -= rate;
            }
        }
        
		if(_looping != 1 && (_duration + _startDelay) < _elapsed)
			[self stopSystem];
	}
    
	_particleIdx = 0;
    
	CGPoint currentPosition = CGPointZero;
	if( _positionType == kCCPositionTypeFree ) {
		currentPosition = [self convertToWorldSpace:CGPointZero];
	}
	else if( _positionType == kCCPositionTypeRelative ) {
		currentPosition = _position;
	}
    
	if (_visible)
	{
		while( _particleIdx < _particleCount )
		{
			rCCParticle *p = &_particles[_particleIdx];
            
			// life
			p->timeToLive -= dt;
            
			if( p->timeToLive > 0 ) {
                
                float relativeTime = (p->totalTimeToLive - p->timeToLive) / p->totalTimeToLive;
                
				// Mode A: gravity, direction, tangential accel & radial accel
                CGPoint tmp, radial, tangential;
                
                radial = CGPointZero;
                // radial acceleration
                if(p->pos.x || p->pos.y)
                {
                    radial = ccpNormalize(p->pos);
                }

                tangential = radial;
                radial = ccpMult(radial, p->mode.A.radialAccel);

                // tangential acceleration
                float newy = tangential.x;
                tangential.x = -tangential.y;
                tangential.y = newy;
                tangential = ccpMult(tangential, p->mode.A.tangentialAccel);

                // (gravity + radial + tangential) * dt
                tmp = ccpAdd( ccpAdd( radial, tangential), _mode.A.gravity);
                tmp = ccpMult( tmp, dt);
                p->mode.A.dir = ccpAdd( p->mode.A.dir, tmp);
                tmp = ccpMult(p->mode.A.dir, dt);
                p->pos = ccpAdd( p->pos, tmp );
                
				// color
                float alpha = 0.0f;
                float red = 0.0f;
                float blue = 0.0f;
                float green = 0.0f;
                
                for(int colorIndex = 0; colorIndex < [colorOverTime count]; colorIndex++)
                {
                    NSDictionary *thisColorDict = [colorOverTime objectAtIndex:colorIndex];
                    float thisTime = [[thisColorDict objectForKey:@"time"] floatValue];
                    
                    int nextIndex = colorIndex+1;
                    if(nextIndex > [colorOverTime count]-1)
                        nextIndex = (int)[colorOverTime count]-1;
                    
                    NSDictionary *nextColourDict = [colorOverTime objectAtIndex:nextIndex];
                    float nextTime = [[nextColourDict objectForKey:@"time"] floatValue];
                    
                    if(relativeTime >= thisTime && relativeTime < nextTime)
                    {
                        float alphaStartValue = [[thisColorDict objectForKey:@"a"] floatValue];
                        float redStartValue = [[thisColorDict objectForKey:@"r"] floatValue];
                        float greenStartValue = [[thisColorDict objectForKey:@"g"] floatValue];
                        float blueStartValue = [[thisColorDict objectForKey:@"b"] floatValue];
                        
                        float nextAlphaStartValue = [[nextColourDict objectForKey:@"a"] floatValue];
                        float nextRedStartValue = [[nextColourDict objectForKey:@"r"] floatValue];
                        float nextGreenStartValue = [[nextColourDict objectForKey:@"g"] floatValue];
                        float nextBlueStartValue = [[nextColourDict objectForKey:@"b"] floatValue];

                        float sectionStart = thisTime;
                        float sectionEnd = nextTime;

                        float sectionRelativeTime = (sectionStart - relativeTime) / (sectionStart - sectionEnd);

                        float redGradient = (nextRedStartValue - redStartValue) / (sectionEnd - sectionStart);
                        float greenGradient = (nextGreenStartValue - greenStartValue) / (sectionEnd - sectionStart);
                        float blueGradient = (nextBlueStartValue - blueStartValue) / (sectionEnd - sectionStart);
                        float alphaGradient = (nextAlphaStartValue - alphaStartValue) / (sectionEnd - sectionStart);

                        red = redStartValue + ((sectionEnd - sectionStart) * sectionRelativeTime) * redGradient;
                        green = greenStartValue + ((sectionEnd - sectionStart) * sectionRelativeTime) * greenGradient;
                        blue = blueStartValue + ((sectionEnd - sectionStart) * sectionRelativeTime) * blueGradient;
                        alpha = alphaStartValue + ((sectionEnd - sectionStart) * sectionRelativeTime) * alphaGradient;
                        
                        break;
                    }
                }
                p->color.r = red;
                p->color.g = green;
                p->color.b = blue;
                p->color.a = alpha;
                
				// size
                float size = 0.0f;
                
                for(int sizeIndex = 0; sizeIndex < [sizeOverTime count]; sizeIndex++)
                {
                    NSDictionary *thisSizeDict = [sizeOverTime objectAtIndex:sizeIndex];
                    float thisTime = [[thisSizeDict objectForKey:@"time"] floatValue];
                    
                    int nextIndex = sizeIndex+1;
                    if(nextIndex > [sizeOverTime count]-1)
                        nextIndex = (int)[sizeOverTime count]-1;
                    
                    NSDictionary *nextSizeDict = [sizeOverTime objectAtIndex:nextIndex];
                    float nextTime = [[nextSizeDict objectForKey:@"time"] floatValue];
                    
                    if(relativeTime >= thisTime && relativeTime < nextTime)
                    {
                        float startValue = [[thisSizeDict objectForKey:@"value"] floatValue];
                        
                        float nextStartValue = [[nextSizeDict objectForKey:@"value"] floatValue];
                        
                        float sectionStart = thisTime;
                        float sectionEnd = nextTime;
                        
                        float sectionRelativeTime = (sectionStart - relativeTime) / (sectionStart - sectionEnd);
                        
                        float sizeGradient = (nextStartValue - startValue) / (sectionEnd - sectionStart);
                        
                        size = startValue + ((sectionEnd - sectionStart) * sectionRelativeTime) * sizeGradient;
                        
                        break;
                    }
                }
                
				p->size = size;
                
				// angle
				p->rotation += (p->deltaRotation * dt);
                
				//
				// update values in quad
				//
                
				CGPoint	newPos;
                
				if( _positionType == kCCPositionTypeFree || _positionType == kCCPositionTypeRelative )
				{
					CGPoint diff = ccpSub( currentPosition, p->startPos );
					newPos = ccpSub(p->pos, diff);
				} else
					newPos = p->pos;
                
				//translate newPos to correct position, since matrix transform isn't performed in batchnode
				//don't update the particle with the new position information, it will interfere with the radius and tangential calculations
				if (_batchNode)
				{
                    newPos.x += _position.x;
                    newPos.y += _position.y;
				}
                
				_updateParticleAdvancedImp(self, _updateParticleSel, p, newPos);
                
				// update particle counter
				_particleIdx++;
                
			} else {
				// life < 0
				NSUInteger currentIndex = p->atlasIndex;
                
				if( _particleIdx != _particleCount-1 )
					_particles[_particleIdx] = _particles[_particleCount-1];
                
				if (_batchNode)
				{
					//disable the switched particle
					[_batchNode disableParticle:(_atlasIndex+currentIndex)];
                    
					//switch indexes
					_particles[_particleCount-1].atlasIndex = currentIndex;
				}
                
				_particleCount--;
                
				if( _particleCount == 0 && _autoRemoveOnFinish ) {
                    [self unscheduleUpdate];
					[_parent removeChild:self cleanup:YES];
					return;
				}
			}
		}//while
		_transformSystemDirty = NO;
	}
    
    if (!_batchNode)
		[self postStep];
    
	CC_PROFILER_STOP_CATEGORY(kCCProfilerCategoryParticles , @"CCParticleSystem - update");
}

-(void) updateWithNoTime
{
	[self update:0.0f];
}

-(void) updateQuadWithParticle:(rCCParticle*)particle newPosition:(CGPoint)pos;
{
	// should be overriden
}

-(void) postStep
{
	// should be overriden
}

#pragma mark ParticleSystem - CCTexture protocol

-(void) setTexture:(CCTexture2D*) texture
{
	if( _texture != texture ) {
		[_texture release];
		_texture = [texture retain];
        
		[self updateBlendFunc];
	}
}

-(CCTexture2D*) texture
{
	return _texture;
}

#pragma mark ParticleSystem - Additive Blending
-(void) setBlendAdditive:(BOOL)additive
{
	if( additive ) {
		_blendFunc.src = GL_SRC_ALPHA;
		_blendFunc.dst = GL_ONE;
        
	} else {
        
		if( _texture && ! [_texture hasPremultipliedAlpha] ) {
			_blendFunc.src = GL_SRC_ALPHA;
			_blendFunc.dst = GL_ONE_MINUS_SRC_ALPHA;
		} else {
			_blendFunc.src = CC_BLEND_SRC;
			_blendFunc.dst = CC_BLEND_DST;
		}
	}
}

-(BOOL) blendAdditive
{
	return( _blendFunc.src == GL_SRC_ALPHA && _blendFunc.dst == GL_ONE);
}

-(void) setBlendFunc:(ccBlendFunc)blendFunc
{
	if( _blendFunc.src != blendFunc.src || _blendFunc.dst != blendFunc.dst ) {
		_blendFunc = blendFunc;
		[self updateBlendFunc];
	}
}
#pragma mark ParticleSystem - Total Particles Property

- (void) setTotalParticles:(NSUInteger)tp
{
    NSAssert( tp <= _allocatedParticles, @"Particle: resizing particle array only supported for quads");
    _totalParticles = tp;
}

- (NSUInteger) _totalParticles
{
    return _totalParticles;
}

#pragma mark ParticleSystem - Properties of Gravity Mode
-(void) setTangentialAccel:(float)t
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	_mode.A.tangentialAccel = t;
}
-(float) tangentialAccel
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return _mode.A.tangentialAccel;
}

-(void) setTangentialAccelVar:(float)t
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	_mode.A.tangentialAccelVar = t;
}
-(float) tangentialAccelVar
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return _mode.A.tangentialAccelVar;
}

-(void) setRadialAccel:(float)t
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	_mode.A.radialAccel = t;
}
-(float) radialAccel
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return _mode.A.radialAccel;
}

-(void) setRadialAccelVar:(float)t
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	_mode.A.radialAccelVar = t;
}
-(float) radialAccelVar
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return _mode.A.radialAccelVar;
}

-(void) setGravity:(CGPoint)g
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	_mode.A.gravity = g;
}
-(CGPoint) gravity
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return _mode.A.gravity;
}

-(void) setSpeed:(float)speed
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	_mode.A.speed = speed;
}
-(float) speed
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return _mode.A.speed;
}

-(void) setSpeedVar:(float)speedVar
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	_mode.A.speedVar = speedVar;
}
-(float) speedVar
{
	NSAssert( _emitterMode == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return _mode.A.speedVar;
}

#pragma mark ParticleSystem - Properties of Radius Mode

-(void) setStartRadius:(float)startRadius
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	_mode.B.startRadius = startRadius;
}
-(float) startRadius
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return _mode.B.startRadius;
}

-(void) setStartRadiusVar:(float)startRadiusVar
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	_mode.B.startRadiusVar = startRadiusVar;
}
-(float) startRadiusVar
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return _mode.B.startRadiusVar;
}

-(void) setEndRadius:(float)endRadius
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	_mode.B.endRadius = endRadius;
}
-(float) endRadius
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return _mode.B.endRadius;
}

-(void) setEndRadiusVar:(float)endRadiusVar
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	_mode.B.endRadiusVar = endRadiusVar;
}
-(float) endRadiusVar
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return _mode.B.endRadiusVar;
}

-(void) setRotatePerSecond:(float)degrees
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	_mode.B.rotatePerSecond = degrees;
}
-(float) rotatePerSecond
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return _mode.B.rotatePerSecond;
}

-(void) setRotatePerSecondVar:(float)degrees
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	_mode.B.rotatePerSecondVar = degrees;
}
-(float) rotatePerSecondVar
{
	NSAssert( _emitterMode == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return _mode.B.rotatePerSecondVar;
}

#pragma mark ParticleSystem - methods for batchNode rendering

-(CCParticleBatchNode*) batchNode
{
	return _batchNode;
}

-(void) setBatchNode:(CCParticleBatchNode*) batchNode
{
	if( _batchNode != batchNode ) {
        
		_batchNode = batchNode; // weak reference
        
		if( batchNode ) {
			//each particle needs a unique index
			for (int i = 0; i < _totalParticles; i++)
			{
				_particles[i].atlasIndex=i;
			}
		}
	}
}

//don't use a transform matrix, this is faster
-(void) setScale:(float) s
{
	_transformSystemDirty = YES;
	[super setScale:s];
}

-(void) setRotation: (float)newRotation
{
	_transformSystemDirty = YES;
	[super setRotation:newRotation];
}

-(void) setScaleX: (float)newScaleX
{
	_transformSystemDirty = YES;
	[super setScaleX:newScaleX];
}

-(void) setScaleY: (float)newScaleY
{
	_transformSystemDirty = YES;
	[super setScaleY:newScaleY];
}

#pragma mark Particle - Helpers

-(void) updateBlendFunc
{
	NSAssert(! _batchNode, @"Can't change blending functions when the particle is being batched");
    
	BOOL premultiplied = [_texture hasPremultipliedAlpha];
    
	_opacityModifyRGB = NO;
    
	if( _texture && ( _blendFunc.src == CC_BLEND_SRC && _blendFunc.dst == CC_BLEND_DST ) ) {
		if( premultiplied )
			_opacityModifyRGB = YES;
		else {
			_blendFunc.src = GL_SRC_ALPHA;
			_blendFunc.dst = GL_ONE_MINUS_SRC_ALPHA;
		}
	}
}


@end