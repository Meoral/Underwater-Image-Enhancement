clc;clear; close all;

img = imread('waterImg.jpg');

% Color balance
img1 = SimplestColorBalance(img);
lab1 = rgb_to_lab(img1);

% CLAHE
lab2 = lab1;
lab2(:, :, 1) = adapthisteq(lab2(:, :, 1));
img2 = lab_to_rgb(lab2);

R1 = double(lab1(:, :, 1)) / 255;

% calculate laplacian contrast weight
WL1 = abs(imfilter(R1, fspecial('Laplacian'), 'replicate', 'conv'));

%calculate Local contrast weight
h = 1/16* [1, 4, 6, 4, 1];
WC1 = imfilter(R1, h'*h, 'replicate', 'conv');
WC1(find(WC1 > (pi/2.75))) = pi/2.75;
WC1 = (R1 - WC1).^2;

% calculate the saliency weight
WS1 = saliency_detection(img1);

% calculate the exposedness weight
sigma = 0.25;
aver = 0.5;
WE1 = exp(-(R1 - aver).^2 / (2*sigma^2));

R2 = double(lab2(:, :, 1)) / 255;

% calculate laplacian contrast weight
WL2 = abs(imfilter(R1, fspecial('Laplacian'), 'replicate', 'conv'));

%calculate Local contrast weight
h = 1/16* [1, 4, 6, 4, 1];
WC2 = imfilter(R2, h'*h, 'replicate', 'conv');
WC2(find(WC2 > (pi/2.75))) = pi/2.75;
WC2 = (R2 - WC2).^2;

% calculate the saliency weight
WS2 = saliency_detection(img2);

% calculate the exposedness weight
sigma = 0.25;
aver = 0.5;
WE2 = exp(-(R2 - aver).^2 / (2*sigma^2));

% calculate the normalized weight
W1 = (WL1 + WC1 + WS1 + WE1) ./ ...
     (WL1 + WC1 + WS1 + WE1 + WL2 + WC2 + WS2 + WE2);
W2 = (WL2 + WC2 + WS2 + WE2) ./ ...
     (WL1 + WC1 + WS1 + WE1 + WL2 + WC2 + WS2 + WE2);

% calculate the gaussian pyramid
level = 5;
Weight1 = gaussian_pyramid(W1, level);
Weight2 = gaussian_pyramid(W2, level);

% calculate the laplacian pyramid
R1 = laplacian_pyramid(double(double(img1(:, :, 1))), level);
G1 = laplacian_pyramid(double(double(img1(:, :, 2))), level);
B1 = laplacian_pyramid(double(double(img1(:, :, 3))), level);

R2 = laplacian_pyramid(double(double(img2(:, :, 1))), level);
G2 = laplacian_pyramid(double(double(img2(:, :, 2))), level);
B2 = laplacian_pyramid(double(double(img2(:, :, 3))), level);

% fusion
for i = 1 : level
   R_r{i} = Weight1{i} .* R1{i} + Weight2{i} .* R2{i};
   R_g{i} = Weight1{i} .* G1{i} + Weight2{i} .* G2{i};
   R_b{i} = Weight1{i} .* B1{i} + Weight2{i} .* B2{i};
end

% reconstruct & output
R = pyramid_reconstruct(R_r);
G = pyramid_reconstruct(R_g);
B = pyramid_reconstruct(R_b);
fusion = cat(3, uint8(R), uint8(G), uint8(B));

figure, imshow([img, fusion])