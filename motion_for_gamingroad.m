
function motion_for_gamingroad()
%% Tracking Using Optical Flow

%% Initialization
% Create the System objects outside of the main video processing loop.
imaqreset;

import java.awt.Robot;
import java.awt.event.*;
keyboard = Robot;

NET.addAssembly('System.Speech');
Speaker = System.Speech.Synthesis.SpeechSynthesizer;


%% Initialization
% Create the Video Device System object.

hVidReader = imaq.VideoDevice('winvideo', 1, 'YUY2_160x120', ...
                              'ROI', [1 1 160 120], ...
                              'ReturnedColorSpace', 'rgb');
  

%%
% Optical flow object for estimating direction and speed of object motion.
hOpticalFlow = vision.OpticalFlow( ...
    'OutputValue', 'Horizontal and vertical components in complex form');

%%
% Create two objects for analyzing optical flow vectors.
hMean1 = vision.Mean;
hMean2 = vision.Mean('RunningMean', true);

%%
% Filter object for removing speckle noise introduced during segmentation.
hMedianFilt = vision.MedianFilter;

%%
% Morphological closing object for filling holes in blobs.
hclose = vision.MorphologicalClose('Neighborhood', strel('line',5,45));

%%
% Create a blob analysis System object to segment cars in the video.
hblob = vision.BlobAnalysis(...
    'CentroidOutputPort', false, 'AreaOutputPort', true, ...
    'BoundingBoxOutputPort', true, 'OutputDataType', 'double', ...
    'MinimumBlobArea', 250, 'MaximumBlobArea', 3600, 'MaximumCount', 80);

%%
% Morphological erosion object for removing portions and other 
% unwanted objects.
herode = vision.MorphologicalErode('Neighborhood', strel('square',2));

%%
% Create objects for drawing the bounding boxes and motion vectors.
hshapeins1 = vision.ShapeInserter('BorderColor', 'Custom', ...
                                  'CustomBorderColor', [0 1 0]);
hshapeins2 = vision.ShapeInserter( 'Shape','Lines', ...
                                   'BorderColor', 'Custom', ...
                                   'CustomBorderColor', [255 255 0]);

%%
% This object will write the number of tracked cars in the output image.
htextins = vision.TextInserter('Text', '%4d', 'Location',  [1 1], ...
                               'Color', [1 1 1], 'FontSize', 12);

%%
% Create System objects to display the original video, motion vector video,
% the thresholded video and the final result.
sz = get(0,'ScreenSize');
pos = [20 sz(4)-300 300 300];
hVideo1 = vision.VideoPlayer('Name','Original Video','Position',pos);
pos(1) = pos(1)+320; % move the next viewer to the right
hVideo2 = vision.VideoPlayer('Name','Motion Vector','Position',pos);
pos(1) = pos(1)+320;
hVideo3 = vision.VideoPlayer('Name','Thresholded Video','Position',pos);
pos(1) = pos(1)+320;
hVideo4 = vision.VideoPlayer('Name','Results','Position',pos);

% Initialize variables used in plotting motion vectors.
lineRow   =  22;
firstTime = true;
motionVecGain  = 20;
borderOffset   = 5;
decimFactorRow = 5;
decimFactorCol = 5;    

pre_cn=0;
%% Tracking
% Create the processing loop to track in video.
nFrames=0;
pause(1);
while (nFrames<1500)  % Stop when end of file is reached  
    frame  = step(hVidReader);  % Read input video frame
    grayFrame = rgb2gray(frame);
    ofVectors = step(hOpticalFlow, grayFrame);   % Estimate optical flow

    % The optical flow vectors are stored as complex numbers. Compute their
    % magnitude squared which will later be used for thresholding.
    y1 = ofVectors .* conj(ofVectors);
    % Compute the velocity threshold from the matrix of complex velocities.
    vel_th = 0.5 * step(hMean2, step(hMean1, y1));

    % Threshold the image and then filter it to remove speckle noise.
    segmentedObjects = step(hMedianFilt, y1 >= vel_th);

    % Thin-out the parts of the road and fill holes in the blobs.
    segmentedObjects = step(hclose, step(herode, segmentedObjects));

    % Estimate the area and bounding box of the blobs.
    [area, bbox] = step(hblob, segmentedObjects);
    % Select ;Pboxes inside ROI (below white line).
    Idx = bbox(:,1) > lineRow;

    % Based on blob sizes, filter out objects
    % When the ratio between the area of the blob and the area of the 
    % bounding box is above 0.4 (40%).
    ratio = zeros(length(Idx), 1);
    ratio(Idx) = single(area(Idx,1))./single(bbox(Idx,3).*bbox(Idx,4));
    ratiob = ratio > 0.3 ;  % can be changed P
    count = int32(sum(ratiob))  ; 
    bbox(~ratiob, :) = int32(-1);

    ind=find(ratiob);
    for i=1:length(ind)
        bbox1(i,:)=bbox(ind(i),:);
    end
    
    keyboard.keyPress(KeyEvent.VK_R);
    pause(0.1);
    keyboard.keyRelease(KeyEvent.VK_R);
   
    
    if ind>0
        for i=1:length(ind)
            cn(i,:)=[bbox1(i,1)+bbox1(i,3)/2 bbox1(i,2)+bbox1(i,4)/2];
        end
        avg_cn=mean(cn);
        diff=avg_cn- pre_cn     
        
        if abs(diff)>=10   
           if  diff>0
               keyboard.keyPress(KeyEvent.VK_A); 
               pause(0.1);
               keyboard.keyRelease(KeyEvent.VK_A);
%                 inputemu('key_normal',',');
                
           

           else
                keyboard.keyPress(KeyEvent.VK_D); 
                pause(0.1);
                keyboard.keyRelease(KeyEvent.VK_D);
%                 inputemu('key_normal',':');
                
            end 
            
        else
%             inputemu('key_normal','p');
%             fprintf('heavy punch')
                keyboard.keyPress(KeyEvent.VK_R); 
                pause(0.1);
                keyboard.keyRelease(KeyEvent.VK_R);
             
            
        end
%         
        pre_cn=avg_cn;
        %pause(.5)
    end
    
    
    % Draw bounding boxes around the tracked parts.
    y2 = step(hshapeins1, frame, bbox);
 
    y2(22:23,:,:)   = 1;   % The white line.
    y2(1:15,1:30,:) = 0;   % Background for displaying count
    result = step(htextins, y2, count);

    % Generate coordinates for plotting motion vectors.
    if firstTime
      [R C] = size(ofVectors);            % Height and width in pixels
      RV = borderOffset:decimFactorRow:(R-borderOffset);
      CV = borderOffset:decimFactorCol:(C-borderOffset);
      [Y X] = meshgrid(CV,RV);
      firstTime = false;
    end
    
    % Calculate and draw the motion vectors.
    tmp = ofVectors(RV,CV) .* motionVecGain;
    lines = [Y(:), X(:), Y(:) + real(tmp(:)), X(:) + imag(tmp(:))];
    motionVectors = step(hshapeins2, frame, lines);

    % Display the results
%     step(hVideo1, frame);            % Original video
%     step(hVideo2, motionVectors);    % Video with motion vectors
    step(hVideo3, segmentedObjects); % Thresholded video
    step(hVideo4, result);           % Video with bounding boxes

     nFrames = nFrames + 1;
    
end

release(hVidReader);

