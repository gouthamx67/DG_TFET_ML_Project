function [Jy_y_out] = func_Jy_y_B2B(y,Vgs,Vgs_eff,Vs,Vd,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,...
                               Ns,Nd,eps_s,eps_ch,eps_d,eps_ox,x_jun,phi_jun_sur,phi_jun_cen,...
                               x_ch1,phi_ch1_sur,phi_ch1_cen,x_ch2,phi_ch2_sur,phi_ch2_cen,...
                               y1,y3,lch,tch,tox,m_ON,m_AMB,T,lambda_fit,q,m0,h_quer,kb,TFET_Plot,...
                               Phi_bi_eff_s ,Phi_bi_eff_d,tox_mod,sigma2_B2B)
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
% Qinv          - Invervion charges
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
% phi_jun_cen   - Potential at x_jun and y = y3
% x_ch1         - First x-posistion in the channel
% phi_ch1_sur   - Potential at x_ch1 and y = y1
% phi_ch1_cen   - Potential at x_ch1 and y = y3
% x_ch2         - Second x-posistion in the channel
% phi_ch2_sur   - Potential at x_ch2 and y = y1
% phi_ch2_cen   - Potential at x_ch2 and y = y3
% y1            - y-position describing the surface of the channel
% y3            - y-position describing the center of the channel
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
    % Source potential along the x-axis
        % Calculating screening length at the surface
        lambda_sur = func_lambda(y1,lambda_fit,eps_ch,eps_ox,tch,tox);
        % Check the position of the junction
        if (x_jun > lch/2)
            % calculating x-position in drain where potential bending is
            % zero
            x_ds_sur = lch + func_ds(lambda_sur,Phi_bi_d, Vgs_eff ,Vd,Nd,eps_d,q);
        else
            % calculating x-position in source where potential bending is
            % zero
            x_ds_sur = -func_ds(lambda_sur,Phi_bi_s, Vgs_eff ,Vs,Ns,eps_s,q);
        end
        % Calculate first parameter of the potential approximation in
        % source at the surface
        a_sur = (phi_jun_sur-phi_ds)/((x_jun-x_ds_sur)^2);
        % Calculate second parameter of the potential approximation in
        % source at the surface
        b_sur = (-2*x_ds_sur*(phi_jun_sur-phi_ds))/((x_jun-x_ds_sur)^2);
        % Calculate third parameter of the potential approximation in
        % source at the surface
        c_sur = phi_ds + x_ds_sur^2*(phi_jun_sur-phi_ds)/((x_jun-x_ds_sur)^2);

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
            if l_sur == x_jun
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
            if l_sur == x_jun
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
    % Source potential along the x-axis
        % Calculating screening length at the surface        
        lambda_cen = func_lambda(y3,lambda_fit,eps_ch,eps_ox,tch,tox);
        % Check the position of the junction
        if (x_jun > lch/2)
           % calculating x-position in drain where potential bending is
           % zero
           x_ds_cen = lch + func_ds(lambda_cen,Phi_bi_d,Vgs_eff,Vd,Nd,eps_d,q);
        else
           % calculating x-position in source where potential bending is
           % zero
           x_ds_cen = -func_ds(lambda_cen,Phi_bi_s,Vgs_eff,Vs,Ns,eps_s,q);
        end
        % Calculate first parameter of the potential approximation in
        % source at the center
        a_cen = (phi_jun_cen-phi_ds)/((x_jun-x_ds_cen)^2);
        % Calculate second parameter of the potential approximation in
        % source at the center
        b_cen = (-2*x_ds_cen*(phi_jun_cen-phi_ds))/((x_jun-x_ds_cen)^2);
        % Calculate third parameter of the potential approximation in
        % source at the center
        c_cen = phi_ds + x_ds_cen^2*(phi_jun_cen-phi_ds)/((x_jun-x_ds_cen)^2);
        
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
            if l_cen == x_jun
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
            if l_cen == x_jun
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
    f_jun = (phi_jun_sur - phi_jun_cen)/(y3-y1)^e_y;
    % Calculating the potential at the y-position and x = x_jun
    phi_jun_y = f_jun *abs((y - y3)^e_y) + phi_jun_cen;
    % Calculating the prefactor of x = x_ch1  
    f_ch1 = (phi_ch1_sur - phi_ch1_cen)/(y3-y1)^e_y;
    % Calculating the potential at the y-position and x = x_ch1
    phi_ch1_y = f_ch1 *abs((y - y3)^e_y) + phi_ch1_cen;
    % Calculating the prefactor of x = x_ch2
    f_ch2 = (phi_ch2_sur - phi_ch2_cen)/(y3-y1)^e_y;
    % Calculating the potential at the y-position and x = x_ch2
    phi_ch2_y = f_ch2 *abs((y - y3)^e_y) + phi_ch2_cen;
    
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
%             x_ds_y = -func_ds(lambda_y1_s,Phi_bi_s, Vgs_eff ,Vs,Ns,eps_s,q);
            
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
            if l_y == x_jun
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
            if l_y == x_jun
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
    xTA_ll = func_xTA_ll(k_y,l_y,m_y,Vs,Vd,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch);
