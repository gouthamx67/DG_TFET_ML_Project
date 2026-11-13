function [ Phi_bi_eff] = func_Phi_bi_eff(V_,Phi_bi_,Vgs_eff,lambda_,eps_,N_,q)
%% Function to calculate the effective built-in potential at the source-to-
% channel junction.
%
% func_Phi_bi_eff_s(Vs,Phi_bi_s,Vgs_eff,lambda_s,eps_s,Ns,q)
%
% Inputs:
%--------------------------------------------------------------------------
% V_            - Source/Drain voltage
% Phi_bi_       - Built-in potential source/drain
% Vgs_eff       - Effective Vgs
% lambda_       - Screening length of the source/drain region
% eps_          - Permittivity source/drain
% N_            - Source/Drain doping concentration
% q             - Elementary charge
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
% Calculation of the diffence of the built-in potential in source region
        
    delta_Phi_bi = abs(-Phi_bi_ -V_ +Vgs_eff)+lambda_^2*q/eps_*N_*...
			(1-sqrt(1+abs(2*(-Phi_bi_-V_+Vgs_eff))/(lambda_^2*q/(eps_)*N_)));        
        
% Checking effective Vgs in order to define the sign of the delta_Phi_bi_s
    if ((Phi_bi_+V_) > Vgs_eff)
        % Calculation of the effective built-in potential in source region
        Phi_bi_eff = Phi_bi_ + V_ - delta_Phi_bi;
    else
        % Calculation of the effective built-in potential in source region
        Phi_bi_eff = Phi_bi_ + V_ + delta_Phi_bi;
    end
%--------------------------------------------------------------------------