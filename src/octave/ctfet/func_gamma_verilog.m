function [gamma] = func_gamma_verilog(x)
%% Function to calculate the Gamma(x)-Function in a very simple way to use
% it in Verilog-A. 
% Considered inputs are x = 1.5 and x = 2.5. Used in the Fermi-Dirac
% Integral. It is possible to use the MATLAB Function gamma(x) instead.
%
% func_gamma_verilog(x)
%
% Inputs:
%--------------------------------------------------------------------------
% x - input variable (1.5/2.5)
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
tol_1 = abs(x - 1.5);
tol_2 = abs(x - 2.5);

    if (tol_1 <= 1.0e-6)
        gamma = 0.8862; % Calculated with MATLAB [gamma(1.5)]
    elseif(tol_2 <=1.0e-6)
        gamma = 1.3293; % Calculated with MATLAB [gamma(2.5)]
    else
        gamma = 1.3293;
    end
%--------------------------------------------------------------------------
end

