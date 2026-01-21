clc;
clear;
close all;

disp('--- PROJECT STARTED (API-BASED SLOPE & ELEVATION) ---');

%% =========================================================
% STEP 1: INPUT LOCATION (LATITUDE & LONGITUDE)
% =========================================================
lat = 11.411975;
lon = 76.695462;

fprintf('Location → Lat: %.4f | Lon: %.4f\n', lat, lon);

%% =========================================================
% STEP 2: DEFINE NEARBY POINTS (~100 m OFFSET)
% =========================================================
delta = 0.0009;   % ≈100 meters

points = [
    lat,         lon;
    lat+delta,   lon;
    lat-delta,   lon;
    lat,         lon+delta;
    lat,         lon-delta
];

labels = {'Center','North','South','East','West'};
elev = zeros(5,1);

%% =========================================================
% STEP 3: FETCH ELEVATION USING API
% =========================================================
for i = 1:5
    apiURL = sprintf( ...
        'https://api.opentopodata.org/v1/srtm90m?locations=%.6f,%.6f', ...
        points(i,1), points(i,2));

    try
        data = webread(apiURL);
        elev(i) = data.results(1).elevation;
    catch
        warning('API error. Using fallback elevation.');
        elev(i) = mean(elev(max(i-1,1):i));
    end

    fprintf('%s Elevation: %.2f m\n', labels{i}, elev(i));
    pause(1.2);   % avoid API rate limit
end

elevationNow = elev(1);

%% =========================================================
% STEP 4: COMPUTE SLOPE (PHYSICS-BASED)
% =========================================================
d = 100;   % meters

slopeN = atand(abs(elev(2) - elev(1)) / d);
slopeS = atand(abs(elev(1) - elev(3)) / d);
slopeE = atand(abs(elev(4) - elev(1)) / d);
slopeW = atand(abs(elev(1) - elev(5)) / d);

slopeDeg = max([slopeN slopeS slopeE slopeW]);

fprintf('\nComputed Slopes (deg): N %.2f | S %.2f | E %.2f | W %.2f\n', ...
        slopeN, slopeS, slopeE, slopeW);
fprintf('FINAL TERRAIN SLOPE: %.2f degrees\n', slopeDeg);

%% =========================================================
% STEP 5: SYNTHETIC TRAINING DATA (2000)
% =========================================================
rng(10);
N = 2000;

X = zeros(N,4);   % [Rainfall Slope Elevation Soil]
Y = strings(N,1);

for i = 1:N
    r = rand;

    if r < 0.33
        rainfall = rand*40;
        slope    = rand*5;
        elevT    = 200 + rand*300;
        soil     = randi([1 3]);
        label    = "NoDisaster";

    elseif r < 0.66
        rainfall = 180 + rand*250;
        slope    = rand*8;
        elevT    = rand*150;
        soil     = randi([1 2]);
        label    = "Flood";

    else
        rainfall = 100 + rand*200;
        slope    = 25 + rand*20;
        elevT    = 500 + rand*900;
        soil     = randi([2 3]);
        label    = "Landslide";
    end

    X(i,:) = [rainfall slope elevT soil];
    Y(i)   = label;
end

Y = categorical(Y);

%% =========================================================
% STEP 6: TRAIN ML MODEL (RANDOM FOREST)
% =========================================================
mlModel = TreeBagger(150, X, Y, ...
    'Method','classification', ...
    'OOBPrediction','On');

disp('Machine Learning model trained.');

%% =========================================================
% STEP 7: CURRENT CONDITIONS
% =========================================================
rainfallNow = 100;    % mm
soilType    = 2;      % laterite

currentCondition = [rainfallNow slopeDeg elevationNow soilType];

%% =========================================================
% STEP 8: ML PREDICTION
% =========================================================
[~, scores] = predict(mlModel, currentCondition);
classNames = mlModel.ClassNames(:);
probabilities = scores(:) * 100;

