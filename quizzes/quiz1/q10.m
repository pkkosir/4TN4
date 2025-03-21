clear;
clc;

% loads images
race = imread('race.tif');
einstein = imread('einstein.tif');

% variables to change
test1 = [20, 220];
test2 = [100, 200];
test3 = [30, 120];


%---------- FUNCTION CREATION ----------%
function Y = stretch(X, T1, T2)

    X = double(X); %converted to floats to do calculations on
    Y = zeros(size(X)); %intialized output matrix
    linear = (X >= T1) & (X <= T2); %linear section of the stretching transform
    diff = T2-T1; %difference between max and min thresholds (for mapping)

    %NOTE: all below T1 already set to 0 so no need to update
    Y(X > T2) = 1; %sets all values above T2 to max grey value
    Y(linear) = (X(linear)-T1) / diff; %maps grey values 0 to 1
    Y = uint8(Y)*255; % converts values back into integer values betweeen 0 and 255
end

%---------- STRETCHING ----------%
raceS1 = stretch(race, test1(1), test1(2));
einsteinS1 = stretch(einstein, test1(1), test1(2));

raceS2 = stretch(race, test2(1), test2(2));
einsteinS2 = stretch(einstein, test2(1), test2(2));

raceS3 = stretch(race, test3(1), test3(2));
einsteinS3 = stretch(einstein, test3(1), test3(2));


%----------- PLOTTING -----------%
figure;

subplot(2,4,1), imshow(race), title('Race');
subplot(2,4,2), imshow(raceS1), title(['Streched w/ T1=', num2str(test1(1)), ', T2=', num2str(test1(2))]);
subplot(2,4,3), imshow(raceS2), title(['Streched w/ T1=', num2str(test2(1)), ', T2=', num2str(test2(2))]);
subplot(2,4,4), imshow(raceS3), title(['Streched w/ T1=', num2str(test3(1)), ', T2=', num2str(test3(2))]);

subplot(2,4,5), imshow(einstein), title('Einstein');
subplot(2,4,6), imshow(einsteinS1), title(['Streched w/ T1=', num2str(test1(1)), ', T2=', num2str(test1(2))]);
subplot(2,4,7), imshow(einsteinS1), title(['Streched w/ T1=', num2str(test2(1)), ', T2=', num2str(test2(2))]);
subplot(2,4,8), imshow(einsteinS1), title(['Streched w/ T1=', num2str(test3(1)), ', T2=', num2str(test3(2))]);




