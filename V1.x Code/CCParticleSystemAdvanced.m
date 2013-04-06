#import "CCParticleSystemAdvanced.h"

@implementation CCParticleSystemAdvanced

@synthesize active, duration;
@synthesize sourcePosition, posVar;
@synthesize particleCount;
@synthesize life, lifeVar;
@synthesize angle, angleVar;
@synthesize startColor, startColorVar, endColor, endColorVar;
@synthesize startSpin, startSpinVar, endSpin, endSpinVar;
@synthesize emissionRate;
@synthesize totalParticles;
@synthesize startSize, startSizeVar;
@synthesize endSize, endSizeVar;
@synthesize startScale, startScaleVar;
@synthesize endScale, endScaleVar;
@synthesize blendFunc = blendFunc_;
@synthesize opacityModifyRGB = opacityModifyRGB_;
@synthesize positionType = positionType_;
@synthesize autoRemoveOnFinish = autoRemoveOnFinish_;
@synthesize emitterMode = emitterMode_;
@synthesize atlasIndex = atlasIndex_;
@synthesize useBatchNode = useBatchNode_;
@synthesize animationType=animationType_;

@synthesize looping = _looping;
@synthesize startDelay = _startDelay;
@synthesize emitterType = _emitterType, emitterRadius = _emitterRadius, emitterWidth = _emitterWidth, emitterHeight = _emitterHeight;

-(NSUInteger) getMaxParticles
{
    NSUInteger amount = ceil([[_dict valueForKey:@"emissionRate"] floatValue] * [[_dict valueForKey:@"duration"] floatValue]);
    
    NSUInteger maxParticles = [[_dict valueForKey:@"maxParticles"] intValue];
    
    if(amount > maxParticles)
        amount = maxParticles;
    
//    NSLog(@"AMOUNT: %ld", amount);
    return amount;
}

