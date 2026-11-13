%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Add your code here for the main body of your program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path(path,'../src');

%% Device Parameters
global TFET_Para
TFET_Para.TYPE = str2num(TYPE);                % Choose TYPE: 1 = n-type, -1 = p-type
TFET_Para.lch = lch;                  % Channel length [cm]
TFET_Para.lsd = lsd;                  % Source/Drain length [cm]
TFET_Para.tch = tch;                  % Channel thickness [cm]
TFET_Para.tox = tox;                  % Gate-Oxide thickness [cm]
TFET_Para.wch = wch;                   % Channel width [cm]
TFET_Para.eps_ox = eps_ox * 8.854e-14;     % Permittivity oxide
TFET_Para.eps_s = eps_s * 8.854e-14;     % Permittivity source
TFET_Para.eps_d = eps_d * 8.854e-14;     % Permittivity drain
TFET_Para.eps_ch = eps_ch * 8.854e-14;    % Permittivity channel
TFET_Para.N_s = N_s;                   % Doping concentration Source [cm^-3]
TFET_Para.N_d = N_d;                   % Doping concentration Drain [cm^-3]
TFET_Para.N_ch = N_ch;               % Doping concentration Channel [cm^-3]    
TFET_Para.Eg0_s = Eg0_s;              % Bandgap Source [eV]
TFET_Para.Eg0_d = Eg0_d;              % Bandgap Drain [eV]
TFET_Para.Eg_ch = Eg0_ch;              % Bandgap Channel [eV]
TFET_Para.E_s = E_s;          % Degeneration within the source region [eV]
TFET_Para.E_d = E_d;               % Degeneration within the drain region [eV]
TFET_Para.X_s = X_s;                   % Affinity Source [eV]
TFET_Para.X_ch = X_ch;                  % Affinity Channel [eV]
TFET_Para.X_d = X_d;                   % Affinity Channel [eV]

TFET_Para.mat_s = string('Silicon');
TFET_Para.N_T = N_T;


%% Fitting Parameters
global TFET_Fit
TFET_Fit.m_s = m_s;    
TFET_Fit.m_d = m_d;   
TFET_Fit.eta2_Jy_on = eta2_Jy_on;
TFET_Fit.eta2_Jy_amb = eta2_Jy_amb;
TFET_Fit.sigma2_TGR_B2B_on  = sigma2_TGR_B2B_on;
TFET_Fit.sigma2_TGR_B2B_amb = sigma2_TGR_B2B_amb;
TFET_Fit.sigma2_TGR_TAT_on  = sigma2_TGR_TAT_on;
TFET_Fit.sigma2_TGR_TAT_amb = sigma2_TGR_TAT_amb;
TFET_Fit.tau_on = tau_on;
TFET_Fit.tau_amb = tau_amb;
TFET_Fit.f_Slope_TAT_on  = f_Slope_TAT_on; 
TFET_Fit.f_Slope_TAT_amb = f_Slope_TAT_amb;     
TFET_Fit.lambda_fit_s = lambda_fit_s; 
TFET_Fit.lambda_fit_d = lambda_fit_d; 
TFET_Fit.Vgs_sat_offset_on = Vgs_sat_offset_on; 
TFET_Fit.Vgs_sat_offset_amb = Vgs_sat_offset_amb;
TFET_Fit.A_Vgs = A_Vgs;
TFET_Fit.Vds_sat_on = Vds_sat_on; 
TFET_Fit.A_Vds_sat = A_Vds_sat;
TFET_Fit.lambda_0_log_shift_s = lambda_0_log_shift_s;
TFET_Fit.lambda_0_log_shift_d = lambda_0_log_shift_d;
TFET_Fit.Vfb = Vfb; 

TFET_Fit.N_ch = N_ch;            
TFET_Fit.Ninv_Vgs_eff = 1.6e19;   %% reference inversion charge for surface potential model (maybe additional fitting parameter)
TFET_Fit.xmax_TAT = xmax_TAT;
TFET_Fit.J_S_Diode = J_S_Diode;

TFET_Fit.n_diode = n_diode;
q = 1.602176634e-19;                  % Elementary charge [As]

%% Plot Properties
% global TFET_Plot_Prop

% TFET_Plot_Prop.LineWidth = 1.5;             % LineWidth



global TFET_Plot 

