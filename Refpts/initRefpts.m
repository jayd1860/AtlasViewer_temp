function refpts = initRefpts(handles)

refpts = struct( ...
    'pathname',filesepStandard(pwd), ...
    'name','refpts', ...
    'handles',struct(...
        'labels',[], ...
        'circles',[], ...
        'radiobuttonShowRefptsLabels',[], ...
        'radiobuttonShowRefptsCircles',[], ...
        'menuItemShowRefpts',[], ...
        'menuItemShow10_20',[], ...
        'menuItemShow10_10',[], ...
        'menuItemShow10_5',[], ...
        'menuItemShowSelectedCurves',[], ...
        'menuItemShowSelectedCurves10_20',[], ...
        'menuItemShowSelectedCurves10_10',[], ...
        'menuItemShowSelectedCurves10_5',[], ...
        'menuItemRefptsToCortex',[], ...
        'hCortexProjection',[], ...
        'hProjectionRays',[], ...
        'selected',[], ...
        'textSize',9, ...
        'circleSize',18, ...
        'color',[.2 .05 .1], ...
        'axes',[], ...
        'SelectEEGCurvesGUI',[], ...
        'selectedcurves',[], ...
        'radiobuttonHeadDimensions',[], ...
        'uipanelHeadDimensions', [], ...
        'editCircumference',[], ...
        'editSagittal',[], ...
        'editCoronal',[] ...
    ), ...
    'pos',zeros(0,3), ...
    'labels',{{}}, ...
    'eeg_system',struct('selected','10-10','ear_refpts_anatomy','preauricular', ...
                        'curves',init_eeg_curves1(), ...
                        'labels',extract_eeg_labels(init_eeg_curves1()), ...
                        'lengths',struct('circumference',0,'NzCzIz',0,'LPACzRPA',0), ...
                        'sphere',struct('label',[], 'theta',[], 'phi',[], 'r',[], 'xc',[], 'yc',[], 'zc',[]) ...
                        ),  ...
    'T_2vol',eye(4), ...
    'center', [], ...
    'orientation', '', ...
    'checkCompatability',[], ...
    'isempty',@isempty_loc, ...
    'copyLandmarks',@copyLandmarks, ...
    'prepObjForSave',[], ...
    'cortexProjection', struct(...
        'vertices',[], ...
        'iFaces',[], ...
        'iVertices',[], ...
        'pos',[] ...
    ), ...
    'scaling',1.0 ...
);

refpts = initFontSizeConfigParams(refpts, 'Reference Points');

if exist('handles','var')
    refpts.handles.radiobuttonShowRefptsLabels = handles.radiobuttonShowRefptsLabels;
    refpts.handles.radiobuttonShowRefptsCircles = handles.radiobuttonShowRefptsCircles;
    set(refpts.handles.radiobuttonShowRefptsLabels,'enable','off');
    set(refpts.handles.radiobuttonShowRefptsLabels,'value',0);
    set(refpts.handles.radiobuttonShowRefptsCircles,'enable','off');
    set(refpts.handles.radiobuttonShowRefptsCircles,'value',0);
    
    refpts.handles.menuItemShowRefpts = handles.menuItemShowRefpts;
    
    refpts.handles.menuItemShow10_20 = handles.menuItemShow10_20;
    refpts.handles.menuItemShow10_10 = handles.menuItemShow10_10;
    refpts.handles.menuItemShow10_5 = handles.menuItemShow10_5;
    refpts.handles.menuItemShowSelectedCurves = handles.menuItemShowSelectedCurves;
    refpts.handles.menuItemShowSelectedCurves10_20 = handles.menuItemShowSelectedCurves10_20;
    refpts.handles.menuItemShowSelectedCurves10_10 = handles.menuItemShowSelectedCurves10_10;
    refpts.handles.menuItemShowSelectedCurves10_5 = handles.menuItemShowSelectedCurves10_5;
    
    refpts.handles.menuItemCalcRefpts = handles.menuItemCalcRefpts;

    set(refpts.handles.menuItemShowRefpts,'enable','off');

    refpts = setRefptsMenuItemSelection(refpts);
    
    refpts.handles.axes = handles.axesSurfDisplay;
    refpts.handles.menuItemRefptsToCortex = handles.menuItemRefptsToCortex;

    refpts.handles.radiobuttonHeadDimensions = handles.radiobuttonHeadDimensions;
    refpts.handles.uipanelHeadDimensions = handles.uipanelHeadDimensions;
    refpts.handles.editCircumference = handles.editCircumference;
    refpts.handles.editSagittal = handles.editSagittal;
    refpts.handles.editCoronal = handles.editCoronal;
end



% --------------------------------------------------------------
function b = isempty_loc(refpts)

b = false;
if isempty(refpts)
    b = true;   
else
    if isempty(refpts.pos)
        b = true;
    end
    if isempty(refpts.labels)
        b = true;
    end
end



% ---------------------------------------------------------------
function r2 = copyLandmarks(r2, r1)
if nargin<2
    return;
end
idxs = [];
for ii = 1:length(r1.labels)
    switch(lower(r1.labels{ii}))
        case {'nz','iz','lpa','rpa','cz'}
            idxs = [idxs, ii]; %#ok<AGROW>
    end
end
r2.labels   = r1.labels(idxs);
r2.pos      = r1.pos(idxs,:);
r2.eeg_system.sphere  = r1.eeg_system.sphere;