-(id) initWithDictionary:(NSDictionary *)dictionary
{
    _dict = [dictionary retain];
//    TODO: Figure out looping
    
    _looping = [[dictionary valueForKey:@"looping"] unsignedIntegerValue];
    
    NSUInteger maxParticles = [self getMaxParticles];
    
//    CCLOG(@"MAX PARTICLES: %ld", maxParticles);
    
    _emitterType = [[dictionary valueForKey:@"emitterType"] intValue];
    
	// self, not super
	if ((self=[self initWithTotalParticles:maxParticles] ) )
	{
		// angle
		angle = [[dictionary valueForKey:@"angle"] floatValue];
		angleVar = [[dictionary valueForKey:@"angleVariance"] floatValue];
        
		// duration
		duration = [[dictionary valueForKey:@"duration"] floatValue];
        
		// blend function
		blendFunc_.src = [[dictionary valueForKey:@"blendFuncSource"] intValue];
		blendFunc_.dst = [[dictionary valueForKey:@"blendFuncDestination"] intValue];

        // position
        float x = [[dictionary valueForKey:@"sourcePositionx"] floatValue];
		float y = [[dictionary valueForKey:@"sourcePositiony"] floatValue];
		self.position = ccp(x,y);
		posVar.x = [[dictionary valueForKey:@"sourcePositionVariancex"] floatValue];
		posVar.y = [[dictionary valueForKey:@"sourcePositionVariancey"] floatValue];
        
		// Spinning
		startSpin = [[dictionary valueForKey:@"rotationStart"] floatValue];
		startSpinVar = [[dictionary valueForKey:@"rotationStartVariance"] floatValue];
		endSpin = [[dictionary valueForKey:@"rotationEnd"] floatValue];
		endSpinVar = [[dictionary valueForKey:@"rotationEndVariance"] floatValue];
        _useSameRotation = [[dictionary valueForKey:@"sameRotation"] unsignedIntegerValue];
        
		//v2 additions
		if ([dictionary valueForKey:@"version"] && [[dictionary valueForKey:@"version"] intValue] == 2)
		{
			startScale = [[dictionary valueForKey:@"startScale"] floatValue];
			startScaleVar = [[dictionary valueForKey:@"startScaleVar"] floatValue];
			endScale = [[dictionary valueForKey:@"endScale"] floatValue];
			endScaleVar = [[dictionary valueForKey:@"endScaleVar"] floatValue];
		}
        
		emitterMode_ = kCCParticleModeGravity;
        
		// Mode A: Gravity + tangential accel + radial accel
        // gravity
        mode.A.gravity.x = [[dictionary valueForKey:@"gravityx"] floatValue];
        mode.A.gravity.y = [[dictionary valueForKey:@"gravityy"] floatValue];
        
        // There're some differences between high and low resolutions
        mode.A.gravity.x *= CC_CONTENT_SCALE_FACTOR();
        mode.A.gravity.y *= CC_CONTENT_SCALE_FACTOR();
        
        //
        // speed
        mode.A.speed = [[dictionary valueForKey:@"speed"] floatValue];
        mode.A.speedVar = [[dictionary valueForKey:@"speedVariance"] floatValue];
        
        // radial acceleration
        NSString *tmp = [dictionary valueForKey:@"radialAcceleration"];
        mode.A.radialAccel = tmp ? [tmp floatValue] : 0;
        
        tmp = [dictionary valueForKey:@"radialAccelVariance"];
        mode.A.radialAccelVar = tmp ? [tmp floatValue] : 0;
        
        // tangential acceleration
        tmp = [dictionary valueForKey:@"tangentialAcceleration"];
        mode.A.tangentialAccel = tmp ? [tmp floatValue] : 0;
        
        tmp = [dictionary valueForKey:@"tangentialAccelVariance"];
        mode.A.tangentialAccelVar = tmp ? [tmp floatValue] : 0;
        
		// life span
		life = [[dictionary valueForKey:@"particleLifespan"] floatValue];
		lifeVar = [[dictionary valueForKey:@"particleLifespanVariance"] floatValue];
        
		// emission Rate
        emissionRate = [[dictionary valueForKey:@"emissionRate"] floatValue];
        
        sizeOverTime = [[dictionary objectForKey:@"sizeOverLifetime"] retain];
        colorOverTime = [[dictionary objectForKey:@"colorOverLifetime"] retain];
        
        _startDelay = [[dictionary valueForKey:@"startDelay"] floatValue];
        
        _emitterRadius = [[dictionary valueForKey:@"emitterRadius"] floatValue];
        
        _emitterWidth = [[dictionary valueForKey:@"emitterWidth"] floatValue];
        _emitterHeight = [[dictionary valueForKey:@"emitterHeight"] floatValue];
	}
    
    return self;
}

-(id) initWithTotalParticles:(NSUInteger) numberOfParticles
{
	if( (self=[super init]) ) {
        
		totalParticles = numberOfParticles;
        
		particles = calloc( totalParticles, sizeof(rCCParticle) );
        
		if( ! particles ) {
			CCLOG(@"Particle system: not enough memory");
			[self release];
			return nil;
		}
        
		if (batchNode_)
		{
			for (int i = 0; i < totalParticles; i++)
			{
				particles[i].atlasIndex=i;
			}
		}
        
		// default, active
		active = YES;
        
		// default blend function
		blendFunc_ = (ccBlendFunc) { CC_BLEND_SRC, CC_BLEND_DST };
        
        // Set a compatible default for the alpha transfer
        opacityModifyRGB_ = NO;
        
		// default movement type;
		positionType_ = kCCPositionTypeFree;
        
		// by default be in mode A:
		emitterMode_ = kCCParticleModeGravity;
        
		autoRemoveOnFinish_ = NO;
        
		// profiling
#if CC_ENABLE_PROFILERS
		_profilingTimer = [[CCProfiler timerWithName:@"particle system" andInstance:self] retain];
#endif
        
		// Optimization: compile udpateParticle method
		updateParticleSel = @selector(updateQuadWithParticle:newPosition:);
		updateParticleImp = (CC_UPDATE_PARTICLE_IMP) [self methodForSelector:updateParticleSel];
        
		//for batchNode
		transformSystemDirty_ = NO;
        
		// animation
		useAnimation_ = NO;
		totalFrameCount_ = 0;
		animationFrameData_ = NULL;
		animationType_ = kCCParticleAnimationTypeLoop;
        
		// udpate after action in run!
		[self scheduleUpdateWithPriority:1];
	}
	return self;
}

