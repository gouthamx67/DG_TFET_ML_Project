function [Jy_y_out] = func_Jy_y_TAT(y,Vgs,Vgs_eff,Vs,Vd,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...
                               Ns,Nd,eps_s,eps_ch,eps_d,eps_ox,x_jun,phi_jun_sur,phi_jun_cen,...
                               x_ch1,phi_ch1_sur,phi_ch1_cen,x_ch2,phi_ch2_sur,phi_ch2_cen,...
                               y1,y2,lch,tch,tox,m_s,m_d,T,lambda_fit,q,m0,h_quer,kb,sigma2_TAT,...
                               N_T_in, tau_on, tau_amb, f_Slope_TAT_on, f_Slope_TAT_amb, xmax_TAT)
% Function to calculate the current density for a specific y position. The
% current density is calculated by the integral of the tunneling genration
% rate (TGR), which is approximated by a Gaussian distribution.
%
% fun_Jy_y(y,Vgs,Vgs_eff,Vs,Vd,Qinv,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...
%          Ns,Nd,eps_s,eps_ch,eps_d,eps_ox,x_jun,phi_jun_sur,phi_jun_cen,...
%          x_ch1,phi_ch1_sur,phi_ch1_cen,x_ch2,phi_ch2_sur,phi_ch2_cen,...
%          y1,y3,lch,tch,tox,mn_s,mn_d,T,lambda_fit,q,m0,h_bar,kb,TFET_Plot)
%
% Inputs:
%--------------------------------------------------------------------------
% y             - y-position
% Vgs           - Gate-Source Voltage
% Vgs_eff       - Effective Gate-Source Voltage
% Vs            - Source Voltage
% Vd            - Drain Voltage
% Qinv          - Inversion charges
% Phi_bi_s      - Built-in potential source
% Phi_bi_d      - Built-in potential drain
% Eg_s          - Band gap source
% Eg_ch         - Band gap channel
% Eg_d          - Band gap drain
% X_s           - Electron affinity source
% X_ch          - Electron affinity channel
% X_d           - Electron affinity drain
% Ns            - Doping concentration source
% Nd            - Doping concentration drain
% eps_s         - Permittivity source
% eps_ch        - Permittivity channel
% eps_d         - Permittivity drain
% eps_ox        - Permittivity gate oxide
% x_jun         - x-position of the junction
% phi_jun_sur   - Potential at x_jun and y = y1
% phi_jun_cen   - Potential at x_jun and y = y2
% x_ch1         - First x-posistion in the channel
% phi_ch1_sur   - Potential at x_ch1 and y = y1
% phi_ch1_cen   - Potential at x_ch1 and y = y2
% x_ch2         - Second x-posistion in the channel
% phi_ch2_sur   - Potential at x_ch2 and y = y1
% phi_ch2_cen   - Potential at x_ch2 and y = y2
% y1            - y-position describing the surface of the channel
% y2            - y-position describing the center of the channel
% lch           - channel length
% tch           - channel thickness
% tox           - gate oxide thickness
% m_s           - Effective electron mass of carriers at the source-to-channel junction
% m_d           - Effective electron mass of carriers at the drain-to-channel junction
% T             - Temperature
% lambda_fit    - Fit-Factor of the screening length
% q             - Elementary charge
% m0            - Electron rest mass
% h_bar         - Reduced Planck constant
% kb            - Boltzmann constant [eV/K]
% TFET_Plot     - Struct containing the information about plotting
%--------------------------------------------------------------------------
%
% Outputs:
%--------------------------------------------------------------------------
% Jy_y_out      - Struct containing the current density at y as well as the
%                 calculated results for potential, efield, bands...
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
% Calulating potential where band bending in the considered region is zero
    % Check the position of the junction
    if (x_jun > lch/2)
       % Set phi_ds to the value where potential bending in drain is zero 
       phi_ds = Phi_bi_d + Vd;
    else
       % Set phi_ds to the value where potential bending in source is zero
       phi_ds = Phi_bi_s + Vs;
    end

