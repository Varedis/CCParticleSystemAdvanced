//
//  Original File Name - JGCCTextParticleSystem.m
//  Renamed SpriteSheetParticleSystem.m by Rob Scott 10/2/13
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

#import "SpriteSheetParticleSystem.h"

@interface SpriteSheetParticleSystem (private)
-(id) initializeParticleSystemWithBatchNode:(CCParticleBatchNode*) batchNode rect:(CGRect) rect;
@end

@implementation SpriteSheetParticleSystem

@synthesize quads=quads_;
@synthesize particleAnimation=particleAnimation_;

-(id)initWithDictionary:(NSDictionary *)dictionary WithSpriteSheet:(NSString *)spritesheet andString:(NSString *)str count:(int)count
{
    if ((self = [super initWithDictionary:dictionary]))
    {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:spritesheet];
        
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"%@_01.png", str]];
        nameString = [str retain];
        
        _amountOfParticles = count;
        
        _usingSpriteSheet = YES;
        
        [self setTexture:frame.texture];
        
        [self initTexCoordsWithRect:CGRectZero];
    }
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary andString:(NSString *)str
{
    if ((self = [super initWithDictionary:dictionary]))
    {
        nameString = [str retain];
        CCSprite *frame = [CCSprite spriteWithFile:nameString];
        
        _amountOfParticles = 1;
        _usingSpriteSheet = NO;
        
        [self setTexture:frame.texture];
        
        [self initTexCoordsWithRect:CGRectZero];
    }
    return self;
}

// overriding the init method, this is the base initializer
-(id) initWithTotalParticles:(NSUInteger)numberOfParticles batchNode:(CCParticleBatchNode*) batchNode rect:(CGRect) rect
{
	batchNode_ = batchNode;
	textureRect_ = rect;
    
	//first super then self
	if( (self=[super initWithTotalParticles:numberOfParticles]) ) {
		if ([self initializeParticleSystemWithBatchNode:batchNode rect:rect]==nil) return nil;
	}
    
	return self;
}

-(id) initWithTotalParticles:(NSUInteger) numberOfParticles
{
	CCParticleBatchNode* batchNode = nil;
	CGRect rect = CGRectMake(0.0f,0.0f,0.0f,0.0f);
	if (batchNode_)
	{
		batchNode = batchNode_;
		rect = textureRect_;
	}
	return [self initWithTotalParticles:numberOfParticles batchNode:batchNode rect:rect];
}

