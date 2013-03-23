//
//  CCParticleSystemAdvanced.h
//  LayeredParticleSystem
//
//  Created by Robert Scott on 10/02/2013.
//  Copyright 2013 Unseen-Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef struct tCCParticle
{
    CGPoint		pos;
	CGPoint		startPos;
    
	ccColor4F	color;
	ccColor4F	deltaColor;
    
	float		size;
	float		deltaSize;
    
	float		rotation;
	float		deltaRotation;
    
	ccTime		timeToLive;
    ccTime      totalTimeToLive;
    
	NSUInteger	atlasIndex;
    
	union {
		// Mode A: gravity, direction, radial accel, tangential accel
		struct {
			CGPoint		dir;
			float		radialAccel;
			float		tangentialAccel;
		} A;
        
		// Mode B: radius mode
		struct {
			float		angle;
			float		degreesPerSecond;
			float		radius;
			float		deltaRadius;
		} B;
	} mode;
}rCCParticle;

typedef void (*CC_UPDATE_PARTICLE_ADVANCED_IMP)(id, SEL, rCCParticle*, CGPoint);

typedef enum
{
    kEmitterTypePoint = 0,
    kEmitterTypeCircle = 1,
    kEmitterTypeBox = 2
} EmitterType;

@interface CCParticleSystemAdvanced : CCNode <CCTextureProtocol>
{
//    CCParticleSystem variables
    // is the particle system active ?
	BOOL _active;
	// duration in seconds of the system. -1 is infinity
	float _duration;
	// time elapsed since the start of the system (in seconds)
	float _elapsed;
    
	// position is from "superclass" CocosNode
	CGPoint _sourcePosition;
	// Position variance
	CGPoint _posVar;
    
	// The angle (direction) of the particles measured in degrees
	float _angle;
	// Angle variance measured in degrees;
	float _angleVar;
    
	// Different modes
    
	NSInteger _emitterMode;
	union {
		// Mode A:Gravity + Tangential Accel + Radial Accel
		struct {
			// gravity of the particles
			CGPoint gravity;
            
			// The speed the particles will have.
			float speed;
			// The speed variance
			float speedVar;
            
			// Tangential acceleration
			float tangentialAccel;
			// Tangential acceleration variance
			float tangentialAccelVar;
            
			// Radial acceleration
			float radialAccel;
			// Radial acceleration variance
			float radialAccelVar;
        } A;
        
		// Mode B: circular movement (gravity, radial accel and tangential accel don't are not used in this mode)
		struct {
            
			// The starting radius of the particles
			float startRadius;
			// The starting radius variance of the particles
			float startRadiusVar;
			// The ending radius of the particles
			float endRadius;
			// The ending radius variance of the particles
			float endRadiusVar;
			// Number of degress to rotate a particle around the source pos per second
			float rotatePerSecond;
			// Variance in degrees for rotatePerSecond
			float rotatePerSecondVar;
		} B;
	} _mode;
    
	// start ize of the particles
	float _startSize;
	// start Size variance
	float _startSizeVar;
	// End size of the particle
	float _endSize;
	// end size of variance
	float _endSizeVar;
    
	// How many seconds will the particle live
	float _life;
	// Life variance
	float _lifeVar;
    
	// start angle of the particles
	float _startSpin;
	// start angle variance
	float _startSpinVar;
	// End angle of the particle
	float _endSpin;
	// end angle ariance
	float _endSpinVar;
    
	// Array of particles
	rCCParticle *_particles;
	// Maximum particles
	NSUInteger _totalParticles;
	// Count of active particles
	NSUInteger _particleCount;
    // Number of allocated particles
    NSUInteger _allocatedParticles;
    
	// How many particles can be emitted per second
	float _emissionRate;
	float _emitCounter;
    
	// Texture of the particles
	CCTexture2D *_texture;
	// blend function
	ccBlendFunc	_blendFunc;
	// Texture alpha behavior
	BOOL _opacityModifyRGB;
    
	// movment type: free or grouped
	tCCPositionType	_positionType;
    
	// Whether or not the node will be auto-removed when there are not particles
	BOOL	_autoRemoveOnFinish;
    
	//  particle idx
	NSUInteger _particleIdx;
    
	// Optimization
    CC_UPDATE_PARTICLE_ADVANCED_IMP	_updateParticleAdvancedImp;
	SEL						_updateParticleSel;
    
	// for batching. If nil, then it won't be batched
	CCParticleBatchNode *_batchNode;
    
	// index of system in batch node array
	NSUInteger _atlasIndex;
    
	//YES if scaled or rotated
	BOOL _transformSystemDirty;
    
    
//    CCParticleSystemAdvanced Varibles
    NSUInteger _looping;
    NSUInteger _useSameRotation;
    
    EmitterType _emitterType;
    float _startDelay;
    float _emitterRadius;
    float _emitterWidth;
    float _emitterHeight;
    
	NSArray *sizeOverTime;
    NSArray *colorOverTime;
    
    NSDictionary *_dict;
}

/** Is the emitter active */
@property (nonatomic,readonly) BOOL active;
/** Quantity of particles that are being simulated at the moment */
@property (nonatomic,readonly) NSUInteger	particleCount;
/** How many seconds the emitter wil run. -1 means 'forever' */
@property (nonatomic,readwrite,assign) float duration;
/** sourcePosition of the emitter */
@property (nonatomic,readwrite,assign) CGPoint sourcePosition;
/** Position variance of the emitter */
@property (nonatomic,readwrite,assign) CGPoint posVar;
/** life, and life variation of each particle */
@property (nonatomic,readwrite,assign) float life;
/** life variance of each particle */
@property (nonatomic,readwrite,assign) float lifeVar;
/** angle and angle variation of each particle */
@property (nonatomic,readwrite,assign) float angle;
/** angle variance of each particle */
@property (nonatomic,readwrite,assign) float angleVar;

