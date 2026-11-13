function [ Vgs_eff ] = func_Vgs_eff_new( Vgs,Vds,eps_ox,tox,eps_ch,tch,Nch,Eg_ch,kB,T,q,Ninv)
%% Function to calculate the effective Vgs of a DG TFET/MOSFET
% by considering inversion charges in the channel
%
% fun_Vgs_eff(Vgs,Vds,eps_ox,tox,eps_ch,tch,Nch,Eg_ch,kB,T,q)
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
% Eg_ch     - Band Gap of the Channel Material [eV]
% kB        - Boltzmann constant [eV/K]
% T         - Temperature [K]
% q         - Elementary Charge [As]
%------------------------------------------------------
%
% Output:
%----------------------------------------------
% Vgs_eff - Effective Vgs [V]
%----------------------------------------------
%
% References:
%--------------------------------------------------------------------------------------------------
% [1] Chunlei Wu, "An Analytical Surface Potential Model Accounting for the Dual-Modulation Effects in Tunnel FETs", 2014
% [2] Yuan Taur, "An analytical solution to a double-gate MOSFET with undoped body", 2000
% [3] Lining Zhang, "SPICE Modeling of Double-Gate Tunnel-FETs Including Channel Transports",2014
%--------------------------------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------

% Consideration of negative Vgs values
if Vgs < 0
    Vgs_int = -Vgs;
    Vds_int = 0;    
else
    Vgs_int = Vgs;
    Vds_int = Vds;
end

% First step: Calculation of the surface and center potential of a DG MOSFET [1,2]
%===================================================================================================================
% Ninv = 1.6e19; % 1.6e18
ni = 1.45e10;

phi_1 = kB*T *log((Nch*Ninv)/(ni^2));

Cox = eps_ox/tox;
gamma = sqrt(2*eps_ch*q*Nch)/Cox;

phi_ch_dep = (sqrt(Vgs_int + gamma^2/4)-gamma/2)^2;

F_smooth_sqrt_sat = Vds + phi_1 + phi_ch_dep;
		
F_smooth_sqrt_var = sqrt((phi_ch_dep - Vds - phi_1)^2);

if (Vds <0)
    F_smooth_sqrt_part = F_smooth_sqrt_sat*(1.0-1.0/(log(1.0+exp(15.0)))*...
                        log(1.0+exp(15.0*(1.0-F_smooth_sqrt_var/F_smooth_sqrt_sat))));
else
    F_smooth_sqrt_part = F_smooth_sqrt_var;
end


F_smooth = (F_smooth_sqrt_sat - F_smooth_sqrt_part)/2.0;

% F_smooth = 1/2*( Vds_int + phi_1 + phi_ch_dep - sqrt((phi_ch_dep - Vds_int - phi_1)^2 ) );

phi_sur_TFET = F_smooth + kB*T*log(1/(kB*T)*( kB*T + (sqrt(F_smooth))/(sqrt(F_smooth) +gamma) *(Vgs_int - F_smooth)  ...
               + 1/2*((F_smooth)/((sqrt(F_smooth) + gamma)^2) - (gamma*(F_smooth-2))/(2*(sqrt(F_smooth) + gamma)^3))*(Vgs_int-F_smooth)^2 ));

% A_Vgs_eff = 15;


phi_cen_sat = kB*T * log(2*pi^2*eps_ch*kB*T/(q*Nch*tch^2))+Vds_int;

exp_phi_cen = 15*(1.0-Vgs/phi_cen_sat);

MAX_EXP = 1.14200738981568e26;
MIN_EXP = 8.75651076269652e-27;


if ( exp_phi_cen > 60)
    phi_cen_TFET = phi_cen_sat* (1.0-1.0/(log(1.0+exp(15)))*log(1.0+MAX_EXP));
elseif (exp_phi_cen < -60)
    phi_cen_TFET = phi_cen_sat* (1.0-1.0/(log(1.0+exp(15)))*log(1.0+MIN_EXP));