% Calculation of the x-postion which defines the end of the tunneling
% area (upper integration limit)
    xTA_ul = func_xTA_ul(k_y,l_y,m_y,Vs,Vd,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch);  
% Calculaction of the x-position where the TGR is the greatest which is
% used for the TGR approximation along the x-axis for the handover
% y-position
    xmax_TGR = func_xmax_TGR(a_y,b_y,c_y,k_y,l_y,m_y,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch);
    
% Calculation of the closed-form electric field at x = xmax_TGR
    % Calculating x-contibution of the electric field
    Efield_xmax_x = - k_y/(xmax_TGR-l_y)^2;
    % y potential approximation at x = xmax_TGR
    phi_xmax_sur = k_sur/(xmax_TGR-l_sur) + m_sur;
    phi_xmax_cen = k_cen/(xmax_TGR-l_cen) + m_cen;
    f_xmax = (phi_xmax_sur - phi_xmax_cen)/(y3-y1)^e_y;
    % Calculating y-contibution of the electric field
    Efield_xmax_y = - f_xmax*e_y*(y3-y)^(e_y-1);
    % Calculating resulting electric field
    Efield_xmax = sqrt(Efield_xmax_x^2 + Efield_xmax_y^2); 
%         Efield_xmax = abs(Efield_xmax_x); 

    Efield_xmax_Michi = func_efield_abs_Michi(xmax_TGR, y ,Vgs_eff, Phi_bi_eff_s, Phi_bi_eff_d, lch, tch, tox_mod);
% Approximation of the TGR along the x-axis for the handover y-position
% without Landauer's transmission theory
    % Calculating the tunneling probability at x = xmax_TGR
    [Ttun_xmax, ltun_xmax, E_bh_xmax] = func_Ttun_B2B(xmax_TGR,m_ON,m_AMB,a_y,b_y,c_y,k_y,l_y,m_y,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,q,m0,h_quer,lch);
    [Ttun_xmax_Michi, ltun_xmax_Michi, E_bh_xmax_Michi] = func_Ttun_Michi( xmax_TGR,m_ON,m_AMB,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,a_y,b_y,c_y,k_y,l_y,m_y,Efield_xmax_Michi,q,m0,h_quer,lch);
    
    % Calculating the supply of carriers with the help of Landauer's
    % tranmission theory
    Landauer = func_Landauer(Vs,Vd,Phi_bi_d,Phi_bi_s,k_y,l_y,m_y,Eg_s,Eg_d,X_s,X_d,lch,kb,T);        
    % Calculating the maximum TGR value

    if x_jun > lch/2
        TGR_prefactor = (4*pi*m0*m_AMB*(kb*abs(q)*T))/((2*pi*h_quer)^3*10000); % kb in [J]
    else
        TGR_prefactor = (4*pi*m0*m_ON*(kb*abs(q)*T))/((2*pi*h_quer)^3*10000);
    end
    
    TGR_xmax = TGR_prefactor*Ttun_xmax * Efield_xmax *q * Landauer;
    
