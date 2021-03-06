// Copyright (c) 2018 Intel Corporation
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

#pragma once

#include "common_kernel_base.h"
#include "kernel_selector_params.h"

namespace kernel_selector {
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// gemm_params
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
struct gemm_params : public base_params {
    gemm_params()
        : base_params(KernelType::GEMM), alpha(1.0f), beta(0.0f), transpose_input0(false), transpose_input1(false) {}

    float alpha;
    float beta;
    bool transpose_input0;
    bool transpose_input1;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// gemm_optional_params
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
struct gemm_optional_params : optional_params {
    gemm_optional_params() : optional_params(KernelType::GEMM) {}
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// BorderKernelBase
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class GemmKernelBase : public common_kernel_base {
public:
    using common_kernel_base::common_kernel_base;

    using DispatchData = CommonDispatchData;

protected:
    JitConstants GetJitConstants(const gemm_params& params) const;
    DispatchData SetDefault(const gemm_params& params) const;
    KernelsData GetCommonKernelsData(const Params& params, const optional_params&, float estimated_time) const;

    virtual Datatype GetAccumulatorType(const gemm_params& params) const;
};
}  // namespace kernel_selector
