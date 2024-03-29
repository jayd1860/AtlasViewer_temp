classdef DataFilesClass < handle
    
    properties
        files;
        filesErr;
        filetype;
        dirFormats;
        err;
        errmsg;
        rootdir;
        config;
        nfiles;
        logger
    end
    
    properties (Access = private)
        lookupTable
        excludedFolders
    end
    
    methods
        
        % ----------------------------------------------------
        function obj = DataFilesClass(varargin)
            obj.files = FileClass.empty();
            obj.filesErr = FileClass.empty();
            obj.filetype = '';
            obj.rootdir = pwd;
            obj.nfiles = 0;
            obj.err = -1;
            obj.errmsg = {};
            obj.dirFormats = struct('type',0, 'choices',{{}});

            global logger
            global cfg
            
            logger = InitLogger(logger);
            cfg    = InitConfig(cfg);
            
            obj.logger = logger;
            obj.lookupTable = [];
            obj.excludedFolders = {};
            
            skipconfigfile = false;
            askToFixNameConflicts = [];
            
            if nargin==0
                return
            end            
            if nargin==1
                obj.rootdir = varargin{1};
            end            
            if nargin==2
                obj.rootdir = varargin{1};
                obj.filetype = varargin{2};
            end
            if nargin==3
                obj.rootdir = varargin{1};
                obj.filetype = varargin{2};
                if strcmp(varargin{3}, 'standalone')
                    skipconfigfile = true;
                end
            end            
            if nargin==4
                obj.rootdir = varargin{1};
                obj.filetype = varargin{2};
                if strcmp(varargin{3}, 'standalone')
                    skipconfigfile = true;
                end
                askToFixNameConflicts = varargin{4};
            end
                        
            if obj.filetype(1) == '.'
                obj.filetype(1) = '';
            end
            obj.rootdir = filesepStandard(obj.rootdir,'full');           
            
            % Configuration parameters
            obj.config = struct('RegressionTestActive','',  'AskToFixNameConflicts',1, 'DerivedDataDir','');
            if skipconfigfile==false
                str = cfg.GetValue('Regression Test Active');
                if strcmp(str,'true')
                    obj.config.RegressionTestActive=true;
                else
                    obj.config.RegressionTestActive=false;
                end
            else
                obj.config.RegressionTestActive=false;
            end
            obj.config.SuppressErrorChecking = false;
            if ~isempty(askToFixNameConflicts)
                obj.config.AskToFixNameConflicts = askToFixNameConflicts;
            elseif strcmp(cfg.GetValue('Fix File Name Conflicts'), sprintf('don''t ask again'))
                obj.config.AskToFixNameConflicts = 0;
            end
            
            if ~obj.config.AskToFixNameConflicts
                obj.config.SuppressErrorChecking = true;                
            end
            
            [p, f] = fileparts(cfg.GetValue('Output Folder Name'));
            if isempty(p)
                obj.config.DerivedDataDir = f;
            else
                obj.config.DerivedDataDir = p;
            end
            obj.excludedFolders = {...
                [obj.rootdir, obj.config.DerivedDataDir];
                [obj.rootdir, 'fw'];
                [obj.rootdir, 'imagerecon'];
                [obj.rootdir, 'anatomical'];
                };
            if nargin==0
                return;
            end
            
            obj.err = 0;
            
            obj.InitFolderFromats();
            obj.GetDataSet();
        end
        
        
        
        % -----------------------------------------------------------------------------------
        function GetDataSet(obj)
            if exist(obj.rootdir, 'dir')~=7
                error('Invalid subject folder: ''%s''', obj.rootdir);
            end
            
            for ii = 1:length(obj.dirFormats.choices)
                obj.InitLookupTable();
                obj.FindDataSet(ii);
                
                % Remove any files that cannot pass the basic test of loading
                % its data
                obj.ErrorCheck();
                if ~isempty(obj.files)
                    break
                end
            end
            
            obj.ErrorCheckFinal();
        end

        
        
        % -----------------------------------------------------------------------------------
        function InitFolderFromats(obj)
            obj.dirFormats.choices = {
                
                %%%% 1. Flat #1
                {
                ['*_run*.', obj.filetype];
                }

                %%%% 2. Flat #2
                {
                ['*.', obj.filetype];
                }
                
                %%%% 3. Subjects 
                {
                '*';
                ['*.', obj.filetype];
                }

                %%%% 4. BIDS #1,    sub-<label>[_ses-<label>][_task-<label>][_run-<index>]_nirs.snirf
                {                
                'sub-*';
                'ses-*';
                ['nirs/sub-*_run-*_nirs.', obj.filetype];
                }
                                
                %%%% 5. BIDS #2 
                {
                'sub-*';
                ['nirs/sub-*_run-*_nirs.', obj.filetype];
                }
                
                %%%% 6. BIDS #3
                {
                'sub-*';
                ['nirs/sub-*_*_nirs.', obj.filetype];
                }
                
                %%%% 7. BIDS #4 
                {
                '*';
                ['nirs/sub-*_*_nirs.', obj.filetype];
                }
                
                %%%% 8. BIDS folder structure
                {
                'sub-*';
                'ses-*';
                ['nirs/sub-*_run-*_nirs.', obj.filetype];
                }
                               
                %%%% 9. BIDS-like folder structure without file naming restrictions
                {
                'sub-*';
                'ses-*';
                ['nirs/*.', obj.filetype];
                }
                                
                %%%% 10. BIDS-like folder structure without nirs sub-folder
                {
                'sub-*';
                'ses-*';
                ['*.', obj.filetype];
                }
                                
                };
        end
        

            
        
        % ----------------------------------------------------
        function FindDataSet(obj, iFormat, iPattern, parentdir)
            if ~exist('iFormat','var')
                iFormat = 1;
            end
            if ~exist('iPattern','var')
                iPattern = 1;
            end            
            if ~exist('parentdir','var')
                parentdir = obj.rootdir;
            end
            
            if iFormat > length(obj.dirFormats.choices)
                return
            end
            if iPattern > length(obj.dirFormats.choices{iFormat})
                return
            end
            parentdir = filesepStandard(parentdir);
            
            % Check if folder is excluded, if yes don't search there
            for ii = 1:length(obj.excludedFolders)
                if includes(parentdir, obj.excludedFolders{ii})
                    return;
                end
            end
            
            pattern = obj.dirFormats.choices{iFormat}{iPattern};
            
            dirs = mydir([parentdir, pattern], obj.rootdir);
            
            dirnamePrev = '';
            for ii = 1:length(dirs)
                if dirs(ii).IsEmpty()
                    continue;
                end
                if dirs(ii).IsFile()
                    % If the pattern that found this file has no extension
                    % that means this pattern is meant ONLY for folders. 
                    % Therefore any file matches should be skipped. 
                    % Bug Fix - JD, Jun 20, 2023
                    [~,~,ext] = fileparts(pattern);
                    if isempty(ext)  
                        continue
                    end
                    if includes(dirs(ii).name, obj.filetype)
                        if ~strcmp(dirs(ii).name, dirnamePrev)
                            obj.AddParentDirs(dirs(ii));
                        end
                        obj.AddFile(dirs(ii));
                    end
                    
                    if obj.dirFormats.type == 0 
                        obj.dirFormats.type = iFormat;
                    end
                elseif dirs(ii).IsDir()
                    obj.FindDataSet(iFormat, iPattern+1, [parentdir, dirs(ii).filename])
                end
                dirnamePrev = dirs(ii).name;
            end
        end
        

        
        % ----------------------------------------------------
        function AddParentDirs(obj, dirname)
            pathrel = getPathRelative([dirname.rootdir, dirname.name], obj.rootdir);
            subdirs = str2cell_fast(pathrel, {'/','\'});
            N = length(subdirs);
            for ii = 1:N-1
                if strcmp(subdirs{ii}, 'nirs')
                    continue;
                end
                pathrel2 = buildpathfrompathparts(subdirs(1:ii));
                if obj.SearchLookupTable(pathrel2)
                    continue;
                end
                obj.files(end+1) = FileClass([obj.rootdir, '/', pathrel2], obj.rootdir);
                obj.AddLookupTable(obj.files(end).name)
            end
        end
        
        
        
        % ----------------------------------------------------
        function AddFile(obj, file)
            obj.files(end+1) = file;
            obj.nfiles = obj.nfiles+1;
            obj.AddLookupTable(obj.files(end).filename)
        end
        
        
        
        % ----------------------------------------------------
        function ErrorCheckName(obj)
            for ii = length(obj.files):-1:1
                if obj.files(ii).ErrorCheckName()<0
                    q = obj.AskToFixNameConflicts(ii);                    
                    if q == 1
                        obj.files(ii).FixNameConflict();
                    else
                        obj.files(ii).NameConflictFixed();
                    end
                end
                if obj.files(ii).GetError()<0
                    obj.err = -1;
                end
            end
        end
        
        
        
        % ----------------------------------------------------
        function ErrorCheckFinal(obj)
            obj.ErrorCheckName();
            
            % Find all acquisition files in group folder
            fileNames = findTypeFiles(obj.rootdir, ['.', obj.filetype], obj.excludedFolders);
            
            % Make a list of all files excluded from current data set  
            for ii = 1:length(fileNames)
                filefound = false;
                
                for jj = 1:length(obj.files)
                    if pathscompare(fileNames{ii}, [obj.rootdir, obj.files(jj).name])
                        filefound = true;
                        break;
                    end
                end
                
                for jj = 1:length(obj.filesErr)
                    if pathscompare(fileNames{ii}, [obj.rootdir, obj.filesErr(jj).name])
                        filefound = true;
                        break;
                    end
                end
                
                if ~filefound
                    obj.filesErr(end+1) = FileClass(fileNames{ii});
                    obj.filesErr(end).SetError('Invalid File Name');
                end
            end
        
        end
        
        
        
        % --------------------------------------------------------------------------
        function answer = AskToFixNameConflicts(obj, ii)
            global cfg
            
            ConfigFileClass
            answer = 0;
            if obj.config.AskToFixNameConflicts == 0
                obj.files(ii).NameConflictFixed();
                return
            end
            q = MenuBox(obj.GetErrorMsg(ii), {'YES','NO'},[],[],'askEveryTimeOptions');
            if q(1) == 0
                return;
            end
            if length(q)>1 && q(2) == 1
                cfg.SetValue('Fix File Name Conflicts', sprintf('don''t ask again'));
                cfg.Save()
                obj.config.AskToFixNameConflicts = 0;
            end
            if q(1)==2
                obj.files(ii).NameConflictFixed();
            end
            answer = q(1);
        end
        
        
        
        % -----------------------------------------------------
        function errmsg = GetErrorMsg(obj, ii)
            p1      = fileparts(obj.files(ii).GetName());
            [p2,f2] = fileparts(filesepStandard(obj.files(ii).rootdir,'nameonly:file'));
            [~,f3]  = fileparts(p2);
            if isfile_private(obj.files(ii).GetName())
                filetype = 'file'; %#ok<*PROPLC>
            else
                filetype = 'folder';
            end
            containingFolder = '';
            if obj.files(ii).GetError() == -1
                containingFolder = p1;
            end
            if obj.files(ii).GetError() == -2
                containingFolder = f2;
            end
            if obj.files(ii).GetError() == -3
                containingFolder = f3;
            end
            msg{1} = sprintf('WARNING: The current %s (%s) has the same name as the folder (%s) containing it. ', filetype, obj.files(ii).GetName(), containingFolder);
            msg{2} = sprintf('All %ss should have a different name than the folder containing them, otherwise ', ['F',filetype(2:end)]);
            msg{3} = sprintf('it may cause incorrect results in processing. Do you want to rename this %s?', filetype);
            errmsg = [msg{:}];            
        end
        

        
        % -------------------------------------------------------
        function pushbuttonLoadDataset_Callback(~, hObject)
            hp = get(hObject,'parent');
            hc = get(hp,'children');
            for ii = 1:length(hc)
                
                if strcmp(get(hc(ii),'tag'),'pushbuttonLoad')
                    hButtnLoad = hc(ii);
                elseif strcmp(get(hc(ii),'tag'),'pushbuttonSelectAnother')
                    hButtnSelectAnother = hc(ii);
                end
                
            end
            
            if hObject==hButtnLoad
                delete(hButtnSelectAnother);
            elseif hObject==hButtnSelectAnother
                delete(hButtnLoad);
            end
            delete(hp);
        end
            
        
        % ----------------------------------------------------------
        function b = IsEmpty(obj)
            if isempty(obj.files)
                b = true;
            else
                b = false;
            end
        end
       
        
                
        % ----------------------------------------------------------
        function found = ConvertedFrom(obj, src)
            found = zeros(length(src.files), 1);
            for ii = 1:length(src.files)
                if src.files(ii).isdir
                    found(ii) = -1;
                    continue;
                end
                [ps, fs] = fileparts(src.files(ii).name);
                
                % Search both:  files found without error  AND  files found with error
                for jj = 1:length(obj.files)
                    [pd, fd] = fileparts(obj.files(jj).name);
                    if strcmp(filesepStandard([ps,'/',fs], 'nameonly'), filesepStandard([pd,'/',fd], 'nameonly'))
                        found(ii) = 1;
                        break;
                    end
                end
                if found(ii) == 1
                    continue;
                end
                for jj = 1:length(obj.filesErr)
                    [pd, fd] = fileparts(obj.filesErr(jj).name);
                    if strcmp(filesepStandard([ps,'/',fs], 'nameonly'), filesepStandard([pd,'/',fd], 'nameonly'))
                        found(ii) = 1;
                        break;
                    end
                end
            end
        end
        
        
        
        % ----------------------------------------------------------
        function ErrorCheck(obj)
            errorIdxs = [];

            if isempty(obj.files)
                return
            end
                       
            % Assume constructor name follows from name of data format type
            constructor = sprintf('%sClass', [upper(obj.filetype(1)), obj.filetype(2:end)]);
            
            % Make sure function by that name exists; otherwise no way to
            % use it to check loadability
            if isempty(which(constructor))
                return;
            end
            
            % Try to create object of data filetype and load data into it
            msg = 'Please wait while we check group folder for valid data files ...';
            hwait = waitbar_improved(0, msg);
            for ii = 1:length(obj.files)
                if obj.files(ii).isdir
                    continue;
                end
                filename = [obj.rootdir, obj.files(ii).name]; %#ok<NASGU>
                eval( sprintf('o = %s(filename);', constructor) );
                if  o.GetError() < 0
                    msg = sprintf('DataFilesClass.ErrorCheck - "%s" ERROR:\n%s\n', obj.files(ii).name, o.GetErrorMsg());
                    obj.LogError(msg, obj.files(ii));
                    errorIdxs = [errorIdxs, ii]; %#ok<AGROW>
                elseif o.GetError() > 0
                    if ~o.IsDataValid()
                        msg = sprintf('DataFilesClass.ErrorCheck - "%s" WARNING:\n%s\n', obj.files(ii).name, o.GetErrorMsg());
                        obj.LogError(msg, obj.files(ii));
                        errorIdxs = [errorIdxs, ii]; %#ok<AGROW>
                    else
                    	obj.logger.Write(sprintf('DataFilesClass.ErrorCheck - "%s" WARNING:\n%s\n', obj.files(ii).name, o.GetErrorMsg()));
                    end
                end
                if ~isempty(o.GetErrorMsg())
                    obj.files(ii).SetError(o.GetErrorMsg());
                end
                hwait = waitbar_improved(ii/length(obj.files), hwait, msg);
            end

            obj.AddErrorFiles(errorIdxs);
            if obj.nfiles == 0
                obj.files = FileClass.empty();
            end            
            close(hwait);
        end
        
        
        
        % ----------------------------------------------------------
        function AddErrorFiles(obj, errorIdxs)
            for jj = 1:length(errorIdxs)
                % Make sure new error file we are adding is unique. It's
                % possible to double count a file because a folder pattern
                % match could have the same root folder (e.g., pattern 1
                % and 2)
                alreadyExists = false;
                for kk = 1:length(obj.filesErr)
                    if strcmp(obj.filesErr(kk).name, obj.files(errorIdxs(jj)).name)
                        alreadyExists = true;
                        break;
                    end
                end
                if ~alreadyExists
                    obj.filesErr(end+1) = obj.files(errorIdxs(jj)).copy;
                end
            end
            obj.files(errorIdxs) = [];
            obj.nfiles = obj.nfiles - length(errorIdxs);
        end
        

        
        % ----------------------------------------------------------
        function alreadyExists = LogError(obj, msg, file)
            alreadyExists = false;
            for kk = 1:length(obj.filesErr)
                if strcmp(obj.filesErr(kk).name, file.name)
                    alreadyExists = true;
                    break;
                end
            end
            if ~alreadyExists
                obj.logger.Write(msg)
            end
        end
        

        
        % ----------------------------------------------------------
        function err = GetError(obj)
            err = -1;
            if isempty(obj)
                return;
            end
            err = obj.err;
        end
                   
        % ----------------------------------------------------------
        function PrintFolderStructure(obj, options)
            if ~exist('options','var')
                options = '';
            end
            stepsize = 3;
            obj.logger.Write('\n');
            obj.logger.Write('DataTreeClass - Data Set Folder Structure:\n');
            for ii = 1:length(obj.files)
                k = length(find(obj.files(ii).name=='/'));   
                if ii<10
                    j=3; 
                elseif ii>9 && ii<100
                    j=2;
                else
                    j=3;
                end
                if optionExists(options, 'flat')
                    obj.logger.Write(sprintf('%d.%s%s\n', ii, blanks(j), obj.files(ii).name));
                else
                    if ii<10
                        j=3; 
                    elseif ii>9 && ii<100
                        j=2; 
                    else 
                        j=3; 
                    end
                    if optionExists(options, 'numbered')
                        n = k*stepsize+stepsize+j;
                        obj.logger.Write(sprintf('%d.%s%s\n', ii, blanks(n), obj.files(ii).filename));
                    else
                        n = k*stepsize+stepsize;
                        obj.logger.Write(sprintf('%s%s\n', blanks(n), obj.files(ii).filename));
                    end
                end
            end
            obj.logger.Write('\n');
        end
        
    end
        
    
    
    methods (Access = private)

        % ----------------------------------------------------------
        function InitLookupTable(obj)
            width = 4;
            if isempty(obj.lookupTable)
                obj.lookupTable = int32(zeros((10^width)-1, 1));
            else
                obj.lookupTable(:) = 0;                
            end
        end

        
        % ----------------------------------------------------------
        function AddLookupTable(obj, str)
            n = round(log10(length(obj.lookupTable)));
            obj.lookupTable(string2hash(str, n)) = 1;
        end

        
        % ----------------------------------------------------------
        function b = SearchLookupTable(obj, str)
            n = round(log10(length(obj.lookupTable)));
            b = obj.lookupTable(string2hash(str, n));
        end
        
        
    end
end
