//
//  KernelTypes.h
//  TextureTest
//
//  Created by Xcode Developer on 1/15/22.
//

#ifndef KernelTypes_h
#define KernelTypes_h

typedef struct
{
    vector_float3 touch_point_xy__angle_z;
    vector_float3 button_center_xy__angle_z[5];
    vector_float3 arc_center_xy__radius_z;
    vector_float3 arc_control_points_xyz[2];
} CaptureDevicePropertyControlLayout;

#endif /* KernelTypes_h */
