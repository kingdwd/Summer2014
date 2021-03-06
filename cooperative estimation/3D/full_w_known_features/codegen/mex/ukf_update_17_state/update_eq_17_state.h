/*
 * update_eq_17_state.h
 *
 * Code generation for function 'update_eq_17_state'
 *
 * C source code generated on: Thu Dec  4 12:26:46 2014
 *
 */

#ifndef __UPDATE_EQ_17_STATE_H__
#define __UPDATE_EQ_17_STATE_H__
/* Include files */
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "mwmathutil.h"

#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include "blas.h"
#include "rtwtypes.h"
#include "ukf_update_17_state_types.h"

/* Function Declarations */
extern void update_eq_17_state(const emxArray_real_T *xk, const emxArray_real_T *vk, const real_T uk_data[250], const int32_T uk_size[1], emxArray_real_T *xkPlus);
#endif
/* End of code generation (update_eq_17_state.h) */
