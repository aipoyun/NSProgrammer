/*
 
 Copyright (C) 2013 Nolan O'Brien
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "HLSSettings.h"

typedef struct {
    BOOL stereo;
    NSUInteger width;
    NSUInteger height;
    NSUInteger kbps;
    NSUInteger videoKbps;
} HLSConfig;

static const HLSConfig s_wideScreenConfigs[] = {
    { NO, 320, 180, 150, 90 },
    { NO, 320, 180, 320, 260 },
    { NO, 640, 360, 640, 580 },
    { YES, 640, 360, 1280, 1200 },
    { YES, 960, 540, 1920, 1800 },
    { YES, 1280, 720, 2560, 2400 }
};

static const HLSConfig s_standardConfigs[] = {
    { NO, 240, 180, 150, 90 },
    { NO, 240, 180, 320, 260 },
    { NO, 480, 360, 640, 580 },
    { YES, 480, 360, 1280, 1200 },
    { YES, 720, 540, 1920, 1800 },
    { YES, 960, 720, 2560, 2400 }
};

HLSType KBPS2HLSType(NSInteger kbps)
{
    for (HLSType type = 0; type < HLSTypeCount; type++)
    {
        if (s_wideScreenConfigs[type].kbps == kbps)
        {
            return type;
        }
    }
    return -1;
}

NSArray* GetAllHLSTypes(void)
{
    NSMutableArray* allTypes = [[NSMutableArray alloc] init];
    for (HLSType type = 0; type < HLSTypeCount; type++)
    {
        [allTypes addObject:@(type)];
    }
    return allTypes;
}

@implementation HLSSettings

+ (NSArray*) allDefaultHLSSettings:(NSString*)sourceFile outputDirectory:(NSString*)outputDir widescreen:(BOOL)widescreen
{
    NSMutableArray* settingsList = [[NSMutableArray alloc] init];
    for (HLSType type = 0; type < HLSTypeCount; type++)
    {
        [settingsList addObject:[HLSSettings settingsForHLSType:type sourceFile:sourceFile outputDirectory:outputDir widescreen:widescreen]];
    }
    return [settingsList copy];
}

+ (HLSSettings*) settingsForHLSType:(HLSType)type sourceFile:(NSString *)sourceFile outputDirectory:(NSString*)outputDir widescreen:(BOOL)widescreen
{
    const HLSConfig* configs = (widescreen ? s_wideScreenConfigs : s_standardConfigs);
    HLSConfig config = configs[type];
    return [[HLSSettings alloc] initWithConfig:config sourceFile:sourceFile outputDirectory:outputDir];
}

- (id) initWithConfig:(HLSConfig)config sourceFile:(NSString*)sourceFile outputDirectory:(NSString*)outputDir
{
    if (self = [super init])
    {
        self.sourceFile = sourceFile;
        self.stereo = config.stereo;
        self.width  = config.width;
        self.height = config.height;
        self.kbps   = config.kbps;
        self.videoKbps = config.videoKbps;
        NSString* name = [[sourceFile lastPathComponent] stringByDeletingPathExtension];
        name = [name stringByAppendingFormat:@"_%li", config.kbps];
        name = [name stringByAppendingPathExtension:@"mp4"];
        self.outputFile = [outputDir stringByAppendingPathComponent:name];
        self.outputDirectory = [outputDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%li", config.kbps]];
    }
    return self;
}

- (NSString*) description
{
    NSMutableDictionary* d = [[NSMutableDictionary alloc] init];
    if (self.sourceFile)
        [d setObject:self.sourceFile forKey:@"sourceFile"];
    if (self.outputDirectory)
        [d setObject:self.outputDirectory forKey:@"outputDirectory"];
    if (self.outputFile)
        [d setObject:self.outputFile forKey:@"outputFile"];
    [d setObject:@(self.stereo) forKey:@"stereo"];
    [d setObject:@(self.width) forKey:@"width"];
    [d setObject:@(self.height) forKey:@"height"];
    [d setObject:@(self.kbps) forKey:@"kbps"];
    [d setObject:@(self.videoKbps) forKey:@"videoKbps"];
    return d.description;
}

@end