function [ TFET_result ] = func_TFET_verilog(V_G,V_D,V_S,TFET_Para,TFET_Fit,TFET_Plot)
%% Function to calculate the band-to-band tunneling current of the DG TFET
%
% func_TFET_verilog(V_G,V_D,V_S,TFET_Para,TFET_Fit,TFET_Plot)
%
% Inputs:
%--------------------------------------------------------------------------
% V_G       - Gate bias [V]
% V_D       - Drain bias [V]
% V_S       - Source bias [V]
% TFET_Para - struct containing the structural parameter of the TFET
% TFET_Fit  - struct containing the fitting parameter of the TFET
% TFET_Plot - struct containing the information about plotting 
%--------------------------------------------------------------------------
%
% Outputs:
%--------------------------------------------------------------------------
%TFET_result - struct containing the B2B tunneling current as well as the
%              results for plotting
%--------------------------------------------------------------------------

%% Defining the TFET parameter and constants
%--------------------------------------------------------------------------
    % Switch device type (nTFET = 1, pTFET = -1)
        TYPE = TFET_Para.TYPE;
    % Defining Constants
        q = 1.602176634e-19;                  % Elementary charge [As]
        k = 1.380649e-23;                   % Boltzmann constant [J/K]
        kb = 8.617333262e-5;            % Boltzmann constant [eV/K]
        h_bar = 1.05458e-34;            % Reduced Planck constant: h_bar = (h/2pi)) [Js]
        T = 300;                        % Temperature [K]
        m0 = 9.1095e-31;                % Electron rest mass [kg]
    
    % Defining TFET Parameter
        lch = TFET_Para.lch;            % Channel lenght [cm]
        lsd = TFET_Para.lsd;            % Source/Drain lenght [cm]
        tch = TFET_Para.tch;            % Channel thickness [cm]
        tox = TFET_Para.tox;            % Gate-Oxide thickness [cm]
        wch = TFET_Para.wch;            % Channel width [cm]
        eps_ox = TFET_Para.eps_ox;      % Permittivity gate oxid [HfO2=22]
        eps_s = TFET_Para.eps_s;        % Permittivity source [Si=11.7]
        eps_d = TFET_Para.eps_d;        % Permittivity drain [Si=11.7]
        eps_ch = TFET_Para.eps_ch;      % Permittivity channel [Si=11.7]
        N_s = TFET_Para.N_s;            % Doping concentration Source [cm^-3]
        N_d = TFET_Para.N_d;            % Doping concentration Drain [cm^-3]
        N_ch = TFET_Para.N_ch;          % Doping concentration Channel [cm^-3]    
        Eg0_s = TFET_Para.Eg0_s;        % Bandgap Source [eV]
        Eg0_d = TFET_Para.Eg0_d;        % Bandgap Drain [eV]
        Eg_ch = TFET_Para.Eg_ch;        % Bandgap Channel [eV]
        E_s = TFET_Para.E_s;            % Degeneration within the source region [eV]
        E_d = TFET_Para.E_d;            % Degeneration within the drain region [eV]
        X_s = TFET_Para.X_s;            % Affinity Source [eV]
        X_ch = TFET_Para.X_ch;          % Affinity Channel [eV]
        X_d = TFET_Para.X_d;            % Affinity Channel [eV]
    
    % Defining Adjustable Constants & Fitting Parameter 
        m_s = TFET_Fit.m_s;                     % Effective electron mass in source region[-]
        m_d = TFET_Fit.m_d;                     % Effective electron mass in drain region[-]
        lambda_fit_s = TFET_Fit.lambda_fit_s;   % Fit-Factor of the screening length in source [-]
        lambda_fit_d = TFET_Fit.lambda_fit_d;   % Fit-Factor of the screening length in drain [-]
        Vfb = TFET_Fit.Vfb;                     % Flat-band voltage [V]
        N_ch = TFET_Fit.N_ch;                   % Doping concentration channel [cm^-3]
        eta2_Jy_on = TFET_Fit.eta2_Jy_on;       % Variance of the on-state current density approximation [cm^2]
        eta2_Jy_amb = TFET_Fit.eta2_Jy_amb;     % Variance of the amb-state current density approximation [cm^2]
        sigma2_TGR_B2B_on = TFET_Fit.sigma2_TGR_B2B_on;     % Variance of the on-state B2B TGR approximation [cm^2]
        sigma2_TGR_B2B_amb = TFET_Fit.sigma2_TGR_B2B_amb;   % Variance of the amb-state B2B TGR approximation [cm^2]
        sigma2_TGR_TAT_on = TFET_Fit.sigma2_TGR_TAT_on;     % Variance of the on-state TAT TGR approximation [cm^2]
        sigma2_TGR_TAT_amb = TFET_Fit.sigma2_TGR_TAT_amb;   % Variance of the amb-state TAT TGR approximation [cm^2]        
        lambda_0_log_shift_s = TFET_Fit.lambda_0_log_shift_s; % Parameter to change the influence of inversion charges in on-state
        lambda_0_log_shift_d = TFET_Fit.lambda_0_log_shift_d; % Parameter to change the influence of inversion charges in amb-state        
        Ninv_Vgs_eff = TFET_Fit.Ninv_Vgs_eff;               % Emperical parameter inversion charge density        
        N_T = TFET_Para.N_T;                                % Trap Density        
        tau_on = TFET_Fit.tau_on;                           % Capture cross section on-state
        tau_amb = TFET_Fit.tau_amb;                         % Capture cross section amb-state        
        f_Slope_TAT_on  = TFET_Fit.f_Slope_TAT_on;          % Paramter to tune the slope of the TAT current in on-state
        f_Slope_TAT_amb = TFET_Fit.f_Slope_TAT_amb;         % Paramter to tune the slope of the TAT current in amb-state        
        xmax_TAT = TFET_Fit.xmax_TAT;                       % x-pos of the maximum TGR TAT value in on-state        
        
        % Vgs limitation parameter
        A_Vgs_sat = TFET_Fit.A_Vgs;
        Vgs_sat_offset_on = TFET_Fit.Vgs_sat_offset_on;
        Vgs_sat_offset_amb = TFET_Fit.Vgs_sat_offset_amb;
        
        % Vds limitation parameter
        A_Vds_sat = TFET_Fit.A_Vds_sat;
        Vds_sat_on = TFET_Fit.Vds_sat_on;
        
        % Parameter of the parasitic diode for negative Vds values
        J_S_Diode = TFET_Fit.J_S_Diode;
        n_diode = TFET_Fit.n_diode;
        
%--------------------------------------------------------------------------