%% =========================================================
% STEP 9: PHYSICS + HIGH-ELEVATION LOGIC
% =========================================================
if rainfallNow > 200 && slopeDeg < 8 && elevationNow < 300
    probabilities(strcmp(classNames,'Flood')) = ...
        probabilities(strcmp(classNames,'Flood')) + 20;
end

if slopeDeg > 25 && rainfallNow > 100
    probabilities(strcmp(classNames,'Landslide')) = ...
        probabilities(strcmp(classNames,'Landslide')) + 30;
end

if elevationNow >= 800 && slopeDeg <= 5 && rainfallNow >= 120
    probabilities(strcmp(classNames,'Landslide')) = ...
        probabilities(strcmp(classNames,'Landslide')) + 25;
end

if elevationNow >= 800 && rainfallNow < 50
    probabilities(strcmp(classNames,'NoDisaster')) = ...
        probabilities(strcmp(classNames,'NoDisaster')) + 30;
end

probabilities = max(probabilities,0);
probabilities = probabilities / sum(probabilities) * 100;

%% =========================================================
% STEP 10: DISPLAY PROBABILITIES
% =========================================================
disp('--- FINAL PREDICTION ---');
resultTable = table(classNames, probabilities, ...
    'VariableNames', {'DisasterType','Probability_%'});
disp(resultTable);

%% =========================================================
% STEP 11: ALERT GENERATION
% =========================================================
floodProb     = probabilities(strcmp(classNames,'Flood'));
landslideProb = probabilities(strcmp(classNames,'Landslide'));

alertLevel  = "GREEN ALERT";
alertReason = "Terrain and weather conditions are stable.";

if floodProb >= 70 || landslideProb >= 60
    alertLevel  = "RED ALERT";
    alertReason = "High disaster risk detected.";
elseif floodProb >= 40 || landslideProb >= 30
    alertLevel  = "ORANGE ALERT";
    alertReason = "Moderate disaster risk. Stay alert.";
end

disp(['ALERT LEVEL: ', alertLevel]);
disp(['REASON     : ', alertReason]);

%% =========================================================
% STEP 12: RISK INDEX (0–100)
% =========================================================
riskIndex = 0.5*floodProb + 0.4*landslideProb + ...
            0.1*(100 - probabilities(strcmp(classNames,'NoDisaster')));
riskIndex = min(max(riskIndex,0),100);

disp(['Risk Index (0–100): ', num2str(riskIndex,'%0.1f')]);

%% =========================================================
% STEP 13: GENAI-STYLE RISK EXPLANATION
% =========================================================
%% =========================================================
% GENAI-STYLE RISK EXPLANATION (FIXED)
% =========================================================

if landslideProb > floodProb
    dominantRisk = 'Landslide';
else
    dominantRisk = 'Flood';
end

if alertLevel == "RED ALERT"
    riskExplanation = sprintf( ...
        'High %s risk detected. Rainfall is %.1f mm, terrain slope is %.1f degrees, and elevation is %.1f meters. These combined conditions significantly increase disaster likelihood.', ...
        dominantRisk, rainfallNow, slopeDeg, elevationNow);

elseif alertLevel == "ORANGE ALERT"
    riskExplanation = sprintf( ...
        'Moderate %s risk observed. Rainfall (%.1f mm) and terrain slope (%.1f degrees) indicate potential instability. Monitoring is advised.', ...
        dominantRisk, rainfallNow, slopeDeg);

else
    riskExplanation = sprintf( ...
        'Current conditions indicate low disaster risk. Rainfall (%.1f mm), slope (%.1f degrees), and elevation (%.1f meters) remain within safe limits.', ...
        rainfallNow, slopeDeg, elevationNow);
end

disp('--- GENAI RISK EXPLANATION ---');
disp(riskExplanation);

%% =========================================================
% STEP 14: ALERT DISPLAY (COLOR)
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
text(0.5,0.45,riskExplanation,'FontSize',14,...
     'HorizontalAlignment','center','Interpreter','none');

title('AI-Based Disaster Alert System','FontSize',18,'FontWeight','bold');

disp('--- PROJECT COMPLETED SUCCESSFULLY ---');
