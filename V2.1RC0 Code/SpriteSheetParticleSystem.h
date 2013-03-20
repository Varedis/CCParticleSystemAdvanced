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

@interface SpriteSheetParticleSystem : CCParticleSystemAdvanced
{
    ccV3F_C4B_T2F_Quad	*_quads;		// quads to be rendered
	GLushort			*_indices;		// indices
	GLuint				_VAOname;
	GLuint				_buffersVBO[2]; //0: vertex  1: indices
    
    
    NSString *nameString;
    
    int _amountOfParticles;
}

/** initialices the indices for the vertices */
-(void) initIndices;

/** initilizes the texture with a rectangle measured Points */
-(void) initTexCoordsWithRect:(CGRect)rect;

/** Sets a new CCSpriteFrame as particle.
 WARNING: this method is experimental. Use setTexture:withRect instead.
 @since v0.99.4
 */
-(void)setDisplayFrame:(CCSpriteFrame*)spriteFrame;

/** Sets a new texture with a rect. The rect is in Points.
 @since v0.99.4
 */
-(void) setTexture:(CCTexture2D *)texture withRect:(CGRect)rect;


-(id)initWithDictionary:(NSDictionary *)dictionary WithSpriteSheet:(NSString *)spritesheet andString:(NSString *)str count:(int)count;
-(id)initWithDictionary:(NSDictionary *)dictionary andString:(NSString *)str;

@end
