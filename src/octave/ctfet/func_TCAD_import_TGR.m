function [x_TCAD,TGR_TCAD] = func_TCAD_import_TGR(Vd,Vg,position,eTGR_or_hTGR)
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
% eTGR_or_hTGR - select electron or hole TGR (eTGR / hTGR) [string]
%--------------------------------------------------------------------------
%
% Outputs
%--------------------------------------------------------------------------
% x_TCAD - x-data from TCAD at the chosen y-position
% TGR_TCAD - y-data (electron or hole TGR)
%                  from TCAD at the chosen y-position
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
% Round the  constant voltage in order to avoid numerical problems
    Vd_temp = round(1000*Vd)/1000;
    Vg_temp = round(1000*Vg)/1000;
% Checking the range of the handover bias values
    if (Vd_temp >= 0) && (Vd_temp <= 0.7)
        if (Vg_temp >= -2 && Vg_temp <= 2)
        % Creating the filename in dependency of the inputs
        
        fileName = sprintf('../00_TCAD_Simulation_Data/TGR/%s_TGR_Vd_%.3f_Vg_%.2f.csv',position,Vd_temp,Vg_temp);
        % Import CSV data with the help of the created filename
            TCAD_Data = csvread(fileName,2,0);

        % Read out the x-axis
            x_TCAD = 1e-4*TCAD_Data(:,3);

        % Read out the potential or the band structure.
            if (strcmp(eTGR_or_hTGR,string('eTGR')))
                TGR_TCAD = TCAD_Data(:,1);  % electron TGR              
            elseif (strcmp(eTGR_or_hTGR,string('hTGR')))
                TGR_TCAD = TCAD_Data(:,2);  % hole TGR
            else
                TGR_TCAD = zeros(length(x_TCAD),1); % Null
            end
        else
            disp('Bias out of range!')
        end
    else
        disp('Bias out of range!')
        x_TCAD = 0;
        TGR_TCAD = 0;   
    end
end

