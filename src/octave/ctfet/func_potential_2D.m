function [potential_2D] = func_potential_2D(x,y,Vgs_eff,Phi_bi_eff_sur_s,...
    Phi_bi_eff_sur_d,Phi_bi_eff_cen_s,Phi_bi_eff_cen_d,lch,tch,tox_mod)
%% Function for the calculation of the analytic 2D-potential within the 
% channel for source and drain related case, considering the parabolic 
% shaped boundary condition.
%
% func_potential_2D(x,y,Vgs_eff,Phi_bi_eff_sur_s,...
%    Phi_bi_eff_sur_d,Phi_bi_eff_cen_s,Phi_bi_eff_cen_d,lch,tch,tox_mod)
%
% Inputs
%--------------------------------------------------------------------------
% x                 - x-coordinate
% y                 - y-coordinate
% Vgs_eff           - effective Gate-Source voltage
% Phi_bi_eff_sur_s  - effective built-in potential at source surface
% Phi_bi_eff_sur_d  - effective built-in potential at drain surface
% Phi_bi_eff_cen_s  - effective built-in potential at the source center
% Phi_bi_eff_cen_d  - effective built-in potential at the drain center
% lch               - channel length
% tch               - channel thickness
% tox_mod           - modificated gate oxide thicknessS
%--------------------------------------------------------------------------

%% Applying Conformal Mapping
%--------------------------------------------------------------------------
delta_y     = 2*tox_mod + tch;                                  % Delta y for the conformal mapping functions [cm]
ubar_inf2   = func_mapping_u(3*lch,(2*tox_mod+tch),delta_y);    % Mapping Point 1'' (-inf)
ubar2       = func_mapping_u(0,(2*tox_mod+tch), delta_y);       % Mapping Point 2
ubar3       = func_mapping_u(0,tox_mod + tch, delta_y);         % Mapping Point 3
ubar4       = func_mapping_u(0,tox_mod,delta_y);                % Mapping Point 4
ubar5       = func_mapping_u(0,0,delta_y);                      % Mapping Point 5
ubar_inf1   = func_mapping_u(3*lch,0,delta_y);                  % Mapping Point 1' (-inf)
%--------------------------------------------------------------------------

%% Source related case
%=============================================================================================================
% Mapping functions for each point in the channel region
%-------------------------------------------------------------------------------------------------------------
u = func_mapping_u(x,tox_mod + y,delta_y);
v = func_mapping_v(x,tox_mod + y,delta_y);

% Point 1'' to point 2:
% Constant boundary condition
%-------------------------------------------------------------------------------------------------------------
phi_bnd = Vgs_eff;                                     % Boundary condition

phi_P1_inf_2_to_P2_s = func_potential_constant_bnd(u,v,ubar2,phi_bnd)-...
                       func_potential_constant_bnd(u,v,ubar_inf2,phi_bnd);       % Potential between point 1'' and point 2

% Point 2 to point 3:
% Linear boundary condition
%-------------------------------------------------------------------------------------------------------------
phi_bnd = Vgs_eff;                                     % Boundary condition constant

constant_phi_P2_to_P3_s = func_potential_constant_bnd(u,v,ubar3,phi_bnd)-...
                          func_potential_constant_bnd(u,v,ubar2,phi_bnd);             % Constant potential between point 2 and point 3

b = ubar2;                                                 % Parameter of the square root approximation
a = (ubar3 - b)/((Phi_bi_eff_sur_s - phi_bnd)^2);             % Parameter of the square root approximation

linear_phi_P2_to_P3_s = func_potential_linear_bnd(u,v,ubar3,a,b,phi_bnd,Phi_bi_eff_sur_s)...
                      - func_potential_linear_bnd(u,v,ubar2,a,b,phi_bnd,Phi_bi_eff_sur_s); % Linear potential between point 2 and point 3


phi_P2_to_P3_s = linear_phi_P2_to_P3_s + constant_phi_P2_to_P3_s;   % Superposition of the linear and the constant potential

% Point 3 to point 4:
% constant boundary condition
%-------------------------------------------------------------------------------------------------------------

phi_bnd = Phi_bi_eff_sur_s;                                % Boundary condition
phi_P3_to_P4_s = func_potential_constant_bnd(u,v,ubar4,phi_bnd)-...
                 func_potential_constant_bnd(u,v,ubar3,phi_bnd);

% Point 4 to point 5:
% Linear boundary condition
%-------------------------------------------------------------------------------------------------------------
phi_bnd = Vgs_eff;                                  % Boundary condition
constant_phi_P4_to_P5_s = func_potential_constant_bnd(u,v,ubar5,phi_bnd)...
                         -func_potential_constant_bnd(u,v,ubar4,phi_bnd);        % Constant potential between point 4 and point 5

b = ubar5;                                             % Parameter of the square root approximation
a = (ubar4-b)/((Phi_bi_eff_sur_s - phi_bnd)^2);           % Parameter of the square root approximation