TFET_Plot.transfer_current              = 1;            % Plot transfer current on/off (1/0)
TFET_Plot.capacitances                  = 0;
TFET_Plot.transconductance              = 0;
TFET_Plot.second_derivative_transfer_curve = 0;
TFET_Plot.transfer_current_param_N_T    = 0;            % Plot transfer current on/off (1/0)
TFET_Plot.transfer_current_param_mat_s  = 0;            % Plot transfer current on/off (1/0)
TFET_Plot.transfer_current_param_tox    = 0;            % Plot transfer current on/off (1/0)
TFET_Plot.transfer_current_param_tch    = 0;
TFET_Plot.transfer_current_param_lch    = 0;
TFET_Plot.transfer_current_param_eps_ox = 0;
TFET_Plot.transfer_current_param_Nd     = 0;
TFET_Plot.transfer_current_param_Ns     = 0;
TFET_Plot.transfer_current_meas_NTFET   = 0;       % Plot transfer current on/off (1/0)
TFET_Plot.transfer_current_meas_PTFET   = 0;       % Plot transfer current on/off (1/0)
TFET_Plot.output_current                = 0;            % Plot output current on/off (1/0)
TFET_Plot.output_coductance             = 0;
TFET_Plot.potential                     = 0;            % Plot potential at x_pos on/off (1/0)
TFET_Plot.y_potential                   = 0;
TFET_Plot.bands                         = 0;            % Plot bands at y_pos on/off (1/0)
TFET_Plot.bands_GaAs                    = 0;            % Plot bands at y_pos on/off (1/0)
TFET_Plot.bands_SiliconGermanium        = 0;            % Plot bands at y_pos on/off (1/0)
TFET_Plot.bands_Germanium               = 0;            % Plot bands at y_pos on/off (1/0)
TFET_Plot.efield                        = 0;            % Plot efield at y_pos on/off (1/0)
TFET_Plot.Vgs_eff           = 0;            % Plot Vgs_eff in dependency of Vg on/off (1/0)
TFET_Plot.phi_center        = 0;            % Plot center potential in dependency of Vg on/off (1/0)
TFET_Plot.Vgs_eff_Vds_var   = 0;            % Plot Vgs_eff in dependency of Vg on/off (1/0)
TFET_Plot.phi_center_Vds_var= 0;            % Plot center potential in dependency of Vg on/off (1/0)
TFET_Plot.Phi_bi_eff_s      = 0;            % Plot effective built-in potential at source in dependency of Vg on/off (1/0)
TFET_Plot.Phi_bi_eff_d      = 0;            % Plot effective built-in potential at drain in dependency of Vg on/off (1/0)
TFET_Plot.TGR               = 0;
TFET_Plot.TGR_GaAs          = 0;
TFET_Plot.TGR_Germanium     = 0;
TFET_Plot.TGR_SiliconGermanium = 0;
TFET_Plot.Ttun              = 0;
TFET_Plot.Ttun_GaAs         = 0;
TFET_Plot.Ttun_Germanium    = 0;
TFET_Plot.Ttun_SiliconGermanium = 0;
TFET_Plot.potential_2D_ch   = 0;
TFET_Plot.second_derivative_output_curve = 0;
TFET_Plot.show_ambipolar_state = 1;
TFET_Plot.save              = 0;            % Save plots on/off (1/0)
TFET_Plot.save_csv          = 1;            % Save CSV on/off (1/0)
TFET_Plot.clear_plot        = 1;            % Clear plots on/off (1/0)

if 1
    TFET_Plot.y_pos     = string('Surface');    % Choose y-Position within channel (Surface/Center)
else
    TFET_Plot.y_pos   = string('Center');     % Choose y-Position within channel (Surface/Center)
end

if 0
    TFET_Plot.x_pos =  string('xch2');
elseif 0
    TFET_Plot.x_pos =  string('xjun_s');
else
    TFET_Plot.x_pos =  string('xjun_d');
end


% Prepare capacitance model
TYPE = TFET_Para.TYPE;
cdep =  eps_ch/tdep* 8.854e-14;
cox = eps_ox/tox* 8.854e-14;
cox1 = 1/(1/cox+1/cdep)+Covl/(lch-Xb);	% normalize Covl to (lch-Xb), because it will be multiplied with (lch-Xb)
delta_V = -0.001*TYPE;
Qi0 = q*TFET_Para.N_ch*tch;