%% Handover external voltages nodes to internal voltages nodes
%--------------------------------------------------------------------------
    % Gate bias
        Vg = TYPE * V_G;
    % Source bias
        Vs = TYPE * V_S;
    % Drain bias
        Vd = TYPE * V_D;
    % Calculating the differential Gate-Source voltage considering the flat
    % band voltage of the channel region

% Model equations are source related with Vs=0.
% Therefore adapt bias conditions:
Vd = Vd - Vs;
Vg = Vg - Vs;
Vs = 0;

        Vgs_in = Vg - Vs - TYPE*Vfb;

    % Calculating the saturated differential Drain-Source voltage
        % Differential Drain-Source voltage without saturation
        Vds_in = Vd - Vs;
    % Set internal Source bias to zero
        Vs = 0;
%--------------------------------------------------------------------------

%% Calculation of parameters to estimate the band structure
%--------------------------------------------------------------------------    
	Eg_s = Eg0_s;
	Eg_d = Eg0_d;
    % Calculation of the built-in potentials for source and drain
	Phi_bi_s = -(E_s + Eg_s/2);
	Phi_bi_d = (E_d + Eg_d/2);
    % Calculation of the band-overlap voltages describing the energy where
    % B2B tunneling can occur
        V_ol_on 	= Phi_bi_s+Vs+Eg_s/2+Eg_ch/2+TYPE*Vfb + X_s - X_ch;
        V_ol_amb    = Phi_bi_d + Vds_in - Eg_d/2 + TYPE*Vfb -Eg_ch/2 +X_d - X_ch;
%--------------------------------------------------------------------------
    % Smooth limitation of the Gate-source voltage        
        Vgs_sat_on = V_ol_on  + Vgs_sat_offset_on;
        Vgs_sat_amb = V_ol_amb - Vgs_sat_offset_amb - Vds_in;            
        
        Vgs_tmp     = Vgs_sat_amb*(1-1/(log(1+exp(A_Vgs_sat)))*log(1+exp(A_Vgs_sat*(1-Vgs_in/Vgs_sat_amb))));
        Vgs   = Vgs_sat_on*(1-1/(log(1+exp(A_Vgs_sat)))*log(1+exp(A_Vgs_sat*(1-Vgs_tmp/Vgs_sat_on))));
        
    %======================================================================
    
    % Smooth limitation of the Drain-source voltage
        % Calculating the saturation voltage in dependency of Vgs to differ
        % the on- and ambipolar-state
        Vds_sat = -Vds_sat_on*(1.0-1.0/(log(1.0+exp(A_Vds_sat)))*log(1.0+exp(A_Vds_sat*(1.0-Vgs_in/Vds_sat_on)))) + 2.0*Vds_sat_on;       
        
        Vds_neg_lim = -0.1*(1.0-1.0/(log(1.0+exp(15.0)))*log(1.0+exp(15.0*(1.0-Vds_in/-0.1))));    
        
        Vds = Vds_sat*(1-1/(log(1+exp(A_Vds_sat)))*log(1+exp(A_Vds_sat*(1-Vds_neg_lim/Vds_sat)))); 

%% Defining the physical parameters of the TFET in dependency of the TYPE
%--------------------------------------------------------------------------
 
            m_ON = m_s;                 % Electron effective mass for ON-State
            m_AMB = m_d;		% Hole effective mass for Ambipolar-State
 
 
%--------------------------------------------------------------------------


%% Definition of the characteric points to describe the potential, band
% structure, efield and the B2B tunneling current
%--------------------------------------------------------------------------
    % x-position defining the source-to-channel junction
        x_jun_s = 1e-20;
    % First x-position in the channel to describe the source-to-channel
    % junction
        lch_var = 22e-7*(1-1/(log(1+exp(15)))*log(1+exp(15*(1-lch/22e-7))));
        
        x_ch1_s = 2.0*tox*(lch_var/22e-7)^3;        

        lch_sat = 100e-7;
 %%       lch_in = lch;
        
    % Channel length limitation
        lch_lim = lch_sat * (1-1/(log(1+exp(15)))*log(1+exp(15*(1-lch/lch_sat))));
    % Secound x-position in the channel to describe the source-to-channel
    % and drain-to-channel junction
        x_ch2_sd = lch_lim/2;
    % First x-position in the channel to describe the drain-to-channel
    % junction
        x_ch1_d = lch_lim - x_ch1_s;
    % x-position defining the drain-to-channel junction
        x_jun_d = lch_lim - 1e-20;     
    % First y-position to describe the behavior along the y-axis
        y1 = 1e-20;
%         y1 = tch/200;
    % Third y-position to describe the behavior along the y-axis
        y2 = tch/2;
%--------------------------------------------------------------------------        
        
%% Considering the influence of inversion charges on the electrostatics
%--------------------------------------------------------------------------
    % Calculation of the effective gate-source voltage
%         Vgs_eff = func_Vgs_eff(Vgs,Vds,eps_ox,tox,eps_ch,tch,N_ch,Eg_ch,kb,T,q);
        Vgs_eff = func_Vgs_eff(Vgs,Vds,eps_ox,tox,eps_ch,tch,N_ch,Eg_ch,kb,T,q,Ninv_Vgs_eff);
    % Calculation of the center potential 
        phi_cen = func_center_potential(Vgs,Vds,eps_ch,tch,N_ch,kb,T,q);        
    % Calculation oxide capacitance per gate area
        Cox = eps_ox/tox;

%% Calculation of the corrected tox        
    % Calculation of the screening length at y = 0
        lambda_0 = sqrt(eps_ch*tch*tox/2/eps_ox);
    % Correction of the screening length in dependency of Qinv      
        
        Vgs_eff_Vds_00 = func_Vgs_eff(Vgs,0,eps_ox,tox,eps_ch,tch,N_ch,Eg_ch,kb,T,q,Ninv_Vgs_eff);
        
        if Vgs == 0
            Vgs_eff_Vds_00 = 1e-20;
        end
        
        lambda_Vds_00_s = sqrt(1/((1/((lambda_0^2))) + (8*2*Cox*(Vgs-Vgs_eff_Vds_00)/(eps_ch*tch*Vgs_eff_Vds_00))));
        lambda_Vds_00_d = sqrt(1/((1/((lambda_0^2))) + (8*2*Cox*(Vgs-Vgs_eff_Vds_00)/(eps_ch*tch*Vgs_eff_Vds_00))));

        if lambda_0_log_shift_s < 0.2
            lambda_0_log_shift_s = 0.2;
        end
        
        if lambda_0_log_shift_d < 0.2
            lambda_0_log_shift_d = 0.2;
        end
        
        lambda_y1_s = lambda_Vds_00_s + (lambda_0 - lambda_Vds_00_s)*(1 - exp(-log((Vds)/abs(Vgs-Vgs_eff)  + 1 + lambda_0_log_shift_s)  ));
        lambda_y1_d = lambda_Vds_00_d + (lambda_0 - lambda_Vds_00_d)*(1 - exp(-log((Vds)/abs(Vgs-Vgs_eff)  + 1 + lambda_0_log_shift_d)  ));

        tox_mod_s = 2*(lambda_y1_s^2)/tch;
        tox_mod_d = 2*(lambda_y1_d^2)/tch;   
