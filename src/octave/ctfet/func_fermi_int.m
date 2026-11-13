function [fermi_int] = func_fermi_int(order,eta)
%% Function to calculate the Fermi-Dirac Integral at the position 
% "eta" and order "order" with the help of a approximation
%
% func_fermi_int(order,eta)
%
% Inputs:
%--------------------------------------------------------------------------
% eta       - Variable where the Fermi-Dirac Integral is calculated [-]
% order     - order of the Fermi-Dirac Integral [-]
%--------------------------------------------------------------------------
%
% Output:
%--------------------------------------------------------------------------
% fermi_int - Approximation of the Fermi-Dirac Integral [-]
%--------------------------------------------------------------------------
%
% References:
%--------------------------------------------------------------------------
% [1] X. Aymerich-Humet, "A Generalized Approximation of the Fermi–Dirac 
%     Integrals", 1983
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
% Limitations of the exponential function exp(x)
    EXP_THRESHOLD =  34;        % Maximum/Minimum exponent of exp(x)
    MIN_EXP = 1.713908431e-15;  % Minimun value of exp(x)
    MAX_EXP = 5.834617425e14;   % Maximum value of exp(x)

% Approximation of the Fermi-Dirac Integral [1]
    a = sqrt(1 + 15/4*(order+1) + 1/40*(order+1)^2);    % Simplifaction Parameter
    b = 1.8 + 0.61*order;                               % Simplifaction Parameter
    c = 2 + (2-sqrt(2))*2^(-order);                     % Simplifaction Parameter

    % First part of the Fermi-Dirac Integral Approximation
    part_1 = ((order+1)*2^(order+1))/((b+eta+((abs(eta-b))^c+a^c)^(1/c))^(order+1));

    % Second part of the Fermi-Dirac Integral Approximation
    if ( eta > EXP_THRESHOLD)
        part_2 = MIN_EXP/func_gamma_verilog(order+1);
    elseif ( eta < - EXP_THRESHOLD)
        part_2 = MAX_EXP/func_gamma_verilog(order+1);
    else
        part_2 = exp(-eta)/func_gamma_verilog(order+1);
    end

% Writing Output
    fermi_int = 1/(part_1 + part_2);
%--------------------------------------------------------------------------
end