% Calulating potential at the channel's surface along the x-axis
    % Channel potential along the x-axis
        % First simplification
        D12_sur = (phi_ch1_sur-phi_jun_sur)/(x_jun-x_ch1);
        % Second simplification
        D13_sur = (phi_ch2_sur-phi_jun_sur)/(x_jun-x_ch2);
        % Calculation of the first parameter l of the potential
        % approximation in channel at the surface. It contains of two
        % solutions l1 and l2 caused by the sqrt            
        l1 = -(D13_sur*(x_jun+x_ch2)-D12_sur*(x_jun+x_ch1))/(2*(D12_sur-D13_sur)) + ...
        sqrt((-(D13_sur*(x_jun+x_ch2)-D12_sur*(x_jun+x_ch1))/(2*(D12_sur-D13_sur)))^2-...
        x_jun*(D12_sur*x_ch1-D13_sur*x_ch2)/(D12_sur-D13_sur));
        l2 = -(D13_sur*(x_jun+x_ch2)-D12_sur*(x_jun+x_ch1))/(2*(D12_sur-D13_sur)) - ...
        sqrt((-(D13_sur*(x_jun+x_ch2)-D12_sur*(x_jun+x_ch1))/(2*(D12_sur-D13_sur)))^2-...
        x_jun*(D12_sur*x_ch1-D13_sur*x_ch2)/(D12_sur-D13_sur));
        % Check the position of the junction
        if (x_jun > lch/2)
        % Solution has to be greater than lch for the drain case, so
        % setting l_sur to the biggest value
            if (l2 >= l1)
               l_sur = l2;
            else
               l_sur = l1;
            end
            if (l_sur == x_jun) || (l_sur == lch)
                % Avoid a division by zero
                l_sur = l_sur + 2e-20;
            end        
        else
        % Solution has to be smaller than zero for the source case, so
        % setting l_sur to the smallest value    
            if (l2 <= l1)
               l_sur = l2;
            else
               l_sur = l1;
            end
            if (l_sur == x_jun) || (l_sur == lch)
                % Avoid a division by zero
                l_sur = l_sur - 2e-20;
            end
        end
        % Calculation of the second parameter of the potential
        % approximation in channel at the surface.
        k_sur = (phi_ch1_sur-phi_jun_sur)/(1/(x_ch1-l_sur)-1/(x_jun-l_sur));
        % Calculation of the third parameter of the potential
        % approximation in channel at the surface.
        m_sur = phi_jun_sur - k_sur/(x_jun-l_sur);        
% Calulating potential at the channel's center along the x-axis 
    % Channel potential along the x-axis
        % First simplification
        D12_cen = (phi_ch1_cen-phi_jun_cen)/(x_jun-x_ch1);
        % Second simplification
        D13_cen = (phi_ch2_cen-phi_jun_cen)/(x_jun-x_ch2);
        % Calculation of the first parameter l of the potential
        % approximation in channel at the center. It contains of two
        % solutions l1 and l2 caused by the sqrt 
        l1 = -(D13_cen*(x_jun+x_ch2)-D12_cen*(x_jun+x_ch1))/(2*(D12_cen-D13_cen)) + ...
        sqrt((-(D13_cen*(x_jun+x_ch2)-D12_cen*(x_jun+x_ch1))/(2*(D12_cen-D13_cen)))^2-...
        x_jun*(D12_cen*x_ch1-D13_cen*x_ch2)/(D12_cen-D13_cen));
        l2 = -(D13_cen*(x_jun+x_ch2)-D12_cen*(x_jun+x_ch1))/(2*(D12_cen-D13_cen)) - ...
        sqrt((-(D13_cen*(x_jun+x_ch2)-D12_cen*(x_jun+x_ch1))/(2*(D12_cen-D13_cen)))^2-...
        x_jun*(D12_cen*x_ch1-D13_cen*x_ch2)/(D12_cen-D13_cen));
        % Check the position of the junction
        if (x_jun > lch/2)
        % Solution has to be greater than lch for the drain case, so
        % setting l_cen to the biggest value
            if (l2 >= l1)
               l_cen = l2;
            else
               l_cen = l1;
            end
            if (l_cen == x_jun) || (l_cen == lch)
                % Avoid a division by zero
                l_cen = l_cen + 2e-20;
            end
        else
        % Solution has to be smaller than zero for the source case, so
        % setting l_cen to the smallest value
            if (l2 <= l1)
               l_cen = l2;
            else
               l_cen = l1;
            end
            if (l_cen == x_jun) || (l_cen == lch)
                % Avoid a division by zero
                l_cen = l_cen - 2e-20;
            end
        end
        % Calculation of the second parameter of the potential
        % approximation in channel at the center.
        k_cen = (phi_ch1_cen-phi_jun_cen)/(1/(x_ch1-l_cen)-1/(x_jun-l_cen));
        % Calculation of the third parameter of the potential
        % approximation in channel at the center.
        m_cen = phi_jun_cen - k_cen/(x_jun-l_cen);
    
