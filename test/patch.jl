read_csv_success_patch = @patch function TheGraphData.read(f; kwargs...)
    @info "TheGraphData.read stub => simulating success"
    return CSV.File(IOBuffer("X\nb\nc\na\nc"))
end
