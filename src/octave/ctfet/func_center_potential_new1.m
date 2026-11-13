function [ phi_center ] = func_center_potential_new(Vgs,Vds,eps_ch,tch,Nch,kB,T,q )
%% Function to calculate the center potential of a DG TFET/MOSFET
% by considering inversion charges in the channel
%
% fun_center_potential(Vgs,Vds,eps_ox,tox,eps_ch,tch,Nch,k,T,q )
%
%
% Inputs:
%------------------------------------------------------
% Vgs       - Gate-Source Voltage [V]
% Vds       - Drain-Source Voltage [V]
% eps_ox    - Permittivity Gate Oxide Material [As/Vcm]
% tox       - Gate Oxide Thickness [cm]
% eps_ch    - Permittivity Channel Material [As/Vcm]
% tch       - Channel Thickness [cm]
% Nch       - Channel Doping Concentration [cm-3]
% kB        - Boltzmann constant [eV/K]
% T         - Temperature [K]
% q         - Elementary Charge [As]
%------------------------------------------------------
%
% Output:
%-----------------------------------------------
% phi_center - Center Potential at x = lch/2 [V]
%-----------------------------------------------
%
% References:
%----------------------------------------------------------------------------------
% [1] Yuan Taur, "A Continuous, Analytic Drain-Current Model for DG MOSFETs", 2004
%----------------------------------------------------------------------------------

%% Calculations
%============================================================================================================================================
%============================================================================================================================================
% Consideration of negative Vgs values
if Vgs < 0
    Vgs_int = -Vgs;
    Vds_int = 0;
else
    Vgs_int = Vgs;
    Vds_int = Vds;
end

A_Vgs_eff = 13;

phi_cen_TFET_sat = kB*T * log(2*pi^2*eps_ch*kB*T/(q*Nch*tch^2))+Vds_int;

phi_cen_TFET_1 = phi_cen_TFET_sat*(1-1/(log(1+exp(A_Vgs_eff)))*log(1+exp(A_Vgs_eff*(1-0.9*Vgs_int/phi_cen_TFET_sat))));

phi_cen_TFET = phi_cen_TFET_1*(1 + 0.02*(Vgs_int - phi_cen_TFET_1));
%===================================================================================================================   

% Writing Output
%===================================================================================================================    
    if (Vgs < 0) && (phi_cen_TFET > 0)
        phi_center = -phi_cen_TFET;
    elseif(phi_cen_TFET == 0)
        phi_center = 1e-20;
    else
        phi_center = phi_cen_TFET;
    end
%===================================================================================================================    
end