else
    phi_cen_TFET = phi_cen_sat* (1.0-1.0/(log(1.0+exp(15)))*log(1.0+exp(15*(1.0-Vgs/phi_cen_sat))));
end




% phi_cen_TFET_2 = phi_cen_sat*(1-1/(log(1+exp(A_Vgs_eff)))*log(1+exp(A_Vgs_eff*(1-Vgs_int/phi_cen_sat))));
%===================================================================================================================  

% Second step: Calculation of the surface potential using Fermi Statistics [3]
%===================================================================================================================
if 1
    
    uth = kB*T;     % Thermal Voltage
    ratio = eps_ch*tox/(eps_ox*tch);    % Simplification
    LD = sqrt((eps_ch*uth)/(2 * q * Nch));  % Simplification   

    
    for k = 1:3
            % k iteration of fermi
        %-----------------------------------------------------------------------------------------------------------
        Eg_ch_norm = Eg_ch/(uth);                   % Normalized Band Gap of the Channel Material
        phi_sur_norm = (phi_sur_TFET - Vds_int)/uth;     % Normalized Surface Potential
%         phi_sur_norm = (phi_sur_TFET)/uth;     % Normalized Surface Potential
        phi_cen_norm = (phi_cen_TFET - Vds_int)/uth;     % Normalized Center Potential
%         phi_cen_norm = (phi_cen_TFET)/uth;     % Normalized Center Potential

        % Result of the Fermi function parts (1-3), which are used in the sqrt in the function_Newton_fermi
        fermi_part1 = func_fermi_int(3/2,phi_sur_norm - Eg_ch_norm/2)-func_fermi_int(3/2,phi_cen_norm- Eg_ch_norm/2);
        fermi_part2 = func_fermi_int(1/2,-Eg_ch_norm/2);
        fermi_part3 = 2/3*fermi_part1/fermi_part2;

        % fermi_part3 must be >= 0 to avoid a negative sqrt in the function_Newton_fermi
        if (fermi_part3 < 0)
            fermi_part3 = 0;
%             disp('fermi_part3 = 0!')
        end

        % Result of the Newton Function
        function_Newton_fermi = (Vgs_int-phi_sur_TFET)/(uth) - (ratio*tch)/(LD)*sqrt(fermi_part3);      

        % fermi_part1 must be >= 0 to avoid a negative sqrt and division by 0 in the derivative_Newton_fermi 
        if (fermi_part1 > 0)
            fermi_derivative_part = 3*func_fermi_int(1/2,phi_sur_norm - Eg_ch_norm/2)/4/sqrt(fermi_part1);
            derivative_Newton_fermi = -1 - (ratio * tch)/(LD) * sqrt(2/3/fermi_part2)*fermi_derivative_part;
            if (derivative_Newton_fermi ~= 0) % avoid division by 0
                phi_sur_TFET = phi_sur_TFET - uth * function_Newton_fermi/derivative_Newton_fermi;            
            end
        end
    end
end
    %-----------------------------------------------------------------------------------------------------------
%===================================================================================================================  

% Writing Output
%===================================================================================================================
    if (Vgs < 0) && (phi_sur_TFET > 0)
        Vgs_eff1 = -phi_sur_TFET;
%         Vgs_eff = Vgs;
    elseif (phi_sur_TFET == 0) || (Vgs == 0)
        Vgs_eff1 = 1e-40;
    else
        Vgs_eff1 = phi_sur_TFET;
    end
    
    Vgs_eff_sat = 0.75+Vds;
    
    if 1
        if (phi_sur_TFET == 0) || (Vgs == 0)
            Vgs_eff = 1e-20;
        else
            Vgs_eff = Vgs_eff_sat*(1-1/(log(1+exp(15)))*log(1+exp(15*(1-Vgs_eff1/Vgs_eff_sat))));
        end
    else
        Vgs_eff = Vgs_eff1;
    end
%===================================================================================================================
%--------------------------------------------------------------------------
end