% Calulating potential for the handover y-position and the three
% x-positions x_jun, x_ch1 and x_ch2
    % Calculating the exponent of the potential approximation along the
    % y-axis
    e_y = 2+2*abs(Vgs-Vgs_eff);    
    % Calculating the prefactor of x = x_jun
    f_jun = (phi_jun_sur - phi_jun_cen)/(y2-y1)^e_y;
    % Calculating the potential at the y-position and x = x_jun
    phi_jun_y = f_jun *abs((y - y2)^e_y) + phi_jun_cen;
    % Calculating the prefactor of x = x_ch1  
    f_ch1 = (phi_ch1_sur - phi_ch1_cen)/(y2-y1)^e_y;
    % Calculating the potential at the y-position and x = x_ch1
    phi_ch1_y = f_ch1 *abs((y - y2)^e_y) + phi_ch1_cen;
    % Calculating the prefactor of x = x_ch2
    f_ch2 = (phi_ch2_sur - phi_ch2_cen)/(y2-y1)^e_y;
    % Calculating the potential at the y-position and x = x_ch2
    phi_ch2_y = f_ch2 *abs((y - y2)^e_y) + phi_ch2_cen;
    
% Potential approximation along the x-axis for the handover y-position
    % Approximation in source
        % Calculating screening length
        lambda_y = func_lambda(y,lambda_fit,eps_ch,eps_ox,tch,tox);
        % Check the position of the junction
        if (x_jun > lch/2)
            % calculating x-position in drain where potential bending is
            % zero
            x_ds_y = lch + func_ds(lambda_y,Phi_bi_d, Vgs_eff ,Vd,Nd,eps_d,q);
        else
            % calculating x-position in source where potential bending is
            % zero
            x_ds_y = -func_ds(lambda_y,Phi_bi_s, Vgs_eff ,Vs,Ns,eps_s,q);
        end

        % Calculate first parameter of the potential approximation in
        % source at the handover y-position
        a_y = (phi_jun_y-phi_ds)/((x_jun-x_ds_y)^2);
        % Calculate second parameter of the potential approximation in
        % source at the handover y-position
        b_y = (-2*x_ds_y*(phi_jun_y-phi_ds))/((x_jun-x_ds_y)^2);
        % Calculate third parameter of the potential approximation in
        % source at the handover y-position
        c_y = phi_ds + x_ds_y^2*(phi_jun_y-phi_ds)/((x_jun-x_ds_y)^2);

    % Approximation in channel
        % First simplification
        D12_y = (phi_ch1_y-phi_jun_y)/(x_jun-x_ch1);
        % Second simplification
        D13_y = (phi_ch2_y-phi_jun_y)/(x_jun-x_ch2);
        % Calculation of the first parameter l of the potential
        % approximation in channel at the handover y-position.
        % It contains of two solutions l1 and l2 caused by the sqrt 
        l1 = -(D13_y*(x_jun+x_ch2)-D12_y*(x_jun+x_ch1))/(2*(D12_y-D13_y)) + ...
        sqrt((-(D13_y*(x_jun+x_ch2)-D12_y*(x_jun+x_ch1))/(2*(D12_y-D13_y)))^2-...
        x_jun*(D12_y*x_ch1-D13_y*x_ch2)/(D12_y-D13_y));
        l2 = -(D13_y*(x_jun+x_ch2)-D12_y*(x_jun+x_ch1))/(2*(D12_y-D13_y)) - ...
        sqrt((-(D13_y*(x_jun+x_ch2)-D12_y*(x_jun+x_ch1))/(2*(D12_y-D13_y)))^2-...
        x_jun*(D12_y*x_ch1-D13_y*x_ch2)/(D12_y-D13_y));
        % Check the position of the junction
        if (x_jun > lch/2)
        % Solution has to be greater than lch for the drain case, so
        % setting l_y to the biggest value
            if (l2 >= l1)
               l_y = l2;
            else
               l_y = l1;
            end
            if (l_y == x_jun) || (l_y == lch)
                l_y = l_y + 2e-20;
            end
        else
        % Solution has to be smaller than zero for the source case, so
        % setting l_y to the smallest value        
            if (l2 <= l1)
               l_y = l2;
            else
               l_y = l1;
            end        
            if (l_y == x_jun) || (l_y == lch)
                l_y = l_y - 2e-20;
            end
        end
        % Calculation of the second parameter of the potential
        % approximation in channel at the handover y-position
        k_y = (phi_ch1_y-phi_jun_y)/(1/(x_ch1-l_y)-1/(x_jun-l_y));
        % Calculation of the third parameter of the potential
        % approximation in channel at the handover y-position
        m_y = phi_jun_y - k_y/(x_jun-l_y);
        