-(id) initializeParticleSystemWithBatchNode:(CCParticleBatchNode*) batchNode rect:(CGRect) rect
{
	if (rect.size.width == 0.f && rect.size.height == 0.f && batchNode != nil)
	{
		rect.size = CGSizeMake([batchNode.textureAtlas.texture pixelsWide], [batchNode.textureAtlas.texture pixelsHigh]);
	}
    
	// allocating data space
	if (batchNode == nil)
	{
        
		quads_ = calloc( sizeof(quads_[0]) * totalParticles, 1 );
		indices_ = calloc( sizeof(indices_[0]) * totalParticles * 6, 1 );
        
		if( !quads_ || !indices_) {
			CCLOG(@"cocos2d: Particle system: not enough memory");
			if( quads_ )
				free( quads_ );
			if(indices_)
				free(indices_);
            
			[self release];
			return nil;
		}
        
		// initialize only once the texCoords and the indices
		[self initTexCoordsWithRect:rect];
		[self initIndices];
        
#if CC_USES_VBO
		// create the VBO buffer
		glGenBuffers(1, &quadsID_);
        
		// initial binding
		glBindBuffer(GL_ARRAY_BUFFER, quadsID_);
		glBufferData(GL_ARRAY_BUFFER, sizeof(quads_[0])*totalParticles, quads_,GL_DYNAMIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
#endif
        
		useBatchNode_ = NO;
	}
	else {
		quads_ = NULL;
		indices_ = NULL;
        
		batchNode_ = batchNode;
        
		//can't use setTexture here since system isn't added to batchnode yet
		texture_ = [batchNode.textureAtlas.texture retain];
		textureRect_ = rect;
        
		useBatchNode_ = YES;
	}
    
	particleAnchorPoint_ = ccp(0.5f,0.5f);
	particleAnimation_ = nil;
    
	return [NSNumber numberWithInt:1];
}

-(void) dealloc
{
	if (quads_) free(quads_);
	if (indices_) free(indices_);
#if CC_USES_VBO
	if (!useBatchNode_) glDeleteBuffers(1, &quadsID_);
#endif
    
	[particleAnimation_ release];
    
    [nameString release];
    
	[super dealloc];
}

-(void) initTexCoordsWithRect:(CGRect)pointRect
{
    if(!_amountOfParticles)
        return;
    
    for(NSUInteger i=0; i<totalParticles; i++)
    {
        int frameNumber = 0;
        CGRect rect = CGRectZero;
        if(_usingSpriteSheet)
        {
            frameNumber = (arc4random() % _amountOfParticles) + 1;
            CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"%@_%02i.png", nameString, frameNumber]];
            rect = [frame rect];
        }
        else
        {
            CCSprite *frame = [CCSprite spriteWithFile:nameString];
            rect = [[frame displayedFrame] rect];
        }
        
        rect = CGRectMake(rect.origin.x * CC_CONTENT_SCALE_FACTOR(), rect.origin.y * CC_CONTENT_SCALE_FACTOR(), rect.size.width * CC_CONTENT_SCALE_FACTOR(), rect.size.height * CC_CONTENT_SCALE_FACTOR());
        
        GLfloat wide = [texture_ pixelsWide];
        GLfloat high = [texture_ pixelsHigh];
        
#if CC_FIX_ARTIFACTS_BY_STRECHING_TEXEL
		GLfloat left = (rect.origin.x*2+1) / (wide*2);
		GLfloat bottom = (rect.origin.y*2+1) / (high*2);
		GLfloat right = left + (rect.size.width*2-2) / (wide*2);
		GLfloat top = bottom + (rect.size.height*2-2) / (high*2);
#else
		GLfloat left = rect.origin.x / wide;
		GLfloat bottom = rect.origin.y / high;
		GLfloat right = left + rect.size.width / wide;
		GLfloat top = bottom + rect.size.height / high;
#endif // ! CC_FIX_ARTIFACTS_BY_STRECHING_TEXEL
        
        
        CC_SWAP( top, bottom);
        
        // bottom-left vertex:
        quads_[i].bl.texCoords.u = left;
        quads_[i].bl.texCoords.v = bottom;
        // bottom-right vertex:
        quads_[i].br.texCoords.u = right;
        quads_[i].br.texCoords.v = bottom;
        // top-left vertex:
        quads_[i].tl.texCoords.u = left;
        quads_[i].tl.texCoords.v = top;
        // top-right vertex:
        quads_[i].tr.texCoords.u = right;
        quads_[i].tr.texCoords.v = top;
    }
}

-(void) setTexture:(CCTexture2D *)texture withRect:(CGRect)rect
{
	// Only update the texture if is different from the current one
	if( [texture name] != [texture_ name] )
		[super setTexture:texture];
    
	[self initTexCoordsWithRect:rect];
}

-(void) setTexture:(CCTexture2D *)texture
{
	CGSize s = [texture contentSize];
	[self setTexture:texture withRect:CGRectMake(0,0, s.width, s.height)];
}

-(void) setDisplayFrame:(CCSpriteFrame *)spriteFrame
{
	NSAssert( CGPointEqualToPoint( spriteFrame.offsetInPixels , CGPointZero ), @"QuadParticle only supports SpriteFrames with no offsets");
    
	// update texture before updating texture rect
	if ( spriteFrame.texture.name != texture_.name )
		[self setTexture: spriteFrame.texture withRect:spriteFrame.rect];
}

-(void) initIndices
{
	for( NSUInteger i=0;i< totalParticles;i++) {
		const NSUInteger i6 = i*6;
		const NSUInteger i4 = i*4;
		indices_[i6+0] = (GLushort) i4+0;
		indices_[i6+1] = (GLushort) i4+1;
		indices_[i6+2] = (GLushort) i4+2;
        
		indices_[i6+5] = (GLushort) i4+1;
		indices_[i6+4] = (GLushort) i4+2;
		indices_[i6+3] = (GLushort) i4+3;
	}
}

