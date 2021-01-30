//
//  CustomLayerRegistry.hpp
//  Yolov5Swift
//
//  Created by Zilin Zhu on 2021/1/30.
//

#ifndef CustomLayerRegistry_hpp
#define CustomLayerRegistry_hpp

#include <string>
#include <unordered_map>
#include <ncnn/ncnn/net.h>
#include <ncnn/ncnn/layer.h>

class CustomLayerRegistry {
public:
    struct Entry {
        ncnn::layer_creator_func creator = 0;
        ncnn::layer_destroyer_func destoryer = 0;
    };
    
    CustomLayerRegistry() = default;

    static CustomLayerRegistry* Global() {
        static CustomLayerRegistry* global_custom_layer_registry = new CustomLayerRegistry;
        return global_custom_layer_registry;
    }

    int LookUp(const std::string& name, Entry* entry) {
        auto iter = custom_layers_.find(name);
        if (iter == custom_layers_.end()) {
            return -1;
        }
        *entry = iter->second;
        return 0;
    }

    void Register(const std::string& name, Entry& entry) {
        custom_layers_[name] = entry;
    }

private:
    std::unordered_map<std::string, Entry> custom_layers_;
};

template<typename T>
class CustomLayerRegistrar {
public:
    CustomLayerRegistrar(const std::string& name) {
        CustomLayerRegistry::Entry entry;
        entry.creator = [](void *) -> ncnn::Layer* {
            return new T;
        };
        CustomLayerRegistry::Global()->Register(name, entry);
    }
};

#define DEFINE_CUSTOM_LAYER(name, T)                            \
    CustomLayerRegistrar<T> name##CustomLayerRegistrar(#name)

#endif /* CustomLayerRegistry_hpp */
