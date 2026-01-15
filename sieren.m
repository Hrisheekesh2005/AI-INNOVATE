clc;
clear;
close all;

disp('--- PROJECT STARTED ---');

%% =========================================================
% STEP 1: LOAD TERRAIN IMAGE
% =========================================================
img = imread('ldsldriskt.jpg');

figure;
imshow(img);
title('Uploaded Terrain Image');

%% =========================================================
% STEP 2: PREPROCESS IMAGE
% =========================================================
gray = rgb2gray(img);
gray = imgaussfilt(gray, 1.5);

%% =========================================================
% STEP 3: REMOVE SKY REGION
% =========================================================
[h, w] = size(gray);
groundMask = false(h, w);
groundMask(round(h*0.45):end, :) = true;

%% =========================================================
% STEP 4: EDGE DETECTION (GROUND ONLY)
% =========================================================
edges = edge(gray, 'Canny');
edges = edges & groundMask;

figure;
imshow(edges);
title('Ground Terrain Edges');

%% =========================================================
% STEP 5: REMOVE VERTICAL OBJECT EDGES
% =========================================================
[~, Gdir] = imgradient(gray);
edgeAngles = abs(Gdir(edges));
edgeAngles(edgeAngles > 80) = [];

%% =========================================================
% STEP 6: ESTIMATE TERRAIN SLOPE
% =========================================================
meanAngle = mean(edgeAngles, 'omitnan');

if isempty(meanAngle) || meanAngle < 10
    slopeDeg = 2;
elseif meanAngle < 20
    slopeDeg = 8;
elseif meanAngle < 35
    slopeDeg = 18;
elseif meanAngle < 50
    slopeDeg = 30;
else
    slopeDeg = 45;
end

fprintf('\nEstimated Terrain Slope : %.2f degrees\n', slopeDeg);

%% =========================================================
% STEP 7: LOGIC-AWARE SYNTHETIC TRAINING DATA (2000)
% =========================================================
rng(10);
N = 2000;

X = zeros(N,4);
Y = strings(N,1);

for i = 1:N
    r = rand;

    if r < 0.33
        rainfall = rand*40;
        slope    = rand*5;
        elev     = 200 + rand*300;
        soil     = randi([1 3]);
        label    = "NoDisaster";

    elseif r < 0.66
        rainfall = 180 + rand*250;
        slope    = rand*8;
        elev     = rand*150;
        soil     = randi([1 2]);
        label    = "Flood";

    else
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

%% =========================================================
% STEP 8: TRAIN ML MODEL
% =========================================================
mlModel = TreeBagger(150, X, Y, ...
    'Method','classification', ...
    'OOBPrediction','On');

disp('Machine Learning model trained.');

%% =========================================================
% STEP 9: ML CONVERGENCE
% =========================================================
figure;
plot(oobError(mlModel),'LineWidth',2);
xlabel('Trees');
ylabel('OOB Error');
title('ML Learning Convergence');
grid on;

%% =========================================================
% STEP 10: CURRENT CONDITIONS
% =========================================================
rainfallNow  = 120;
elevationNow = 300;
soilType     = 2;

currentCondition = [rainfallNow slopeDeg elevationNow soilType];

%% =========================================================
% STEP 11: ML PREDICTION
% =========================================================
[~, scores] = predict(mlModel, currentCondition);
classNames = mlModel.ClassNames(:);
probabilities = scores(:) * 100;

%% =========================================================
% STEP 12: PHYSICS-BASED CORRECTION
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

probabilities = max(probabilities,0);
probabilities = probabilities / sum(probabilities) * 100;

%% =========================================================
% STEP 13: DISPLAY PROBABILITIES
% =========================================================
disp('--- FINAL PREDICTION ---');
resultTable = table(classNames, probabilities, ...
    'VariableNames', {'DisasterType','Probability_%'});
disp(resultTable);

figure;
bar(probabilities);
ylim([0 100]);
xticklabels(classNames);
ylabel('Probability (%)');
title('ML-Based Disaster Probability');
grid on;

%% =========================================================
% STEP 14: ALERT GENERATION
% =========================================================
floodProb     = probabilities(strcmp(classNames,'Flood'));
landslideProb = probabilities(strcmp(classNames,'Landslide'));

alertLevel  = "GREEN ALERT";
alertReason = "Terrain and weather conditions are stable.";

if (floodProb >= 70 && rainfallNow >= 180 && elevationNow <= 200)
    alertLevel  = "RED ALERT";
    alertReason = "Extreme flood risk due to heavy rainfall.";

elseif (landslideProb >= 60 && slopeDeg >= 25 && rainfallNow >= 100)
    alertLevel  = "RED ALERT";
    alertReason = "High landslide risk due to steep slope and rainfall.";

elseif (floodProb >= 40)
    alertLevel  = "ORANGE ALERT";
    alertReason = "Moderate flood risk. Stay alert.";

elseif (landslideProb >= 30)
    alertLevel  = "ORANGE ALERT";
    alertReason = "Moderate landslide risk. Monitoring advised.";
end

disp('--- ALERT STATUS ---');
disp(['Alert Level : ', alertLevel]);
disp(['Reason      : ', alertReason]);

%% =========================================================
% STEP 15: FULL BACKGROUND COLOR ALERT DISPLAY
% =========================================================
figure;

switch alertLevel
    case "RED ALERT"
        set(gcf,'Color',[1 0 0]);
    case "ORANGE ALERT"
        set(gcf,'Color',[1 0.65 0]);
    otherwise
        set(gcf,'Color',[0 1 0]);
end

axes('Position',[0 0 1 1]);
axis off;

text(0.5,0.6,alertLevel,'FontSize',36,'FontWeight','bold',...
     'HorizontalAlignment','center','Color','k');
text(0.5,0.45,alertReason,'FontSize',16,...
     'HorizontalAlignment','center','Color','k');

title('Disaster Alert System','FontSize',18,'FontWeight','bold');

%% =========================================================
% STEP 16: RISK INDEX (0–100)
% =========================================================
riskIndex = 0.5*floodProb + 0.4*landslideProb + ...
            0.1*(100 - probabilities(strcmp(classNames,'NoDisaster')));

riskIndex = min(max(riskIndex,0),100);

disp(['Risk Index (0–100): ', num2str(riskIndex,'%0.1f')]);

%% =========================================================
% STEP 17: SIREN SOUND (RED ALERT ONLY)
% =========================================================
if alertLevel == "RED ALERT"
    Fs = 8000;
    t = 0:1/Fs:1;
    siren = sin(2*pi*800*t) + sin(2*pi*1200*t);
    sound(siren, Fs);
end

%% =========================================================
% STEP 18: 3-DAY EARLY WARNING FORECAST
% =========================================================
rainForecast = rainfallNow + [0 40 80];
days = {'Today','Day 2','Day 3'};
riskForecast = zeros(1,3);

for d = 1:3
    tempRain = rainForecast(d);
    riskForecast(d) = min( ...
        0.5*(tempRain/250*100) + ...
        0.4*(slopeDeg/45*100) + ...
        0.1*(100 - probabilities(strcmp(classNames,'NoDisaster'))), 100);
end

figure;
plot(riskForecast,'-o','LineWidth',2);
xticks(1:3);
xticklabels(days);
ylabel('Risk Index (0–100)');
xlabel('Time');
title('3-Day Early Warning Risk Forecast');
grid on;

for i = 1:3
    text(i, riskForecast(i)+2, sprintf('%.1f',riskForecast(i)),...
        'HorizontalAlignment','center');
end

disp('--- PROJECT COMPLETED SUCCESSFULLY ---');
