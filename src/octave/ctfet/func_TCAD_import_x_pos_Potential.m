function [phi_x_pos] = func_TCAD_import_x_pos_Potential(Vd,Vg,x_pos,position)
%% Function to import TCAD simulation data of the electrostatic potential,
% the electric field or the band structure at one specific x-position
%
% func_TCAD_import_x_pos_Potential(Vd,Vg,x_pos,position)
%
% Inputs:
%--------------------------------------------------------------------------
% Vd        - considered drain bias
% Vg        - considered gate bias
% x_pos     - specific x-position
% position  - position of the TCAD data (surface/center) [string]
%--------------------------------------------------------------------------
%
% Outputs
%--------------------------------------------------------------------------
% phi_x_pos - electrostatic potential at the specific x-position
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
% Round the  constant voltage in order to avoid numerical problems
    Vd_temp = round(1000*Vd)/1000;
    Vg_temp = round(1000*Vg)/1000;

% Checking the range of the handover bias values
    if (Vd_temp >= -0.7) && (Vd_temp <= 1)
        if (Vg_temp >= -2 && Vg_temp <= 2)  

        % Creating the filename in dependency of the inputs
            fileName = sprintf('../00_TCAD_Simulation_Data/Potential_Bands/%s_Potential_Bands_Vd_%.3f_Vg_%.2f.csv',position,round(Vd_temp,3),round(Vg_temp,3));

        % Import CSV data with the help of the created filename
            TCAD_Data = csvread(fileName,2,0);

        % Read out the x-axis
            x_TCAD = 1e-4*TCAD_Data(:,4);

        % Read out the potential
            pot_band_TCAD = TCAD_Data(:,1);  % Potential

        % Select the potential at the x_pos
            for i = 1:length(x_TCAD)        
                if ((x_TCAD(i) <= x_pos+1e-10)&&(x_TCAD(i) >= x_pos-1e-10))
                    phi_x_pos = pot_band_TCAD(i);
                end
            end
        else
            disp('Bias out of range!')
        end
        
    else
        disp('Bias out of range!')
        phi_x_pos =0;
    end
end

