function [mapped_u] = func_mapping_u(x,y,delta_y)
%% Function to calculate the real part u of the conformal mapping function
%
% func_mapping_u(x,y,delta_y)
%
% Inputs:
%--------------------------------------------------------------------------
% x         - Real part of the complex plane z  
% y         - Imaginary party of the complex plane z
% delta_y   - Distance between the parallel lines of the polygon
%--------------------------------------------------------------------------

%% Calculation of the real part of the conformal mapping function
%--------------------------------------------------------------------------
   mapped_u = cosh(pi*x/delta_y)*cos(pi*y/delta_y); 
%--------------------------------------------------------------------------
end