% Integration of the TGR along the x-axis for the handover y-position
    % Check the caclulated values to avoid numerical problems
    if(TGR_xmax == 0 || sigma2_B2B == 0)
        % Set Jy_y to zero
        Jy_y = 0;
    else
        % Check the position of the junction
        if x_jun > lch/2
            % Check the integrations limits for the drain-to-channel
            % junction
            if(xTA_ll > xTA_ul)
                % Calculating error function at the upper integration limit
                erf_xint = func_erf((xTA_ul-xmax_TGR)/(sqrt(sigma2_B2B)));
                % Calculating error function at the lower integration limit
                erf_xtun = func_erf((xTA_ll-xmax_TGR)/(sqrt(sigma2_B2B)));
                % Calculation of the TGR integration
                Jy_y = ((sqrt(pi)*TGR_xmax*sqrt(sigma2_B2B)*erf_xtun/2)-...
                       (sqrt(pi)*TGR_xmax*sqrt(sigma2_B2B)*erf_xint/2));
            else
                % Set TGR integration result to zero
                Jy_y = 0;                
            end   
        else
            % Check the integrations limits for the source-to-channel
            % junction
            if(xTA_ll < xTA_ul)
                % Calculating error function at the upper integration limit
                erf_xint = func_erf((xTA_ul-xmax_TGR)/(sqrt(sigma2_B2B)));
                % Calculating error function at the lower integration limit
                erf_xtun = func_erf((xTA_ll-xmax_TGR)/(sqrt(sigma2_B2B)));
                % Calculation of the TGR integration
                Jy_y = ((sqrt(pi)*TGR_xmax*sqrt(sigma2_B2B)*erf_xint/2)-...
                       (sqrt(pi)*TGR_xmax*sqrt(sigma2_B2B)*erf_xtun/2));
            else
                % Set TGR integration result to zero
                Jy_y = 0;               
            end            
        end     
    end
% Handover TGR integration result
    Jy_y_out.Jy_y = Jy_y;
%--------------------------------------------------------------------------

%% Handover results for visualization
%--------------------------------------------------------------------------
% Check plot position 
    if (strcmp(TFET_Plot.y_pos,string('Center')) && y == y3)
        bool_plot_on = 1;
    elseif (strcmp(TFET_Plot.y_pos,string('Surface')) && y == y1)
        bool_plot_on = 1;
    else
        bool_plot_on = 0;
    end

% Calculating compact potential solution
    if (TFET_Plot.potential == 1 && bool_plot_on)
        if (x_jun > lch/2)
            x_channel_y = lch/2:1e-8:lch;
            x_sd_y = lch:1e-8:x_ds_y;
            x_sd_const = x_ds_y:1e-8:(lch+20e-7);
        else
            x_sd_const = -20e-7:1e-8:x_ds_y;
            x_sd_y = x_ds_y:1e-8:0;
            x_channel_y = 0:1e-8:lch/2;
        end
        phi_sd_const = 0.*x_sd_const + phi_ds;
        phi_sd_y = a_y*x_sd_y.^2 + b_y*x_sd_y + c_y;
        phi_channel_y = k_y./(x_channel_y - l_y) + m_y;
        if (x_jun > lch/2)
            Jy_y_out.potential_compact.x_ary = [x_channel_y x_sd_y x_sd_const];
            Jy_y_out.potential_compact.pot_ary = [phi_channel_y phi_sd_y phi_sd_const];
        else
            Jy_y_out.potential_compact.x_ary = [x_sd_const x_sd_y x_channel_y];
            Jy_y_out.potential_compact.pot_ary = [phi_sd_const phi_sd_y phi_channel_y];
        end
    end

% Calculating compact band structure
    if ((TFET_Plot.bands == 1 || TFET_Plot.bands_GaAs || TFET_Plot.bands_SiliconGermanium || TFET_Plot.bands_Germanium) && bool_plot_on)
        if (x_jun > lch/2)
            x_channel_y = lch/2:1e-8:lch;
