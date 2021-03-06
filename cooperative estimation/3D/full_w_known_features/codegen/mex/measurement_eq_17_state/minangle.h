/*
 * minangle.h
 *
 * Code generation for function 'minangle'
 *
 * C source code generated on: Thu Nov 20 11:58:36 2014
 *
 */

#ifndef __MINANGLE_H__
#define __MINANGLE_H__
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
#include "measurement_eq_17_state_types.h"

/* Function Declarations */
extern void c_minangle(emxArray_real_T *x1, const emxArray_real_T *x2);
extern void check_forloop_overflow_error(void);
extern void minangle(const real_T x1[4], const real_T x2[4], real_T b_x1[4]);
#endif
/* End of code generation (minangle.h) */