/** Gravity value. Only available in 'Gravity' mode. */
@property (nonatomic,readwrite,assign) CGPoint gravity;
/** speed of each particle. Only available in 'Gravity' mode.  */
@property (nonatomic,readwrite,assign) float speed;
/** speed variance of each particle. Only available in 'Gravity' mode. */
@property (nonatomic,readwrite,assign) float speedVar;
/** tangential acceleration of each particle. Only available in 'Gravity' mode. */
@property (nonatomic,readwrite,assign) float tangentialAccel;
/** tangential acceleration variance of each particle. Only available in 'Gravity' mode. */
@property (nonatomic,readwrite,assign) float tangentialAccelVar;
/** radial acceleration of each particle. Only available in 'Gravity' mode. */
@property (nonatomic,readwrite,assign) float radialAccel;
/** radial acceleration variance of each particle. Only available in 'Gravity' mode. */
@property (nonatomic,readwrite,assign) float radialAccelVar;

/** The starting radius of the particles. Only available in 'Radius' mode. */
@property (nonatomic,readwrite,assign) float startRadius;
/** The starting radius variance of the particles. Only available in 'Radius' mode. */
@property (nonatomic,readwrite,assign) float startRadiusVar;
/** The ending radius of the particles. Only available in 'Radius' mode. */
@property (nonatomic,readwrite,assign) float endRadius;
/** The ending radius variance of the particles. Only available in 'Radius' mode. */
@property (nonatomic,readwrite,assign) float endRadiusVar;
/** Number of degress to rotate a particle around the source pos per second. Only available in 'Radius' mode. */
@property (nonatomic,readwrite,assign) float rotatePerSecond;
/** Variance in degrees for rotatePerSecond. Only available in 'Radius' mode. */
@property (nonatomic,readwrite,assign) float rotatePerSecondVar;

/** start size in pixels of each particle */
@property (nonatomic,readwrite,assign) float startSize;
/** size variance in pixels of each particle */
@property (nonatomic,readwrite,assign) float startSizeVar;
/** end size in pixels of each particle */
@property (nonatomic,readwrite,assign) float endSize;
/** end size variance in pixels of each particle */
@property (nonatomic,readwrite,assign) float endSizeVar;
//* initial angle of each particle
@property (nonatomic,readwrite,assign) float startSpin;
//* initial angle of each particle
@property (nonatomic,readwrite,assign) float startSpinVar;
//* initial angle of each particle
@property (nonatomic,readwrite,assign) float endSpin;
//* initial angle of each particle
@property (nonatomic,readwrite,assign) float endSpinVar;
/** emission rate of the particles */
@property (nonatomic,readwrite,assign) float emissionRate;
/** maximum particles of the system */
@property (nonatomic,readwrite,assign) NSUInteger totalParticles;
/** conforms to CocosNodeTexture protocol */
@property (nonatomic,readwrite, retain) CCTexture2D * texture;
/** conforms to CocosNodeTexture protocol */
@property (nonatomic,readwrite) ccBlendFunc blendFunc;
/** does the alpha value modify color */
@property (nonatomic, readwrite, getter=doesOpacityModifyRGB, assign) BOOL opacityModifyRGB;
/** whether or not the particles are using blend additive.
 If enabled, the following blending function will be used.
 @code
 source blend function = GL_SRC_ALPHA;
 dest blend function = GL_ONE;
 @endcode
 */
@property (nonatomic,readwrite) BOOL blendAdditive;
/** particles movement type: Free or Grouped
 @since v0.8
 */
@property (nonatomic,readwrite) tCCPositionType positionType;
/** whether or not the node will be auto-removed when it has no particles left.
 By default it is NO.
 @since v0.8
 */
@property (nonatomic,readwrite) BOOL autoRemoveOnFinish;
/** Switch between different kind of emitter modes:
 - kCCParticleModeGravity: uses gravity, speed, radial and tangential acceleration
 - kCCParticleModeRadius: uses radius movement + rotation
 */
@property (nonatomic,readwrite) NSInteger emitterMode;

/** weak reference to the CCSpriteBatchNode that renders the CCSprite */
@property (nonatomic,readwrite,assign) CCParticleBatchNode *batchNode;

@property (nonatomic,readwrite) NSUInteger atlasIndex;

/** initializes a particle system from a NSDictionary.
 @since v0.99.3
 */
-(id) initWithDictionary:(NSDictionary*)dictionary;

//! Initializes a system with a fixed number of particles
-(id) initWithTotalParticles:(NSUInteger) numberOfParticles;
//! stop emitting particles. Running particles will continue to run until they die
-(void) stopSystem;
//! Kill all living particles.
-(void) resetSystem;
//! whether or not the system is full
-(BOOL) isFull;

//! should be overriden by subclasses
-(void) updateQuadWithParticle:(rCCParticle*)particle newPosition:(CGPoint)pos;
//! should be overriden by subclasses
-(void) postStep;

//! called in every loop.
-(void) update: (ccTime) dt;

-(void) updateWithNoTime;



@property(nonatomic, assign) NSUInteger looping;
@property(nonatomic, assign) EmitterType emitterType;
@property(nonatomic, assign) float startDelay;
@property(nonatomic, assign) float emitterRadius;
@property(nonatomic, assign) float emitterWidth;
@property(nonatomic, assign) float emitterHeight;

-(void) initParticle: (rCCParticle*) particle;

@end
