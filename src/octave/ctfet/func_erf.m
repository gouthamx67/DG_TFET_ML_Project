function [erf_out] = func_erf(x)
%% Function to calculate the error function with the help of an 
% approximation
%
% func_erf(x)
%
% Inputs:
%--------------------------------------------------------------------------
% x - value to calculate the error-function 
%--------------------------------------------------------------------------
%
% Reference:
%--------------------------------------------------------------------------
% [1] - Abramowitz, Stegun - Handbook of mathematical functions with 
%       formulas, graphs and mathematical tables (Eq. 7.1.26)
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------

% Considering the sign of the handover x-value
    if(x>=0)
        sign = 1;
        x_temp = x;
    elseif(x<0)
        sign = -1;
        x_temp = -x;
    end
% Parameter of the aprroximation [1]
    p = 0.47047;
    a1 = 0.3480242;
    a2 = -0.0958798;
    a3 = 0.7478556;
    t = 1/(1+p*x_temp);
% Calculating the error function [1]

erf_out = sign*(1-(a1*t + a2*t^2 + a3*t^3)*exp(-x_temp^2));
    
%--------------------------------------------------------------------------
end

