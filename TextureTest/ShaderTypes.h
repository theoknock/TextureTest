//
//  ShaderTypes.h
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

//#include <simd/simd.h>
//
//typedef NS_ENUM(NSInteger, BufferIndex)
//{
//    BufferIndexMeshPositions = 0,
//    BufferIndexMeshGenerics  = 1,
//    BufferIndexUniforms      = 2
//};
//
//typedef NS_ENUM(NSInteger, VertexAttribute)
//{
//    VertexAttributePosition  = 0,
//    VertexAttributeTexcoord  = 1,
//};
//
//typedef NS_ENUM(NSInteger, TextureIndex)
//{
//    TextureIndexColor    = 0,
//};
//
//typedef struct
//{
//    matrix_float4x4 projectionMatrix;
//    matrix_float4x4 modelViewMatrix;
//} Uniforms;

#include <simd/simd.h>

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum AAPLVertexInputIndex
{
    AAPLVertexInputIndexVertices     = 0,
    AAPLVertexInputIndexViewportSize = 1,
} AAPLVertexInputIndex;

// Texture index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API texture set calls
typedef enum AAPLTextureIndex
{
    AAPLTextureIndexBaseColor = 0,
} AAPLTextureIndex;

//  This structure defines the layout of each vertex in the array of vertices set as an input to the
//    Metal vertex shader.  Since this header is shared between the .metal shader and C code,
//    you can be sure that the layout of the vertex array in the code matches the layout that
//    the vertex shader expects

typedef struct
{
    // Positions in pixel space. A value of 100 indicates 100 pixels from the origin/center.
    vector_float2 position;

    // 2D texture coordinate
    vector_float2 textureCoordinate;
} AAPLVertex;

typedef struct
{
    float gaussian_mean;
    float standard_deviation;
} FilterSettings;

#endif /* ShaderTypes_h */

