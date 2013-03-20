CCParticleSystemAdvanced
========================

The code required to run CCParticleSystemAdvanced for Cocos2d.

CCParticleSystemAdvanced plists are generated using Particle Producer which is available on the Mac App Store

(Link to follow once available)

CCParticleSystemAdvanced is an ongoing effort to build a better particle system for use in Cocos2d games and utilities.

The current benefits over the standard CCParticleSystem are:

. Alter the size over the lifetime of the partile. This lets you be in full control over how a particle system behaves over it lifetime.

. Alter the colour over the lifetime of the particle, this gives you fill control over what colour the particle should be at certain stages of its life for advanced effects.

. Make multi layered particle systems and export them all in one .plist.

Experimental: Particle loading from spritesheets.

More features are on the way in future versions including:
. Particle animation.
. A greater range of movement and animation controls.

And much more

# Use #

*** Normal Use ***
Setup is designed to be as simple as possible, simply drop the generated .plist in your project with the required images and then call:
	
	LayeredParticleSystem *pst = [[LayeredParticleSystem alloc] initWithPlist:@"myAdvancedParticle.plist"];
        pst.position = ccp(0,0);
        [self addChild:pst];

This setup will use the images that are defined in the plist to create your particle system

*** Experimental Use ***
You can also use a series of images to populate the particle system, this functionality is still a work in progress at the minute and will be worked on greatly in upcoming revisions.
Using this system you could have for example 10 different fire particles which get spawned and randomly assigned to each particle in the system, this gives you a greater effect and variation than just using one duplicate image throughout the entire system.

There are a few rules to follow when using this system:
. Images must all contain the same name and should contain an incremental suffix depending on the number of images, for example if your image is called skulls_01.png then the other images must be called skulls_02.png, skulls_03.png and skulls_04.png
. At the minute the images will be applied to all layers of the particle system, so this should only really be used on one layer systems

To use this functionality call the following code:
	LayeredParticleSystem *pst = [[LayeredParticleSystem alloc] initWithPlist:@"myAdvancedParticle.plist" WithSpriteSheet:@"ParticleEffect.plist" andString:@"skulls" count:4];
        pst.position = ccp(0,0);
        [self addChild:pst];

The spritesheet is the name of the plist where the images are stored.
The string is the prefix of the image name, without the number.
The count is how many images there are in total (your images suffix should range from 01 to this number)