function [x_TCAD,pot_efield_band_TCAD_1,pot_efield_band_TCAD_2] = func_TCAD_import_Potential_Gate_Underlap(Vd,Vg,position,lg)
%% Function to import TCAD simulation data of the electrostatic potential,
% the electric field or the band structure at the channel's surface or center
%
% func_TCAD_import_Potential_Efield_and_Bands(Vd,Vg,position,potential_efield_or_bands)
%
% Inputs:
%--------------------------------------------------------------------------
% Vd - considered drain bias
% Vg - considered gate bias
% position - position of the TCAD data (surface/center) [string]
% potential_efield_or_bands - select electrostatic potential or band
%                             structure (potential/efield/bands) [string]
%--------------------------------------------------------------------------
%
% Outputs
%--------------------------------------------------------------------------
% x_TCAD - x-data from TCAD at the chosen y-position
% pot_efield_band_TCAD_1 - first y-data (potential, efield or bands)
%                  from TCAD at the chosen y-position
% pot_efield_band_TCAD_2 - second y-data (potential, efield or bands)
%                  from TCAD at the chosen y-position
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
% Round the  constant voltage in order to avoid numerical problems
    Vd_temp = round(1000*Vd)/1000;
    Vg_temp = round(1000*Vg)/1000;
% Checking the range of the handover bias values
    if (Vd_temp >= 0) && (Vd_temp <= 1) 
        if (Vg_temp >= -2 && Vg_temp <= 3)
        % Creating the filename in dependency of the inputs
            fileName = sprintf('N:/synopsys_work/01_TFET_Gate_Underlap/Export/potential_%s_lg_10,12,14.csv',position);

        % Import CSV data with the help of the created filename
            TCAD_Data = csvread(fileName,2,0);

        % Read out the x-axis
            x_TCAD = 1e-4*TCAD_Data(:,1)-20e-7;

        % Read out the potential or the band structure.
            if lg == 10e-7
                pot_efield_band_TCAD_1 = TCAD_Data(:,2);  % Potential
                pot_efield_band_TCAD_2 = zeros(length(x_TCAD),1); % Null
            elseif lg == 12e-7
                pot_efield_band_TCAD_1 = TCAD_Data(:,4);  % Ec
                pot_efield_band_TCAD_2 = zeros(length(x_TCAD),1); % Null
            elseif lg == 14e-7
                pot_efield_band_TCAD_1 = TCAD_Data(:,6);  % Efield
                pot_efield_band_TCAD_2 = zeros(length(x_TCAD),1); % Null
            else
                pot_efield_band_TCAD_1 = zeros(length(x_TCAD),1); % Null
                pot_efield_band_TCAD_2 = zeros(length(x_TCAD),1); % Null
            end
        else
            disp('Bias out of range!')
            x_TCAD = 0;
            pot_efield_band_TCAD_1 = 0;
            pot_efield_band_TCAD_2 = 0;  
        end
    else
        disp('Bias out of range!')
        x_TCAD = 0;
        pot_efield_band_TCAD_1 = 0;
        pot_efield_band_TCAD_2 = 0;        
    end
end