-(void) dealloc
{
    [self unscheduleUpdate];
    
	free( particles );
    
	if (animationFrameData_)
		free(animationFrameData_);
    
	[texture_ release];
	// profiling
#if CC_ENABLE_PROFILERS
	[CCProfiler releaseTimer:_profilingTimer];
#endif
    
    [sizeOverTime release];
    sizeOverTime = nil;
    
    [colorOverTime release];
    colorOverTime = nil;
    
    [super dealloc];
}

-(BOOL) addParticle
{
	if( [self isFull] )
		return NO;
    
	rCCParticle * particle = &particles[ particleCount ];
    
	[self initParticle: particle];
	particleCount++;
    
	return YES;
}

-(void) initParticle: (rCCParticle*) particle
{
	//CGPoint currentPosition = position_;
	// timeToLive
	// no negative life. prevent division by 0
	particle->timeToLive = life + lifeVar * CCRANDOM_MINUS1_1();
	particle->timeToLive = MAX(0, particle->timeToLive);
    
    particle->totalTimeToLive = particle->timeToLive;
    
	// position
	particle->pos.x = sourcePosition.x;
	particle->pos.y = sourcePosition.y;
    
//    CCLOG(@"particle pos %f %f n pos %f %f",particle->pos.x,particle->pos.y, position_.x,position_.y);
	particle->pos.x *= CC_CONTENT_SCALE_FACTOR();
	particle->pos.y *= CC_CONTENT_SCALE_FACTOR();
    
	// size
	//to limit increase in byte size of particle, size is used as scale during animation
	if (useAnimation_)
	{
		float startS = startScale + startScaleVar * CCRANDOM_MINUS1_1();
		startS = MAX(0, startS); // No negative value
        
		particle->size = startS;
		if( endScale == kCCParticleStartSizeEqualToEndSize )
			particle->deltaSize = 0;
		else {
			float endS = endScale + endScaleVar * CCRANDOM_MINUS1_1();
			endS = MAX(0, endS);	// No negative values
			particle->deltaSize = (endS - startS) / particle->timeToLive;
		}
	}
	else
	{
		float startS = startSize + startSizeVar * CCRANDOM_MINUS1_1();
		startS = MAX(0, startS); // No negative value
		startS *= CC_CONTENT_SCALE_FACTOR();
        
		particle->size = startS;
		if( endSize == kCCParticleStartSizeEqualToEndSize )
			particle->deltaSize = 0;
		else {
			float endS = endSize + endSizeVar * CCRANDOM_MINUS1_1();
			endS = MAX(0, endS);	// No negative values
			endS *= CC_CONTENT_SCALE_FACTOR();
			particle->deltaSize = (endS - startS) / particle->timeToLive;
		}
        
	}
	// rotation
	float startA = startSpin + startSpinVar * CCRANDOM_MINUS1_1();
    float endA = 0.0f;
    if(_useSameRotation)
        endA = startA;
    else
        endA = endSpin + endSpinVar * CCRANDOM_MINUS1_1();
    
	particle->rotation = startA;
	particle->deltaRotation = (endA - startA) / particle->timeToLive;
    
	// position
    switch (_emitterType) {
        case kEmitterTypePoint:
            particle->startPos = ccp(position_.x, position_.y);
            break;
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
            particle->startPos = ccp(xPos + position_.x, yPos + position_.y);
            
            break;
        }
        case kEmitterTypeBox:
        {
            float width = _emitterWidth;
            float height = _emitterHeight;
            
            float xPos = -(width/2) + CCRANDOM_0_1() * width;
            float yPos = -(height/2) + CCRANDOM_0_1() * height;
            
            particle->startPos = ccp(xPos + position_.x, yPos + position_.y);
            
            break;
        }
        default:
            break;
    }
    
    particle->startPos = ccpMult( particle->startPos, CC_CONTENT_SCALE_FACTOR() );
    particle->startPos.x /= scaleX_;
    particle->startPos.y /= scaleY_;

    
	// direction
	float a = CC_DEGREES_TO_RADIANS( angle + angleVar * CCRANDOM_MINUS1_1() );
    
	// Mode Gravity: A
    CGPoint v = {cosf( a ), sinf( a )};
    float s = mode.A.speed + mode.A.speedVar * CCRANDOM_MINUS1_1();
    s *= CC_CONTENT_SCALE_FACTOR();
    
    // direction
    particle->mode.A.dir = ccpMult( v, s );
    
    // radial accel
    particle->mode.A.radialAccel = mode.A.radialAccel + mode.A.radialAccelVar * CCRANDOM_MINUS1_1();
    particle->mode.A.radialAccel *= CC_CONTENT_SCALE_FACTOR();
    
    // tangential accel
    particle->mode.A.tangentialAccel = mode.A.tangentialAccel + mode.A.tangentialAccelVar * CCRANDOM_MINUS1_1();
    particle->mode.A.tangentialAccel *= CC_CONTENT_SCALE_FACTOR();
    
	particle->z=vertexZ_;
    
	// animation
	if (useAnimation_)
	{
		particle->split = 0;
		particle->elapsed = 0;
        
		switch (animationType_) {
			default:
			case kCCParticleAnimationTypeOnce:
			case kCCParticleAnimationTypeLoop: {
				particle->currentFrame = 0;
				break;
			}
			case kCCParticleAnimationTypeRandomFrame:
			case kCCParticleAnimationTypeLoopWithRandomStartFrame: {
				particle->currentFrame = (NSUInteger) roundf((CCRANDOM_0_1() * (totalFrameCount_ -1)));
				break;
			}
		}
	}
}

