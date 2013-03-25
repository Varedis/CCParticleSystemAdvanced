//
//  LayeredParticleSystem.m
//  LayeredParticleSystem
//
//  Created by Robert Scott on 10/02/2013.
//  Copyright 2013 Unseen-Studios. All rights reserved.
//

#import "LayeredParticleSystem.h"
#import "SpriteSheetParticleSystem.h"


@implementation LayeredParticleSystem

-(id) initWithPlist:(NSString *)plistFile WithSpriteSheet:(NSString *)spritesheet andString:(NSString *)str count:(int)count
{
    if((self = [super init]))
    {
        NSString *path = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:plistFile];
        NSDictionary *fullDict = [NSDictionary dictionaryWithContentsOfFile:path];
        NSAssert( fullDict != nil, @"Particles: file not found");
        
        int numberOfLayers = [[fullDict objectForKey:@"layers"] intValue];
        
        for(int index = 0; index < numberOfLayers; index++)
        {
            NSDictionary *dict = [fullDict objectForKey:[NSString stringWithFormat:@"Layer%i", index]];
            SpriteSheetParticleSystem *particleLayer = [[SpriteSheetParticleSystem alloc] initWithDictionary:dict WithSpriteSheet:spritesheet andString:str count:count];
            [self addChild:particleLayer z:0];
        }
    }
    return self;
}

-(id) initWithPlist:(NSString *)plistFile
{
    NSString *path = [[CCFileUtils sharedFileUtils]fullPathFromRelativePath:plistFile];
    NSDictionary *fullDict = [NSDictionary dictionaryWithContentsOfFile:path];
    NSAssert( fullDict != nil, @"Particles: file not found");
    
    return [self initWithFullDictionary:fullDict];
}

-(id) initWithFullDictionary:(NSDictionary *)fullDict
{
    if((self = [super init]))
    {
        NSAssert( fullDict != nil, @"Particles: dictionary not found");
        
        int numberOfLayers = [[fullDict objectForKey:@"layers"] intValue];
        
        for(int index = 0; index < numberOfLayers; index++)
        {
            NSDictionary *dict = [fullDict objectForKey:[NSString stringWithFormat:@"Layer%i", index]];
            
            NSString *string = [dict valueForKey:@"textureFileName"];
            
            SpriteSheetParticleSystem *particleLayer = [[SpriteSheetParticleSystem alloc] initWithDictionary:dict andString:string];
            
            [self addChild:particleLayer z:0];
            
            [particleLayer release];
        }
    }
    return self;
}

-(void) dealloc
{
    [super dealloc];
}

-(void)removeChild: (CCParticleSystem*) child cleanup:(BOOL)doCleanup
{
    [super removeChild:child cleanup:doCleanup];
    
    if(![[self children] count])
    {
        [self removeFromParentAndCleanup:YES];
    }
}

-(void) resetAllLayers
{
    for (SpriteSheetParticleSystem *layer in [self children])
    {
        [layer resetSystem];
    }
}

-(void) resetAllOtherLayers:(int)index
{
    for (SpriteSheetParticleSystem *layer in [self children])
    {
        if(layer.tag == index)
            continue;
        
        [layer resetSystem];
    }
}

-(void) stopAllLayers
{
    for (SpriteSheetParticleSystem *layer in [self children])
    {
        [layer stopSystem];
    }
}

-(SpriteSheetParticleSystem *) addNewLayer:(NSDictionary *)dict index:(int)index
{
    NSAssert( dict != nil, @"Particles: file not found");
    
    NSString *string = [[dict valueForKey:@"textureFileUrl"] retain];
    
    SpriteSheetParticleSystem *particleLayer = [[SpriteSheetParticleSystem alloc] initWithDictionary:dict WithSpriteSheet:@"ParticleEffect.plist" andString:string count:1];
    
    [string release];
    
    float x = [[dict valueForKey:@"sourcePositionx"] floatValue];
    float y = [[dict valueForKey:@"sourcePositiony"] floatValue];
    particleLayer.position = ccp(x,y);
    [self addChild:particleLayer z:0 tag:index];
    
    return particleLayer;
}

-(void) removeLayer:(int)index
{
    [self removeChild:[self getChildByTag:index] cleanup:YES];
}

-(SpriteSheetParticleSystem *) removeAndAddLayer:(NSDictionary *)dict index:(int)index
{
    [self removeLayer:index];
    
    return [self addNewLayer:dict index:index];
}

-(void) setAutoRemoveOnFinish:(BOOL)value
{
    for (SpriteSheetParticleSystem *layer in [self children])
    {
        [layer setAutoRemoveOnFinish:value];
    }
}

-(void) setPositionType:(tCCPositionType)value
{
    for (SpriteSheetParticleSystem *layer in [self children])
    {
        [layer setPositionType:value];
    }
}

-(void) runAction:(CCAction *)action
{
    for (SpriteSheetParticleSystem *layer in [self children])
    {
        [layer runAction:[action copy]];
    }
}

@end
