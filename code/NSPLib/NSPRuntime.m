//
//  NSPRuntime.m
//  NSPLib
//
//  Created by Nolan O'Brien on 6/9/13.
//  Copyright (c) 2013 NSProgrammer.com. All rights reserved.
//

#import "NSPRuntime.h"
#include <objc/runtime.h>

void dispatch_sync_on_main_queue(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

BOOL NSPSwizzleInstanceMethods(Class class, SEL dstSel, SEL srcSel)
{
    if (!class || !dstSel || !srcSel)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"%@ cannot be NULL!", (!class ? @"class" : (!dstSel ? @"dstSel" : @"srcSel"))]
                                     userInfo:nil];
    }
    
    Method dstMethod = class_getInstanceMethod(class, dstSel);
    Method srcMethod = class_getInstanceMethod(class, srcSel);

    if (!srcMethod)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Missing source method implementation for swizzling!  Class %@, Source: %@, Destination: %@", NSStringFromClass(class), NSStringFromSelector(srcSel), NSStringFromSelector(dstSel)]
                                     userInfo:nil];
    }

    if (class_addMethod(class, dstSel, method_getImplementation(srcMethod), method_getTypeEncoding(srcMethod)))
    {
        class_replaceMethod(class, dstSel, method_getImplementation(dstMethod), method_getTypeEncoding(dstMethod));
    }
    else
    {
        method_exchangeImplementations(dstMethod, srcMethod);
    }
    return (srcMethod == class_getInstanceMethod(class, dstSel));
}

BOOL NSPSwizzleStaticMethods(Class class, SEL dstSel, SEL srcSel)
{
    Class metaClass = object_getClass(class);
    
    if (!metaClass || metaClass == class) // the metaClass being the same as class shows that class was already a MetaClass
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"%@ does not have a meta class to swizzle methods on!", NSStringFromClass(class)]
                                     userInfo:nil];
    }
    
    return NSPSwizzleInstanceMethods(metaClass, dstSel, srcSel);
}

@implementation NSObject (Swizzle)

+ (BOOL) swizzleInstanceMethod:(SEL)srcSelector toMethod:(SEL)dstSelector
{
    return NSPSwizzleInstanceMethods([self class], dstSelector, srcSelector);
}

+ (BOOL) swizzleStaticMethod:(SEL)srcSelector toMethod:(SEL)dstSelector
{
    return NSPSwizzleStaticMethods([self class], dstSelector, srcSelector);
}

@end

@implementation NSObject (StaticMethodCheck)

+ (BOOL) respondsToStaticMethodSelector:(SEL)sel
{
    return !!class_getClassMethod(self, sel);
}

@end

@implementation NSObject (Properties)

+ (NSArray*) instanceDeclaredPropertyNames
{
    unsigned int propC = 0;
    objc_property_t* propList = class_copyPropertyList(self, &propC);
    NSMutableArray* propArray = [NSMutableArray arrayWithCapacity:propC];

    for (unsigned int i = 0; i < propC; i++)
    {
        [propArray addObject:[NSString stringWithUTF8String:property_getName(propList[i])]];
    }

    free(propList);
    return [propArray copy];
}

+ (NSArray*) instanceInheritedPropertyNames
{
    Class c = self;
    Class s = class_getSuperclass(c);
    NSMutableArray* array = [NSMutableArray array];
    while (c != s &&
           s != NULL)
    {
        [array addObjectsFromArray:[s instanceDeclaredPropertyNames]];
        c = s;
        s = class_getSuperclass(s);
    }
    return [array copy];
}

+ (NSArray*) instanceAllPropertyNames
{
    return [[self instanceInheritedPropertyNames] arrayByAddingObjectsFromArray:[self instanceDeclaredPropertyNames]];
}

+ (BOOL) instanceHasPropertyNamed:(NSString*)property
{
    Class c = self;
    Class s = class_getSuperclass(c);
    const char* name = property.UTF8String;
    while (c != s &&
           c != NULL)
    {
        if (class_getProperty(c, name))
        {
            return YES;
        }

        c = s;
        s = class_getSuperclass(s);
    }
    return NO;
}

- (BOOL) hasPropertyNamed:(NSString*)property
{
    return [[self class] instanceHasPropertyNamed:property];
}

@end