-(void) stopSystem
{
	active = NO;
	elapsed = duration;
	emitCounter = 0;
}

-(void) resetSystem
{
	active = YES;
	elapsed = 0;
	for(particleIdx = 0; particleIdx < particleCount; ++particleIdx) {
		rCCParticle *p = &particles[particleIdx];
		p->timeToLive = 0;
	}
    
}

-(BOOL) isFull
{
	return (particleCount == totalParticles);
}

-(void) update:(ccTime)dt
{
    if( active && emissionRate ) {
		float rate = 1.0f / emissionRate;
        
		//issue #1201, prevent bursts of particles, due to too high emitCounter
        
        elapsed += dt;
        if(elapsed >= _startDelay)
        {
            if (particleCount < totalParticles)
                emitCounter += dt;
            
            while( particleCount < totalParticles && emitCounter > rate ) {
                [self addParticle];
                emitCounter -= rate;
            }
        }
        
		if(_looping != 1 && (duration + _startDelay) < elapsed)
			[self stopSystem];
	}
    
	particleIdx = 0;
    
#if CC_ENABLE_PROFILERS
	CCProfilingBeginTimingBlock(_profilingTimer);
#endif
    
	CGPoint currentPosition;
	//if (useBatchNode_) currentPosition = [self.parent convertToWorldSpace:self.position];
	//else
	currentPosition = CGPointZero;
    
    //divide by scale to get correct position, issue 1352
    
	if( positionType_ == kCCPositionTypeFree ) {
		currentPosition = [self convertToWorldSpace:CGPointZero];
		currentPosition.x *= CC_CONTENT_SCALE_FACTOR() / scaleX_;
		currentPosition.y *= CC_CONTENT_SCALE_FACTOR() / scaleY_;
	}
	else if( positionType_ == kCCPositionTypeRelative ) {
        //currentPosition = [self convertToWorldSpace:CGPointZero];
		currentPosition = position_;
		currentPosition.x *= CC_CONTENT_SCALE_FACTOR() / scaleX_;
		currentPosition.y *= CC_CONTENT_SCALE_FACTOR() / scaleY_;
	}
    
	if (visible_)
	{
		while( particleIdx < particleCount )
		{
			rCCParticle *p = (rCCParticle *)&particles[particleIdx];
            
			// life
			p->timeToLive -= dt;
            
			if( p->timeToLive > 0 ) {
                
				if (useAnimation_) {
					switch (animationType_) {
						default:
						case kCCParticleAnimationTypeLoopWithRandomStartFrame:
						case kCCParticleAnimationTypeLoop:
						{
							p->elapsed += dt;
							while (p->elapsed >= p->split) {
                                
								p->currentFrame++;
								if (p->currentFrame >= totalFrameCount_)
								{
									p->currentFrame = 0;
									p->elapsed = p->elapsed - p->split;
									p->split = 0.f;
								}
								p->split+=animationFrameData_[p->currentFrame].delay;
                                
							}
							break;
						}
						case kCCParticleAnimationTypeOnce:
						{
							//stop after one iteration
							if (p->currentFrame != totalFrameCount_)
							{
								p->elapsed += dt;
								while (p->elapsed >= p->split) {
                                    
									p->currentFrame++;
									if (p->currentFrame >= totalFrameCount_)
									{
										p->currentFrame = totalFrameCount_;
										break;
									}
									p->split+=animationFrameData_[p->currentFrame].delay;
								}
							}
							break;
						}
						case kCCParticleAnimationTypeRandomFrame:
						{
							// frame does not change in random mode
							break;
						}
					}
				}
                
                float relativeTime = (p->totalTimeToLive - p->timeToLive) / p->totalTimeToLive;
                
				// Mode A: gravity, direction, tangential accel & radial accel
                CGPoint tmp, radial, tangential;
                
                radial = CGPointZero;
                // radial acceleration
                if(p->pos.x || p->pos.y)
                    radial = ccpNormalize(p->pos);
            
                tangential = radial;
                radial = ccpMult(radial, p->mode.A.radialAccel);
                
                // tangential acceleration
                float newy = tangential.x;
                tangential.x = -tangential.y;
                tangential.y = newy;
                tangential = ccpMult(tangential, p->mode.A.tangentialAccel);
            
                // (gravity + radial + tangential) * dt
                tmp = ccpAdd( ccpAdd( radial, tangential), mode.A.gravity);
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
                    
                    int newIndex = colorIndex+1;
                    if(newIndex > [colorOverTime count]-1)
                        newIndex = ((int)[colorOverTime count] - 1);
                    
                    NSDictionary *nextColourDict = [colorOverTime objectAtIndex:newIndex];
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
                    
                    int newIndex = sizeIndex+1;
                    if(newIndex > [sizeOverTime count]-1)
                        newIndex = ((int)[sizeOverTime count]-1);
                    
                    NSDictionary *nextSizeDict = [sizeOverTime objectAtIndex:newIndex];
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
                
				if( positionType_ == kCCPositionTypeFree || positionType_ == kCCPositionTypeRelative )
				{
					CGPoint diff = ccpSub( currentPosition, p->startPos );
					newPos = ccpSub(p->pos, diff);
				} else
					newPos = p->pos;
                
				//translate newPos to correct position, since matrix transform isn't performed in batchnode
				//don't update the particle with the new position information, it will interfere with the radius and tangential calculations
				if (useBatchNode_)
				{
                    newPos.x += positionInPixels_.x;
                    newPos.y += positionInPixels_.y;
				}
                
				p->z = vertexZ_;
                
				updateParticleImp(self, updateParticleSel, (tCCParticle *)p, newPos);
                
				// update particle counter
				particleIdx++;
                
			} else {
				// life < 0
				NSUInteger currentIndex = p->atlasIndex;
                
				if( particleIdx != particleCount-1 )
					particles[particleIdx] = particles[particleCount-1];
                
				if (useBatchNode_)
				{
					//disable the switched particle
					[batchNode_ disableParticle:(atlasIndex_+currentIndex)];
                    
					//switch indexes
					particles[particleCount-1].atlasIndex = currentIndex;
				}
                
				particleCount--;
                
				if( particleCount == 0 && autoRemoveOnFinish_ ) {
                    
					[parent_ removeChild:self cleanup:YES];
					return;
				}
			}
		}//while
		transformSystemDirty_ = NO;
	}
    
#if CC_ENABLE_PROFILERS
	CCProfilingEndTimingBlock(_profilingTimer);
#endif
    
#ifdef CC_USES_VBO
	if (!useBatchNode_) [self postStep];
#endif

}

