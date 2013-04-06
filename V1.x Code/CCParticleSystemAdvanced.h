//
//  CCParticleSystemAdvanced.h
//  LayeredParticleSystem
//
//  Created by Robert Scott on 10/02/2013.
//  Copyright 2013 Unseen-Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef struct tCCParticle {
	CGPoint		pos;
	float		z;
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
    
	// animation
	ccTime		elapsed;
	ccTime		split;
	NSUInteger  currentFrame;
    
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
    // is the particle system active ?
	BOOL active;
	// duration in seconds of the system. -1 is infinity
	float duration;
	// time elapsed since the start of the system (in seconds)
	float elapsed;
    
	// position is from "superclass" CocosNode
	CGPoint sourcePosition;
	// Position variance
	CGPoint posVar;
    
	// The angle (direction) of the particles measured in degrees
	float angle;
	// Angle variance measured in degrees;
	float angleVar;
    
	// Different modes
    
	NSInteger emitterMode_;
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
	} mode;
    
	// start ize of the particles
	float startSize;
	// start Size variance
	float startSizeVar;
	// End size of the particle
	float endSize;
	// end size of variance
	float endSizeVar;
    
	float startScale;
	float startScaleVar;
	float endScale;
	float endScaleVar;
    
	// How many seconds will the particle live
	float life;
	// Life variance
	float lifeVar;
    
	// Start color of the particles
	ccColor4F startColor;
	// Start color variance
	ccColor4F startColorVar;
	// End color of the particles
	ccColor4F endColor;
	// End color variance
	ccColor4F endColorVar;
    
	// start angle of the particles
	float startSpin;
	// start angle variance
	float startSpinVar;
	// End angle of the particle
	float endSpin;
	// end angle ariance
	float endSpinVar;
    
	// Array of particles
	rCCParticle *particles;
	// Maximum particles
	NSUInteger totalParticles;
	// Count of active particles
	NSUInteger particleCount;
    
	// How many particles can be emitted per second
	float emissionRate;
	float emitCounter;
    
	// Texture of the particles
	CCTexture2D *texture_;
	// blend function
	ccBlendFunc	blendFunc_;
    // Texture alpha behavior
    BOOL opacityModifyRGB_;
    
	// movment type: free or grouped
	tCCPositionType	positionType_;
    
	// Whether or not the node will be auto-removed when there are not particles
	BOOL	autoRemoveOnFinish_;
    
	//  particle idx
	NSUInteger particleIdx;
    
	// Optimization
	CC_UPDATE_PARTICLE_IMP	updateParticleImp;
	SEL						updateParticleSel;
    
	//for batching
	CCParticleBatchNode *batchNode_;
	BOOL useBatchNode_;
	//index of system in batch node array
	NSUInteger atlasIndex_;
	//YES if scaled or rotated
	BOOL transformSystemDirty_;
    
	// animation
	BOOL				useAnimation_;
	NSUInteger			totalFrameCount_;
    
	//contains offset positions for vertex and precalculated texture coordinates
	ccAnimationFrameData	*animationFrameData_;
	tCCParticleAnimationType animationType_;
    
    
    // profiling
#if CC_ENABLE_PROFILERS
	CCProfilingTimer* _profilingTimer;
#endif
    
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
/** start scale in pixels of each particle. Only used by animation
 @since 1.1
 */
@property (nonatomic,readwrite,assign) float startScale;
/** scale variance in pixels of each particle. Only used by animation
 @since 1.1
 */
@property (nonatomic,readwrite,assign) float startScaleVar;
/** end scale in pixels of each particle. Only used by animation
 @since 1.1
 */
@property (nonatomic,readwrite,assign) float endScale;
/** end scale variance in pixels of each particle. Only used by animation
 @since 1.1
 */
@property (nonatomic,readwrite,assign) float endScaleVar;
/** start color of each particle */
@property (nonatomic,readwrite,assign) ccColor4F startColor;
/** start color variance of each particle */
@property (nonatomic,readwrite,assign) ccColor4F startColorVar;
/** end color and end color variation of each particle */
@property (nonatomic,readwrite,assign) ccColor4F endColor;
/** end color variance of each particle */
@property (nonatomic,readwrite,assign) ccColor4F endColorVar;
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
/** Index of first particle in texture atlas of batch node
 @since 1.1
 */
@property (nonatomic,readwrite) NSUInteger atlasIndex;
/** YES if a particle batchnode is used for rendering, NO for self rendering
 @since 1.1
 */
@property (nonatomic,readonly) BOOL useBatchNode;

/** animation type, once, loop from beginning, random frame, or loop with random start frame
 @since 1.1
 */
@property (nonatomic,readwrite) tCCParticleAnimationType animationType;

@property(nonatomic, assign) NSUInteger looping;
@property(nonatomic, assign) EmitterType emitterType;
@property(nonatomic, assign) float startDelay;
@property(nonatomic, assign) float emitterRadius;
@property(nonatomic, assign) float emitterWidth;
@property(nonatomic, assign) float emitterHeight;

-(id) initWithDictionary:(NSDictionary*)dictionary;

//! Initializes a system with a fixed number of particles and whether a batchnode is used for rendering
-(id) initWithTotalParticles:(NSUInteger) numberOfParticles;
//! Add a particle to the emitter
-(BOOL) addParticle;
//! stop emitting particles. Running particles will continue to run until they die
-(void) stopSystem;
//! Kill all living particles.
-(void) resetSystem;
//! whether or not the system is full
-(BOOL) isFull;

//! should be overriden by subclasses
-(void) updateQuadWithParticle:(tCCParticle*)particle newPosition:(CGPoint)pos;
//! should be overriden by subclasses
-(void) postStep;

//! called in every loop.
-(void) update: (ccTime) dt;

-(void) updateWithNoTime;

//switch to self rendering
-(void) useSelfRender;
//switch to batch node rendering
-(void) useBatchNode:(CCParticleBatchNode*) batchNode;

//used internally by CCParticleBathNode
-(void) batchNodeInitialization;

-(void) initParticle: (rCCParticle*) particle;

@end
