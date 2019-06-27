function facetrack()

imaqreset

import java.awt.Robot;
import java.awt.event.*;
mouse = Robot;
screenSize = get(0, 'screensize');
aspect=[screenSize(3)/320 screenSize(4)/240] ;
%% Initialization
% Create the Video Device System object.
vidDevice = imaq.VideoDevice('winvideo', 1, 'YUY2_320x240', ...
                             'ROI', [1 20 320 200], ...
                             'ReturnedColorSpace', 'rgb');
                              
                         
faceDetector = vision.CascadeObjectDetector; 
preview(vidDevice);

%% 
% Initialize the vector field lines.
maxWidth = imaqhwinfo(vidDevice,'MaxWidth');
maxHeight = imaqhwinfo(vidDevice,'MaxHeight');
shapes = vision.ShapeInserter;
shapes.Shape = 'Rectangles';
shapes.BorderColor = 'white';
r = 1:5:maxHeight;
c = 1:5:maxWidth;
[Y, X] = meshgrid(c,r);
preview(vidDevice);

%%
% Create VideoPlayer System objects to display the videos.
hVideoIn = vision.VideoPlayer;
hVideoIn.Name  = 'Original Video';
hVideoOut = vision.VideoPlayer;
hVideoOut.Name  = 'face Detected Video';

%% Stream Acquisition and Processing Loop
% Create a processing loop to perform motion detection in the input
% video. This loop uses the System objects you instantiated above.
shapeInserter = vision.ShapeInserter('BorderColor','Custom','CustomBorderColor',[255 255 0]); 
% Set up for stream
    rgbData = step(vidDevice);
    bbox = step(faceDetector, rgbData);
    noseBBox=[ ; ];
    
    while isempty(noseBBox)==1
        while isempty(bbox)==1
            rgbData = step(vidDevice);
            bbox = step(faceDetector, rgbData);
        end
        [hueChannel,~,~] = rgb2hsv(rgbData);
    %     rectangle('Position',bbox(1,:),'LineWidth',2,'EdgeColor',[1 1 0])

        noseDetector = vision.CascadeObjectDetector('Nose');
        faceImage    = imcrop(rgbData,bbox);
        noseBBox     = step(noseDetector,faceImage);
        fprintf('face not found')
        preview(vidDevice);
    end

    noseBBox(1:2) = noseBBox(1:2) + bbox(1:2);
    
    if size( noseBBox,1)>1
        noseBBox=noseBBox(1,:);
    end
    
    % Create a tracker object.
    tracker = vision.HistogramBasedTracker;
    % Initialize the tracker histogram using the Hue channel pixels from the
    % nose.
    initializeObject(tracker, hueChannel, noseBBox);
    
    
    rgbData = step(vidDevice);
    [hueChannel,~,~] = rgb2hsv(rgbData); 
    bbox = step(tracker, hueChannel);
    centerp=[bbox(1)+bbox(3)/2 bbox(2)+bbox(4)/2];
    videoOut = step(shapeInserter, rgbData, bbox);
    step(hVideoOut, videoOut);
    
   inputemu({'key_down';'\UP'}, 10)
    
    nFrames = 0;
    
while (nFrames<inf)    
    % Acquire single frame from imaging device.
    rgbData = step(vidDevice);
%     bbox = step(faceDetector, rgbData)
%     rgb_Out = step(shapeInserter, rgbData, int32(bbox)); 
     
    
    % RGB -> HSV
    [hueChannel,~,~] = rgb2hsv(rgbData);
    
    % Track using the Hue channel data
    bbox = step(tracker, hueChannel);
    %action: rotate head according to bbox
    center=[bbox(1)+bbox(3)/2 bbox(2)+bbox(4)/2];
    % Insert a bounding box around the object being tracked
    videoOut = step(shapeInserter, rgbData, bbox);
    
    % Display the annotated video frame using the video player object
    step(hVideoOut, videoOut);
    
    nFrames = nFrames + 1;
%     inputemu('move',[center 0])
    diff=(center(1)-centerp(1))
    if abs(diff)>=10
          if diff>0        
%             inputemu('key_normal','\ENTER');
             fprintf('Enter')

         elseif diff<0
%             inputemu('key_normal','\BACKSPACE');
             fprintf('Backspace')
          end
             mouse.mousePress(InputEvent.BUTTON1_MASK);  %left click
             mouse.mouseMove(center(1)*aspect(1), center(2)*aspect(2))
%              mouse.mouseRelease(InputEvent.BUTTON1_MASK);
          
     end     
    centerp=center;
   pause(.5)
end

%% Release
% Here you call the release method on the System objects to close any open 
% files and devices.
release(vidDevice);
release(hVideoIn);
release(hVideoOut);