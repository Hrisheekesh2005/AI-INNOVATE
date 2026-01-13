clc;
clear;
close all;

%step 2
% Known historical disaster samples
Rainfall_mm = [45; 60; 80; 100; 120; 150; 180; 210];
Slope_deg   = [4; 6; 8; 12; 15; 20; 28; 35];
Elevation_m = [80; 120; 200; 300; 400; 600; 850; 1100];
SoilType    = [1; 1; 2; 2; 2; 3; 3; 3];  % 1=Clay,2=Laterite,3=Sandy

Disaster = categorical([ ...
    "NoDisaster";
    "NoDisaster";
    "Flood";
    "Flood";
    "Flood";
    "Flood";
    "Landslide";
    "Landslide"]);

%step 3 small data base

baseData = table( ...
    Rainfall_mm, Slope_deg, Elevation_m, SoilType, Disaster);

disp(baseData);

%step 4 :1500 datas for tranning ml

rng(10);        % for reproducibility
N = 1500;       % number of generated samples

synRain = zeros(N,1);
synSlope = zeros(N,1);
synElev = zeros(N,1);
synSoil = zeros(N,1);
synDisaster = strings(N,1);

for i = 1:N
    idx = randi(height(baseData));

    synRain(i) = baseData.Rainfall_mm(idx) + randn*10;
    synSlope(i) = baseData.Slope_deg(idx) + randn*2;
    synElev(i) = baseData.Elevation_m(idx) + randn*50;
    synSoil(i) = baseData.SoilType(idx);
    synDisaster(i) = string(baseData.Disaster(idx));
end

%step5 clipping data to real ones

synRain = max(min(synRain,300),20);
synSlope = max(min(synSlope,45),1);
synElev = max(min(synElev,1500),50);
synSoil = max(min(synSoil,3),1);

synDisaster = categorical(synDisaster);

%step6 training dataset
trainingData = table( ...
    synRain, synSlope, synElev, synSoil, synDisaster, ...
    'VariableNames', ...
    {'Rainfall_mm','Slope_deg','Elevation_m','SoilType','Disaster'});

disp(trainingData(1:10,:));

%step7 input and output for ml

X = trainingData{:,1:4};   % inputs
Y = trainingData.Disaster; % labels

%step 8 train ml model
mlModel = TreeBagger(100, X, Y, ...
    'Method','classification', ...
    'OOBPrediction','On');
%step 9 verify ml learning
figure;
plot(oobError(mlModel));
xlabel('Number of Trees');
ylabel('Out-of-Bag Error');
title('ML Learning Convergence');
grid on;

% step 10 predict future
currentCondition = [210 6 120 2];
[predictedClass, scores] = predict(mlModel, currentCondition);

disp("Predicted Disaster:");
disp(predictedClass);


%step 11 early warning
classNames = mlModel.ClassNames(:);
probValues = scores(:);

probabilityTable = table( ...
    classNames, probValues*100, ...
    'VariableNames', {'DisasterType','Probability_%'});

disp(probabilityTable);

%step 12 visualization of result
figure;
bar(probValues*100);
xticklabels(classNames);
ylabel('Probability (%)');
title('ML-Based Disaster Probability');
grid on;







