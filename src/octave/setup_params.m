function [TFET_Para, TFET_Fit, TFET_Plot] = setup_params(p, f)
% Build THM-TFET v1.2 parameter structs.
% Defaults reproduce the published sentaurus benchmark BM1
% (n-type double-gate TFET, Horst et al. 2019 / THM-TFET v1.2).
% Units: cm, V, cm^-3, eV, F/cm.
%
% Inputs p, f are structs whose fields override the defaults.

TFET_Para = struct();
TFET_Para.TYPE = 1;                 % 1 = n-type TFET
TFET_Para.lch  = 22e-7;
TFET_Para.lsd  = 20e-7;
TFET_Para.tch  = 10e-7;
TFET_Para.tox  = 2e-7;
TFET_Para.wch  = 1e-4;              % 1 um reference width
TFET_Para.eps_ox = 22   * 8.854e-14;
TFET_Para.eps_s  = 11.7 * 8.854e-14;
TFET_Para.eps_d  = 11.7 * 8.854e-14;
TFET_Para.eps_ch = 11.7 * 8.854e-14;
TFET_Para.N_s  = 1e20;
TFET_Para.N_d  = 1e20;
TFET_Para.N_ch = 1e11;
TFET_Para.Eg0_s  = 1.124;
TFET_Para.Eg0_d  = 1.124;
TFET_Para.Eg_ch  = 1.08;            % effective channel gap used by BM1 fit
TFET_Para.E_s = 0.05;
TFET_Para.E_d = 0.05;
TFET_Para.X_s   = 4.05;
TFET_Para.X_d   = 4.05;
TFET_Para.X_ch  = 4.05;
TFET_Para.mat_s = 'Silicon';
TFET_Para.N_T   = 1e10;

TFET_Fit = struct();
TFET_Fit.m_s = 0.26;
TFET_Fit.m_d = 0.36;
TFET_Fit.eta2_Jy_on  = 1e-13;
TFET_Fit.eta2_Jy_amb = 1e-13;
TFET_Fit.sigma2_TGR_B2B_on  = 8e-17;
TFET_Fit.sigma2_TGR_B2B_amb = 9e-16;
TFET_Fit.sigma2_TGR_TAT_on  = 1e-21;
TFET_Fit.sigma2_TGR_TAT_amb = 1e-21;
TFET_Fit.tau_on  = 5e-18;
TFET_Fit.tau_amb = 2e-18;
TFET_Fit.f_Slope_TAT_on  = 15;
TFET_Fit.f_Slope_TAT_amb = 15;
TFET_Fit.lambda_fit_s = 1.5;
TFET_Fit.lambda_fit_d = 1.5;
TFET_Fit.lambda_0_log_shift_s = 0.85;
TFET_Fit.lambda_0_log_shift_d = 0.1;
TFET_Fit.Vgs_sat_offset_on  = 10;
TFET_Fit.Vgs_sat_offset_amb = 10;
TFET_Fit.A_Vgs = 5;
TFET_Fit.Vds_sat_on = 10;
TFET_Fit.A_Vds_sat  = 5;
TFET_Fit.Vfb = -0.54;
TFET_Fit.N_ch = 1e11;
TFET_Fit.Ninv_Vgs_eff = 1.6e19;
TFET_Fit.xmax_TAT = 4e-7;
TFET_Fit.J_S_Diode = 1e-29;
TFET_Fit.n_diode = 1;

TFET_Plot = struct();
plot_fields = {'transfer_current','capacitances','transconductance', ...
 'second_derivative_transfer_curve','transfer_current_param_N_T', ...
 'transfer_current_param_mat_s','transfer_current_param_tox', ...
 'transfer_current_param_tch','transfer_current_param_lch', ...
 'transfer_current_param_eps_ox','transfer_current_param_Nd', ...
 'transfer_current_param_Ns','transfer_current_meas_NTFET', ...
 'transfer_current_meas_PTFET','output_current','output_coductance', ...
 'potential','y_potential','bands','bands_GaAs','bands_SiliconGermanium', ...
 'bands_Germanium','efield','Vgs_eff','phi_center','phi_center_Vds_var', ...
 'Phi_bi_eff_s','Phi_bi_eff_d','potential_2D_ch','show_ambipolar_state', ...
 'TGR','TGR_GaAs','TGR_Germanium','TGR_SiliconGermanium','Ttun', ...
 'Ttun_GaAs','Ttun_Germanium','Ttun_SiliconGermanium','Vgs_eff_Vds_var'};
for i = 1:numel(plot_fields)
    TFET_Plot.(plot_fields{i}) = 0;
end
TFET_Plot.y_pos = 'Center';
TFET_Plot.x_pos = 'xch1_s';

for fn = fieldnames(p)'
    TFET_Para.(fn{1}) = p.(fn{1});
end
for fn = fieldnames(f)'
    TFET_Fit.(fn{1}) = f.(fn{1});
end
end
