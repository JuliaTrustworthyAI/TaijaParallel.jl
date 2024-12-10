module MPIExt

export MPIParallelizer

using Logging
using MPI
using ProgressMeter
using TaijaBase
using TaijaParallel

"The `MPIParallelizer` type is used to parallelize the evaluation of a function using `MPI.jl`."
struct MPIParallelizer <: TaijaParallel.AbstractParallelizer
    comm::MPI.Comm
    rank::Int
    n_proc::Int
    n_each::Union{Nothing,Int}
    threaded::Bool
    active_comm::MPI.Comm
end

"""
    MPIParallelizer(comm::MPI.Comm)

Create an `MPIParallelizer` object from an `MPI.Comm` object. Optionally, specify the number of observations to send to each process using `n_each`. If `n_each` is `nothing`, then all observations will be split into equally sized bins and sent to each process. If `threaded` is `true`, then the `MPIParallelizer` will use `Threads.@threads` to further parallelize the evaluation of a function.
"""
function TaijaParallel.MPIParallelizer(
    comm::MPI.Comm;
    n_each::Union{Nothing,Int} = nothing,
    threaded::Bool = false,
    active_comm::Union{Nothing,MPI.Comm} = comm
)
    rank = MPI.Comm_rank(comm)                                  # Rank of this process in the world 🌍
    n_proc = MPI.Comm_size(comm)                                # Number of processes in the world 🌍
    active_comm = isnothing(active_comm) ? comm : active_comm   # Active communication channel (if specified)

    if rank == 0
        @info "Using `MPI.jl` for multi-processing."
        println("Running on $n_proc processes.")
    end

    if !isnothing(n_each)
        @assert n_each > 0 "The number of observations to send to each process must be greater than zero."
        if threaded && n_each < Threads.nthreads()
            @warn "The number of observations to send to each process is less than the number of threads per process."
        end
    end

    return MPIParallelizer(comm, rank, n_proc, n_each, threaded, active_comm)
end

include("generate_counterfactual.jl")
include("evaluate.jl")
include("comms.jl")

end
