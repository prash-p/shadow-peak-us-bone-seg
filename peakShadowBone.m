function [I_seg, I_crop, probShad] = peakShadowBone(I, freq_mode, crop_mode)

%%% This is ultrasound bone segmentation in function format (script in peakShadowSeg.m
%%% file.
%%% INPUT:
%%%         I - Raw ultrasound image or volume containing bone
%%%         freq_mode - 0 for low frequency ultrasound (< 5 MHz)
%%%                   - 1 for high frequency ultrasound (recommended)
%%% crop_mode = 1 to crop image tightly (better for raw bmode
%%% volumes/images)
%%% crop_mode = 0 - no cropping, better for reconstructed volumes from
%%% tracking data

try
    I = gpuArray(I);
catch
    warning('Could not use GPU, using CPU...')
end
I = imnorm(single(I));

[rows, cols, frames] = size(I);
%% Remove black edges from each volume/image (cropping) (this is where the function peakShadowBone.m starts)
if crop_mode == 1
    zero_cols1 = any(I);    %zero columns same on all volumes
    num_of_zeros_cols = cols - sum(zero_cols1(1,:,ceil(end/2)));
    
    zero_rows1 = any(I,2);    %zero rows same on all volumes
    num_of_zeros_rows = rows - sum(zero_rows1(:,1,ceil(end/2)));
    
    I(:,(sum(abs(I(:,:,ceil(end/2)))) == 0),:) = [];
    I((sum(abs(I(:,:,ceil(end/2))),2) == 0),:,:) = [];
    
    I = reshape(I,[size(I,1), cols - num_of_zeros_cols, frames]);
    [rows, cols, frames] = size(I);
elseif crop_mode ~= 1 && crop_mode ~= 0
    error('invalid crop mode set');
end

I_crop = gather(I);

[rows, cols, frames] = size(I);

% %Find better way to do gaussian filtering
% %Previously [1,1,1] for phantom images and [4,4,1] for ddh images
% if rows < 200
%     gauss_std = [1, 1, 1];
% elseif rows >= 200 && rows < 400
%     gauss_std = [4, 4, 1];
% elseif rows >= 400 && rows < 600
%     gauss_std = [6,6,1];
% elseif rows >= 600
%     gauss_std = [8,8,1];
% else
%     gauss_std = [4,4,1];
% end

% I = imgaussfilt3(I, [1,1,1]);   %3D gaussian filtering with std of 6, for phantom data use [1 1 1], DDH data [4 4 1]
gauss_std = [2,2,1];
I = imgaussfilt3(I, gauss_std);   %3D gaussian filtering with std of 6, for phantom data use [1 1 1], DDH data [4 4 1]
% % %I_filt = imguidedfilter(I, 'NeighborhoodSize', [6 6]);
I = I - min(I(:));
I = I/max(I(:));
%% Calculate shadow probability and max intensities
intSum = sum(I); %Intensity sum of all columns
intSum = repmat(intSum, size(I,1),1);
cumSum = cumsum(I,1,'reverse'); %Cumulative intensity summation down along columns

if freq_mode == 0
    probShad = 1 - (cumSum./intSum);
else
    probShad = 1 - sqrt(cumSum./intSum);
end

intSum = gather(intSum);

probShad = imnorm(probShad);


%%%experimental: add depth gain compensation%%%
% grad = linspace(0,1,size(I,1))';
% grad = repmat(grad.^0.5,[1,size(I,2),size(I,3)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%% Test!!!! %%%%%%%%%%%%%%%
% cw = [6,48];
% 
% [Y,X,Z]  = size(I);
% 
% % Construct new filters, as before
% filtStruct = createMonogenicFilters3D(Y,X,Z,cw,cw,'lg',0.55);
% 
% % Find monogenic signal, as before
% [m1,m2,m3,m4] = monogenicSignal3D(I,filtStruct);
% 
% % Now use the 3D phase congruency algorithm. Just like the 2D case
% PC = phaseCongruency3D(m1,m2,m3,m4, 0.0175);
% I = PC;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[maxI, index] = max(I.*probShad);
I_seg = single(zeros(size(I)));

try
    I_seg = gpuArray(I_seg);
catch
end

if frames == 1
    indices = index + (0:size(I,1):size(I,1)*(size(I,2)-1));
else
    indices = index(:)' + (0:size(I,1):size(I,1)*size(I,2)*size(I,3)-1);
end

index = gather(index);

I_seg(indices) = maxI;
I_seg = I_seg - min(I_seg(:));
I_seg = I_seg/max(I_seg(:));
I_seg(I_seg < (mean(nonzeros(I_seg(:))) - 0.5*std(nonzeros(I_seg(:))))) = 0;

% I_seg = I_seg > 0.05;

%Convert back to CPU array
I_seg = gather(I_seg);


%%% To dilate final segmentation, uncomment below
% SE = strel('line',2,90);
% I_seg = imdilate(I_seg,SE);