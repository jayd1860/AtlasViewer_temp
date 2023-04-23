function [srcpos, detpos, ml] = genProbeFromRefpts(optpos, dt)
srcpos = [];
detpos = [];
ml = [];
if nargin==0
    return;
end
if ~exist('dt','var')
    dt = 30;
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

[srcpos, ml] = squeezeOptodes(srcpos, ml, 1);
[detpos, ml] = squeezeOptodes(detpos, ml, 2);




% --------------------------------------------------
function [optpos, ml] = squeezeOptodes(optpos, ml, idx)

% Remove unused optodes
d = diff(ml(:,1));
for ii = 1:length(d)
    if d(ii)>1
        k = unique(ml(ii,idx)+1:ml(ii+1,idx)-1);
        optpos(k,:) = [];
        ml(ii+1:end,1) = ml(ii+1:end,1) - (d(ii)-1);
    end
end