-(void) updateQuadWithParticle:(tCCParticle*)p newPosition:(CGPoint)newPos
{
	// colors
	ccV3F_C4B_T2F_Quad *quad;
    
	if (useBatchNode_)
	{
		ccV3F_C4B_T2F_Quad *batchQuads = [[batchNode_ textureAtlas] quads];
		quad = &(batchQuads[atlasIndex_+p->atlasIndex]);
	}
	else quad = &(quads_[particleIdx]);
    
    ccColor4B color = (opacityModifyRGB_)
    ? (ccColor4B){ p->color.r*p->color.a*255, p->color.g*p->color.a*255, p->color.b*p->color.a*255, p->color.a*255}
    : (ccColor4B){ p->color.r*255, p->color.g*255, p->color.b*255, p->color.a*255};
    
	quad->bl.colors = color;
	quad->br.colors = color;
	quad->tl.colors = color;
	quad->tr.colors = color;
    
	// vertices
	GLfloat pos1x, pos1y, pos2x, pos2y;
	if (useAnimation_)
	{
		//p->size = scale
		ccAnimationFrameData frameData = animationFrameData_[p->currentFrame];
        
		pos1x = (-particleAnchorPoint_.x *  frameData.size.width) * p->size;
		pos1y = (-particleAnchorPoint_.y * frameData.size.height) * p->size;
		pos2x = ((1.f - particleAnchorPoint_.x) * frameData.size.width) * p->size;
		pos2y = ((1.f - particleAnchorPoint_.y) * frameData.size.height) * p->size;
        
		// set the texture coordinates to the (new) frame
		quad->tl.texCoords = frameData.texCoords.tl;
		quad->tr.texCoords = frameData.texCoords.tr;
		quad->bl.texCoords = frameData.texCoords.bl;
		quad->br.texCoords = frameData.texCoords.br;
        
	}
	else
	{
		float size2 = p->size/2.f;
		pos1x = -size2;//leftside x
		pos1y  = -size2; //bottom side y
		pos2x = size2; //rightside x
		pos2y = size2; //topside y
	}
    
	GLfloat r;
    
	//positionTypeFree doesn't react to transformations of parent
	if (useBatchNode_ && positionType_!=kCCPositionTypeFree)
	{//transformation need to be applied to quad manually
        
		pos1x = pos1x * scaleX_;
		pos1y = pos1y * scaleY_;
        
		pos2x = pos2x * scaleX_;
		pos2y = pos2y * scaleY_;
        
		r = (GLfloat)-CC_DEGREES_TO_RADIANS(p->rotation+rotation_);
	}
	else
		r = (GLfloat)-CC_DEGREES_TO_RADIANS(p->rotation);
    
	//don't transform particles if type is free
	if (useBatchNode_ )
	{
		GLfloat x1 = pos1x;
		GLfloat y1 = pos1y;
        
		GLfloat x2 = pos2x;
		GLfloat y2 = pos2y;
		GLfloat x = newPos.x;
		GLfloat y = newPos.y;
        
		GLfloat cr = cosf(r);
		GLfloat sr = sinf(r);
		GLfloat cr2 = cosf(r);
		GLfloat sr2 = sinf(r);
		GLfloat ax = x1 * cr - y1 * sr2 + x;
		GLfloat ay = x1 * sr + y1 * cr2 + y;
		GLfloat bx = x2 * cr - y1 * sr2 + x;
		GLfloat by = x2 * sr + y1 * cr2 + y;
		GLfloat cx = x2 * cr - y2 * sr2 + x;
		GLfloat cy = x2 * sr + y2 * cr2 + y;
		GLfloat dx = x1 * cr - y2 * sr2 + x;
		GLfloat dy = x1 * sr + y2 * cr2 + y;
        
		// bottom-left
		quad->bl.vertices.x = ax;
		quad->bl.vertices.y = ay;
		quad->bl.vertices.z = p->z;
        
		// bottom-right vertex:
		quad->br.vertices.x = bx;
		quad->br.vertices.y = by;
		quad->br.vertices.z = p->z;
        
		// top-left vertex:
		quad->tl.vertices.x = dx;
		quad->tl.vertices.y = dy;
		quad->tl.vertices.z = p->z;
		// top-right vertex:
		quad->tr.vertices.x = cx;
		quad->tr.vertices.y = cy;
		quad->tr.vertices.z = p->z;
	}
	else if( p->rotation) {
		GLfloat x1 = pos1x;
		GLfloat y1 = pos1y;
        
		GLfloat x2 = pos2x;
		GLfloat y2 = pos2y;
        
		GLfloat x = newPos.x;
		GLfloat y = newPos.y;
        
		GLfloat cr = cosf(r);
		GLfloat sr = sinf(r);
        
		GLfloat ax = x1 * cr - y1 * sr + x;
		GLfloat ay = x1 * sr + y1 * cr + y;
		GLfloat bx = x2 * cr - y1 * sr + x;
		GLfloat by = x2 * sr + y1 * cr + y;
		GLfloat cx = x2 * cr - y2 * sr + x;
		GLfloat cy = x2 * sr + y2 * cr + y;
		GLfloat dx = x1 * cr - y2 * sr + x;
		GLfloat dy = x1 * sr + y2 * cr + y;
        
		// bottom-left
		quad->bl.vertices.x = ax;
		quad->bl.vertices.y = ay;
        
		// bottom-right vertex:
		quad->br.vertices.x = bx;
		quad->br.vertices.y = by;
        
		// top-left vertex:
		quad->tl.vertices.x = dx;
		quad->tl.vertices.y = dy;
        
		// top-right vertex:
		quad->tr.vertices.x = cx;
		quad->tr.vertices.y = cy;
	} else {
		// bottom-left vertex:
		quad->bl.vertices.x = newPos.x + pos1x;
		quad->bl.vertices.y = newPos.y + pos1y;
        
		// bottom-right vertex:
		quad->br.vertices.x = newPos.x + pos2x;
		quad->br.vertices.y = newPos.y + pos1y;
        
		// top-left vertex:
		quad->tl.vertices.x = newPos.x + pos1x;
		quad->tl.vertices.y = newPos.y + pos2y;
        
		// top-right vertex:
		quad->tr.vertices.x = newPos.x + pos2x;
		quad->tr.vertices.y = newPos.y + pos2y;
	}
}

