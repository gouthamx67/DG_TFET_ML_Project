function [ x_Meas,y_Meas ] = func_Meas_import_Current(Vds,Vgs,type)
%% Function to import TCAD simulation data of the device current
%
% func_TCAD_import_Current(V_const,V_sweep,type)
%
% Inputs:
%--------------------------------------------------------------------------
% V_const - Constant voltage of the current sweep
% V_sweep - Voltage which is sweeped
% type    - type of current curve ('transfer'/'output') [string]
%--------------------------------------------------------------------------
%
% Outputs
%--------------------------------------------------------------------------
% x_TCAD - x-Data of the TCAD simulations
% y_TCAD - y-Data of the TCAD simulations
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
if(strcmp(type, 'n-type') && Vds <= 0.5 && Vds >= 0.1 ) || (strcmp(type, 'p-type') && Vds <= -0.1 && Vds >=-0.5 )

    % Round the  constant voltage in order to avoid numerical problems
        Vds_temp = round(1000*Vds)/1000;
    % Generate fileName of the csv-file in dependency of the constant
    % voltage and type
        if(strcmp(type, 'n-type'))
            fileName = sprintf('../02_TFET_Measurements/Juelich_Luong/transfer_nTFET_Juelich_meas.csv');
        else
            fileName = sprintf('../02_TFET_Measurements/Juelich_Luong/transfer_pTFET_Juelich_meas.csv');
        end
  
    % Import data from csv data
        Meas_Data = csvread(fileName,1,0);
    % Separate x-data containing V_sweep
    
        if abs(Vds_temp) == 0.5
            x_Meas_int = Meas_Data(:,1);
            y_Meas_int = Meas_Data(:,2);
        elseif abs(Vds_temp) == 0.3
            x_Meas_int = Meas_Data(:,3);
            y_Meas_int = Meas_Data(:,4);
        else
            x_Meas_int = Meas_Data(:,5);
            y_Meas_int = Meas_Data(:,6);
        end
        
    % Calculating the minimum value of V_sweep
        if min(Vgs) >= x_Meas_int(1)
            V_sweep_min = min(Vgs);
        else
            V_sweep_min = x_Meas_int(end);
        end
    % Calculating the maximum value of V_sweep
        if max(Vgs) <= x_Meas_int(end)
            V_sweep_max = max(Vgs);
        else
            V_sweep_max = x_Meas_int(1);
        end
    % Read out TCAD data from V_sweep_min to V_sweep_max
        if(length(Vgs)==1)
            j = 1;
            for i = 1:length(x_Meas_int)
               if(x_Meas_int(i) >= (Vgs-0.2) && x_Meas_int(i) <= (Vgs+0.2))
                  x_Meas(j) = x_Meas_int(i);
                  y_Meas(j) = y_Meas_int(i);
                  j = j + 1;
               end 
            end
        else
            j = 1;
            for i = 1:length(x_Meas_int)
               if(x_Meas_int(i) >= V_sweep_min && x_Meas_int(i) <= V_sweep_max)
                  x_Meas(j) = x_Meas_int(i);
                  y_Meas(j) = y_Meas_int(i);
                  j = j + 1;
               end 
            end
        end
else
    disp('Bias out of Range!')
    x_Meas = zeros(1,length(Vgs));
    y_Meas = zeros(1,length(Vgs));
end
end

