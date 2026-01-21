clc;
clear;
close all;

disp('--- PROJECT STARTED (GEN-AI + ML + PHYSICS) ---');

%% =========================================================
% STEP 0: USER QUERY (NLP-STYLE INPUT)
% =========================================================
userQuery = input('Enter query (e.g., "Check landslide risk near Munnar"): ','s');

keywords = ["check","risk","flood","landslide","near","at","in","of"];
words = split(lower(userQuery));
locationWords = words(~ismember(words, keywords));
locationText = strjoin(locationWords, " ");

fprintf('Extracted Location: %s\n', locationText);

%% =========================================================
% STEP 1: GEOCODING (LOCATION → LAT/LON)
% =========================================================
geoURL = sprintf( ...
    'https://nominatim.openstreetmap.org/search?q=%s&format=json&limit=1', ...
    urlencode(locationText));

geoData = webread(geoURL);
lat = str2double(geoData(1).lat);
lon = str2double(geoData(1).lon);

fprintf('Coordinates → Lat: %.4f | Lon: %.4f\n', lat, lon);

%% =========================================================
% STEP 2: ELEVATION FETCH (API)
% =========================================================
delta = 0.0009; % ~100 m
points = [
    lat, lon;
    lat+delta, lon;
    lat-delta, lon;
    lat, lon+delta;
    lat, lon-delta
];

labels = {'Center','North','South','East','West'};
elev = zeros(5,1);

for i = 1:5
    apiURL = sprintf( ...
        'https://api.opentopodata.org/v1/srtm90m?locations=%.6f,%.6f', ...
        points(i,1), points(i,2));
    data = webread(apiURL);
    elev(i) = data.results(1).elevation;
end

elevationNow = elev(1);
fprintf('Elevation: %.2f m\n', elevationNow);

%% =========================================================
% STEP 3: PHYSICS-BASED SLOPE COMPUTATION
% =========================================================
d = 100; % meters
slopes = [
    atand(abs(elev(2)-elev(1))/d)
    atand(abs(elev(1)-elev(3))/d)
    atand(abs(elev(4)-elev(1))/d)
    atand(abs(elev(1)-elev(5))/d)
];

slopeDeg = max(slopes);
fprintf('Terrain Slope: %.2f°\n', slopeDeg);

%% =========================================================
% STEP 4: SYNTHETIC TRAINING DATA (2000)
% =========================================================
rng(10);
N = 2000;

X = zeros(N,4); % Rain, Slope, Elev, Soil
Y = strings(N,1);

for i = 1:N
    r = rand;

    if r < 0.33
        X(i,:) = [rand*40, rand*5, 200+rand*300, randi([1 3])];
        Y(i) = "NoDisaster";

    elseif r < 0.66
        X(i,:) = [180+rand*250, rand*8, rand*150, randi([1 2])];
        Y(i) = "Flood";

    else
        X(i,:) = [100+rand*200, 25+rand*20, 500+rand*900, randi([2 3])];
        Y(i) = "Landslide";
    end
end

Y = categorical(Y);

%% =========================================================
% STEP 5: TRAIN RANDOM FOREST MODEL
% =========================================================
mlModel = TreeBagger(150, X, Y, ...
    'Method','classification', ...
    'OOBPrediction','On');

disp('Machine Learning model trained.');

%% =========================================================
% STEP 6: CURRENT CONDITIONS
% =========================================================
rainfallNow = 120;   % example
soilType    = 2;     % laterite

currentInput = [rainfallNow slopeDeg elevationNow soilType];

%% =========================================================
% STEP 7: ML PREDICTION
% =========================================================
[~, scores] = predict(mlModel, currentInput);
classNames = mlModel.ClassNames(:);
probabilities = scores(:) * 100;

%% =========================================================
% STEP 8: PHYSICS + ELEVATION LOGIC
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
% STEP 9: ALERT DECISION
% =========================================================
floodProb     = probabilities(strcmp(classNames,'Flood'));
landslideProb = probabilities(strcmp(classNames,'Landslide'));

alertLevel = "GREEN ALERT";
alertReason = "Low disaster risk.";

if floodProb >= 70 || landslideProb >= 60
    alertLevel = "RED ALERT";
    alertReason = "High disaster risk detected.";
elseif floodProb >= 40 || landslideProb >= 30
    alertLevel = "ORANGE ALERT";
    alertReason = "Moderate disaster risk.";
end

%% =========================================================
% STEP 10: GEN-AI RISK EXPLANATION (OFFLINE)
% =========================================================
riskExplanation = genai_explain( ...
    floodProb, landslideProb, slopeDeg, elevationNow, rainfallNow);

disp('--- GEN-AI RISK EXPLANATION ---');
disp(riskExplanation);

%% =========================================================
% STEP 11: PROBABILITY GRAPH
% =========================================================
figure;
bar(probabilities);
ylim([0 100]);
xticklabels(classNames);
ylabel('Probability (%)');
title('Disaster Probability');
grid on;

%% =========================================================
% STEP 12: ALERT DISPLAY (COLOR)
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

axis off;
text(0.5,0.6,alertLevel,'FontSize',36,'FontWeight','bold',...
     'HorizontalAlignment','center','Color','k');
text(0.5,0.45,alertReason,'FontSize',16,...
     'HorizontalAlignment','center','Color','k');


title('Disaster Alert System','FontWeight','bold');

disp('--- PROJECT COMPLETED SUCCESSFULLY ---');
