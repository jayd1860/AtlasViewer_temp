function err = write_numeric_array(fid, name, data)
err = 0;
data = HDF5_Transpose(data);
sizedata = size(data);
if sizedata(1) == 1 || sizedata(2) == 1
    n = length(data);
else
    n = sizedata;
end

tid = -1;
sid = -1;
gid = -1;
dsid = -1;

maxdims = n;
try
    
    tid = H5T.copy("H5T_NATIVE_DOUBLE");
    sid = H5S.create_simple(2, fliplr(maxdims), fliplr(maxdims));
    
    % If the dataset is being created in the root group, then the full group name is '/'
    gname = fileparts(name);
    gid = HDF5_CreateGroup(fid, gname);
    dsid = H5D.create(gid, name, tid, sid, 'H5P_DEFAULT');
    H5D.write(dsid, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);
    
catch
    
    % Clean up; Close everything
    cleanUp(tid, sid, gid, dsid);
    err = -1;
    return;
    
end
cleanUp(tid, sid, gid, dsid);



% ------------------------------------------------------
function cleanUp(tid, sid, gid, dsid)
if ~isnumeric(tid)
    H5T.close(tid);
end
if ~isnumeric(sid)
    H5S.close(sid);
end
if ~isnumeric(gid)
    H5G.close(gid);
end
if ~isnumeric(dsid)
    H5D.close(dsid);
end


