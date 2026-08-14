"""
    MPIParallelizer

Exposes the `MPIParallelizer` function from the `MPIExt` extension.
"""
function MPIParallelizer end
export MPIParallelizer

global _active_comm = nothing

function set_active_comm(comm)
    global _active_comm = comm
    return _active_comm
end

get_active_comm() = _active_comm