-(void) updateWithNoTime
{
	[self update:0.0f];
}

-(void) updateQuadWithParticle:(tCCParticle*)particle newPosition:(CGPoint)pos;
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
	texture_ = [texture retain];
    
    opacityModifyRGB_ = [texture hasPremultipliedAlpha];
	// If the new texture has No premultiplied alpha, AND the blendFunc hasn't been changed, then update it
	if( texture_ && ! [texture hasPremultipliedAlpha] &&
	   ( blendFunc_.src == CC_BLEND_SRC && blendFunc_.dst == CC_BLEND_DST ) ) {
        
		blendFunc_.src = GL_SRC_ALPHA;
		blendFunc_.dst = GL_ONE_MINUS_SRC_ALPHA;
	}
}

-(CCTexture2D*) texture
{
	return texture_;
}

#pragma mark ParticleSystem - Additive Blending
-(void) setBlendAdditive:(BOOL)additive
{
	if( additive ) {
		blendFunc_.src = GL_SRC_ALPHA;
		blendFunc_.dst = GL_ONE;
        
	} else {
        
		if( texture_ && ! [texture_ hasPremultipliedAlpha] ) {
			blendFunc_.src = GL_SRC_ALPHA;
			blendFunc_.dst = GL_ONE_MINUS_SRC_ALPHA;
		} else {
			blendFunc_.src = CC_BLEND_SRC;
			blendFunc_.dst = CC_BLEND_DST;
		}
	}
}

