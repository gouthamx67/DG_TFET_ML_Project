function [ efield_abs ] = func_efield_abs_Michi( x, y,Vg, phi_jun_s, phi_jun_d, lch, tch, tox_mod)
% Function to calculate the electric field at the position (x/y).

%% Applying conformal mapping
% =========================================================================
    delta_y = 2*tox_mod + tch;                % Distance between the parallel lines of the polygon
    ubar2   = func_mapping_u(0,(2*tox_mod+tch),delta_y);   % Mapping point 2
    ubar3   = func_mapping_u(0,(tox_mod+tch),delta_y);     % Mapping point 3
    ubar4   = func_mapping_u(0,tox_mod,delta_y);           % Mapping point 4        
    ubar5   = func_mapping_u(0,0,delta_y);                 % Mapping point 5

%% Source related case
% =========================================================================
% Mapping of the position (x/y)
    u = func_mapping_u(x,y+tox_mod,delta_y);
    v = func_mapping_v(x,y+tox_mod,delta_y);
% Separation of real- and imaginary part of the electric field

    % Polar form of sqrt(1/(1-(w*)^2))
    M1 = 1/((1-u^2+v^2)^2+(2*u*v)^2)^(1/4);
    theta_1 = 0.5 * func_atan2((1-u^2+v^2),(2*u*v));
    
    % Applying equation A.30 of the master thesis for each mapping point
    E_ubar2 = -(ubar2*v*M1*cos(theta_1) + (ubar2*u-1)*M1*sin(theta_1));
    F_ubar2 = sqrt(1-ubar2^2) - (ubar2*u-1)*M1*cos(theta_1) + ubar2*v*M1*sin(theta_1);

    E_ubar3 = -(ubar3*v*M1*cos(theta_1) + (ubar3*u-1)*M1*sin(theta_1));
    F_ubar3 = sqrt(1-ubar3^2) - (ubar3*u-1)*M1*cos(theta_1) + ubar3*v*M1*sin(theta_1);

    E_ubar4 = -(ubar4*v*M1*cos(theta_1) + (ubar4*u-1)*M1*sin(theta_1));
    F_ubar4 = sqrt(1-ubar4^2) - (ubar4*u-1)*M1*cos(theta_1) + ubar4*v*M1*sin(theta_1);

    E_ubar5 = -(ubar5*v*M1*cos(theta_1) + (ubar5*u-1)*M1*sin(theta_1));
    F_ubar5 = sqrt(1-ubar5^2) - (ubar5*u-1)*M1*cos(theta_1) + ubar5*v*M1*sin(theta_1);
    
    % Applying equation A.31 of the master thesis for each mapping point
    G_ubar2 = (E_ubar2*(ubar2-u) + F_ubar2*v)/((ubar2-u)^2 + v^2);
    H_ubar2 = (F_ubar2*(ubar2-u) - E_ubar2*v)/((ubar2-u)^2 + v^2);

    G_ubar3 = (E_ubar3*(ubar3-u) + F_ubar3*v)/((ubar3-u)^2 + v^2);
    H_ubar3 = (F_ubar3*(ubar3-u) - E_ubar3*v)/((ubar3-u)^2 + v^2);

    G_ubar4 = (E_ubar4*(ubar4-u) + F_ubar4*v)/((ubar4-u)^2 + v^2);
    H_ubar4 = (F_ubar4*(ubar4-u) - E_ubar4*v)/((ubar4-u)^2 + v^2);

    G_ubar5 = (E_ubar5*(ubar5-u) + F_ubar5*v)/((ubar5-u)^2 + v^2);
    H_ubar5 = (F_ubar5*(ubar5-u) - E_ubar5*v)/((ubar5-u)^2 + v^2);
    
    % Applying equation A.32 of the master thesis for each mapping point
    M2_ubar2 = sqrt(G_ubar2^2 + H_ubar2^2);
    theta_2_ubar2 = func_atan2(G_ubar2,H_ubar2);

    M2_ubar3 = sqrt(G_ubar3^2 + H_ubar3^2);
    theta_2_ubar3 = func_atan2(G_ubar3,H_ubar3);

    M2_ubar4 = sqrt(G_ubar4^2 + H_ubar4^2);
    theta_2_ubar4 = func_atan2(G_ubar4,H_ubar4);

    M2_ubar5 = sqrt(G_ubar5^2 + H_ubar5^2);
    theta_2_ubar5 = func_atan2(G_ubar5,H_ubar5);
    
    % Polar form of sqrt(1-(w*)^2)
    M3 = ((1-u^2+v^2)^2+(2*u*v)^2)^(1/4);
    theta_3 = 0.5*func_atan2((1-u^2+v^2),(2*u*v));
    
    % Applying equation A.33 of the master thesis for each mapping point
    M4_ubar2 = sqrt((log(M2_ubar2))^2 + theta_2_ubar2^2);
    theta_4_ubar2 = func_atan2(log(M2_ubar2),theta_2_ubar2);

    M4_ubar3 = sqrt((log(M2_ubar3))^2 + theta_2_ubar3^2);
    theta_4_ubar3 = func_atan2(log(M2_ubar3),theta_2_ubar3);

    M4_ubar4 = sqrt((log(M2_ubar4))^2 + theta_2_ubar4^2);
    theta_4_ubar4 = func_atan2(log(M2_ubar4),theta_2_ubar4);

    M4_ubar5 = sqrt((log(M2_ubar5))^2 + theta_2_ubar5^2);
    theta_4_ubar5 = func_atan2(log(M2_ubar5),theta_2_ubar5);

    alpha_ubar2 = -delta_y/pi * M4_ubar2/M3 * cos(theta_4_ubar2 - theta_3);
    beta_ubar2 = -delta_y/pi * M4_ubar2/M3 * sin(theta_4_ubar2 - theta_3);

    alpha_ubar3 = -delta_y/pi * M4_ubar3/M3 * cos(theta_4_ubar3-theta_3);
    beta_ubar3 = -delta_y/pi * M4_ubar3/M3 * sin(theta_4_ubar3-theta_3);

    alpha_ubar4 = -delta_y/pi * M4_ubar4/M3 * cos(theta_4_ubar4-theta_3);
    beta_ubar4 = -delta_y/pi * M4_ubar4/M3 * sin(theta_4_ubar4-theta_3);

    alpha_ubar5 = -delta_y/pi * M4_ubar5/M3 * cos(theta_4_ubar5-theta_3);
    beta_ubar5 = -delta_y/pi * M4_ubar5/M3 * sin(theta_4_ubar5-theta_3);
    
    % Calculation of |dw/dz| with the help of equation (A.34) of the master thesis
    dw_dz_abs = (((u-1)^2 + v^2)*((u+1)^2 + v^2))^(1/4)/(2*tox_mod + tch)*pi;
    
    % Electric field from ubar2 to ubar3
    Ey_23 = (Vg -phi_jun_s)/(tox_mod);
    E_s_23_real = (1/pi * dw_dz_abs * Ey_23 * (alpha_ubar3-alpha_ubar2));
    E_s_23_imag = (1/pi * dw_dz_abs * Ey_23 * (beta_ubar3-beta_ubar2));
    
    % Electric field from ubar4 to ubar5
    Ey_45 = -(Vg -phi_jun_s)/(tox_mod);
    E_s_45_real = (1/pi * dw_dz_abs * Ey_45 * (alpha_ubar5-alpha_ubar4));
    E_s_45_imag = (1/pi * dw_dz_abs * Ey_45 * (beta_ubar5-beta_ubar4));
    
    % Superposed electric field of the source region
    E_s_real = E_s_23_real + E_s_45_real;
    E_s_imag = E_s_23_imag + E_s_45_imag;