%
%--------------------------------------------------------------------------        

%% Calculation of the effective built-in potentials 
%--------------------------------------------------------------------------                  
    % Calculation of the screening length at y = y2
        lambda_y2_s = func_lambda(y2,TFET_Fit.lambda_fit_s,eps_ch,eps_ox,tch,tox);               
        lambda_y2_d = func_lambda(y2,TFET_Fit.lambda_fit_d,eps_ch,eps_ox,tch,tox);

        

    % Calculation of the effective built-in potential at the
    % source-to-channel junction...
        % ... for y = y1
        if (strcmp(TFET_Para.mat_s,string('GaAs')))
            Phi_bi_eff_s_y1 = func_Phi_bi_eff(Vs,Phi_bi_s,Vgs_eff,0.7*lambda_y1_s,eps_s,N_s,q);
        else
            Phi_bi_eff_s_y1 = func_Phi_bi_eff(Vs,Phi_bi_s,Vgs_eff,lambda_y1_s,eps_s,N_s,q);            
        end
        % ... for y = y2
            Phi_bi_eff_s_y2 = func_Phi_bi_eff(Vs,Phi_bi_s,Vgs_eff,lambda_y2_s,eps_s,N_s,q);
    % Calculation of the effective built-in potential at the
    % drain-to-channel junction...
        % ... for y = y1
            Phi_bi_eff_d_y1 = func_Phi_bi_eff(Vds,Phi_bi_d,Vgs_eff,lambda_y1_d,eps_d,N_d,q);
        % ... for y = y2
            Phi_bi_eff_d_y2 = func_Phi_bi_eff(Vds,Phi_bi_d,Vgs_eff,lambda_y2_d,eps_d,N_d,q);
%--------------------------------------------------------------------------  
        
%% Calculation of the electrostatic potential at the characteristic points
%--------------------------------------------------------------------------     
    % Electrostatic potential at x = x_jun_s and ...
        % ... y = y1
            phi_jun_s_y1 = Phi_bi_eff_s_y1;
        % ... y = y2
            phi_jun_s_y2 = Phi_bi_eff_s_y2;   
    % Electrostatic potential at x = x_ch1_s and ...
        % ... y = y1
            phi_ch1_s_y1 = func_potential_2D(x_ch1_s, y1, Vgs_eff, Phi_bi_eff_s_y1, Phi_bi_eff_d_y1,...
                                        Phi_bi_eff_s_y2, Phi_bi_eff_d_y2, lch_lim, tch, tox_mod_s);
        % ... y = y2
            phi_ch1_s_y2 = func_potential_2D(x_ch1_s, y2, phi_cen, Phi_bi_eff_s_y1, Phi_bi_eff_d_y1,...
                                        Phi_bi_eff_s_y2, Phi_bi_eff_d_y2, lch_lim, tch, tox_mod_s);  

    % Electrostatic potential at x = x_ch2_sd and ...
        % ... y = y1      
            phi_ch2_sd_y1 = Vgs_eff;     
        % ... y = y2     
            phi_ch2_sd_y2 = phi_cen;
    % Electrostatic potential at x = x_ch1_d and ...
        % ... y = y1 
            phi_ch1_d_y1 = func_potential_2D(x_ch1_d, y1, Vgs_eff, Phi_bi_eff_s_y1, Phi_bi_eff_d_y1,...
                                        Phi_bi_eff_s_y2, Phi_bi_eff_d_y2, lch_lim, tch, tox_mod_d);
        % ... y = y2
            phi_ch1_d_y2 = func_potential_2D(x_ch1_d, y2, phi_cen, Phi_bi_eff_s_y1, Phi_bi_eff_d_y1,...
                                        Phi_bi_eff_s_y2, Phi_bi_eff_d_y2, lch_lim, tch, tox_mod_d);

    % Electrostatic potential at x = x_jun_d and ...
        % ... y = y1
            phi_jun_d_y1 = Phi_bi_eff_d_y1;
        % ... y = y2
            phi_jun_d_y2 = Phi_bi_eff_d_y2;               
%--------------------------------------------------------------------------