% Calculation of the x-position where tunneling can occur
% x-position which defines the beginning of the tunneling area (lower
% integration limit)
    if x_jun > lch/2
%         xTA_ll = lch - 1e-20;
        xTA_ll = lch/2;
    else
        xTA_ll = 1e-20;
    end
% Definition of the x-postion which defines the end of the tunneling
% area (upper integration limit)
    if x_jun > lch/2
%         xTA_ul = lch - lch/2;
        xTA_ul = lch - 1e-20;
    else
        xTA_ul = lch/2;
    end    
% Definition of the maximum x-postion of the TGR
    if x_jun > lch/2
        xmax_TGR = lch - xmax_TAT;
    else       
        xmax_TGR = xmax_TAT;
    end
    
% Calculation of the closed-form electric field at x = xmax_TGR
    % Calculating x-contibution of the electric field
    Efield_xmax_x = - k_y/(xmax_TGR-l_y)^2;
    % y potential approximation at x = xmax_TGR
    phi_xmax_sur = k_sur/(xmax_TGR-l_sur) + m_sur;
    phi_xmax_cen = k_cen/(xmax_TGR-l_cen) + m_cen;
    f_xmax = (phi_xmax_sur - phi_xmax_cen)/(y2-y1)^e_y;
    % Calculating y-contibution of the electric field
    Efield_xmax_y = - f_xmax*e_y*(y2-y)^(e_y-1);
    % Calculating resulting electric field
    Efield_xmax = sqrt(Efield_xmax_x^2 + Efield_xmax_y^2);
    % Calculating Tunneling probability  
    Ttun_xmax = func_Ttun_TAT(xmax_TGR,m_s,m_d,a_y,b_y,c_y,k_y,l_y,m_y,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,q,m0,h_quer,lch); 
    % Potential at the maximum x position of the TGR
    phi_xmax_TGR = (k_y/(xmax_TGR - l_y) + m_y);
    % Conduction band at the maximum x position of the TGR
    EC_xmax_TGR  = -phi_xmax_TGR + X_s - X_ch + Eg_ch/2;
    % Valence band at the maximum x position of the TGR
    EV_xmax_TGR  = -phi_xmax_TGR + X_s - X_ch - Eg_ch/2;
             
%% Modelderivation Fabian      


% Landauer = func_Landauer(Vs,Vd,Phi_bi_d,Phi_bi_s,k_y,l_y,m_y,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch,kb,T);   
    
    % Drain-to-channel junction: TAT caused by electrons
    if x_jun > lch/2 
        % Calculation of the conduction band at drain-to-channel junction
        Ec_ref_jun = -(a_y*(x_jun)^2 + b_y*x_jun + c_y ) + X_s - X_d + Eg_d/2;
        % Calculation of the valence band at drain-to-channel junction
%         Ev_ref_jun = -(a_y*(x_jun)^2 + b_y*x_jun + c_y ) + X_s - X_d - Eg_d/2;                            
        % Calculating field effect function Gamma with an approximation
        Gamma_approx = 4/4*Ttun_xmax * exp(-(Ec_ref_jun-EV_xmax_TGR)/(f_Slope_TAT_amb*kb*T));
        % Calculation of the trap density as a function of the band diagram
        N_T = N_T_in * exp((EV_xmax_TGR - Ec_ref_jun)/(f_Slope_TAT_amb*kb*T));