rpUtilsProgress(5, 'Calculating transfer characteristics...');
if plot_transfer
	vg_t = (vgs_min:dvgs:vgs_max);
	vs = 0;
	vd = vds_t;
	for i = 1:length(vg_t)
		rpUtilsProgress((i/length(vg_t)*40), 'Calculating transfer characteristics...');
		TFET_result = func_TFET_verilog(vg_t(i), vd, vs,TFET_Para,TFET_Fit,TFET_Plot);
		Id_t(i) = TFET_result.Ids;
		Id_t_b2b(i) = TFET_result.Ids_B2B;
		Id_t_tat(i) = TFET_result.Ids_TAT;
		Id_t_diode(i) = TFET_result.Ids_diode;

		% capacitances:
		ids = abs(Id_t(i));
		result1 = fun_charge(TYPE*vg_t(i),TYPE*vd,TYPE*vs,V0_gd,V0_gs,tch,cox1,lch,Xb,wch,alpha,Qi0,TYPE,ids);
		Qch1_on = result1.Qch_on; 
		Qch1_ambi = result1.Qch_ambi;
		vd2 = vd-delta_V;
		[result2] = fun_charge(TYPE*vg_t(i),TYPE*vd2,TYPE*vs,V0_gd,V0_gs,tch,cox1,lch,Xb,wch,alpha,Qi0,TYPE,ids);
		Qch2_on = result2.Qch_on; 
		Qch2_ambi = result2.Qch_ambi;
		vs2 = vs - delta_V;
		[result3] = fun_charge(TYPE*vg_t(i),TYPE*vd,TYPE*vs2,V0_gd,V0_gs,tch,cox1,lch,Xb,wch,alpha,Qi0,TYPE,ids);
		Qch3_on = result3.Qch_on;
		Qch3_ambi = result3.Qch_ambi;
           	Cd_on(i) = 2*((Qch2_on - Qch1_on) )/(delta_V);		% Factor 2 for DG device
           	Cs_on(i) = 2*((Qch3_on - Qch1_on)/(delta_V));		% Factor 2 for DG device
           
           	Cd_ambi(i) = 2*(Qch1_ambi - Qch2_ambi ) /(delta_V);	% Factor 2 for DG device
           	Cs_ambi(i) = 2*(Qch3_ambi - Qch1_ambi)/(delta_V);	% Factor 2 for DG device
	   	Cs_t(i) = Cs_on(i) + Cs_ambi(i) + wch*Cext;
	   	Cd_t(i) = Cd_on(i) + Cd_ambi(i) + wch*Cext;
           
           	Cgg_t(i) = (Cd_on(i) + Cs_on(i) + Cd_ambi(i) + Cs_ambi(i))+(2*wch*Cext);
	end;
end;

if plot_out
	
	vd_o = vds_min:dvds:vds_max;
	vs = 0;
	vg = vgs_o;
	for i = 1:length(vd_o)
		rpUtilsProgress((45+i/length(vd_o)*40), 'Calculating output characteristics');
		TFET_result = func_TFET_verilog(vg, vd_o(i), vs,TFET_Para,TFET_Fit,TFET_Plot);
		Id_o(i) = TFET_result.Ids;
		Id_o_b2b(i) = TFET_result.Ids_B2B;
		Id_o_tat(i) = TFET_result.Ids_TAT;
		Id_o_diode(i) = TFET_result.Ids_diode;

		% capacitances
		ids = abs(Id_t(i));
		result1 = fun_charge(TYPE*vg,TYPE*vd_o(i),TYPE*vs,V0_gd,V0_gs,tch,cox1,lch,Xb,wch,alpha,Qi0,TYPE,ids);
		Qch1_on = result1.Qch_on; 
		Qch1_ambi = result1.Qch_ambi;
		vd2 = vd_o(i)-delta_V;
		[result2] = fun_charge(TYPE*vg,TYPE*vd2,TYPE*vs,V0_gd,V0_gs,tch,cox1,lch,Xb,wch,alpha,Qi0,TYPE,ids);
		Qch2_on = result2.Qch_on; 
		Qch2_ambi = result2.Qch_ambi;
		vs2 = vs - delta_V;
		[result3] = fun_charge(TYPE*vg,TYPE*vd_o(i),TYPE*vs2,V0_gd,V0_gs,tch,cox1,lch,Xb,wch,alpha,Qi0,TYPE,ids);
		Qch3_on = result3.Qch_on;
		Qch3_ambi = result3.Qch_ambi;
           	Cd_on(i) = 2*((Qch2_on - Qch1_on) )/(delta_V);		% Factor 2 for DG device
           	Cs_on(i) = 2*((Qch3_on - Qch1_on)/(delta_V));		% Factor 2 for DG device
           
           	Cd_ambi(i) = 2*(Qch1_ambi - Qch2_ambi ) /(delta_V);	% Factor 2 for DG device
           	Cs_ambi(i) = 2*(Qch3_ambi - Qch1_ambi)/(delta_V);	% Factor 2 for DG device
	   	Cs_o(i) = Cs_on(i) + Cs_ambi(i) + wch*Cext;
	   	Cd_o(i) = Cd_on(i) + Cd_ambi(i) + wch*Cext;
           
           	Cgg_o(i) = (Cd_on(i) + Cs_on(i) + Cd_ambi(i) + Cs_ambi(i))+(2*wch*Cext);
	end;