%% Calculation of the current densities at the characteristic y-positions
%--------------------------------------------------------------------------
    % Current density for the ambipolar-state and ...
        % ... y = y1
            Jy_amb_y1_result_TAT = func_Jy_y_TAT(y1,Vgs,Vgs_eff,Vs,Vds,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...                                     
                                        N_s,N_d,eps_s,eps_ch,eps_d,eps_ox,x_jun_d,phi_jun_d_y1,phi_jun_d_y2,...                                       
                                        x_ch1_d,phi_ch1_d_y1,phi_ch1_d_y2,x_ch2_sd,phi_ch2_sd_y1,phi_ch2_sd_y2,...                                       
                                        y1,y2,lch_lim,tch,tox,m_ON,m_AMB,T,lambda_fit_d,q,m0,h_bar,kb,sigma2_TGR_TAT_amb,...
                                        N_T,tau_on, tau_amb, f_Slope_TAT_on, f_Slope_TAT_amb, xmax_TAT);                                                                    
            Jy_amb_y1_TAT = Jy_amb_y1_result_TAT.Jy_y;
            
            Jy_amb_y1_result_B2B = func_Jy_y_B2B(y1,Vgs,Vgs_eff,Vs,Vds,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...                                     
                                        N_s,N_d,eps_s,eps_ch,eps_d,eps_ox,x_jun_d,phi_jun_d_y1,phi_jun_d_y2,...                                       
                                        x_ch1_d,phi_ch1_d_y1,phi_ch1_d_y2,x_ch2_sd,phi_ch2_sd_y1,phi_ch2_sd_y2,...                                       
                                        y1,y2,lch_lim,tch,tox,m_ON,m_AMB,T,lambda_fit_d,q,m0,h_bar,kb,TFET_Plot,...
                                        Phi_bi_eff_s_y1,Phi_bi_eff_d_y1,tox_mod_d,sigma2_TGR_B2B_amb);                                                                    
            Jy_amb_y1_B2B = Jy_amb_y1_result_B2B.Jy_y;
            
        % ... y = y2                       
            Jy_amb_y2_result_TAT = func_Jy_y_TAT(y2,Vgs,Vgs_eff,Vs,Vds,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...                                     
                                        N_s,N_d,eps_s,eps_ch,eps_d,eps_ox,x_jun_d,phi_jun_d_y1,phi_jun_d_y2,...                                       
                                        x_ch1_d,phi_ch1_d_y1,phi_ch1_d_y2,x_ch2_sd,phi_ch2_sd_y1,phi_ch2_sd_y2,...                                       
                                        y1,y2,lch_lim,tch,tox,m_ON,m_AMB,T,lambda_fit_d,q,m0,h_bar,kb,sigma2_TGR_TAT_amb,...
                                        N_T, tau_on, tau_amb, f_Slope_TAT_on, f_Slope_TAT_amb, xmax_TAT);                                
            Jy_amb_y2_TAT = Jy_amb_y2_result_TAT.Jy_y;
            
            Jy_amb_y2_result_B2B = func_Jy_y_B2B(y2,Vgs,Vgs_eff,Vs,Vds,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...                                     
                                        N_s,N_d,eps_s,eps_ch,eps_d,eps_ox,x_jun_d,phi_jun_d_y1,phi_jun_d_y2,...                                       
                                        x_ch1_d,phi_ch1_d_y1,phi_ch1_d_y2,x_ch2_sd,phi_ch2_sd_y1,phi_ch2_sd_y2,...                                       
                                        y1,y2,lch_lim,tch,tox,m_ON,m_AMB,T,lambda_fit_d,q,m0,h_bar,kb,TFET_Plot,...
                                        Phi_bi_eff_s_y1,Phi_bi_eff_d_y1,tox_mod_d,sigma2_TGR_B2B_amb);                                
            Jy_amb_y2_B2B = Jy_amb_y2_result_B2B.Jy_y;

    % Current density for the on-state and ...
        % ... y = y1                                
            Jy_on_y1_result_TAT = func_Jy_y_TAT(y1,Vgs,Vgs_eff,Vs,Vds,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...                                     
                                        N_s,N_d,eps_s,eps_ch,eps_d,eps_ox,x_jun_s,phi_jun_s_y1,phi_jun_s_y2,...                                       
                                        x_ch1_s,phi_ch1_s_y1,phi_ch1_s_y2,x_ch2_sd,phi_ch2_sd_y1,phi_ch2_sd_y2,...                                       
                                        y1,y2,lch_lim,tch,tox,m_ON,m_AMB,T,lambda_fit_s,q,m0,h_bar,kb,sigma2_TGR_TAT_on,...
                                        N_T, tau_on, tau_amb, f_Slope_TAT_on, f_Slope_TAT_amb, xmax_TAT);                                
            Jy_on_y1_TAT = Jy_on_y1_result_TAT.Jy_y;
            
            Jy_on_y1_result_B2B = func_Jy_y_B2B(y1,Vgs,Vgs_eff,Vs,Vds,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...                                     
                                        N_s,N_d,eps_s,eps_ch,eps_d,eps_ox,x_jun_s,phi_jun_s_y1,phi_jun_s_y2,...                                       
                                        x_ch1_s,phi_ch1_s_y1,phi_ch1_s_y2,x_ch2_sd,phi_ch2_sd_y1,phi_ch2_sd_y2,...                                       
                                        y1,y2,lch_lim,tch,tox,m_ON,m_AMB,T,lambda_fit_s,q,m0,h_bar,kb,TFET_Plot,...
                                        Phi_bi_eff_s_y1,Phi_bi_eff_d_y1,tox_mod_s,sigma2_TGR_B2B_on);                                
            Jy_on_y1_B2B = Jy_on_y1_result_B2B.Jy_y;
%             Jy_on_y1_B2B = 0;
        % ... y = y2
            Jy_on_y2_result_TAT = func_Jy_y_TAT(y2,Vgs,Vgs_eff,Vs,Vds,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...                                     
                                        N_s,N_d,eps_s,eps_ch,eps_d,eps_ox,x_jun_s,phi_jun_s_y1,phi_jun_s_y2,...                                       
                                        x_ch1_s,phi_ch1_s_y1,phi_ch1_s_y2,x_ch2_sd,phi_ch2_sd_y1,phi_ch2_sd_y2,...                                       
                                        y1,y2,lch_lim,tch,tox,m_ON,m_AMB,T,lambda_fit_s,q,m0,h_bar,kb,sigma2_TGR_TAT_on,...
                                        N_T, tau_on, tau_amb, f_Slope_TAT_on, f_Slope_TAT_amb, xmax_TAT);                                  
            Jy_on_y2_TAT = Jy_on_y2_result_TAT.Jy_y;
            
            Jy_on_y2_result_B2B = func_Jy_y_B2B(y2,Vgs,Vgs_eff,Vs,Vds,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...                                     
                                        N_s,N_d,eps_s,eps_ch,eps_d,eps_ox,x_jun_s,phi_jun_s_y1,phi_jun_s_y2,...                                       
                                        x_ch1_s,phi_ch1_s_y1,phi_ch1_s_y2,x_ch2_sd,phi_ch2_sd_y1,phi_ch2_sd_y2,...                                       
                                        y1,y2,lch_lim,tch,tox,m_ON,m_AMB,T,lambda_fit_s,q,m0,h_bar,kb,TFET_Plot,...
                                        Phi_bi_eff_s_y1,Phi_bi_eff_d_y1,tox_mod_s,sigma2_TGR_B2B_on);                                  
            Jy_on_y2_B2B = Jy_on_y2_result_B2B.Jy_y;                   
            

            if  TFET_Plot.transfer_current_meas_NTFET || TFET_Plot.transfer_current_meas_PTFET
                Jy_TAT_sat = 2.8e20; % Meas P-type
                A_TAT_sat = 2;
                Jy_amb_y1_TAT_sat = Jy_TAT_sat*(1-1/(log(1+exp(A_TAT_sat)))*log(1+exp(A_TAT_sat*(1-Jy_amb_y1_TAT/Jy_TAT_sat))));
                Jy_amb_y2_TAT_sat = Jy_TAT_sat*(1-1/(log(1+exp(A_TAT_sat)))*log(1+exp(A_TAT_sat*(1-Jy_amb_y2_TAT/Jy_TAT_sat))));
                Jy_on_y1_TAT_sat = Jy_TAT_sat*(1-1/(log(1+exp(A_TAT_sat)))*log(1+exp(A_TAT_sat*(1-Jy_on_y1_TAT/Jy_TAT_sat))));
                Jy_on_y2_TAT_sat = Jy_TAT_sat*(1-1/(log(1+exp(A_TAT_sat)))*log(1+exp(A_TAT_sat*(1-Jy_on_y2_TAT/Jy_TAT_sat))));                  
            else
                Jy_amb_y1_TAT_sat = Jy_amb_y1_TAT;
                Jy_amb_y2_TAT_sat = Jy_amb_y2_TAT;
                Jy_on_y1_TAT_sat = Jy_on_y1_TAT;
                Jy_on_y2_TAT_sat = Jy_on_y2_TAT; 
            end