-(void) postStep
{
#if CC_USES_VBO
	glBindBuffer(GL_ARRAY_BUFFER, quadsID_);
	glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(quads_[0])*particleCount, quads_);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
#endif
}

// overriding draw method
-(void) draw
{
	[super draw];
    
	NSAssert(!useBatchNode_,@"draw should not be called when added to a particleBatchNode");
    
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Unneeded states: -
    
	glBindTexture(GL_TEXTURE_2D, [texture_ name]);
    
#define kQuadSize sizeof(quads_[0].bl)
    
#if CC_USES_VBO
	glBindBuffer(GL_ARRAY_BUFFER, quadsID_);
    
	glVertexPointer(3,GL_FLOAT, kQuadSize, 0);
    
	glColorPointer(4, GL_UNSIGNED_BYTE, kQuadSize, (GLvoid*) offsetof(ccV3F_C4B_T2F,colors) );
    
	glTexCoordPointer(2, GL_FLOAT, kQuadSize, (GLvoid*) offsetof(ccV3F_C4B_T2F,texCoords) );
#else // vertex array list
    
	NSUInteger offset = (NSUInteger) quads_;
    
	// vertex
	NSUInteger diff = offsetof( ccV3F_C4B_T2F, vertices);
	glVertexPointer(2,GL_FLOAT, kQuadSize, (GLvoid*) (offset+diff) );
    
	// color
	diff = offsetof( ccV3F_C4B_T2F, colors);
	glColorPointer(4, GL_UNSIGNED_BYTE, kQuadSize, (GLvoid*)(offset + diff));
    
	// tex coords
	diff = offsetof( ccV3F_C4B_T2F, texCoords);
	glTexCoordPointer(2, GL_FLOAT, kQuadSize, (GLvoid*)(offset + diff));
    
#endif // ! CC_USES_VBO
    
	BOOL newBlend = blendFunc_.src != CC_BLEND_SRC || blendFunc_.dst != CC_BLEND_DST;
	if( newBlend )
		glBlendFunc( blendFunc_.src, blendFunc_.dst );
    
	NSAssert( particleIdx == particleCount, @"Abnormal error in particle quad");
	glDrawElements(GL_TRIANGLES, (GLsizei) particleIdx*6, GL_UNSIGNED_SHORT, indices_);
    
	// restore blend state
	if( newBlend )
		glBlendFunc( CC_BLEND_SRC, CC_BLEND_DST );
    
#if CC_USES_VBO
	glBindBuffer(GL_ARRAY_BUFFER, 0);
#endif
    
	// restore GL default state
	// -
}

-(void) useSelfRender
{
	if (useBatchNode_)
	{
		[self initializeParticleSystemWithBatchNode:nil rect:textureRect_];
		useBatchNode_ = NO;
	}
}

-(void) batchNodeInitialization
{
	[self initTexCoordsWithRect:textureRect_];
}

-(void) useBatchNode:(CCParticleBatchNode*) batchNode
{
	if (!useBatchNode_)
	{
		[super useBatchNode:batchNode];
        
		if (quads_) free(quads_);
		quads_ = NULL;
        
		if (indices_) free(indices_);
		indices_ = NULL;
        
#if CC_USES_VBO
		glDeleteBuffers(1, &quadsID_);
#endif
	}
}

