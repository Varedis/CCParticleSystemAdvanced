//
//  Original File Name - JGCCTextParticleSystem.h
//  Renamed SpriteSheetParticleSystem.h by Rob Scott 10/2/13
//
//  This class can use images from spritesheets and create particle systems using those images.
//  It currently only handles static images but I am looking to expand it to handle animated images and sprites
//
//  Created by Jacob Gundersen on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//  Modified by Rob Scott on 10/2/13.
//  Copyright 2013 Unseen-Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCParticleSystemAdvanced.h"

@interface SpriteSheetParticleSystem : CCParticleSystemAdvanced {
    ccV3F_C4B_T2F_Quad	*quads_;		// quads to be rendered
	GLushort			*indices_;		// indices
	CGRect				textureRect_;
#if CC_USES_VBO
	GLuint				quadsID_;		// VBO id
#endif
    
	CGPoint particleAnchorPoint_;
	CCAnimation			*particleAnimation_;
    
    NSString *nameString;
    BOOL _usingSpriteSheet;
    int _amountOfParticles;
}

@property (nonatomic, readwrite) ccV3F_C4B_T2F_Quad* quads;
/** animation that holds the sprite frames
 @since 1.1
 */
@property (nonatomic, retain) CCAnimation* particleAnimation;

-(id) initWithTotalParticles:(NSUInteger)numberOfParticles batchNode:(CCParticleBatchNode*) batchNode rect:(CGRect) rect;

/** initialices the indices for the vertices */
-(void) initIndices;

/** initilizes the texture with a rectangle measured Points */
-(void) initTexCoordsWithRect:(CGRect)rect;

/** Sets a new CCSpriteFrame as particle.
 WARNING: this method is experimental. Use setTexture:withRect instead.
 uses the texture and the rect of the spriteframe to call setTexture:Rect:
 @since v0.99.4
 */
-(void) setDisplayFrame:(CCSpriteFrame*)spriteFrame;

/** Sets a new texture with a rect. The rect is in Points.
 @since v0.99.4
 */
-(void) setTexture:(CCTexture2D *)texture withRect:(CGRect)rect;

/** sets a animation that will be used for each particle, default particle anchorpoint of (0.5,0.5)
 @since 1.1
 
 */
-(void) setAnimation:(CCAnimation*) animation;

/** sets a animation that will be used for each particle, and the anchor point for each particle
 Note, offsets of sprite frames are not used
 @since 1.1
 */
-(void) setAnimation:(CCAnimation*) anim withAnchorPoint:(CGPoint) particleAP;

-(id)initWithDictionary:(NSDictionary *)dictionary WithSpriteSheet:(NSString *)spritesheet andString:(NSString *)str count:(int)count;
-(id)initWithDictionary:(NSDictionary *)dictionary andString:(NSString *)str;

@end