end;



% if plot_distrib
% 	const.fast_calc = false;
% 	[dim] = dev_dimensions_exclude(const, dim);  % fine mesh grid from gate-to-gate: redefine mesh
% 	vs = 0;
% 	rpUtilsProgress((95), 'Calculating location-dependent quantities');
% 	[Id_d,negf_d,result_d] = NBMM_nodef(vgs_dq, vds_dq, vs, mat, const, dim, scattering);
% end;
      

rpUtilsProgress(100, 'Done');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save output values back to Rappture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save output value for output.curve(transfer)
% this assumes a vector 'x' and a vector 'y'
if plot_transfer
	xydata = [vg_t;Id_t];
	str = sprintf('%12g %12g\n', xydata);
	rpLibPutString(io,'output.curve(transfer).component.xy',str,0);
	if plot_transfer_sep
		xydata = [vg_t;Id_t_b2b];
		str = sprintf('%12g %12g\n', xydata);
		rpLibPutString(io,'output.curve(transfer_b2b).component.xy',str,0);

		xydata = [vg_t;Id_t_tat];
		str = sprintf('%12g %12g\n', xydata);
		rpLibPutString(io,'output.curve(transfer_tat).component.xy',str,0);

		xydata = [vg_t;Id_t_diode];
		str = sprintf('%12g %12g\n', xydata);
		rpLibPutString(io,'output.curve(transfer_diode).component.xy',str,0);
	end;
	xydata = [vg_t;Cd_t];
	str = sprintf('%12g %12g\n', xydata);
	rpLibPutString(io,'output.curve(transfer_Cgd).component.xy',str,0);

	% save output value for output.curve(Cgg)
	% this assumes a vector 'x' and a vector 'y'
	xydata = [vg_t;Cgg_t];
	str = sprintf('%12g %12g\n', xydata);
	rpLibPutString(io,'output.curve(transfer_Cgg).component.xy',str,0);

	% save output value for output.curve(Cgs)
	% this assumes a vector 'x' and a vector 'y'
	xydata = [vg_t;Cs_t];
	str = sprintf('%12g %12g\n', xydata);
	rpLibPutString(io,'output.curve(transfer_Cgs).component.xy',str,0);
end;

% save output value for output.curve(output)
% this assumes a vector 'x' and a vector 'y'
if plot_out
	xydata = [vd_o;Id_o];
	str = sprintf('%12g %12g\n', xydata);
	rpLibPutString(io,'output.curve(output).component.xy',str,0);
	if plot_out_sep
		xydata = [vd_o;Id_o_b2b];
		str = sprintf('%12g %12g\n', xydata);
		rpLibPutString(io,'output.curve(output_b2b).component.xy',str,0);

		xydata = [vd_o;Id_o_tat];
		str = sprintf('%12g %12g\n', xydata);
		rpLibPutString(io,'output.curve(output_tat).component.xy',str,0);

		xydata = [vd_o;Id_o_diode];
		str = sprintf('%12g %12g\n', xydata);
		rpLibPutString(io,'output.curve(output_diode).component.xy',str,0);
	end;
	xydata = [vd_o;Cd_o];
	str = sprintf('%12g %12g\n', xydata);
	rpLibPutString(io,'output.curve(output_Cgd).component.xy',str,0);

	% save output value for output.curve(Cgg)
	% this assumes a vector 'x' and a vector 'y'
	xydata = [vd_o;Cgg_o];
	str = sprintf('%12g %12g\n', xydata);
	rpLibPutString(io,'output.curve(output_Cgg).component.xy',str,0);

	% save output value for output.curve(Cgs)
	% this assumes a vector 'x' and a vector 'y'
	xydata = [vd_o;Cs_o];
	str = sprintf('%12g %12g\n', xydata);
	rpLibPutString(io,'output.curve(output_Cgs).component.xy',str,0);
end;

rpLibResult(io);
quit;
