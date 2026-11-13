function [potential_linear_bnd] = func_potential_linear_bnd(u,v,ubar,a,b,phi_bnd1,phi_bnd2)
%% Function to calculate the potential solution of a piecewise linear
% boundary condition
%
% func_potential_linear_bnd(u,v,ubar,a,b,phi_bnd1,phi_bnd2)
%
% Inputs:
%--------------------------------------------------------------------------
% u         - Conformal mapped coordinate within the channel
% v         - Conformal mapped coordinate within the channel
% ubar      - Infinitisemal short distance between two electrodes in the u-axis
% a         - Parameter of the square root approximation
% b         - Parameter of the square root approximation
% phi_bnd1  - First boundary condition
% phi_bnd2  - Secound boundary condition
%--------------------------------------------------------------------------

%% Calculation of the potential solution for a piecewise linear boundary condition
%---------------------------------------------------------------------------------
    % Magnitudes of the linear potential solution
    sigma1 = sqrt(-(b-ubar)/a);
    sigma4 = b^2 - 2*b*u + u^2 + v^2;
    M = (((u-b)/a)^2 + (v/a)^2)^(0.25);     % Magnitude of sigma2 and sigma3
    sigma1_imag = sqrt((b-ubar)/a);         % Value for sigma 1, if sqrt is negative (imaginary)
    
    % Phase of sigma2 and sigma 3
    theta = 1/2*func_atan2(((b-u)/a),(v/a));
    
    % Separation of the real and imaginary part inside the tan^-1 expression
    % for simplification

    % Case 1: (b-ubar)/a <= 0
    if ((b-ubar)/a <= 0)
        C1 = (a * sigma1 * M)/sigma4 * ((u-b) * cos(theta) - v * sin(theta));
        D1 = (a * sigma1 * M)/sigma4 * ((u-b) * sin(theta) + v * cos(theta));
        C2 = (a * sigma1 * M)/sigma4 * ((b-u) * cos(theta) + v * sin(theta));
        D2 = (a * sigma1 * M)/sigma4 * (-(b-u) * sin(theta) + v * cos(theta));

    % Case 2: (b-ubar)/a > 0
    else
        C1 = -(a * sigma1_imag * M)/sigma4 *((u-b)* sin(theta) + v * cos(theta));
        D1 = (a * sigma1_imag * M)/sigma4 *((u-b)* cos(theta) - v * sin(theta));
        C2 = (a * sigma1_imag * M)/sigma4 *((b-u)* sin(theta) - v * cos(theta));
        D2 = (a * sigma1_imag * M)/sigma4 *((b-u)* cos(theta) + v * sin(theta));  
    end

    % Calculation of the simpilification E1
    if (C1 > 0)
        E1 = 1/2 * (atan((C1^2+D1^2-1)/(2*C1)) + pi/2);
    elseif (C1 < 0)
        E1 = 1/2 * (atan((C1^2+D1^2-1)/(2*C1)) - pi/2);
    elseif(C1 == 0 && abs(D1)>1)
        if(D1 > 0)
            E1 = pi/2;
        elseif(D1<0)
            E1 = -pi/2;
        end
    else
        E1 = 0;
    end
    
    % Calculation of the simpilification F1
    F1 = 1/2 * atanh((2*D1)/(C1^2+D1^2+1));
    
    % Calculation of E2
    if (C2 > 0)
        E2 = 1/2 * (atan((C2^2+D2^2-1)/(2*C2)) + pi/2);
    elseif (C2 < 0)
        E2 = 1/2 * (atan((C2^2+D2^2-1)/(2*C2)) - pi/2);
    elseif(C2 == 0 && abs(D2)>1)
        if(D2 > 0)
            E2 = pi/2;
        elseif(D2 < 0)
            E2 = -pi/2;
        end
    else
        E2 = 0;
    end
    
    % Calculation of the simpilification F2
    F2 = 1/2 * atanh((2*D2)/(C2^2+D2^2+1));

    % Real part contains the solution for a piecewise linear boundary condition
    
    if ((phi_bnd2-phi_bnd1) >= 0)
        potential_linear_bnd = M/pi * ((E2-E1)*sin(theta) - (F1+F2)*cos(theta));
    else
        potential_linear_bnd = -M/pi * ((E2-E1)*sin(theta) - (F1+F2)*cos(theta));
    end
%---------------------------------------------------------------------------------
end
    
