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
iOptDetNext = 1;
iSrc = 1;
iDet = 1;
srcpos = zeros(size(optpos));
detpos = zeros(size(optpos));
dm = distmatrix(optpos);
N = size(optpos,1);
while 1
    % Find next source
    k = [];
    for jj = iOptDetNext:N
        if ~ismember(jj, iOptExcl)
            k = jj;
            break;
        end
    end
    if isempty(k)
        break;
    end
    iOptDetNext = k;
    
    % Add source
    srcpos(iSrc,:) = optpos(iOptDetNext,:);
        
    % Find detectors
    k1 = find((dm(iOptDetNext,:)>0) & (dm(iOptDetNext,:)<dt));
    k2 = find((dm(:,iOptDetNext)>0) & (dm(:,iOptDetNext)<dt));
    k = [k1,k2];
    k(ismember(k, iOptExcl)) = [];
    
    % Add detectors
    detpos(iDet:iDet+length(k)-1,:) = optpos(k,:);
    iDet = iDet+length(k);
    
    % Add to list of excluded optode indices
    iOptExcl = unique([iOptExcl, iOptDetNext, k]);

    % Add to measurement list
    n = size(ml,1);
    for ii = n+1:n+length(k)
        ml(ii,:) = [iSrc, k(ii-n)];
    end

    iSrc = iSrc+1;

end
srcpos(iSrc:end,:) = [];
detpos(iDet:end,:) = [];

% if iSrc > iDet
%     detposTemp = detpos;
%     detpos = srcpos;
%     srcpos = detposTemp;
%     ml = [ml(:,2), ml(:,1)];
% end