% =========================================================================
% End source related case


%% Drain related case
% =========================================================================
% Mapping of the position (x/y)
    u = func_mapping_u(lch-x,y+tox_mod,delta_y);
    v = func_mapping_v(lch-x,y+tox_mod,delta_y);
% Separation of real- and imaginary part of the electric field

    % Polar form of sqrt(1/(1-(w*)^2))
    M1 = 1/((1-u^2+v^2)^2+(2*u*v)^2)^(1/4);
    theta_1 = 0.5 * func_atan2((1-u^2+v^2),(2*u*v));
    
    % Applying equation A.30 of the master thesis for each mapping point
    E_ubar2 = -(ubar2*v*M1*cos(theta_1) + (ubar2*u-1)*M1*sin(theta_1));
    F_ubar2 = sqrt(1-ubar2^2) - (ubar2*u-1)*M1*cos(theta_1) + ubar2*v*M1*sin(theta_1);

    E_ubar3 = -(ubar3*v*M1*cos(theta_1) + (ubar3*u-1)*M1*sin(theta_1));
    F_ubar3 = sqrt(1-ubar3^2) - (ubar3*u-1)*M1*cos(theta_1) + ubar3*v*M1*sin(theta_1);

    E_ubar4 = -(ubar4*v*M1*cos(theta_1) + (ubar4*u-1)*M1*sin(theta_1));
    F_ubar4 = sqrt(1-ubar4^2) - (ubar4*u-1)*M1*cos(theta_1) + ubar4*v*M1*sin(theta_1);

    E_ubar5 = -(ubar5*v*M1*cos(theta_1) + (ubar5*u-1)*M1*sin(theta_1));
    F_ubar5 = sqrt(1-ubar5^2) - (ubar5*u-1)*M1*cos(theta_1) + ubar5*v*M1*sin(theta_1);
    
    % Applying equation A.31 of the master thesis for each mapping point
    G_ubar2 = (E_ubar2*(ubar2-u) + F_ubar2*v)/((ubar2-u)^2 + v^2);
    H_ubar2 = (F_ubar2*(ubar2-u) - E_ubar2*v)/((ubar2-u)^2 + v^2);

    G_ubar3 = (E_ubar3*(ubar3-u) + F_ubar3*v)/((ubar3-u)^2 + v^2);
    H_ubar3 = (F_ubar3*(ubar3-u) - E_ubar3*v)/((ubar3-u)^2 + v^2);

    G_ubar4 = (E_ubar4*(ubar4-u) + F_ubar4*v)/((ubar4-u)^2 + v^2);
    H_ubar4 = (F_ubar4*(ubar4-u) - E_ubar4*v)/((ubar4-u)^2 + v^2);

    G_ubar5 = (E_ubar5*(ubar5-u) + F_ubar5*v)/((ubar5-u)^2 + v^2);
    H_ubar5 = (F_ubar5*(ubar5-u) - E_ubar5*v)/((ubar5-u)^2 + v^2);
    
    % Applying equation A.32 of the master thesis for each mapping point
    M2_ubar2 = sqrt(G_ubar2^2 + H_ubar2^2);
    theta_2_ubar2 = func_atan2(G_ubar2,H_ubar2);

    M2_ubar3 = sqrt(G_ubar3^2 + H_ubar3^2);
    theta_2_ubar3 = func_atan2(G_ubar3,H_ubar3);

    M2_ubar4 = sqrt(G_ubar4^2 + H_ubar4^2);
    theta_2_ubar4 = func_atan2(G_ubar4,H_ubar4);

    M2_ubar5 = sqrt(G_ubar5^2 + H_ubar5^2);
    theta_2_ubar5 = func_atan2(G_ubar5,H_ubar5);
    
    % Polar form of sqrt(1-(w*)^2)
    M3 = ((1-u^2+v^2)^2+(2*u*v)^2)^(1/4);
    theta_3 = 0.5*func_atan2((1-u^2+v^2),(2*u*v));
    
    % Applying equation A.33 of the master thesis for each mapping point
    M4_ubar2 = sqrt((log(M2_ubar2))^2 + theta_2_ubar2^2);
    theta_4_ubar2 = func_atan2(log(M2_ubar2),theta_2_ubar2);

    M4_ubar3 = sqrt((log(M2_ubar3))^2 + theta_2_ubar3^2);
    theta_4_ubar3 = func_atan2(log(M2_ubar3),theta_2_ubar3);

    M4_ubar4 = sqrt((log(M2_ubar4))^2 + theta_2_ubar4^2);
    theta_4_ubar4 = func_atan2(log(M2_ubar4),theta_2_ubar4);

    M4_ubar5 = sqrt((log(M2_ubar5))^2 + theta_2_ubar5^2);
    theta_4_ubar5 = func_atan2(log(M2_ubar5),theta_2_ubar5);

    alpha_ubar2 = -delta_y/pi * M4_ubar2/M3 * cos(theta_4_ubar2 - theta_3);
    beta_ubar2 = -delta_y/pi * M4_ubar2/M3 * sin(theta_4_ubar2 - theta_3);

    alpha_ubar3 = -delta_y/pi * M4_ubar3/M3 * cos(theta_4_ubar3-theta_3);
    beta_ubar3 = -delta_y/pi * M4_ubar3/M3 * sin(theta_4_ubar3-theta_3);

    alpha_ubar4 = -delta_y/pi * M4_ubar4/M3 * cos(theta_4_ubar4-theta_3);
    beta_ubar4 = -delta_y/pi * M4_ubar4/M3 * sin(theta_4_ubar4-theta_3);

    alpha_ubar5 = -delta_y/pi * M4_ubar5/M3 * cos(theta_4_ubar5-theta_3);
    beta_ubar5 = -delta_y/pi * M4_ubar5/M3 * sin(theta_4_ubar5-theta_3);
    
    % Calculation of |dw/dz| with the help of equation (A.34) of the master thesis
    dw_dz_abs = (((u-1)^2 + v^2)*((u+1)^2 + v^2))^(1/4)/(2*tox_mod + tch)*pi;
    
    % Electric field from ubar2 to ubar3
    Ey_23 = -(-Vg+phi_jun_d)/(tox_mod);
    E_d_23_real = (1/pi * dw_dz_abs * Ey_23 * (alpha_ubar3-alpha_ubar2));
    E_d_23_imag = (1/pi * dw_dz_abs * Ey_23 * (beta_ubar3-beta_ubar2));
    
    % Electric field from ubar4 to ubar5
    Ey_45 = (-Vg+phi_jun_d)/(tox_mod);
    E_d_45_real = (1/pi * dw_dz_abs * Ey_45 * (alpha_ubar5-alpha_ubar4));
    E_d_45_imag = (1/pi * dw_dz_abs * Ey_45 * (beta_ubar5-beta_ubar4));
    
    % Superposed electric field of the drain region
    E_d_real = E_d_23_real + E_d_45_real;
    E_d_imag = E_d_23_imag + E_d_45_imag;
% =========================================================================
% End drain related case


%% Superposed electric field from source and drain region
% =========================================================================
    E_real = E_s_real +(-E_d_real);
    E_imag = E_s_imag +(-E_d_imag);
% =========================================================================

%% Absolute value of the electric field
% =========================================================================
    efield_abs = sqrt(E_real^2 + E_imag^2);
% =========================================================================
