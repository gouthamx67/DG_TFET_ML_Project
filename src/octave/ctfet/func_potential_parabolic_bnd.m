function [potential_parabolic_bnd] = func_potential_parabolic_bnd(u,v,phi_bnd)
% Function to calculate the potential solution for parabolic boundariers.
%
% func_potential_parabolic_bnd(u,v,phi_bnd)
%
% Inputs:
%-----------------------------------------------------------
% u         - Conformal mapped coordinate within the channel
% v         - Conformal mapped coordinate within the channel
% phi_bnd   - Boundary condition
%-----------------------------------------------------------

%% Calculation of the potential solution for a parabolic boundary condition
%--------------------------------------------------------------------------
    M = sqrt(u^2 + v^2);     % Magnitude of the complex expression (w = u +jv)
    delta = func_atan2(u,v); % Phase of the complex expression (w = u + jv)
    
    % Simplification of the expressions within the sqrt-expression.
    A = 1 - M^2 * cos(2 * delta);   % real-Part of the simplification
    B = M^2 * sin(2 * delta);       % imag-Part of the simplification
    
    % Phase of the simplified expression
    gamma = func_atan2(A,B);
    
    % Simplification of the sqrt-expressions
    sqrt_part =  (A^2 + B^2)^(1/4) * 2 * cos(gamma/2);
    
    potential_parabolic_bnd = phi_bnd * ( sqrt_part/2 -v);
%--------------------------------------------------------------------------        
end

