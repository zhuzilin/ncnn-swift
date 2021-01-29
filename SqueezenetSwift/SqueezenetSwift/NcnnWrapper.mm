//
//  NcnnWrapper.m
//  SwiftNCNN
//
//  Created by Zilin Zhu on 2021/1/28.
//

#import <Foundation/Foundation.h>
#import <ncnn/ncnn/net.h>

#import "NcnnWrapper.h"

#include <vector>

// MARK: Mat
struct _Mat {
    ncnn::Mat _mat;
    
    _Mat() {}
};

@implementation NcnnMat
- (instancetype)init
{
    self = [super init];
    _mat = new _Mat;
    return self;
}

- (instancetype)initFromPixels:(NSData*)data :(int)type :(int)w :(int)h
{
    self = [super init];
    unsigned char *bytes = (unsigned char *)[data bytes];
    _mat = new _Mat;
    _mat->_mat = ncnn::Mat::from_pixels(bytes, type, w, h);
    return self;
}

- (NSData *)toData:(int)length
{
    return [NSData dataWithBytes:_mat->_mat.data length:length];
}

- (void)dealloc
{
    delete _mat;
}

- (void)substractMeanNormalize:(NSArray<NSNumber*>*)mean :(NSArray<NSNumber*>*)std
{
    std::vector<float> meanVal, stdVal;
    for(id val in mean) {
        meanVal.push_back([val floatValue]);
    }
    for(id val in std) {
        stdVal.push_back([val floatValue]);
    }
    if (mean && std) {
        _mat->_mat.substract_mean_normalize(meanVal.data(), stdVal.data());
    } else if (mean) {
        _mat->_mat.substract_mean_normalize(meanVal.data(), 0);
    } else if (std) {
        _mat->_mat.substract_mean_normalize(0, stdVal.data());
    }
}
@end


// MARK: Net
struct _Net {
    ncnn::Net _net;
};

@implementation NcnnNet

- (instancetype)init
{
    self = [super init];
    _net = new _Net;
    return self;
}

- (void)dealloc
{
    delete _net;
}

- (int)loadParam:(NSString *)paramPath
{
    return _net->_net.load_param([paramPath UTF8String]);
}

- (int)loadParamBin:(NSString *)paramBinPath
{
    return _net->_net.load_param_bin([paramBinPath UTF8String]);
}

- (int)loadModel:(NSString *)modelPath
{
    return _net->_net.load_model([modelPath UTF8String]);
}

- (void)clear
{
    _net->_net.clear();
}

- (NSDictionary<NSNumber *,NcnnMat *> *)run:(NSDictionary<NSNumber *,NcnnMat *> *)inputs :(NSArray<NSNumber *> *)extracts
{
    ncnn::Extractor ex = _net->_net.create_extractor();
    ex.set_light_mode(true);
    for (id key in inputs) {
        int blobIndex = [key intValue];
        NcnnMat *input = inputs[key];
        if (ex.input(blobIndex, input->_mat->_mat) != 0) {
            NSLog(@"Failed to set input %d", blobIndex);
            return nil;
        }
    }
    NSMutableDictionary *result = @{}.mutableCopy;
    for (id index in extracts) {
        int blobIndex = [index intValue];
        ncnn::Mat output;
        if (ex.extract(blobIndex, output) != 0) {
            NSLog(@"Failed to extract output %d", blobIndex);
            return nil;
        }
        NcnnMat *outputWrapper = [[NcnnMat alloc] init];
        outputWrapper->_mat->_mat = output;
        [result setObject:outputWrapper forKey:index];
    }
    return result;
}

@end