-(void) setAnimation:(CCAnimation*) animation
{
	[self setAnimation:animation withAnchorPoint:ccp(0.5f,0.5f)];
}

// animation
-(void) setAnimation:(CCAnimation*)anim withAnchorPoint:(CGPoint) particleAP
{
	NSAssert (anim != nil,@"animation is nil");
    
	[anim retain];
	[particleAnimation_ release];
	particleAnimation_ = anim;
    
	particleAnchorPoint_ = particleAP;
    
    
	NSArray* frames = particleAnimation_.frames;
    
	if ([frames count] == 0)
	{
		useAnimation_ = NO;
		CCLOG(@"no frames in animation");
		return;
	}
    
	CCSpriteFrame *frame = [[frames objectAtIndex:0] spriteFrame];
	if ([frame offsetInPixels].x != 0.f || [frame offsetInPixels].y != 0.f)
	{
		CCLOG(@"Particle animation, offset will not be taken into account");
	}
    
	if (batchNode_)
	{
		NSAssert (batchNode_.texture.name == texture_.name,@"CCParticleSystemQuad can only use a animation with the same texture as the batchnode");
	}
	else
	{
		CCSpriteFrame* frame = ([[frames objectAtIndex:0] spriteFrame]);
		self.texture = frame.texture;
	}
    
	totalFrameCount_ = [frames count];
    
	if (animationFrameData_)
	{
		free(animationFrameData_);
		animationFrameData_ = NULL;
	}
    
	// allocate memory for an array that will store data of the animation in the easies usable way for fast per frame updates of the particle system
	animationFrameData_ = malloc( sizeof(animationFrameData_[0]) * totalFrameCount_ );
    
	useAnimation_ = YES;
    
	//same as CCAnimate
	float newUnitOfTimeValue = particleAnimation_.duration / particleAnimation_.totalDelayUnits;
    
	for (int i = 0; i < totalFrameCount_; i++) {
        
		CCAnimationFrame *animationFrame = [frames objectAtIndex:i];
		CCSpriteFrame* frame = animationFrame.spriteFrame;
        
		CGRect rect = [frame rectInPixels];
        
		animationFrameData_[i].delay = newUnitOfTimeValue * animationFrame.delayUnits;
		animationFrameData_[i].size = rect.size;
        
		// now calculate the texture coordinates for the frame
		float left,right,top,bottom;
		ccT2F_Quad quad;
		GLfloat atlasWidth = (GLfloat)texture_.pixelsWide;
		GLfloat atlasHeight = (GLfloat)texture_.pixelsHigh;
        
		if(frame.rotated){
#if CC_FIX_ARTIFACTS_BY_STRECHING_TEXEL
			left	= (2*rect.origin.x+1)/(2*atlasWidth);
			right	= left+(rect.size.height*2-2)/(2*atlasWidth);
			top		= (2*rect.origin.y+1)/(2*atlasHeight);
			bottom	= top+(rect.size.width*2-2)/(2*atlasHeight);
#else
			left	= rect.origin.x/atlasWidth;
			right	= left+(rect.size.height/atlasWidth);
			top		= rect.origin.y/atlasHeight;
			bottom	= top+(rect.size.width/atlasHeight);
#endif // ! CC_FIX_ARTIFACTS_BY_STRECHING_TEXEL
            
			quad.bl.u = left;
			quad.bl.v = top;
			quad.br.u = left;
			quad.br.v = bottom;
			quad.tl.u = right;
			quad.tl.v = top;
			quad.tr.u = right;
			quad.tr.v = bottom;
            
		} else {
#if CC_FIX_ARTIFACTS_BY_STRECHING_TEXEL
			left	= (2*rect.origin.x+1)/(2*atlasWidth);
			right	= left + (rect.size.width*2-2)/(2*atlasWidth);
			top		= (2*rect.origin.y+1)/(2*atlasHeight);
			bottom	= top + (rect.size.height*2-2)/(2*atlasHeight);
#else
			left	= rect.origin.x/atlasWidth;
			right	= left + rect.size.width/atlasWidth;
			top		= rect.origin.y/atlasHeight;
			bottom	= top + rect.size.height/atlasHeight;
#endif // ! CC_FIX_ARTIFACTS_BY_STRECHING_TEXEL
            
			quad.bl.u = left;
			quad.bl.v = bottom;
			quad.br.u = right;
			quad.br.v = bottom;
			quad.tl.u = left;
			quad.tl.v = top;
			quad.tr.u = right;
			quad.tr.v = top;
		}
        
		animationFrameData_[i].texCoords = quad;
        
	} // for
}

@end
