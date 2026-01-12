clc;
clear;
close all;
% Historical environmental conditions
%1 = Clay
%2 = Laterite
%3 = Sandy / loose soil
Rainfall_mm = [50; 80; 120; 160; 200; 220; 90; 140; 180; 60];
Slope_deg   = [5; 10; 15; 25; 35; 40; 8; 20; 30; 6];
Elevation_m = [100; 200; 400; 700; 900; 1200; 150; 500; 800; 120];
SoilType    = [1; 1; 2; 2; 3; 3; 1; 2; 3; 1];
% Disaster outcome
% 0 = No disaster
% 1 = Flood
% 2 = Landslide
DisasterType = categorical([ ...
    0; 0; 1; 1; 2; 2; 0; 1; 2; 0], ...
    [0 1 2], ...
    {'NoDisaster','Flood','Landslide'});
historicalData = table( ...
    Rainfall_mm, Slope_deg, Elevation_m, SoilType, DisasterType);

disp(historicalData);


%STEP 2

X = [Rainfall_mm, Slope_deg, Elevation_m, SoilType];
Y = DisasterType;
mlModel = fitctree(X, Y);
view(mlModel, 'Mode', 'graph');


%step3 predict future

currentRainfall  = 170;   % mm
currentSlope     = 36;    % degrees
currentElevation = 800;   % meters
currentSoil      = 2;     % sandy

currentInput = [ ...
    currentRainfall, ...
    currentSlope, ...
    currentElevation, ...
    currentSoil];
predictedDisaster = predict(mlModel, currentInput);

disp("Predicted Outcome:");
disp(predictedDisaster);

%step 4

[~, probability] = predict(mlModel, currentInput);

probTable = table( ...
    mlModel.ClassNames, ...
    probability', ...
    'VariableNames', {'DisasterType','Probability'});

disp(probTable);
