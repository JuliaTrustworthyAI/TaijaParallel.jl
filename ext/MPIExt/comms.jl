global _active_comm::Union{Nothing,MPI.Comm} = nothing

function set_active_comm(comm::MPI.Comm)
    global _active_comm = comm
    return _active_comm
end

get_active_comm() = _active_comm