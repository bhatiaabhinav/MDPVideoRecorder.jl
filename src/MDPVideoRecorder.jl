module MDPVideoRecorder

using MDPs
using FileIO
using Colors
using Luxor

export VideoRecorder

struct VideoRecorder <: AbstractHook
    dirname::String
    format::String
    interval::Int
    fps::Int
    frames::Vector{Matrix{RGB{Colors.N0f8}}}
    display_stats_dict
    function VideoRecorder(dirname, format="mp4"; interval=1, fps=30, display_stats_dict=nothing)
        @assert format ∈ ["mp4", "gif"] "Only mp4 or gif are supported"
        rm(dirname, recursive=true, force=true)
        mkpath(dirname)
        new(dirname, format, interval, fps, [], display_stats_dict)
    end
end


function MDPs.preepisode(vr::VideoRecorder; kwargs...)
    empty!(vr.frames)
end

function MDPs.poststep(vr::VideoRecorder; env, returns, kwargs...)
    if length(returns) % vr.interval == 0
        viz = convert(Matrix{RGB{Colors.N0f8}}, visualize(env))
        if vr.display_stats_dict !== nothing
            H, W = size(viz)
            Drawing(W, H, :image)
            Drawing(W, H, :image)
            background("white")
            fontface("courier new")
            fs = 10
            fontsize(fs)
            origin(Point(1, 1))
            items = vr.display_stats_dict()
            for (i, item) in enumerate(items)
                text(string(item), Point(0, fs * i), halign=:left, valign=:top)
            end
            vizstats = convert(Matrix{RGB{Colors.N0f8}}, image_as_matrix())
            if H > W
                viz = hcat(viz, vizstats)
            else
                viz = vcat(viz, vizstats)
            end
        end
        push!(vr.frames, viz)
    end
    nothing
end

function MDPs.postepisode(vr::VideoRecorder; steps, returns, kwargs...)
    if length(returns) % vr.interval == 0
        fn = "$(vr.dirname)/ep-$(length(returns))-steps-$(steps)-return-$(returns[end]).$(vr.format)"
        if vr.format == "mp4"
            save(fn, vr.frames)
        elseif vr.format == "gif"
            save(fn, cat(vr.frames..., dims=3), fps=vr.fps)
        end
    end
    nothing
end



end # module MDPVideoRecorder