%             x_channel_y = 0:1e-8:lch/2;
            x_sd_y = lch:1e-8:x_ds_y;
            x_sd_const = (x_ds_y+1e-8):1e-8:(lch+20e-7);
        else
            x_sd_const = -20e-7:1e-8:x_ds_y;
            x_sd_y = x_ds_y:1e-8:0;
            x_channel_y = 0:1e-8:lch/2;
        end
        phi_sd_const = 0.*x_sd_const + phi_ds;
        phi_sd_y = a_y*x_sd_y.^2 + b_y*x_sd_y + c_y;
        phi_channel_y = k_y./(x_channel_y - l_y) + m_y;
        if (x_jun > lch/2)
            EC_sd_const = -phi_sd_const + Eg_d/2 + X_s - X_d;
            EV_sd_const = -phi_sd_const - Eg_d/2 + X_s - X_d;
            EC_sd_y = -phi_sd_y + Eg_d/2 + X_s - X_d;
            EV_sd_y = -phi_sd_y - Eg_d/2 + X_s - X_d;
        else
            EC_sd_const = -phi_sd_const + Eg_s/2;
            EV_sd_const = -phi_sd_const - Eg_s/2;
            EC_sd_y = -phi_sd_y + Eg_s/2;
            EV_sd_y = -phi_sd_y - Eg_s/2;
        end
        EC_channel_y = -phi_channel_y + Eg_ch/2 + X_s - X_ch;
        EV_channel_y = -phi_channel_y - Eg_ch/2 + X_s - X_ch;
        if (x_jun > lch/2)
            Jy_y_out.bands_compact.x_ary = [x_channel_y x_sd_y x_sd_const];
            Jy_y_out.bands_compact.EC_ary = [ EC_channel_y EC_sd_y EC_sd_const];
            Jy_y_out.bands_compact.EV_ary = [ EV_channel_y EV_sd_y EV_sd_const];  
        else
            Jy_y_out.bands_compact.x_ary = [ x_sd_const  x_sd_y x_channel_y];
            Jy_y_out.bands_compact.EC_ary = [ EC_sd_const EC_sd_y EC_channel_y];
            Jy_y_out.bands_compact.EV_ary = [ EV_sd_const EV_sd_y EV_channel_y];     
        end
    end
    
% Calculating compact electric field
%--------------------------------------------------------------------------
    if (TFET_Plot.efield && bool_plot_on)

        if (x_jun > lch/2)
%             x_mesh_efield = lch/2:1e-8:x_ds_y;
            x_mesh_efield = lch/2:1e-8:lch;
        else
%             x_mesh_efield = x_ds_y:1e-8:lch/2;
            x_mesh_efield = 0:1e-8:lch/2;
        end
        for i = 1:length(x_mesh_efield)
            if x_mesh_efield(i) >=0 && x_mesh_efield(i) <= lch
                % Efield x-contribution for x >= 0 
                Efield_x_x = - k_y/(x_mesh_efield(i)-l_y)^2;
                % Efield y-contribution for x >= 0
                e_x = e_y;
                phi_x_sur = k_sur/(x_mesh_efield(i)-l_sur) + m_sur;
                phi_x_cen = k_cen/(x_mesh_efield(i)-l_cen) + m_cen;
                f_x = (phi_x_sur - phi_x_cen)/(y3-y1)^e_x;
                Efield_x_y = - f_x*e_x*(y3-y)^(e_x-1);
                % Resulting Efield for x >= 0
                Efield_ary(i) = sqrt(Efield_x_x^2 + Efield_x_y^2);
            else
                % Efield x-contribution for x < 0 
                Efield_x_x = -2*a_y*x_mesh_efield(i) - b_y;
                % Efield y-contribution for x < 0
                e_x = e_y;
                phi_x_sur = a_sur*x_mesh_efield(i)^2 + b_sur*x_mesh_efield(i)+ c_sur;
                phi_x_cen = a_cen*x_mesh_efield(i)^2 + b_cen*x_mesh_efield(i) + c_cen;
                f_x = (phi_x_sur - phi_x_cen)/(y3-y1)^e_x;
                Efield_x_y = - f_x*e_x*(y3-y)^(e_x-1);
                % Resulting Efield for x >= 0
                Efield_ary(i) = sqrt(Efield_x_x^2 + Efield_x_y^2);
            end
        end

        Jy_y_out.efield_compact.x_ary = x_mesh_efield;
        Jy_y_out.efield_compact.efield_ary = Efield_ary;   
    end
    
%% Calculating the tunneling probability

