clear all
close all
clc
%% define constants

d1 = 13.6e-3;
d2 = 25e-3;


%% prompting which setup is used
sample = input('Which sample was being used? : ');
%setup = input('Which setup was being used? : ');

setup=10;

if (sample<10)
    sample = ['00', num2str(sample)];
elseif (sample>=10 && sample<100)
    sample = ['0', num2str(sample)];
elseif (sample>=10 && sample<100)
    sample = [num2str(sample)];    
end

example_name = ['output_sample_',sample,'*.csv'];
files = dir(example_name);

example_name = ['CO2_Test_',sample,'*.csv'];
filesCO2 = dir(example_name);

if length(files) == 1
    file_name = files(1).name;
elseif length(filesCO2) == 1
    file_name = files(1).name;
else
    disp('File not found, select file:');
    Names = dir();
    for i = 3:length((Names))
        disp([num2str(i),' ',Names(i).name]);
    end
    i = input('Please select which file you want to use: ');
    file_name = Names(i).name;
end

% file_name = 'output_sample_000_setup_4_2020_04_07_12_09_41.csv';
%% import data
data = readtable(file_name);

%% Find the index where the data becomes proper
for i = 1:height(data)-3
    if contains(data{i,3}, 'Analog value: ') && strlength(data{i,3}) == 17
        if contains(data{i+1,3}, 'Sensor 1:  Z ') && strlength(data{i+1,3}) == 26
            if contains(data{i+2,3}, 'Sensor 2:  Z ') && strlength(data{i+2,3}) == 26
                index = i;
                break
            end
        end
    end
end

%% Split all the data in the desired data
c = floor((height(data)-index)/3);

for i = 0:c-1
    % extract the time stamp in cell aray form
    t_analog = data{index+3*i,2};
    t_sensor1 = data{index+1+3*i,2};
    t_sensor2 = data{index+2+3*i,2};
    
    % convert cell aray and insert into array as double
    analog(i+1,1) = t_analog;
    sensor1(i+1,1) = t_sensor1;
    sensor2(i+1,1) = t_sensor2;
    
    
    t_analog = data{index+3*i,3};
    temp_c_sensor1 = data{index+1+3*i,3};
    temp_c_sensor2 = data{index+2+3*i,3};   
     
    % extract large Z and small z value from sensor 1
    for k = 1 : length(t_analog)
    cellContents = t_analog{k};
    % Truncate and stick back into the cell
    analog1 = cellContents(15:17);
    end
    
    % extract large Z and small z value from sensor 1
    % extract large Z and small z value from sensor 1
    for k = 1 : length(temp_c_sensor1)
    cellContents = temp_c_sensor1{k};
    % Truncate and stick back into the cell
    Z_sensor1 = cellContents(13:18);
    z_sensor1 = cellContents(22:26);
    end
   
    % extract large Z and small z value from sensor 2
    for k = 1 : length(temp_c_sensor2)
    cellContents = temp_c_sensor2{k};
    % Truncate and stick back into the cell
    Z_sensor2 = cellContents(13:18);
    z_sensor2 = cellContents(22:26);
    end
    
    %save all the found values as a double in the string
    analog(i+1,2) = str2double(analog1);
    sensor1(i+1,2) = str2double(Z_sensor1);
    sensor2(i+1,2) = str2double(Z_sensor2);
    
    sensor1(i+1,3) = str2double(z_sensor1);
    sensor2(i+1,3) = str2double(z_sensor2);
end

%% Do data processing
voltage = analog(:,2)./1023.*5;

%dP = (voltage ./ (2.0) - 1.25).^2 .* 525.0;
dP = sign(voltage/5 -0.5).*((voltage/(5*0.4))-1.25).^2*525;
% for i=1:length(dP)
%     if(dP(i)<0)
%     dP(i) = dP(i)/0.25;
%     end
% end

Q = 60e3*pi/4*d1.^2.*sqrt(2.*abs(dP)/(1.20.*(1-(d1./d2).^4)));
Q = sign(voltage/5-0.5).*Q;
Q(Q<0) = 0;


% for i=1:length(Q)
%     if(Q(i)<0)
%     Q(i) = Q(i)/0.48;
%     end
% end

%% Breating freq
Location1 = find(Q>25);
Location1(Location1==1) = '';
Location2 = find(Q(Location1-1)<25);
TimestampsNeg = analog((Location1(Location2))',1);
LocationsNeg = Location1(Location2);

Location1 = find(Q<25);
Location1(Location1==1) = '';
Location2 = find(Q(Location1-1)>25);
TimestampsPos = analog((Location1(Location2))',1);
LocationsPos = Location1(Location2);

Difference = [0;TimestampsNeg]-[TimestampsNeg;0];
Difference(end) = '';
disp(['Breathing rate is ',num2str(-60/mean(Difference)),' cycles/min']);

try
Qexhale = mean(Q(Q>25));    
Qinhale = mean(Q(Q<-25));

Tot = sort([TimestampsNeg;TimestampsPos]);
DifferenceTot = [Tot;0]-[0;Tot]; DifferenceTot(end)='';

EvenDiff=[];OddDiff=[];i=1;
while i<length(DifferenceTot-1)
   EvenDiff(end+1) = DifferenceTot(i+1);
   OddDiff(end+1)  = DifferenceTot(i);
   i=i+2;
end

if(TimestampsNeg(1)>TimestampsPos(1))
 DifferenceInhale = mean(EvenDiff);
 DifferenceExhale = mean(OddDiff(2:end));
else
 DifferenceExhale = mean(EvenDiff);
 DifferenceInhale = mean(OddDiff(2:end)); 
end

disp(['Inhale duration is: ',num2str(mean(DifferenceInhale)), ' seconds, Volume is ',num2str(-Qinhale/60*mean(DifferenceInhale)) ' L']);
disp(['Exhale duration is: ',num2str(mean(DifferenceExhale)), ' seconds, Volume is ',num2str(Qexhale/60*mean(DifferenceExhale)) ' L']);

catch
    disp('No in-out could be calculated')
end
Sensor2 = sensor2(:,2);  
Sensor1 = sensor1(:,2);

disp(['Inhale CO_2 concentration is: ',num2str(mean(Sensor2(Sensor2>mean(Sensor2)))/1000), ' %']);
disp(['Exhale CO_2 concentration is: ',num2str(mean(Sensor1(Sensor2>mean(Sensor2)))/1000), ' %']);


A = [DifferenceInhale,-Qinhale/60*mean(DifferenceInhale),DifferenceExhale,Qexhale/60*mean(DifferenceExhale),-60/mean(Difference)];
B = [(mean(Sensor2(Sensor2>mean(Sensor2)))/1000),(mean(Sensor1(Sensor2>mean(Sensor2)))/1000),(Qexhale/60*mean(DifferenceExhale))];

%% Plot some data

figure();
%plot(analog(:,1), A);
%plot(sensor1(:,1), sensor1(:,2)/1000);
plot(sensor1(:,2)/1000);
hold on
%plot(sensor2(:,1), sensor2(:,2)/1000);
plot(sensor2(:,2)/1000);
ylabel('CO2 volume [%]');
yyaxis right
%plot(analog(:,1), Q);
plot(Q);
xlabel('Elapsed time [s]');
legend('Exhale CO2','Inhale CO2','Flow rate');
ylabel('Flow rate [L/min]');