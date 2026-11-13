function [mapped_v] = func_mapping_v( x,y,delta_y)
%% Function to calculate the imaginary part v of the conformal mapping function
%
% func_mapping_v( x,y,delta_y)
%
% Inputs:
%--------------------------------------------------------------------------
% x         - Real part of the complex plane z  
% y         - Imaginary party of the complex plane z
% delta_y   - Distance between the parallel lines of the polygon
%--------------------------------------------------------------------------

%% Calculation of the imaginary part of the conformal mapping function
%--------------------------------------------------------------------------
   mapped_v = sinh(pi*x/delta_y)*sin(pi*y/delta_y); 
%--------------------------------------------------------------------------
end