%--------------------------------------------------------------------------
            
%% Calculation of the B2B tunneling current
%--------------------------------------------------------------------------
        % B2B and TAT
        if 01
            Jy_on_y1  = Jy_on_y1_B2B  + Jy_on_y1_TAT_sat;
            Jy_on_y2  = Jy_on_y2_B2B  + Jy_on_y2_TAT_sat;
            Jy_amb_y1 = Jy_amb_y1_B2B + Jy_amb_y1_TAT_sat;
            Jy_amb_y2 = Jy_amb_y2_B2B + Jy_amb_y2_TAT_sat;
        % Only B2B
        elseif 0
            Jy_on_y1  = Jy_on_y1_B2B;
            Jy_on_y2  = Jy_on_y2_B2B;
            Jy_amb_y1 = Jy_amb_y1_B2B;
            Jy_amb_y2 = Jy_amb_y2_B2B;
        % Only TAT
        else
            Jy_on_y1  = Jy_on_y1_TAT_sat;
            Jy_on_y2  = Jy_on_y2_TAT_sat; 
            Jy_amb_y1 = Jy_amb_y1_TAT_sat;
            Jy_amb_y2 = Jy_amb_y2_TAT_sat; 
        end


    % Calculation for the ambipolar-state
        % Calculation of B2B tunneling current part for the ambipolar-state by the
        % intgegration the Gaussian distribution shaped Jy expression
            if (Jy_amb_y1 == 0)
                Ids_amb = 0;
                Ids_amb_TAT = 0;
                Ids_amb_B2B = 0;
            else                
                Ids_amb = 2*q*...
                         ((Jy_amb_y1-Jy_amb_y2)*(-sqrt(pi)*sqrt(eta2_Jy_amb)*func_erf((y1-y2)/(sqrt(eta2_Jy_amb)))/2 ...
                          +sqrt(pi)*sqrt(eta2_Jy_amb)*func_erf((y1-y1)/(sqrt(eta2_Jy_amb)))/2)...
                          +(Jy_amb_y2*y2) - (Jy_amb_y2*y1) );
                      
                Ids_amb_TAT = 2*q*...
                         ((Jy_amb_y1_TAT_sat-Jy_amb_y2_TAT_sat)*(-sqrt(pi)*sqrt(eta2_Jy_amb)*func_erf((y1-y2)/(sqrt(eta2_Jy_amb)))/2 ...
                          +sqrt(pi)*sqrt(eta2_Jy_amb)*func_erf((y1-y1)/(sqrt(eta2_Jy_amb)))/2)...
                          +(Jy_amb_y2_TAT_sat*y2) - (Jy_amb_y2_TAT_sat*y1) );
                Ids_amb_B2B = 2*q*...
                         ((Jy_amb_y1_B2B-Jy_amb_y2_B2B)*(-sqrt(pi)*sqrt(eta2_Jy_amb)*func_erf((y1-y2)/(sqrt(eta2_Jy_amb)))/2 ...
                          +sqrt(pi)*sqrt(eta2_Jy_amb)*func_erf((y1-y1)/(sqrt(eta2_Jy_amb)))/2)...
                          +(Jy_amb_y2_B2B*y2) - (Jy_amb_y2_B2B*y1) );
            end

    % Calculation for the on-state

        % Calculation of B2B tunneling current part for the ambipolar-state by the
        % intgegration the Gaussian distribution shaped Jy expression
            if (Jy_on_y1 == 0)
                Ids_on = 0;
                Ids_on_TAT = 0;
                Ids_on_B2B = 0;
            else                                                                                              
                
                Ids_on = 2*q*...
                         ((Jy_on_y1-Jy_on_y2)*(-sqrt(pi)*sqrt(eta2_Jy_on)*func_erf((y1-y2)/(sqrt(eta2_Jy_on)))/2 ...
                         +sqrt(pi)*sqrt(eta2_Jy_on)*func_erf((y1-y1)/(sqrt(eta2_Jy_on)))/2)...
                         +(Jy_on_y2*y2)-(Jy_on_y2*y1));
                     
                Ids_on_TAT = 2*q*...
                         ((Jy_on_y1_TAT_sat-Jy_on_y2_TAT_sat)*(-sqrt(pi)*sqrt(eta2_Jy_on)*func_erf((y1-y2)/(sqrt(eta2_Jy_on)))/2 ...
                         +sqrt(pi)*sqrt(eta2_Jy_on)*func_erf((y1-y1)/(sqrt(eta2_Jy_on)))/2)...
                         +(Jy_on_y2_TAT_sat*y2)-(Jy_on_y2_TAT_sat*y1));
                Ids_on_B2B = 2*q*...
                         ((Jy_on_y1_B2B-Jy_on_y2_B2B)*(-sqrt(pi)*sqrt(eta2_Jy_on)*func_erf((y1-y2)/(sqrt(eta2_Jy_on)))/2 ...
                         +sqrt(pi)*sqrt(eta2_Jy_on)*func_erf((y1-y1)/(sqrt(eta2_Jy_on)))/2)...
                         +(Jy_on_y2_B2B*y2)-(Jy_on_y2_B2B*y1));
            end    
    % Calculation of the total B2B tunneling current
        
        Ids_int = (Ids_on + Ids_amb)*wch;
        Ids_int_TAT = (Ids_on_TAT + Ids_amb_TAT)*wch;
        Ids_int_B2B = (Ids_on_B2B + Ids_amb_B2B)*wch;
                
        Ids_diode = -J_S_Diode*wch*( exp(  -(Vd - Vs)/(kb*T*n_diode)  )  -1 );
        
    % Handover total current with respect to the chosen TYPE
        TFET_result.Ids = TYPE*Ids_int;
        TFET_result.Ids = TYPE*(Ids_int+Ids_diode);
        TFET_result.Ids_TAT = TYPE*Ids_int_TAT;
        TFET_result.Ids_B2B = TYPE*Ids_int_B2B;
	TFET_result.Ids_diode = TYPE*Ids_diode;
%--------------------------------------------------------------------------

%% Calculating and handover results for plotting TFET_results
%--------------------------------------------------------------------------

