//
//  NcnnWrapper.h
//  SwiftNCNN
//
//  Created by Zilin Zhu on 2021/1/30.
//

#ifndef NcnnWrapper_h
#define NcnnWrapper_h

#import <Foundation/Foundation.h>

// MARK: Mat
struct _Mat;
@interface NcnnMat : NSObject
{
    @public struct _Mat *_mat;
}

- (instancetype)initFromPixels:(NSData*)data :(int)type :(int)w :(int)h;
- (instancetype)initFromPixelsResize:(NSData*)data :(int)type :(int)w :(int)h :(int)target_width :(int)target_height;
- (instancetype)initFromPathResize:(NSString*)path :(int)target_width :(int)target_height;
- (int)w;
- (int)h;
- (int)c;
- (NSData*)toData;
- (void)substractMeanNormalize:(NSArray<NSNumber*>*)mean :(NSArray<NSNumber*>*)std;
@end

// MARK: Net
struct _Net;
@interface NcnnNet : NSObject
{
    @public struct _Net *_net;
}
- (int)loadParam:(NSString*)paramPath;
- (int)loadParamBin:(NSString*)paramBinPath;
- (int)loadModel:(NSString*)modelPath;
- (void)clear;

- (int)registerCustomLayer:(NSString*)type;

- (NSDictionary<NSNumber *, NcnnMat *> *)runWithIndex:(NSDictionary<NSNumber *, NcnnMat *> *)inputs
                                            :(NSArray<NSNumber *> *)extracts;
- (NSDictionary<NSString *, NcnnMat *> *)runWithName:(NSDictionary<NSString *, NcnnMat *> *)inputs
                                            :(NSArray<NSString *> *)extracts;
@end

#endif /* NcnnWrapper_h */
