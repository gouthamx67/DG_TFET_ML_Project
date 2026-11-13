function [ds] = func_ds(lambda_,Phi_bi_,Vgs_eff,V_,N_,eps_,q)
%% Function to calculate the position where the potential bending in source 
% region is zero.
%
% fun_ds(lambda_s,Phi_bi_s,Vgs_eff,Vs,Ns,eps_s,q)
% 
% Inputs:
%--------------------------------------------------------------------------
% lambda_   - screening length in the source region
% Phi_bi_   - built-in potential source
% Vgs_eff   - long channel center potential
% V_        - source voltage
% N_        - doping concentration of the source region
% eps_      - permittivity source
% q         - elementary charge
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
    if ((Phi_bi_+V_)>Vgs_eff)
        ds = -lambda_ + sqrt(lambda_^2 + ((Phi_bi_+V_- Vgs_eff)*2.0*eps_/q/N_));		
    else
        ds = -lambda_ + sqrt(lambda_^2 - ((Phi_bi_+V_- Vgs_eff)*2.0*eps_/q/N_));
    end    
%--------------------------------------------------------------------------
end

