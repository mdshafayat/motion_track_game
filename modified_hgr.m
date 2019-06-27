% ProjectHGR - Hand Gesture Recognizer Project
% results : holds the following information for each image in the database
        % X position of the database image's center point
        % Y position of the database image's center point
        % X position of the input(query) image's center point
        % Y position of the input(query) image's center point
        % Number of matched keypoints
        % Number of valid matched keypoints
        % Validity Ratio
        % index number
% ----------------------------------------------------------------

function [a results]= hgr(input)
a=0;
global Selecteds
load theHGRDatabase
%The locations of database images are stored in "dataBase(i,:)"
% For accessing the path of 'B' character use dataBase(2,:).
% Note that 2 denotes  the 2nd character in the alphabet(i.e. 'B').

% Step1) Initialize the critical parameters
distRatio=0.65; %Distance Ratio for the SIFT Match methods. % default distRatio = 0.65
threshold=0.035; % default threshold=0.035
distRatioIncrement=0.05; % default distRatioIncrement=0.05
thresholdDecrement=0.005; % default thresholdDecrement=0.005

% 'Selecteds' indicate the selected Database Images.
% If you add 1.jpg to the Database folder, you have to change the first
% number as 1. For our case, you have to make the first 0 of 'Selected'as 1.
% Also note that, this array stores the candidate database images.
% At the end of the algorithm only 1 selected (matched) image is left
% inside this array

% Selecteds=[1 2 3 4 5 6 7 8 9 10 11 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];

% 'mask' denotes the maximum character number (The maximum charachter
% number for ASL (American Sign Language) is set as 26.
mask=26;

% 'check' specifies the number of checks done so far.
% it is set as 1 for the initial check/test.

check=1;

% Since there isn't any process, the initial value of the matchFound is 0.
matchFound=0;

% StringArray is used for outputing the equivalent ASCII character

StringArray=Selecteds;
StringArray=StringArray+64;

% ----------------------------------------------------------------
% Step2) Run the main algorithm

while(sum(mask)>1) 
    % Investigate the function 'formResults' for the details of the
    % algorithm
    results=formResults(input,distRatio,threshold);
    
    if(mask<=2)
        % Select the best candidate
        Selecteds=findMax(results(:,7),1); %Note that 7th field of results hold the validity ratio of the validly matched keypoints
    else
        % Select the 3 best candidates
        % Note: This section could be changed by replacing the 'depth' of 3 as
        % the numberOfBestCandidates by setting a separate ValidityRatio threshold after the first iteration.
        % For demonstration purposes it is left as 3.
        Selecteds=findMax(results(:,7),3);
    end
    
    % Inform that the n'th check is done and increment the check for the
    % next possible iteration
    disp('---------------');
    fprintf('Check %d Done.\n',check);
    disp('---------------');
    check=check+1;
    
    % Increment the distRatio for the next iteration for the selected
    % candidate database images in order to find more matched keypoints
    distRatio=distRatio+distRatioIncrement;
    if(distRatio>=0.9)
        distRatio=0.9;
    end
    
    % Decrement the threshold value in order to find more valid keypoints.
    threshold=threshold-thresholdDecrement;
    if(threshold<=0.01)
        threshold=0.01;
    end
    % Store the Selecteds inside 'mask' and enforce it to be under 1 in
    % order to exit the loop if only 1 selected item left. In the case of
    % having 2 candidates the loop will continue.
    mask=(Selecteds)./(Selecteds+1);
end

fprintf('End of tests...\n');

% ----------------------------------------------------------------
% Step3) Printing and displaying the result 
for i=1:26
    if (Selecteds(i)~=0)
        matchFound=1;
        inputImage=imread(input);
        outputImage=imread(dataBase(Selecteds(i),:));
        imshow(appendimages(outputImage,inputImage));
        a=i;
        title('Matched Database Image -versus- Input Image');
        fprintf('Match Found: %c char.\n',StringArray(i));
    end
end

if(matchFound==0)
    fprintf('No match found...\n');
    a=0;
end

% ----------------------------------------------------------------
% ----------------------------------------------------------------