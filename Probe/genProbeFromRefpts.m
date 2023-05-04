function SD = genProbeFromRefpts(refpts, dt, nW, options)
optpos = refpts.pos;
ml = [];
if nargin==0
    return;
end
if ~exist('dt','var')
    dt = 30;
end
if ~exist('nW','var')
    nW = 2;
end
iOptExcl = [];
iOptSrcNext = 1;
iSrc = 1;
iDet = 0;
srcpos = zeros(size(optpos));
detpos = zeros(size(optpos));
dm     = distmatrix(optpos);
N      = size(optpos,1);
while 1
    % Find next source
    k = [];
    for jj = iOptSrcNext:N
        if ~ismember(jj, iOptExcl)
            k = jj;
            break;
        end
    end
    if isempty(k)
        break;
    end
    iOptSrcNext = k;
    
    % Add source
    srcpos(iSrc,:) = optpos(iOptSrcNext,:);
        
    % Find detectors
    k1 = find((dm(iOptSrcNext,:)>0) & (dm(iOptSrcNext,:)<dt));
    k2 = find((dm(:,iOptSrcNext)>0) & (dm(:,iOptSrcNext)<dt));
    k = [k1(:)',k2(:)'];
    k(ismember(k, iOptExcl)) = [];
    idxsNew = iDet+1:iDet+length(k);
        
    % Add detectors
    detpos(idxsNew,:) = optpos(k,:);
    
    % Add to list of excluded optode indices
    iOptExcl = unique([iOptExcl, iOptSrcNext, k]);

    % Add to measurement list
    n = size(ml,1);
    for ii = 1:length(idxsNew)
        ml(n+ii,:) = [iSrc, idxsNew(ii)];
    end

    iSrc = iSrc+1;
    iDet = iDet+length(idxsNew);

end
srcpos(iSrc:end,:) = [];
detpos(iDet+1:end,:) = [];
ml = [ml, ones(size(ml,1),2)];

[srcpos, ml, dummypos1] = squeezeOptodes(srcpos, ml, 1);
[detpos, ml, dummypos2] = squeezeOptodes(detpos, ml, 2);

dummypos = [dummypos1; dummypos2];

% Create multiple wavelength meas list
ml2 = ml;
for ii = 2:nW
    ml2(:,4) = ii;
    ml = [ml; ml2];
end

% Create Lambda
w0 = 650;
Wstep = 100;
lambda = [];
for ii = w0 : Wstep : w0 + nW*Wstep
    lambda = [lambda, ii];
end

% Create SD
SD = NirsClass().InitProbe(srcpos, detpos, ml, lambda, dummypos);
SD = generateSpringRegistration(SD);



% --------------------------------------------------
function [optpos, ml, dummy] = squeezeOptodes(optpos, ml, idx)
% Get only src/det pairs
ml = ml((ml(:,4)==1), :);
mlNew = ml;

% Remove unused optodes
d = diff(ml(:,1))';
k = [];
for ii = 1:length(d)
    if d(ii)>1
        knew = ml(ii,idx)+1 : ml(ii+1,idx)-1;
        k = unique([k, knew]);
        mlNew(ii+1:end,1) = mlNew(ii+1:end,1) - (d(ii)-1);
    end
end
k = unique([k, max(ml(:,idx))+1:size(optpos,1)]);
dummy = optpos(k,:);
optpos(k,:) = [];
ml = mlNew;




% -----------------------------------------------
function SD = generateSprings(SD)
optpos = [SD.SrcPos; SD.DetPos; SD.DummyPos];
dm = distmatrix(optpos);
dt = 50;
sl = [];
kk = 1;
maxsprings = 3;
for ii = 1:size(dm,1)
    k = find(dm(ii,:)>0 & dm(ii,:)<dt);
    for jj = 1:length(k)
        if jj > maxsprings
            break
        end
        sl(kk,:) = [ii, k(jj), dm(ii,k(jj))];
        kk = kk+1;
    end
end
SD.SpringList = sl;



% -----------------------------------------------
function SD = generateAnchors(SD, refpts)
al = 
for ii = 1:


% -----------------------------------------------
function SD = generateSpringRegistration(SD)
SD = generateSprings(SD);
SD = generateAnchorPts(SD);
