function [potential_constant_bnd] = func_potential_constant_bnd(u,v,ubar,phi_bnd)
% Function to calculate the potential solution of a piecewise constant
% boundary condition
%
% func_potential_constant_bnd(u,v,ubar,phi_bnd)
%
% Inputs:
%--------------------------------------------------------------------------
% u         - Conformal mapped coordinate within the channel
% v         - Conformal mapped coordinate within the channel
% ubar      - Infinitisemal short distance between two electrodes in the u-axis
% phi_bnd   - Boundary condition
%--------------------------------------------------------------------------

%% Calculation of the potential solution for a piecewise constant boundary 
% condition
%--------------------------------------------------------------------------
    potential_constant_bnd = -phi_bnd * atan((u-ubar)/v) / pi;
%--------------------------------------------------------------------------

end

