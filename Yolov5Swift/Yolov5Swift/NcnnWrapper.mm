//
//  NcnnWrapper.m
//  SwiftNCNN
//
//  Created by Zilin Zhu on 2021/1/30.
//

#import <Foundation/Foundation.h>
#import <ncnn/ncnn/net.h>
#import <ncnn/ncnn/cpu.h>
#include <opencv2/opencv2/highgui.hpp>

#import "NcnnWrapper.h"

#include <vector>

#include "CustomLayerRegistry.hpp"

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

- (instancetype)initFromPixelsResize:(NSData*)data :(int)type :(int)w :(int)h :(int)target_width :(int)target_height
{
    self = [super init];
    unsigned char *bytes = (unsigned char *)[data bytes];
    _mat = new _Mat;
    _mat->_mat = ncnn::Mat::from_pixels_resize(bytes, type, w, h, target_width, target_height);
    return self;
}

- (instancetype)initFromPathResize:(NSString*)path :(int)target_width :(int)target_height
{
    std::string path_str = std::string([path UTF8String], [path length]);
    _mat = new _Mat;
    NSDate *start = [NSDate date];
    cv::Mat img = cv::imread(path_str);
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"imread time: %.2f", timeInterval * -1000);
    _mat->_mat = ncnn::Mat::from_pixels_resize(img.data, 1, img.cols, img.rows, target_width, target_height);
    return self;
}

- (int)w
{
    return _mat->_mat.w;
}

- (int)h
{
    return _mat->_mat.h;
}

- (int)c
{
    return _mat->_mat.c;
}

- (NSData *)toData
{
    unsigned long length = _mat->_mat.w * _mat->_mat.h * _mat->_mat.c * _mat->_mat.elemsize;
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

- (int)registerCustomLayer:(NSString *)type
{
    std::string name([type UTF8String]);
    CustomLayerRegistry::Entry entry;
    if (CustomLayerRegistry::Global()->LookUp(name, &entry) != 0) {
        return -1;
    }
    return _net->_net.register_custom_layer([type UTF8String], entry.creator, entry.destoryer);
}

- (NSDictionary<NSNumber *,NcnnMat *> *)runWithIndex:(NSDictionary<NSNumber *,NcnnMat *> *)inputs :(NSArray<NSNumber *> *)extracts
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

- (NSDictionary<NSNumber *,NcnnMat *> *)runWithName:(NSDictionary<NSNumber *,NcnnMat *> *)inputs :(NSArray<NSNumber *> *)extracts
{
    ncnn::Extractor ex = _net->_net.create_extractor();
    for (id key in inputs) {
        NcnnMat *input = inputs[key];
        if (ex.input([key UTF8String], input->_mat->_mat) != 0) {
            NSLog(@"Failed to set input %@", key);
            return nil;
        }
    }
    NSMutableDictionary *result = @{}.mutableCopy;
    for (id key in extracts) {
        ncnn::Mat output;
        if (ex.extract([key UTF8String], output) != 0) {
            NSLog(@"Failed to extract output %@", key);
            return nil;
        }
        NcnnMat *outputWrapper = [[NcnnMat alloc] init];
        outputWrapper->_mat->_mat = output;
        [result setObject:outputWrapper forKey:key];
    }
    return result;
}

@end
