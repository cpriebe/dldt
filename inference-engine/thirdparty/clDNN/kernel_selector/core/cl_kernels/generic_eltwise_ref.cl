/*
// Copyright (c) 2016-2019 Intel Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
*/

#include "include/include_all.cl"

#if defined(INPUT_STRIDED) && OUTPUT_DIMS == 5
    #define GET_INDEX(prefix, num, idx_order) \
                CAT(CAT(prefix, num), _OFFSET) + \
                ((d1 * CAT(CAT(prefix, num), _STRIDE_X)) % CAT(CAT(prefix, num), _SIZE_X))*CAT(CAT(prefix, num), _X_PITCH) +\
                ((d2 * CAT(CAT(prefix, num), _STRIDE_Y)) % CAT(CAT(prefix, num), _SIZE_Y))*CAT(CAT(prefix, num), _Y_PITCH) +\
                ((d3 * CAT(CAT(prefix, num), _STRIDE_Z)) % CAT(CAT(prefix, num), _SIZE_Z))*CAT(CAT(prefix, num), _Z_PITCH) +\
                (d4 % CAT(CAT(prefix, num), _FEATURE_NUM))*CAT(CAT(prefix, num), _FEATURE_PITCH) + \
                (d5 % CAT(CAT(prefix, num), _BATCH_NUM  ))*CAT(CAT(prefix, num), _BATCH_PITCH)
#else
    #if ELTWISE_LAYOUT_BASED || QUANTIZATION_TERM || ELTWISE_BROADCAST
        #define GET_INDEX(prefix, num, idx_order) CAT(CAT(prefix, num), _GET_INDEX_SAFE)(idx_order)
    #elif ELTWISE_NO_PITCH_SAME_DIMS
        #define GET_INDEX(prefix, num, idx_order) CAT(CAT(prefix, num), _OFFSET) + idx_order
    #else
        #define GET_INDEX(prefix, num, idx_order) CAT(CAT(prefix, num), _GET_INDEX)(idx_order)
    #endif
#endif

KERNEL(eltwise)(
    INPUTS_DECLS
    __global UNIT_TYPE* output
#if CALIBRATION_TERM
    , const __global float* calibrations
#endif
    )
{
#if OUTPUT_DIMS == 5 // 3D spatial
    #if ELTWISE_LAYOUT_BASED || QUANTIZATION_TERM || ELTWISE_BROADCAST
        uint data_idx = get_global_id(GWS_YX);
        const uint d1 = data_idx % OUTPUT_SIZE_X; // X
        data_idx = data_idx / OUTPUT_SIZE_X;

        const uint d2 = data_idx % OUTPUT_SIZE_Y; // Y
        data_idx = data_idx / OUTPUT_SIZE_Y;

        const uint d3 = data_idx % OUTPUT_SIZE_Z; // Z

        const uint d4 = get_global_id(GWS_FEATURE);             // Feature
        const uint d5 = get_global_id(GWS_BATCH);               // Batch

        uint output_offset = OUTPUT_GET_INDEX(d5, d4, d3, d2, d1);
    #elif ELTWISE_NO_PITCH_SAME_DIMS
        const uint d1 = get_global_id(0);
        uint output_offset = OUTPUT_OFFSET + d1;
    #else
        const uint d1 = get_global_id(0);
        const uint d2 = get_global_id(1) % OUTPUT_SIZES[1];
        const uint d3 = get_global_id(1) / OUTPUT_SIZES[1];
        const uint d4 = get_global_id(2) % OUTPUT_SIZES[3];
        const uint d5 = get_global_id(2) / OUTPUT_SIZES[3];

        uint output_offset = OUTPUT_GET_INDEX(d5, d4, d3, d2, d1);
    #endif
#else // 2D spatial
    #if ELTWISE_LAYOUT_BASED || QUANTIZATION_TERM || ELTWISE_BROADCAST
        const uint d1 = get_global_id(GWS_YX) % OUTPUT_SIZE_X;  // X
        const uint d2 = get_global_id(GWS_YX) / OUTPUT_SIZE_X;  // Y
        const uint d3 = get_global_id(GWS_FEATURE);             // Feature
        const uint d4 = get_global_id(GWS_BATCH);               // Batch

        uint output_offset = GET_INDEX(OUTPUT,, OUTPUT_IDX_ORDER);
    #elif ELTWISE_NO_PITCH_SAME_DIMS
        const uint d1 = get_global_id(0);
        uint output_offset = OUTPUT_OFFSET + d1;
    #else
        const uint d1 = get_global_id(0);
        const uint d2 = get_global_id(1);
        const uint d3 = get_global_id(2) % OUTPUT_SIZES[2];
        const uint d4 = get_global_id(2) / OUTPUT_SIZES[2];

        uint output_offset = GET_INDEX(OUTPUT,, OUTPUT_IDX_ORDER);
    #endif
#endif


#if QUANTIZATION_TERM
    int res;
#else
    UNIT_TYPE res;
#endif

    DO_ELTWISE;

#if QUANTIZATION_TERM
#if CALIBRATION_TERM
    res = (int)round(((float)res) * calibrations[d3]);
#else  // CALIBRATION_TERM
    res = (int)round(((float)res) * O_QF);
#endif // CALIBRATION_TERM
#endif // QUANTIZATION_TERM

#if QUANTIZATION_TERM
    output[output_offset] = ACTIVATION(convert_char_sat(res), ACTIVATION_PARAMS);
#else
    output[output_offset] = ACTIVATION(res, ACTIVATION_PARAMS);
#endif
}