%         N_T = N_T_in * exp((EV_xmax_TGR - Ec_ref_jun)/(1*kb*T));
        % Calculating the supply function
        Landauer = log( (1+exp(-(-EV_xmax_TGR + (-Vd)  )/(f_Slope_TAT_amb*kb*T))) / (1+exp(-(-EV_xmax_TGR + (-Vs)  )/(f_Slope_TAT_amb*kb*T))) );
        % Maximum of tunneling generation rate               
        TGR_xmax = (4*pi*m_d*m0*kb*q*T)/((2*pi*h_quer)^3*10000)*tau_amb*N_T*Landauer*(1+Gamma_approx)*q*Efield_xmax;
        
        
    % Source-to-channel junction: TAT caused by holes
    else
        % Calculation of the conduction band at source-to-channel junction
%         Ec_ref_jun = -(a_y*(x_jun)^2 + b_y*x_jun + c_y ) + Eg_s/2;
        % Calculation of the valence band at source-to-channel junction
        Ev_ref_jun = -(a_y*(x_jun)^2 + b_y*x_jun + c_y ) - Eg_s/2;
        % Calculating field effect function Gamma with an approximation
        Gamma_approx = 4/4* Ttun_xmax * exp((Ev_ref_jun - EC_xmax_TGR)/(f_Slope_TAT_on*kb*T));
        
        % Calculation of the trap density as a function of the band diagram
        N_T = N_T_in * exp(-(EC_xmax_TGR - Ev_ref_jun)/(f_Slope_TAT_on*kb*T)); 
        % Calculating the Fermi distribution for holes        
        Landauer = log((1+exp(-(EC_xmax_TGR-(-Vs))/(f_Slope_TAT_on*kb*T)))/(1+exp(-(EC_xmax_TGR-(-Vd))/(f_Slope_TAT_on*kb*T))));
        
        % Maximum of tunneling generation rate 
        TGR_xmax = (4*pi*m_s*m0*kb*q*T)/((2*pi*h_quer)^3*10000)*tau_on*N_T*Landauer*(1+Gamma_approx)*q*Efield_xmax;        
    end          
    
% Integration of the TGR along the x-axis for the handover y-position
    % Check the caclulated values to avoid numerical problems
    if(TGR_xmax == 0 || sigma2_TAT == 0)
        % Set Jy_y to zero
        Jy_y = 0;
    else
        % Check the position of the junction
        if x_jun > lch/2
            % Check the integrations limits for the drain-to-channel
            % junction
            if(xTA_ll < xTA_ul)
                % Calculating error function at the upper integration limit
                erf_xTA_ul = func_erf((xTA_ul-xmax_TGR)/(sqrt(sigma2_TAT)));
                % Calculating error function at the lower integration limit
                erf_xTA_ll = func_erf((xTA_ll-xmax_TGR)/(sqrt(sigma2_TAT)));
                % Calculation of the TGR integration
                Jy_y = ((sqrt(pi)*TGR_xmax*sqrt(sigma2_TAT)*erf_xTA_ul/2)-...
                       (sqrt(pi)*TGR_xmax*sqrt(sigma2_TAT)*erf_xTA_ll/2));
            else
                % Set TGR integration result to zero
                Jy_y = 0;                
            end   
        else
            % Check the integrations limits for the source-to-channel
            % junction
            if(xTA_ll < xTA_ul)
                % Calculating error function at the upper integration limit
                erf_xTA_ul = func_erf((xTA_ul-xmax_TGR)/(sqrt(sigma2_TAT)));
                % Calculating error function at the lower integration limit
                erf_xTA_ll = func_erf((xTA_ll-xmax_TGR)/(sqrt(sigma2_TAT)));
                % Calculation of the TGR integration
                Jy_y = ((sqrt(pi)*TGR_xmax*sqrt(sigma2_TAT)*erf_xTA_ul/2)-...
                       (sqrt(pi)*TGR_xmax*sqrt(sigma2_TAT)*erf_xTA_ll/2));
            else
                % Set TGR integration result to zero
                Jy_y = 0;               
            end            
        end     
    end
% Handover TGR integration result
    Jy_y_out.Jy_y = Jy_y;

end