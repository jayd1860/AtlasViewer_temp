function sd_file_load_bttn_Callback(~, ~, handles)

filename0 = sd_filename_edit_Get(handles);
pathname0 = sd_file_panel_GetPathname(handles);

% Convert pathname to full path and filename to filename ONLY (no path
% info at all)
[pname, fname, ext] = fileparts(fullpath([pathname0, filename0]));
pathname = filesepStandard(pname);
filename = [fname, ext];

file = [];
if ~isempty(filename)
    file = dir([pathname, filename]);
end
if isempty(file)
    % if exist([pathname, filename],'file')~=2
    [filename, pathname] = uigetfile({'*.SD; *.sd; *.nirs; *.snirf'}, 'Open SD file', [pathname, filename]);
    if filename==0
        set(handles.sd_filename_edit, 'string', filename0);
        return;
    end
end
sd_file_open(filename, pathname, handles);
