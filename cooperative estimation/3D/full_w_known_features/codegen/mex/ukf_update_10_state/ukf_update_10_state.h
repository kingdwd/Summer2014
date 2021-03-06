/*
 * ukf_update_10_state.h
 *
 * Code generation for function 'ukf_update_10_state'
 *
 * C source code generated on: Wed Dec  3 17:28:48 2014
 *
 */

#ifndef __UKF_UPDATE_10_STATE_H__
#define __UKF_UPDATE_10_STATE_H__
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
#include "ukf_update_10_state_types.h"

/* Function Declarations */
extern void ukf_update_10_state(const real_T xk_data[100], const int32_T xk_size[1], const emxArray_real_T *Pxk, const emxArray_real_T *Pvk, const emxArray_real_T *Pnk, const real_T uk_data[500], const int32_T uk_size[1], const real_T ytilde_data[500], const int32_T ytilde_size[1], real_T alpha, real_T xnew_data[100], int32_T xnew_size[1], emxArray_real_T *Pnew);
#endif
/* End of code generation (ukf_update_10_state.h) */