if ((TFET_Plot.TGR || TFET_Plot.TGR_GaAs|| TFET_Plot.TGR_Germanium || TFET_Plot.TGR_SiliconGermanium) && bool_plot_on)
    
    if (x_jun > lch/2)
        x_mesh_TGR = lch/2:lch/300:lch;
        TGR_Vorfaktor = (4*pi*m0*m_AMB*q*kb*q*T)/((2*pi*h_quer)^3*10000);
    else
        x_mesh_TGR = 0:lch/300:lch/2;
        TGR_Vorfaktor = (4*pi*m0*m_ON*q*kb*q*T)/((2*pi*h_quer)^3*10000);  
    end

    for i = 1:length(x_mesh_TGR)      
        
        % Calculating x-contibution of the electric field
        Efield_x_x = - k_y/(x_mesh_TGR(i)-l_y)^2;
        % y potential approximation at x = xmax_TGR
        phi_x_sur = k_sur/(x_mesh_TGR(i)-l_sur) + m_sur;
        phi_x_cen = k_cen/(x_mesh_TGR(i)-l_cen) + m_cen;
        f_x = (phi_x_sur - phi_x_cen)/(y3-y1)^e_y;
        % Calculating y-contibution of the electric field
        Efield_x_y = - f_x*e_y*(y3-y)^(e_y-1);
        % Calculating resulting electric field
        Efield_x = sqrt(Efield_x_x^2 + Efield_x_y^2); 
            
            
        Efield_Michi = func_efield_abs_Michi(x_mesh_TGR(i), y ,Vgs_eff, Phi_bi_eff_s, Phi_bi_eff_d, lch, tch, tox_mod);
        
        
        Ttun_FH = func_Ttun_B2B(x_mesh_TGR(i),m_ON,m_AMB,a_y,b_y,c_y,k_y,l_y,m_y,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,q,m0,h_quer,lch);
        Ttun_Michi = func_Ttun_Michi( x_mesh_TGR(i),m_ON,m_AMB,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,a_y,b_y,c_y,k_y,l_y,m_y,Efield_Michi,q,m0,h_quer,lch);                    
        
        Landauer = func_Landauer(Vs,Vd,Phi_bi_d,Phi_bi_s,k_y,l_y,m_y,Eg_s,Eg_d,X_s,X_d,lch,kb,T);
        TGR_ary(i) = TGR_Vorfaktor* Ttun_FH * Landauer * Efield_x ;
        TGR_ary_Michi(i) = TGR_Vorfaktor* Ttun_Michi * Landauer * Efield_Michi;
    end
    
%     TGR_ary = TGR_xmax.*exp( - (x_mesh_TGR - x_mesh_TGR).^2/(sigma2_B2B)^2 )
      
    Jy_y_out.TGR_compact.TGR_ary2 = 1 * TGR_xmax*exp(-(x_mesh_TGR-xmax_TGR).^2/(sigma2_B2B));
    
    Jy_y_out.TGR_compact.x_ary = x_mesh_TGR;
    Jy_y_out.TGR_compact.TGR_ary = TGR_ary;
    Jy_y_out.TGR_compact.TGR_ary_Michi = TGR_ary_Michi;
    Jy_y_out.TGR_compact.xmax_TGR = xmax_TGR;
    Jy_y_out.TGR_compact.TGR_xmax = TGR_Vorfaktor*TGR_xmax/q;
end          
%--------------------------------------------------------------------------

% Calculating compact band structure
    if ((TFET_Plot.Ttun == 1 || TFET_Plot.Ttun_GaAs || TFET_Plot.Ttun_Germanium || TFET_Plot.Ttun_SiliconGermanium)  && bool_plot_on)
        if (x_jun > lch/2)
            x_channel_y = lch/2:1e-10:lch;
            x_sd_y = lch:1e-10:x_ds_y;
            x_sd_const = x_ds_y:1e-10:(lch+20e-7);
        else
            x_sd_const = -20e-7:1e-10:x_ds_y;
            x_sd_y = x_ds_y:1e-10:0;
            x_channel_y = 0:1e-10:lch/2;
        end
        phi_sd_const = 0.*x_sd_const + phi_ds;
        phi_sd_y = a_y*x_sd_y.^2 + b_y*x_sd_y + c_y;
        phi_channel_y = k_y./(x_channel_y - l_y) + m_y;
        
