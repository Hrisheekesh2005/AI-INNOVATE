Date = ["Day1"; "Day2"; "Day3"; "Day4"; "Day5"];
Rainfall_mm = [40; 60; 90; 130; 160];

rainfall = table(Date, Rainfall_mm);

disp(rainfall);
figure;
plot(Rainfall_mm, '-o', 'LineWidth', 2);
xlabel('Day');
ylabel('Rainfall (mm)');
title('Daily Rainfall');
grid on;
% Area (ward) information
WardID = [1; 2; 3; 4; 5];
Slope = [10; 25; 40; 15; 35];        % in degrees
Elevation = [200; 600; 1200; 400; 900]; % in meters
SoilType = [1; 2; 3; 1; 2];          % 1=Clay, 2=Laterite, 3=Sandy

wards = table(WardID, Slope, Elevation, SoilType);

disp(wards);
latestRain = Rainfall_mm(end);
disp(latestRain);
% Create combined data for risk calculation
features = table();
features.WardID = WardID;
features.Rainfall = repmat(latestRain, length(WardID), 1);
features.Slope = Slope;
features.Elevation = Elevation;
features.SoilType = SoilType;

disp(features);
figure;
bar(features.Rainfall);
xlabel('Ward');
ylabel('Rainfall (mm)');
title('Rainfall Applied to All Wards');
% Normalize values (scale to 0–1 range)
rain_norm = features.Rainfall / max(features.Rainfall);
slope_norm = features.Slope / max(features.Slope);
soil_norm  = features.SoilType / max(features.SoilType);
% Risk score calculation using weighted sum
riskScore = ...
    0.5 * rain_norm + ...
    0.3 * slope_norm + ...
    0.2 * soil_norm;
features.RiskScore = riskScore;
disp(features);
RiskLevel = strings(height(features),1);

for i = 1:height(features)
    if features.RiskScore(i) < 0.35
        RiskLevel(i) = "Low";
    elseif features.RiskScore(i) < 0.65
        RiskLevel(i) = "Medium";
    else
        RiskLevel(i) = "High";
    end
end

features.RiskLevel = RiskLevel;
disp(features);
figure;
bar(features.RiskScore);
xlabel('Ward ID');
ylabel('Risk Score');
title('Flood & Landslide Risk by Ward');
grid on;
figure;
bar(features.RiskScore);
ylim([0 1]);
xlabel('Ward ID');
ylabel('Risk Score (0 to 1)');
title('Micro-Zone Flood & Landslide Risk');
grid on;
figure;
colors = zeros(height(features),3);

for i = 1:height(features)
    if features.RiskLevel(i) == "Low"
        colors(i,:) = [0 0.7 0];      % Green
    elseif features.RiskLevel(i) == "Medium"
        colors(i,:) = [0.9 0.6 0];    % Yellow
    else
        colors(i,:) = [0.8 0 0];      % Red
    end
end

bar(features.RiskScore,'FaceColor','flat');
for i = 1:height(features)
    bar(i,features.RiskScore(i),'FaceColor',colors(i,:));
    hold on;
end
hold off;

xlabel('Ward ID');
ylabel('Risk Score');
title('Risk Classification by Ward');
grid on;
figure;
scatter(features.Rainfall, features.RiskScore, 100, 'filled');
xlabel('Rainfall (mm)');
ylabel('Risk Score');
title('Rainfall vs Risk Relationship');
grid on;
