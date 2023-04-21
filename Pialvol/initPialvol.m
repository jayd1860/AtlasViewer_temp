function pialvol = initPialvol()

pialvol = struct( ...
                 'pathname', '', ...
                 'name', 'pialvol', ...
                 'handles',struct('hSurf',[], 'hAxes',[], 'axes', gca), ...
                 'img',uint8([]), ...
                 'imgOrig',uint8([]), ...
                 'center',[], ...
                 'mesh',initMesh(), ...
                 'tiss_prop',struct('name','', 'scattering',[], 'anisotropy',[], 'absorption',[], 'refraction',[]), ...
                 'T_2ras',eye(4), ...
                 'T_2digpts',eye(4), ...
                 'T_2mc',eye(4), ...
                 'orientation', '', ...
                 'orientationOrig', '', ...
                 'checkCompatability',[], ...
                 'isempty',@isempty_loc, ...                 
                 'prepObjForSave',[] ...                 
                );

% --------------------------------------------------------------
function b = isempty_loc(pialvol)

b = false;
if isempty(pialvol)
    b = true;
elseif isempty(pialvol.img)
    b = true;
end