linear_phi_P4_to_P5_s = func_potential_linear_bnd(u,v,ubar5,a,b,phi_bnd,Phi_bi_eff_sur_s)...
                      - func_potential_linear_bnd(u,v,ubar4,a,b,phi_bnd,Phi_bi_eff_sur_s); % Linear potential between point 4 and point 5

phi_P4_to_P5_s = linear_phi_P4_to_P5_s + constant_phi_P4_to_P5_s; % Superposition of the linear and the constant potential

% Point 5 to point 1':
% constant boundary condition
%-------------------------------------------------------------------------------------------------------------
phi_bnd = Vgs_eff;     % Boundary condition

phi_P5_to_P1_inf_1_s = func_potential_constant_bnd(u,v,ubar_inf1,phi_bnd)-...
                       func_potential_constant_bnd(u,v,ubar5,phi_bnd);       % Potential between point 2 and point 1'

% Superposition of the source related potentials in channel
%-------------------------------------------------------------------------------------------------------------
phi_source_ch = phi_P1_inf_2_to_P2_s + phi_P2_to_P3_s + phi_P3_to_P4_s + ...
    phi_P4_to_P5_s + phi_P5_to_P1_inf_1_s;

% Parabolic boundary condition 
%-------------------------------------------------------------------------------------------------------------
phi_bnd = Phi_bi_eff_cen_s - Phi_bi_eff_sur_s;            % Boundary condition

% phi_bnd = Phi_bi_eff_sur_s - Phi_bi_eff_cen_s;            % Boundary condition

phi_para_s = func_potential_parabolic_bnd(u,v,phi_bnd);  % Solution for the parabolic shaped boundary condition 

% phi_para_s =0;

% Superposed source potentials
%-------------------------------------------------------------------------------------------------------------
phi_source = phi_source_ch + phi_para_s;
%=============================================================================================================


%% Drain related case
%=============================================================================================================
% Mapping functions for each point in the channel region
%-------------------------------------------------------------------------------------------------------------
u = func_mapping_u(lch-x, tox_mod + y, delta_y);
v = func_mapping_v(lch-x, tox_mod + y, delta_y);

% Point 2 to point 3:
% Linear boundary condition
% No constant potential value because of phi_bnd = 0!
%-------------------------------------------------------------------------------------------------------------
phi_bnd = Phi_bi_eff_sur_d - (Vgs_eff);                 % Boundary condition
b = ubar2;                                             % Parameter of the square root approximation
a = (ubar3 - b)/((Phi_bi_eff_sur_d - (Vgs_eff))^2);      % Parameter of the square root approximation

phi_P2_to_P3_d = func_potential_linear_bnd(u,v,ubar3,a,b,0,phi_bnd)...
               - func_potential_linear_bnd(u,v,ubar2,a,b,0,phi_bnd);  % Linear potential between point 2 and point 3

% Point 3 to point 4:
% constant boundary condition
%-------------------------------------------------------------------------------------------------------------

phi_bnd = Phi_bi_eff_sur_d - (Vgs_eff);                 % Boundary condition
phi_P3_to_P4_d = func_potential_constant_bnd(u,v,ubar4,phi_bnd)-...
                 func_potential_constant_bnd(u,v,ubar3,phi_bnd);         % Constant potential between point 3 and point 4

% Point 4 to point 5:
% Linear boundary condition
%-------------------------------------------------------------------------------------------------------------
phi_bnd = Phi_bi_eff_sur_d - (Vgs_eff);                 % Boundary condition
b = ubar5;                                             % Parameter of the square root approximation
a = (ubar4 - b)/((Phi_bi_eff_sur_d - (Vgs_eff))^2);      % Parameter of the square root approximation

phi_P4_to_P5_d = func_potential_linear_bnd(u,v,ubar5,a,b,0,phi_bnd)...
               - func_potential_linear_bnd(u,v,ubar4,a,b,0,phi_bnd);  % Linear potential between point 4 and point 5

% Superposition of the drain related potentials in channel
%-------------------------------------------------------------------------------------------------------------
phi_drain_ch = phi_P2_to_P3_d + phi_P3_to_P4_d + phi_P4_to_P5_d;

% Parabolic boundary condition 
%-------------------------------------------------------------------------------------------------------------
phi_bnd = Phi_bi_eff_cen_d - Phi_bi_eff_sur_d;            % Boundary condition

% phi_bnd = Phi_bi_eff_sur_d - Phi_bi_eff_cen_d;            % Boundary condition

phi_para_d = func_potential_parabolic_bnd(u,v,phi_bnd);  % Solution for the parabolic shaped boundary condition 

% phi_para_d =0;

% Superposed drain potentials
%-------------------------------------------------------------------------------------------------------------
phi_drain = phi_drain_ch + phi_para_d;

%=============================================================================================================

%% Superposed potentials from source and drain related case
%=============================================================================================================
potential_2D = phi_source + phi_drain;
end

