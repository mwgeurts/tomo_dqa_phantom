% DQAphantom is a script that reads in a CT (provided through MATLAB UI)
% and writes a copy of the CT renamed such that TomoTherapy will 
% recognize it as a DQA phantom.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2015 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

% Open UI to allow user to select files
[names, path] = uigetfile({'*.dcm', 'CT Image Files (*.dcm)'}, ...
    'Select the Image Files', userpath, 'MultiSelect', 'on');

% If files were selected
if iscell(names) || sum(names ~= 0)
    
    % Open UI to allow user to select location of destination files
    dest = uigetdir(path, 'Select the Destination Folder');

    % Open UI to allow user to enter a phantom name
    id = inputdlg('Enter a name for the phantom');

    % Generate unique study, series, and FOR UIDs
    study = dicomuid;
    series = dicomuid;
    frame = dicomuid;
    
    % Start waitbar
    progress = waitbar(0, 'Processing DICOM images');
   
    % Loop through each file in names list
    for i = 1:length(names)
        
        % Update waitbar
        waitbar(i/(length(names)+2), progress);
        
        % Attempt to load each file using dicominfo
        try

            % If dicominfo is successful, store the header information
            info = dicominfo(fullfile(path, names{i}));

        catch

            % Otherwise, automatically skip to next file in directory 
            continue
        end 
        
        % Replace the patient name
        info.PatientName = struct();
        info.PatientName.FamilyName = '_phantom';

        % Replace the patient ID
        info.PatientID = id{1};
        
        % Replace the storage instance UIDs
        info.MediaStorageSOPInstanceUID = dicomuid;
        info.SOPInstanceUID = info.MediaStorageSOPInstanceUID;

        % Replace the study, series instance, and FOR UIDs
        info.StudyInstanceUID = study;
        info.SeriesInstanceUID = series;
        info.FrameOfReferenceUID = frame;
        
        % Read in the 2D DICOM image data
        img = dicomread(info);

        % Modify the first voxel by one to make the CT image unique
        img(1,1) = img(1,1)+1;
        
        % Write a new CT image
        dicomwrite(img, fullfile(dest, names{i}), info, ...
            'CreateMode', 'copy');
    end
    
    % Update waitbar
    waitbar(1.0, progress, 'CT processing completed');
    close(progress);
    
end

% Clear variables
clear names path dest info img id progress i series study;
