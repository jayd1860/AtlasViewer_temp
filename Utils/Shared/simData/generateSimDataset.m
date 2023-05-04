function nirs = generateSimDataset(dirname, nSubj, nSess, nRuns)
nirs = [];

if ~exist('dirname','var')
    dirname = filesepStandard(pwd);
end
if ~exist('nsubj','var')
    nsubj = 3;
end
if ~exist('nSess','var')
    nSess = 3;
end
if ~exist('nRuns','var')
    nRuns = 3;
end

% Create template data
setNamespace('AtlasViewerGUI');
dirnameAtlas = getAtlasDir();
if ~ispathvalid(dirnameAtlas)
    return;
end
refpts = initRefpts();
refpts = getRefpts(refpts, dirnameAtlas);
SD = genProbeFromRefpts(refpts, 30);
nirs = NirsClass(SD);

% for iSubj = 1:nSubj
%     sname = sprintf('%d/subj-%d', dirname, iSubj);
%     if ~ispathv
%     mkdir();
%     for iSess = 1:nSess
%         for iRuns = 1:nRuns
%             for iM = 1:length(nirs.SD.MeasList)
%                 [nirs.t, nirs.d(:,iM)] = simulateDataTimeSeries(ntpts);
%             end
%             snirf = SnirfClass(nirs.d, nirs.t, nirs.SD, [], []);
%             
%             snirf.Save(sprintf('./', './a,'.snirf']);
%         end
%     end
% end
% 