-(BOOL) blendAdditive
{
	return( blendFunc_.src == GL_SRC_ALPHA && blendFunc_.dst == GL_ONE);
}

#pragma mark ParticleSystem - Properties of Gravity Mode
-(void) setTangentialAccel:(float)t
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.tangentialAccel = t;
}
-(float) tangentialAccel
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.tangentialAccel;
}

-(void) setTangentialAccelVar:(float)t
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.tangentialAccelVar = t;
}
-(float) tangentialAccelVar
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.tangentialAccelVar;
}

-(void) setRadialAccel:(float)t
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.radialAccel = t;
}
-(float) radialAccel
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.radialAccel;
}

-(void) setRadialAccelVar:(float)t
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.radialAccelVar = t;
}
-(float) radialAccelVar
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.radialAccelVar;
}

-(void) setGravity:(CGPoint)g
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.gravity = g;
}
-(CGPoint) gravity
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.gravity;
}

-(void) setSpeed:(float)speed
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.speed = speed;
}
-(float) speed
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.speed;
}

-(void) setSpeedVar:(float)speedVar
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.speedVar = speedVar;
}
-(float) speedVar
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.speedVar;
}

#pragma mark ParticleSystem - Properties of Radius Mode

-(void) setStartRadius:(float)startRadius
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.startRadius = startRadius;
}
-(float) startRadius
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.startRadius;
}

-(void) setStartRadiusVar:(float)startRadiusVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.startRadiusVar = startRadiusVar;
}
-(float) startRadiusVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.startRadiusVar;
}

-(void) setEndRadius:(float)endRadius
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.endRadius = endRadius;
}
-(float) endRadius
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.endRadius;
}

-(void) setEndRadiusVar:(float)endRadiusVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.endRadiusVar = endRadiusVar;
}
-(float) endRadiusVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.endRadiusVar;
}

-(void) setRotatePerSecond:(float)degrees
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.rotatePerSecond = degrees;
}
-(float) rotatePerSecond
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.rotatePerSecond;
}

-(void) setRotatePerSecondVar:(float)degrees
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.rotatePerSecondVar = degrees;
}
-(float) rotatePerSecondVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.rotatePerSecondVar;
}

#pragma mark ParticleSystem - methods for batchNode rendering

-(void) useSelfRender
{
	useBatchNode_ = NO;
}

-(void) useBatchNode:(CCParticleBatchNode*) batchNode
{
	batchNode_ = batchNode;
	useBatchNode_ = YES;
    
	//each particle needs a unique index
	for (NSUInteger i = 0; i < totalParticles; i++)
	{
		particles[i].atlasIndex=i;
	}
}

-(void) batchNodeInitialization
{//override this
}

//don't use a transform matrix, this is faster
-(void) setScale:(float) s
{
	transformSystemDirty_ = YES;
	[super setScale:s];
}

-(void) setRotation: (float)newRotation
{
	transformSystemDirty_ = YES;
	[super setRotation:newRotation];
}

-(void) setScaleX: (float)newScaleX
{
	transformSystemDirty_ = YES;
	[super setScaleX:newScaleX];
}

-(void) setScaleY: (float)newScaleY
{
	transformSystemDirty_ = YES;
	[super setScaleY:newScaleY];
}

@end