if TFET_Plot.potential_2D_ch && TFET_Plot.potential
   x_mesh_pot_2D = 1e-20:1e-8:lch;
   
   if (strcmp(TFET_Plot.y_pos,string('Center')))
       
       for p=1:length(x_mesh_pot_2D)
          
           Pot_2D_ary(p) = func_potential_2D(x_mesh_pot_2D(p),y2,phi_cen,Phi_bi_eff_s_y1,...
                            Phi_bi_eff_d_y1,Phi_bi_eff_s_y2,Phi_bi_eff_d_y2,lch,tch,tox_mod_s);           
       end
       
   elseif(strcmp(TFET_Plot.y_pos,string('Surface')))
       for p=1:length(x_mesh_pot_2D)
          
           Pot_2D_ary(p) = func_potential_2D(x_mesh_pot_2D(p),y1,Vgs_eff,Phi_bi_eff_s_y1,...
                            Phi_bi_eff_d_y1,Phi_bi_eff_s_y2,Phi_bi_eff_d_y2,lch,tch,tox_mod_s);           
       end
       
   end
   
   TFET_result.phi_2D_ch.x = x_mesh_pot_2D;
   TFET_result.phi_2D_ch.phi = Pot_2D_ary;
    
end



    % Plotting the effective built-in potential at the source-to-channel 
    % junction 
        if TFET_Plot.Phi_bi_eff_s
            if (strcmp(TFET_Plot.y_pos,string('Center')))
                TFET_result.Phi_bi_eff_s = Phi_bi_eff_s_y2;
            elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                TFET_result.Phi_bi_eff_s = Phi_bi_eff_s_y1;
            end
        end
    % Plotting the effective built-in potential at the drain-to-channel 
    % junction
        if TFET_Plot.Phi_bi_eff_d
            if (strcmp(TFET_Plot.y_pos,string('Center')))
                TFET_result.Phi_bi_eff_d = Phi_bi_eff_d_y2;
            elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                TFET_result.Phi_bi_eff_d = Phi_bi_eff_d_y1;
            end
        end
    % Plotting the potential along the x-axis for a specific y-position
        if TFET_Plot.potential            
            
            if (strcmp(TFET_Plot.y_pos,string('Center')))
                
                if TFET_Plot.show_ambipolar_state
                    TFET_result.potential_compact.x_ary     = [Jy_amb_y2_result_B2B.potential_compact.x_ary];            
                    TFET_result.potential_compact.pot_ary   = [Jy_amb_y2_result_B2B.potential_compact.pot_ary];
                else
                    TFET_result.potential_compact.x_ary     = [Jy_on_y2_result_B2B.potential_compact.x_ary];
                    TFET_result.potential_compact.pot_ary   = [Jy_on_y2_result_B2B.potential_compact.pot_ary];
                end
                 
            elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                
                if TFET_Plot.show_ambipolar_state
                    TFET_result.potential_compact.x_ary     = [Jy_amb_y1_result_B2B.potential_compact.x_ary];            
                    TFET_result.potential_compact.pot_ary   = [Jy_amb_y1_result_B2B.potential_compact.pot_ary];
                else
                    TFET_result.potential_compact.x_ary     = [Jy_on_y1_result_B2B.potential_compact.x_ary];
                    TFET_result.potential_compact.pot_ary   = [Jy_on_y1_result_B2B.potential_compact.pot_ary];
                end               
            end
        end 
    % Plotting the efield along the x-axis for a specific y-position
        if TFET_Plot.efield    
            
            if TFET_Plot.show_ambipolar_state
                if (strcmp(TFET_Plot.y_pos,string('Center')))
                    TFET_result.efield_compact.x_ary        = [Jy_amb_y2_result_B2B.efield_compact.x_ary];
                    TFET_result.efield_compact.efield_ary   = [Jy_amb_y2_result_B2B.efield_compact.efield_ary];
                elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                    TFET_result.efield_compact.x_ary        = [Jy_amb_y1_result_B2B.efield_compact.x_ary];
                    TFET_result.efield_compact.efield_ary   = [Jy_amb_y1_result_B2B.efield_compact.efield_ary];
                end
            else                        
                if (strcmp(TFET_Plot.y_pos,string('Center')))
                    TFET_result.efield_compact.x_ary        = [Jy_on_y2_result_B2B.efield_compact.x_ary];
                    TFET_result.efield_compact.efield_ary   = [Jy_on_y2_result_B2B.efield_compact.efield_ary];
                elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                    TFET_result.efield_compact.x_ary        = [Jy_on_y1_result_B2B.efield_compact.x_ary];
                    TFET_result.efield_compact.efield_ary   = [Jy_on_y1_result_B2B.efield_compact.efield_ary];
                end
            end
        end
    % Plotting the band structure along the x-axis for a specific y-position
        if TFET_Plot.bands  || TFET_Plot.bands_GaAs || TFET_Plot.bands_SiliconGermanium || TFET_Plot.bands_Germanium
            if (strcmp(TFET_Plot.y_pos,string('Center')))
                
                if TFET_Plot.show_ambipolar_state
                    TFET_result.bands_compact.x_ary     = [Jy_amb_y2_result_B2B.bands_compact.x_ary];
                    TFET_result.bands_compact.EC_ary    = [Jy_amb_y2_result_B2B.bands_compact.EC_ary];
                    TFET_result.bands_compact.EV_ary    = [Jy_amb_y2_result_B2B.bands_compact.EV_ary];
                else                    
                    TFET_result.bands_compact.x_ary     = [Jy_on_y2_result_B2B.bands_compact.x_ary];               
                    TFET_result.bands_compact.EC_ary    = [Jy_on_y2_result_B2B.bands_compact.EC_ary];
                    TFET_result.bands_compact.EV_ary    = [Jy_on_y2_result_B2B.bands_compact.EV_ary];
                end
                
                
            elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                
                if TFET_Plot.show_ambipolar_state
                     TFET_result.bands_compact.x_ary     = [Jy_amb_y1_result_B2B.bands_compact.x_ary];                   
                     TFET_result.bands_compact.EC_ary    = [Jy_amb_y1_result_B2B.bands_compact.EC_ary];        
                     TFET_result.bands_compact.EV_ary    = [Jy_amb_y1_result_B2B.bands_compact.EV_ary];
                else                                                        
                    TFET_result.bands_compact.x_ary     = [Jy_on_y1_result_B2B.bands_compact.x_ary];
                    TFET_result.bands_compact.EC_ary    = [Jy_on_y1_result_B2B.bands_compact.EC_ary];
                    TFET_result.bands_compact.EV_ary    = [Jy_on_y1_result_B2B.bands_compact.EV_ary];
                end

            end
        end
        
        
        if TFET_Plot.TGR || TFET_Plot.TGR_GaAs || TFET_Plot.TGR_Germanium || TFET_Plot.TGR_SiliconGermanium
            if TFET_Plot.show_ambipolar_state
                if (strcmp(TFET_Plot.y_pos,string('Center')))
                    TFET_result.TGR_compact.x_ary            = [Jy_amb_y2_result_B2B.TGR_compact.x_ary Jy_amb_y2_result_B2B.TGR_compact.x_ary];
                    TFET_result.TGR_compact.TGR_ary          = [Jy_amb_y2_result_B2B.TGR_compact.TGR_ary Jy_amb_y2_result_B2B.TGR_compact.TGR_ary];   
                    TFET_result.TGR_compact.TGR_ary2         = [Jy_amb_y2_result_B2B.TGR_compact.TGR_ary2 Jy_amb_y2_result_B2B.TGR_compact.TGR_ary2];
                    TFET_result.TGR_compact.TGR_ary_Michi    = [Jy_amb_y2_result_B2B.TGR_compact.TGR_ary_Michi Jy_amb_y2_result_B2B.TGR_compact.TGR_ary_Michi];
                    TFET_result.TGR_compact.TGR_xmax         = Jy_amb_y2_result_B2B.TGR_compact.TGR_xmax;
                    TFET_result.TGR_compact.xmax_TGR         = Jy_amb_y2_result_B2B.TGR_compact.xmax_TGR;
