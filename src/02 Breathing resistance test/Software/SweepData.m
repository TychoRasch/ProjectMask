clean %Clean up workspace 
% Matlab file to process breathing resistance measurement data

%%%%%%%%%%%%%%%%%%%%%%% 
% addpath('directory measurement data files')
addpath('Validation')
% filename = 'Name of data file you want to analyze'
filename = 'output_sample_OPENFLOW_setup_2_2020_04_07_13_18_12.csv';
%%%%%%%%%%%%%%%%%%%%%%%%




[FlowSensor, PressureSensor] = importfile(filename);
d1 = 12e-3;                         % Narrow tube diameter [m]
d2 = 33e-3;                         % Inlet (wide) tube diameter [m]
rhoL = 1.2;                         % Density air [kg/m³]

Vdd     = 5;                            % Control voltage [V]
Analog1 = 5/1023*FlowSensor;            % Analog output value 1 [V]
Analog2 = 5/1023*PressureSensor;        % Analog output value 2 [V]

% If the pressure sensor is used squared
dP1 = ((Analog1./(Vdd.*0.4))-1.25).^2.*525;  % Pressure difference 1 [Pa]
dP2 = ((Analog2./(Vdd.*0.4))-1.25).^2.*525;  % Pressure difference 2 [Pa]

% Remove the nan shit from your data
 dP1 = dP1(~isnan(dP1));
 dP2 = dP2(~isnan(dP2));

% If the supply is another tube
Q = pi/4*d1^2.*sqrt((2.*abs(dP1))./(rhoL*(1-(d1/d2)^4)))*60e3;        %Flow [L/min]

figure(1)
plot(Q,dP2,'.','LineWidth', 1.2)
xlabel('Airflow [L/min]','FontSize', 17); ylabel('Static Pressure [Pa]','FontSize', 17); title('Open flow','FontSize', 17);
hold on
