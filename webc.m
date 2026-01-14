clc;
clear;
close all;

disp('--- PROJECT STARTED ---');

%% =========================================================
% STEP 1: LOAD TERRAIN IMAGE
% =========================================================
img = imread('ldsldriskt.jpg');   % <-- insert terrain image here

figure;
imshow(img);
title('Uploaded Terrain Image');

%% =========================================================
% STEP 2: PREPROCESS IMAGE
% =========================================================
gray = rgb2gray(img);
gray = imgaussfilt(gray, 1.5);

%% =========================================================
% STEP 3: REMOVE SKY REGION (TOP PART)
% =========================================================
[h, w] = size(gray);
groundMask = false(h, w);
groundMask(round(h*0.45):end, :) = true;   % bottom 55% only

%% =========================================================
% STEP 4: EDGE DETECTION (GROUND ONLY)
% =========================================================
edges = edge(gray, 'Canny');
edges = edges & groundMask;

figure;
imshow(edges);
title('Ground Terrain Edges');

%% =========================================================
% STEP 5: REMOVE VERTICAL OBJECT EDGES (TREES, POLES)
% =========================================================
[~, Gdir] = imgradient(gray);     % gradient direction in degrees
edgeAngles = abs(Gdir(edges));

% Remove near-vertical edges (>80°)
edgeAngles(edgeAngles > 80) = [];

%% =========================================================
% STEP 6: ESTIMATE TERRAIN SLOPE (ORIENTATION-BASED)
% =========================================================
meanAngle = mean(edgeAngles, 'omitnan');

% Map orientation dominance → terrain slope
if isempty(meanAngle) || meanAngle < 10
    slopeDeg = 2;          % Plain land
elseif meanAngle < 20
    slopeDeg = 8;          % Gentle slope
elseif meanAngle < 35
    slopeDeg = 18;         % Hill
elseif meanAngle < 50
    slopeDeg = 30;         % Steep hill
else
    slopeDeg = 45;         % Cliff
end

fprintf('\n--- IMAGE-BASED TERRAIN FEATURE ---\n');
fprintf('Estimated Terrain Slope : %.2f degrees\n', slopeDeg);

%% =========================================================
% STEP 7: LOGIC-AWARE SYNTHETIC TRAINING DATA (2000)
% =========================================================
rng(10);
N = 2000;

X = zeros(N,4);   % [Rainfall Slope Elevation Soil]
Y = strings(N,1);

for i = 1:N
    r = rand;

    if r < 0.33
        % -------- NO DISASTER --------
        rainfall = rand*40;
        slope    = rand*5;
        elev     = 200 + rand*300;
        soil     = randi([1 3]);
        label    = "NoDisaster";

    elseif r < 0.66
        % -------- FLOOD --------
        rainfall = 180 + rand*250;
        slope    = rand*8;
        elev     = rand*150;
        soil     = randi([1 2]);
        label    = "Flood";

    else
        % -------- LANDSLIDE --------
        rainfall = 100 + rand*200;
        slope    = 25 + rand*20;
        elev     = 500 + rand*900;
        soil     = randi([2 3]);
        label    = "Landslide";
    end

    X(i,:) = [rainfall slope elev soil];
    Y(i)   = label;
end

Y = categorical(Y);

disp('Training data generated.');

%% =========================================================
% STEP 8: TRAIN ML MODEL
% =========================================================
mlModel = TreeBagger(150, X, Y, ...
    'Method','classification', ...
    'OOBPrediction','On');

disp('Machine Learning model trained.');

%% =========================================================
% STEP 9: ML CONVERGENCE CHECK
% =========================================================
figure;
plot(oobError(mlModel),'LineWidth',2);
xlabel('Trees');
ylabel('OOB Error');
title('ML Learning Convergence');
grid on;

%% =========================================================
% STEP 10: CURRENT REAL-WORLD INPUT
% =========================================================
rainfallNow  = 80;    % mm (example)
elevationNow = 300;   % meters
soilType     = 2;     % laterite

currentCondition = [rainfallNow slopeDeg elevationNow soilType];

%% =========================================================
% STEP 11: ML PREDICTION
% =========================================================
[predictedClass, scores] = predict(mlModel, currentCondition);

classNames = mlModel.ClassNames(:);
probabilities = scores(:) * 100;

%% =========================================================
% STEP 12: REAL-WORLD PHYSICS CORRECTION
% =========================================================
if rainfallNow > 200 && slopeDeg < 8
    probabilities(strcmp(classNames,'Flood')) = ...
        probabilities(strcmp(classNames,'Flood')) + 20;
end

if slopeDeg > 25 && rainfallNow > 100
    probabilities(strcmp(classNames,'Landslide')) = ...
        probabilities(strcmp(classNames,'Landslide')) + 30;
end

if rainfallNow < 40 && slopeDeg < 5
    probabilities(strcmp(classNames,'NoDisaster')) = ...
        probabilities(strcmp(classNames,'NoDisaster')) + 25;
end

probabilities(probabilities < 0) = 0;
probabilities = probabilities / sum(probabilities) * 100;

%% =========================================================
% STEP 13: DISPLAY RESULTS
% =========================================================
disp(' ');
disp('--- FINAL PREDICTION ---');

[~, idx] = max(probabilities);
disp(['Predicted Disaster: ', char(classNames(idx))]);

resultTable = table(classNames, probabilities, ...
    'VariableNames', {'DisasterType','Probability_%'});
disp(resultTable);

%% =========================================================
% STEP 14: VISUALIZATION
% =========================================================
figure;
bar(probabilities);
ylim([0 100]);
xticklabels(classNames);
ylabel('Probability (%)');
title('Image-Based Terrain + ML Disaster Prediction');
grid on;

for i = 1:length(probabilities)
    text(i, probabilities(i)+2, ...
        sprintf('%.1f%%', probabilities(i)), ...
        'HorizontalAlignment','center');
end

disp('--- PROJECT COMPLETED SUCCESSFULLY ---');