%                     TFET_result.TGR_compact.TGR_x2        = Jy_amb_y2_result_B2B.TGR_compact.TGR_x2;
%                     TFET_result.TGR_compact.x2_TGR         = Jy_amb_y2_result_B2B.TGR_compact.x2_TGR;
                elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                    TFET_result.TGR_compact.x_ary            = [Jy_amb_y1_result_B2B.TGR_compact.x_ary Jy_amb_y1_result_B2B.TGR_compact.x_ary];
                    TFET_result.TGR_compact.TGR_ary          = [Jy_amb_y1_result_B2B.TGR_compact.TGR_ary Jy_amb_y1_result_B2B.TGR_compact.TGR_ary]; 
                    TFET_result.TGR_compact.TGR_ary2         = [Jy_amb_y1_result_B2B.TGR_compact.TGR_ary2 Jy_amb_y1_result_B2B.TGR_compact.TGR_ary2];
                    TFET_result.TGR_compact.TGR_ary_Michi    = [Jy_amb_y1_result_B2B.TGR_compact.TGR_ary_Michi Jy_amb_y1_result_B2B.TGR_compact.TGR_ary_Michi];
                    TFET_result.TGR_compact.TGR_xmax         = Jy_amb_y1_result_B2B.TGR_compact.TGR_xmax;
                    TFET_result.TGR_compact.xmax_TGR         = Jy_amb_y1_result_B2B.TGR_compact.xmax_TGR;
%                     TFET_result.TGR_compact.TGR_x2         = Jy_amb_y1_result_B2B.TGR_compact.TGR_x2;
%                     TFET_result.TGR_compact.x2_TGR         = Jy_amb_y1_result_B2B.TGR_compact.x2_TGR;
                end
            
            else
                if (strcmp(TFET_Plot.y_pos,string('Center')))
                    TFET_result.TGR_compact.x_ary            = [Jy_on_y2_result_B2B.TGR_compact.x_ary Jy_amb_y2_result_B2B.TGR_compact.x_ary];
                    TFET_result.TGR_compact.TGR_ary          = [Jy_on_y2_result_B2B.TGR_compact.TGR_ary Jy_amb_y2_result_B2B.TGR_compact.TGR_ary];   
                    TFET_result.TGR_compact.TGR_ary2         = [Jy_on_y2_result_B2B.TGR_compact.TGR_ary2 Jy_amb_y2_result_B2B.TGR_compact.TGR_ary2];
                    TFET_result.TGR_compact.TGR_ary_Michi    = [Jy_on_y2_result_B2B.TGR_compact.TGR_ary_Michi Jy_amb_y2_result_B2B.TGR_compact.TGR_ary_Michi];
                    TFET_result.TGR_compact.TGR_xmax         = Jy_on_y2_result_B2B.TGR_compact.TGR_xmax;
                    TFET_result.TGR_compact.xmax_TGR         = Jy_on_y2_result_B2B.TGR_compact.xmax_TGR;
%                     TFET_result.TGR_compact.TGR_x2        = Jy_on_y2_result_B2B.TGR_compact.TGR_x2;
%                     TFET_result.TGR_compact.x2_TGR         = Jy_on_y2_result_B2B.TGR_compact.x2_TGR;
                elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                    TFET_result.TGR_compact.x_ary            = [Jy_on_y1_result_B2B.TGR_compact.x_ary Jy_amb_y1_result_B2B.TGR_compact.x_ary];
                    TFET_result.TGR_compact.TGR_ary          = [Jy_on_y1_result_B2B.TGR_compact.TGR_ary Jy_amb_y1_result_B2B.TGR_compact.TGR_ary]; 
                    TFET_result.TGR_compact.TGR_ary2         = [Jy_on_y1_result_B2B.TGR_compact.TGR_ary2 Jy_amb_y1_result_B2B.TGR_compact.TGR_ary2];
                    TFET_result.TGR_compact.TGR_ary_Michi    = [Jy_on_y1_result_B2B.TGR_compact.TGR_ary_Michi Jy_amb_y1_result_B2B.TGR_compact.TGR_ary_Michi];
                    TFET_result.TGR_compact.TGR_xmax         = Jy_on_y1_result_B2B.TGR_compact.TGR_xmax;
                    TFET_result.TGR_compact.xmax_TGR         = Jy_on_y1_result_B2B.TGR_compact.xmax_TGR;