%         for h = 1:length(x_channel_y)
%             phi_channel_y_michi(i) = func_potential_2D(x_channel_y(h),y,Phi_bi_eff_s)
%         end
        
        if (x_jun > lch/2)
            EC_sd_const = -phi_sd_const + Eg_d/2 + X_s - X_d;
            EV_sd_const = -phi_sd_const - Eg_d/2 + X_s - X_d;
            EC_sd_y = -phi_sd_y + Eg_d/2 + X_s - X_d;
            EV_sd_y = -phi_sd_y - Eg_d/2 + X_s - X_d;
        else
            EC_sd_const = -phi_sd_const + Eg_s/2;
            EV_sd_const = -phi_sd_const - Eg_s/2;
            EC_sd_y = -phi_sd_y + Eg_s/2;
            EV_sd_y = -phi_sd_y - Eg_s/2;
        end
        EC_channel_y = -phi_channel_y + Eg_ch/2 + X_s - X_ch;
        EV_channel_y = -phi_channel_y - Eg_ch/2 + X_s - X_ch;
        if (x_jun > lch/2)
            Jy_y_out.bands_compact.x_ary = [x_channel_y x_sd_y x_sd_const];
            Jy_y_out.bands_compact.EC_ary = [ EC_channel_y EC_sd_y EC_sd_const];
            Jy_y_out.bands_compact.EV_ary = [ EV_channel_y EV_sd_y EV_sd_const];            
            Jy_y_out.xmax = xmax_TGR;
            Jy_y_out.EC_xmax = -(k_y/(xmax_TGR - l_y) + m_y) + Eg_ch/2 + X_s - X_ch;
            Jy_y_out.EV_xmax = -(k_y/(xmax_TGR - l_y) + m_y) - Eg_ch/2 + X_s - X_ch;
            Jy_y_out.ltun = ltun_xmax;
            Jy_y_out.E_bh = E_bh_xmax;
            Jy_y_out.ltun_Michi = ltun_xmax_Michi;
            Jy_y_out.E_bh_Michi = E_bh_xmax_Michi;
            Jy_y_out.Ttun_xmax = Ttun_xmax;
            Jy_y_out.Ttun_xmax_Michi = Ttun_xmax_Michi;
        else
            Jy_y_out.bands_compact.x_ary = [ x_sd_const  x_sd_y x_channel_y];
            Jy_y_out.bands_compact.EC_ary = [ EC_sd_const EC_sd_y EC_channel_y];
            Jy_y_out.bands_compact.EV_ary = [ EV_sd_const EV_sd_y EV_channel_y];
            Jy_y_out.xmax = xmax_TGR;
            Jy_y_out.EC_xmax = -(k_y/(xmax_TGR - l_y) + m_y) + Eg_ch/2 + X_s - X_ch;
            Jy_y_out.EV_xmax = -(k_y/(xmax_TGR - l_y) + m_y) - Eg_ch/2 + X_s - X_ch;
            Jy_y_out.ltun = ltun_xmax;
            Jy_y_out.E_bh = E_bh_xmax;
            Jy_y_out.ltun_Michi = ltun_xmax_Michi;
            Jy_y_out.E_bh_Michi = E_bh_xmax_Michi;
            Jy_y_out.Ttun_xmax = Ttun_xmax;
            Jy_y_out.Ttun_xmax_Michi = Ttun_xmax_Michi;
        end
    end
    
    if TFET_Plot.y_potential
       y_ary = 0:1e-8:tch;
       
       if (strcmp(TFET_Plot.x_pos,string('xjun_s'))||strcmp(TFET_Plot.x_pos,string('xjun_d')))
           y_potential = f_jun.*abs(y_ary-tch/2).^e_y + phi_jun_cen;
       elseif (strcmp(TFET_Plot.x_pos,string('xch2')))
           y_potential = f_ch2.*abs(y_ary-tch/2).^e_y + phi_ch2_cen;
       end
        
       Jy_y_out.y_potential.y_ary = y_ary;
       Jy_y_out.y_potential.y_potential =  y_potential;
    end
    
    
end