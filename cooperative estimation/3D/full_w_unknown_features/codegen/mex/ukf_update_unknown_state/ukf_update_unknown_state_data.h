/*
 * ukf_update_unknown_state_data.h
 *
 * Code generation for function 'ukf_update_unknown_state_data'
 *
 * C source code generated on: Thu Dec 11 11:40:53 2014
 *
 */

#ifndef __UKF_UPDATE_UNKNOWN_STATE_DATA_H__
#define __UKF_UPDATE_UNKNOWN_STATE_DATA_H__
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
#include "ukf_update_unknown_state_types.h"

/* Variable Declarations */
extern const volatile char_T *emlrtBreakCheckR2012bFlagVar;
extern real_T Ts;
extern uint32_T Ts_dirty;
extern emlrtRSInfo x_emlrtRSI;
extern emlrtRSInfo y_emlrtRSI;
extern emlrtRSInfo ab_emlrtRSI;
extern emlrtRSInfo bb_emlrtRSI;
extern emlrtRSInfo cb_emlrtRSI;
extern emlrtRSInfo db_emlrtRSI;
extern emlrtRSInfo eb_emlrtRSI;
extern emlrtRSInfo fb_emlrtRSI;
extern emlrtRSInfo ec_emlrtRSI;
extern emlrtRSInfo fc_emlrtRSI;
extern emlrtRSInfo gc_emlrtRSI;
extern emlrtRSInfo hc_emlrtRSI;
extern emlrtRSInfo ic_emlrtRSI;
extern emlrtRSInfo jc_emlrtRSI;
extern emlrtRSInfo kc_emlrtRSI;
extern emlrtRSInfo mc_emlrtRSI;
extern emlrtRSInfo oc_emlrtRSI;
extern emlrtRSInfo pc_emlrtRSI;
extern emlrtRSInfo qc_emlrtRSI;
extern emlrtRSInfo rc_emlrtRSI;
extern emlrtRSInfo sc_emlrtRSI;
extern emlrtRSInfo gd_emlrtRSI;
extern emlrtRSInfo hd_emlrtRSI;
extern emlrtRSInfo id_emlrtRSI;
extern emlrtRSInfo jd_emlrtRSI;
extern emlrtRSInfo kd_emlrtRSI;
extern emlrtRSInfo ld_emlrtRSI;
extern emlrtRSInfo md_emlrtRSI;
extern emlrtRSInfo nd_emlrtRSI;
extern emlrtRSInfo od_emlrtRSI;
extern emlrtRSInfo pd_emlrtRSI;
extern emlrtRSInfo qd_emlrtRSI;
extern emlrtRSInfo rd_emlrtRSI;
extern emlrtRSInfo sd_emlrtRSI;
extern emlrtRSInfo td_emlrtRSI;
extern emlrtRSInfo ud_emlrtRSI;
extern emlrtRSInfo vd_emlrtRSI;
extern emlrtRSInfo wd_emlrtRSI;
extern emlrtRSInfo xd_emlrtRSI;
extern emlrtRSInfo yd_emlrtRSI;
extern emlrtRSInfo ae_emlrtRSI;
extern emlrtRSInfo be_emlrtRSI;
extern emlrtRSInfo ce_emlrtRSI;
extern emlrtRSInfo de_emlrtRSI;
extern emlrtRSInfo ee_emlrtRSI;
extern emlrtRSInfo fe_emlrtRSI;
extern emlrtRSInfo ge_emlrtRSI;
extern emlrtRSInfo he_emlrtRSI;
extern emlrtRSInfo ie_emlrtRSI;
extern emlrtRSInfo je_emlrtRSI;
extern emlrtRSInfo ke_emlrtRSI;
extern emlrtRSInfo le_emlrtRSI;
extern emlrtRSInfo qe_emlrtRSI;
extern emlrtRSInfo re_emlrtRSI;
extern emlrtRSInfo se_emlrtRSI;
extern emlrtRSInfo te_emlrtRSI;
extern emlrtRSInfo ue_emlrtRSI;
extern emlrtRSInfo ve_emlrtRSI;
extern emlrtRSInfo we_emlrtRSI;
extern emlrtRSInfo xe_emlrtRSI;
extern emlrtRSInfo gg_emlrtRSI;
extern emlrtRSInfo hg_emlrtRSI;
extern emlrtRSInfo ig_emlrtRSI;
extern emlrtRSInfo jg_emlrtRSI;
extern emlrtRSInfo kg_emlrtRSI;
extern emlrtRSInfo lg_emlrtRSI;
extern emlrtRSInfo gh_emlrtRSI;
extern emlrtRSInfo jh_emlrtRSI;
extern emlrtRSInfo kh_emlrtRSI;
extern emlrtRSInfo lh_emlrtRSI;
extern emlrtRSInfo mh_emlrtRSI;
extern emlrtRSInfo nh_emlrtRSI;
extern emlrtRSInfo oh_emlrtRSI;
extern emlrtRSInfo ph_emlrtRSI;
extern emlrtRSInfo qh_emlrtRSI;
extern emlrtRSInfo rh_emlrtRSI;
extern emlrtRSInfo sh_emlrtRSI;
extern emlrtRSInfo th_emlrtRSI;
extern emlrtRSInfo uh_emlrtRSI;
extern emlrtRSInfo vh_emlrtRSI;
extern emlrtRSInfo wh_emlrtRSI;
extern emlrtRSInfo xh_emlrtRSI;
extern emlrtRSInfo yh_emlrtRSI;
extern emlrtRSInfo ai_emlrtRSI;
extern emlrtRSInfo bi_emlrtRSI;
extern emlrtRSInfo ci_emlrtRSI;
extern emlrtRSInfo di_emlrtRSI;
extern emlrtRSInfo ei_emlrtRSI;
extern emlrtRSInfo fi_emlrtRSI;
extern emlrtRSInfo gi_emlrtRSI;
extern emlrtRSInfo hi_emlrtRSI;
extern emlrtRSInfo ni_emlrtRSI;
extern emlrtRSInfo oi_emlrtRSI;
extern emlrtRSInfo ti_emlrtRSI;
extern emlrtRSInfo ui_emlrtRSI;
extern emlrtRSInfo ck_emlrtRSI;
extern emlrtRSInfo dk_emlrtRSI;
extern emlrtRSInfo ek_emlrtRSI;
extern emlrtRSInfo fk_emlrtRSI;
extern emlrtRSInfo hk_emlrtRSI;
extern emlrtRSInfo ml_emlrtRSI;
extern emlrtRSInfo ol_emlrtRSI;
extern emlrtRSInfo dm_emlrtRSI;
extern emlrtRSInfo fm_emlrtRSI;
extern emlrtRSInfo gm_emlrtRSI;
extern emlrtRSInfo hm_emlrtRSI;
extern emlrtRSInfo qm_emlrtRSI;
extern emlrtRSInfo rm_emlrtRSI;
extern emlrtMCInfo b_emlrtMCI;
extern emlrtMCInfo c_emlrtMCI;
extern emlrtMCInfo j_emlrtMCI;
extern emlrtMCInfo k_emlrtMCI;
extern emlrtMCInfo l_emlrtMCI;
extern emlrtMCInfo m_emlrtMCI;
extern emlrtMCInfo n_emlrtMCI;
extern emlrtMCInfo o_emlrtMCI;
extern emlrtMCInfo q_emlrtMCI;
extern emlrtMCInfo r_emlrtMCI;
extern emlrtMCInfo s_emlrtMCI;
extern emlrtMCInfo t_emlrtMCI;
extern emlrtMCInfo u_emlrtMCI;
extern emlrtMCInfo ab_emlrtMCI;
extern emlrtMCInfo bb_emlrtMCI;
extern emlrtMCInfo cb_emlrtMCI;
extern emlrtMCInfo db_emlrtMCI;
extern emlrtMCInfo eb_emlrtMCI;
extern emlrtRTEInfo b_emlrtRTEI;
extern emlrtRTEInfo n_emlrtRTEI;
extern emlrtRTEInfo p_emlrtRTEI;
extern emlrtRTEInfo q_emlrtRTEI;
extern emlrtRTEInfo t_emlrtRTEI;
extern emlrtRTEInfo w_emlrtRTEI;
extern emlrtRTEInfo wb_emlrtRTEI;
#endif
/* End of code generation (ukf_update_unknown_state_data.h) */