%                     TFET_result.TGR_compact.TGR_x2         = Jy_on_y1_result_B2B.TGR_compact.TGR_x2;
%                     TFET_result.TGR_compact.x2_TGR         = Jy_on_y1_result_B2B.TGR_compact.x2_TGR;
                end
            end
        end
        
        
        
        if TFET_Plot.Ttun || TFET_Plot.Ttun_GaAs || TFET_Plot.Ttun_Germanium || TFET_Plot.Ttun_SiliconGermanium

            if TFET_Plot.show_ambipolar_state                       
                if (strcmp(TFET_Plot.y_pos,string('Center')))
                    TFET_result.bands_compact.x_ary     = [Jy_amb_y2_result_B2B.bands_compact.x_ary];
                    TFET_result.bands_compact.EC_ary    = [Jy_amb_y2_result_B2B.bands_compact.EC_ary];
                    TFET_result.bands_compact.EV_ary    = [Jy_amb_y2_result_B2B.bands_compact.EV_ary];
                    TFET_result.xmax                    = Jy_amb_y2_result_B2B.xmax;
                    TFET_result.EC_xmax                 = Jy_amb_y2_result_B2B.EC_xmax;
                    TFET_result.EV_xmax                 = Jy_amb_y2_result_B2B.EV_xmax;
                    TFET_result.ltun                    = Jy_amb_y2_result_B2B.ltun;
                    TFET_result.E_bh                    = Jy_amb_y2_result_B2B.E_bh;
                    TFET_result.ltun_Michi              = Jy_amb_y2_result_B2B.ltun_Michi;
                    TFET_result.E_bh_Michi              = Jy_amb_y2_result_B2B.E_bh_Michi;
                    TFET_result.Ttun_xmax               = Jy_on_y2_result_B2B.Ttun_xmax + Jy_amb_y2_result_B2B.Ttun_xmax;
                    TFET_result.Ttun_xmax_Michi         = Jy_amb_y2_result_B2B.Ttun_xmax_Michi;
                elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                    TFET_result.bands_compact.x_ary     = [Jy_amb_y1_result_B2B.bands_compact.x_ary];
                    TFET_result.bands_compact.EC_ary    = [Jy_amb_y1_result_B2B.bands_compact.EC_ary];
                    TFET_result.bands_compact.EV_ary    = [Jy_amb_y1_result_B2B.bands_compact.EV_ary];
                    TFET_result.xmax                    = Jy_amb_y1_result_B2B.xmax;
                    TFET_result.EC_xmax                 = Jy_amb_y1_result_B2B.EC_xmax;
                    TFET_result.EV_xmax                 = Jy_amb_y1_result_B2B.EV_xmax;
                    TFET_result.ltun                    = Jy_amb_y1_result_B2B.ltun;
                    TFET_result.E_bh                    = Jy_amb_y1_result_B2B.E_bh;
                    TFET_result.ltun_Michi              = Jy_amb_y1_result_B2B.ltun_Michi;
                    TFET_result.E_bh_Michi              = Jy_amb_y1_result_B2B.E_bh_Michi;
                    TFET_result.Ttun_xmax               = Jy_on_y1_result_B2B.Ttun_xmax + Jy_amb_y1_result_B2B.Ttun_xmax;
                    TFET_result.Ttun_xmax_Michi         = Jy_amb_y1_result_B2B.Ttun_xmax_Michi;
%                     TFET_result.x_phi_michi               = x_mesh_channel_michi;
%                     TFET_result.phi_michi               = phi_michi;
                end
            else
                if (strcmp(TFET_Plot.y_pos,string('Center')))
                    TFET_result.bands_compact.x_ary     = [Jy_on_y2_result_B2B.bands_compact.x_ary];
                    TFET_result.bands_compact.EC_ary    = [Jy_on_y2_result_B2B.bands_compact.EC_ary];
                    TFET_result.bands_compact.EV_ary    = [Jy_on_y2_result_B2B.bands_compact.EV_ary];
                    TFET_result.xmax                    = Jy_on_y2_result_B2B.xmax;
                    TFET_result.EC_xmax                 = Jy_on_y2_result_B2B.EC_xmax;
                    TFET_result.ltun                    = Jy_on_y2_result_B2B.ltun;
                    TFET_result.E_bh                    = Jy_on_y2_result_B2B.E_bh;
                    TFET_result.ltun_Michi              = Jy_on_y2_result_B2B.ltun_Michi;
                    TFET_result.E_bh_Michi              = Jy_on_y2_result_B2B.E_bh_Michi;
                    TFET_result.Ttun_xmax               = Jy_on_y2_result_B2B.Ttun_xmax + Jy_amb_y2_result_B2B.Ttun_xmax;
                    TFET_result.Ttun_xmax_Michi         = Jy_on_y2_result_B2B.Ttun_xmax_Michi;
                elseif (strcmp(TFET_Plot.y_pos,string('Surface')))
                    TFET_result.bands_compact.x_ary     = [Jy_on_y1_result_B2B.bands_compact.x_ary];
                    TFET_result.bands_compact.EC_ary    = [Jy_on_y1_result_B2B.bands_compact.EC_ary];
                    TFET_result.bands_compact.EV_ary    = [Jy_on_y1_result_B2B.bands_compact.EV_ary];
                    TFET_result.xmax                    = Jy_on_y1_result_B2B.xmax;
                    TFET_result.EC_xmax                 = Jy_on_y1_result_B2B.EC_xmax;
                    TFET_result.ltun                    = Jy_on_y1_result_B2B.ltun;
                    TFET_result.E_bh                    = Jy_on_y1_result_B2B.E_bh;
                    TFET_result.ltun_Michi              = Jy_on_y1_result_B2B.ltun_Michi;
                    TFET_result.E_bh_Michi              = Jy_on_y1_result_B2B.E_bh_Michi;
                    TFET_result.Ttun_xmax               = Jy_on_y1_result_B2B.Ttun_xmax + Jy_amb_y1_result_B2B.Ttun_xmax;                
                    TFET_result.Ttun_xmax_Michi         = Jy_on_y1_result_B2B.Ttun_xmax_Michi;
%                     TFET_result.x_phi_michi               = x_mesh_channel_michi;
%                     TFET_result.phi_michi               = phi_michi;
                end      
            end
        end
        

    % Plotting the effective Vgs of the TFET
        if TFET_Plot.Vgs_eff || TFET_Plot.Vgs_eff_Vds_var
            TFET_result.Vgs_eff = Vgs_eff;
        else
            TFET_result.phi_sur = 0;
        end
        
    % Plotting the center potential of the TFET
        if TFET_Plot.phi_center || TFET_Plot.phi_center_Vds_var
            TFET_result.phi_cen = phi_cen;
        else
            TFET_result.phi_cen = 0;
        end
        
        if TFET_Plot.y_potential
           if strcmp(TFET_Plot.x_pos,string('xjun_s'))
               TFET_result.y_potential.y_ary = Jy_on_y1_result_B2B.y_potential.y_ary;
               TFET_result.y_potential.y_potential = Jy_on_y1_result_B2B.y_potential.y_potential;
           elseif strcmp(TFET_Plot.x_pos,string('xjun_d'))
               TFET_result.y_potential.y_ary = Jy_amb_y1_result_B2B.y_potential.y_ary;
               TFET_result.y_potential.y_potential = Jy_amb_y1_result_B2B.y_potential.y_potential;
           else
               TFET_result.y_potential.y_ary = Jy_on_y1_result_B2B.y_potential.y_ary;
               TFET_result.y_potential.y_potential = Jy_on_y1_result_B2B.y_potential.y_potential;
           end
        end
       
        
%--------------------------------------------------------------------------   
end



