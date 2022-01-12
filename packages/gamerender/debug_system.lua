local ecs = ...
local world = ecs.world
local w = world.w

---
local print_srt; do
    local math3d = require "math3d"
    local iom = ecs.import.interface "ant.objcontroller|iobj_motion"

    function print_srt(e)
        print("print_str", tostring(e))
        print("position", table.concat(math3d.tovalue(iom.get_position(e)), ","))
        print("rotation", table.concat(math3d.tovalue(iom.get_rotation(e)), ","))
    end
end

--
local get_track_joint; do
    local hierarchy = require "hierarchy"
    local animation = hierarchy.animation
    local skeleton = hierarchy.skeleton

    function get_track_joint(translations, rotations, duration, ratio)
        local raw_animation = animation.new_raw_animation()
        raw_animation:push_key(translations, rotations, duration)
        local skl = skeleton.build({{name = "root", s = {1.0, 1.0, 1.0}, r = {0.0, 0.0, 0.0, 1.0}, t = {0.0, 0.0, 0.0}}})
        local poseresult = animation.new_pose_result(1)
        poseresult:setup(skl)
        poseresult:do_sample(animation.new_sampling_context(), raw_animation:build(), ratio)
        poseresult:fetch_result()
        if poseresult:count() < 1 then
            return
        end

        return poseresult:joint(1)
    end
end

local get_fluid_material_mat; do
    local iom = ecs.import.interface "ant.objcontroller|iobj_motion"
    local animation = require "hierarchy".animation
    local new_vector_float3 = animation.new_vector_float3
    local new_vector_quaternion = animation.new_vector_quaternion

    local cache = {}
    function get_fluid_material_mat(game_object, ratio)
        -- if cache[ratio] then
        --     return cache[ratio]
        -- end

        w:sync("prefab_slot_cache:in", game_object)
        local slot_cache = game_object.prefab_slot_cache
        if not slot_cache then
            return
        end

        local translations = new_vector_float3()
        local rotations = new_vector_quaternion()
        for _, slot_name in ipairs({"empty", "full"}) do
            local e = slot_cache[slot_name]
            translations:insert(iom.get_position(e))
            rotations:insert(iom.get_rotation(e))
        end

        local mat = get_track_joint(translations, rotations, 10.0, ratio)
        cache[ratio] = mat
        return mat
    end
end

local m = ecs.system 'debug_system'
local debug_mb = world:sub {"debug"}
local funcs = {}
local test_funcs = {}

local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"
local function get_debug_component(debug)
    for game_object in w:select "debug_component:in" do
        if game_object.debug_component == debug then
            return game_object
        end
    end
end

local function get_debug_prefab(debug)
    local game_object = get_debug_component(debug)
    if not game_object then
        -- print(("Can not found debug component `%s`"):format(debug))
        return
    end
    return igame_object.get_prefab_object(game_object)
end

local function get_debug_prefab_object(debug)
    local game_object = get_debug_component(debug)
    if not game_object then
        -- print(("Can not found debug component `%s`"):format(debug))
        return
    end
    return igame_object.get_prefab_object(game_object)
end

local function remove_debug_prefab(debug)
    local prefab = get_debug_prefab_object(debug)
    if prefab then
        prefab:remove()
    end
end

------
-- test animation
funcs[1] = function ()
    local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"
    local prefab
    for game_object in w:select "inserter:in" do
        prefab = igame_object.get_prefab_object(game_object)
        prefab:send("play_animation_once", "DownToUp")
    end
end

funcs[2] = function ()
    local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"
    local prefab
    for game_object in w:select "inserter:in" do
        prefab = igame_object.get_prefab_object(game_object)
        prefab:send("play_animation_once", "UpToDown")
    end
end

test_funcs[1] = function ()
    local animation_mb = world:sub {"animation"}
    for _, name, action, game_object in animation_mb:unpack() do
        local slot_name <const> = "货物挂点"
        local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"
        local prefab = igame_object.get_prefab_object(game_object)
        if action == "play" then
            local sprefab = ecs.create_instance("/pkg/vaststars.resources/rock.prefab")
            sprefab.on_message = function(prefab, cmd)
                if cmd == "remove" then
                    prefab:remove()
                end
            end
            prefab:send("slot_attach", slot_name, world:create_object(prefab))
        elseif action == "stop" then
            prefab:send("slot_detach", slot_name, slot_name)
        end
    end
end

------
funcs[3] = function ()
    local iroad = ecs.import.interface "vaststars.gamerender|iroad"
    local iom = ecs.import.interface "ant.objcontroller|iobj_motion"
    local iprefab_object = ecs.import.interface "vaststars.gamerender|iprefab_object"

    local t = {
        {{}       , {123,129}},
        {{123,129}, {123,128}},
        {{123,128}, {124,128}},
        {{124,128}, {125,128}},
        {{125,128}, {125,129}},
        {{125,128}, {125,127}},
        {{125,128}, {126,128}},
        {{126,128}, {127,128}},
        {{127,128}, {128,128}},
        {{128,128}, {129,128}},
        {{129,128}, {130,128}},
        {{130,128}, {131,128}},
        {{131,128}, {132,128}},
        {{132,128}, {132,129}},
        {{132,128}, {133,128}},
        {{132,128}, {132,127}},
        {{132,129}, {132,130}},
        {{132,130}, {131,130}},
    }

    for _, v in ipairs(t) do
        if #v[1] > 0 then
            iroad.construct(v[1], v[2])
        else
            iroad.construct(nil,  v[2])
        end
    end

    -- add logistics_center
    local new_prefab = ecs.create_instance(("/pkg/vaststars.resources/%s"):format("logistics_center.prefab"))
    local srt = {
        s = {1.0,1.0,1.0,0.0},
        r = {0.0,0.0,0.0,1.0},
        t = {-50.0,0.0,30.0,1.0},
    }
    iom.set_srt(new_prefab.root, srt.s, srt.r, srt.t)
    local template = {
        policy = {
            "ant.general|name",
            "vaststars.gamerender|building",
        },
        data = {
            name = "",
            building = {
                building_type = "logistics_center",
                area = {3, 3},
            },
            stop_ani_during_init = true,
            set_road_entry_during_init = true,
            pickup_show_ui = {url = "route.rml"},
            route_endpoint = true,
            named = true,
        },
    }
    template.data.building.tile_coord = {0x7b,0x83}
    iprefab_object.create(new_prefab, template)

    -- add logistics_center
    local new_prefab = ecs.create_instance(("/pkg/vaststars.resources/%s"):format("logistics_center.prefab"))
    local srt = {
        s = {1.0,1.0,1.0,0.0},
        r = {0.0,0.0,0.0,1.0},
        t = {30.0,0.0,40.0,1.0},
    }
    iom.set_srt(new_prefab.root, srt.s, srt.r, srt.t)
    local template = {
        policy = {
            "ant.general|name",
            "vaststars.gamerender|building",
        },
        data = {
            name = "",
            building = {
                building_type = "logistics_center",
                area = {3, 3},
            },
            stop_ani_during_init = true,
            set_road_entry_during_init = true,
            pickup_show_ui = {url = "route.rml"},
            route_endpoint = true,
            named = true,
        },
    }
    template.data.building.tile_coord = {0x83,0x84}
    iprefab_object.create(new_prefab, template)

    --
end

-- test track
do
    local iom = ecs.import.interface "ant.objcontroller|iobj_motion"

    local math3d        = require "math3d"
    local animation = require "hierarchy".animation
    local new_vector_float3 = animation.new_vector_float3
    local new_vector_quaternion = animation.new_vector_quaternion

    local translations
    local rotations
    local ratio = 1.1
    local times = 0

    funcs[4] = function ()
        translations = new_vector_float3()
        rotations = new_vector_quaternion()

        local prefab = get_debug_prefab(1)
        for _, e in ipairs(prefab.tag["*"]) do
            w:sync("slot?in name:in", e)
            if e.slot and e.name:match("^path.*$") then
                translations:insert(iom.get_position(e)) -- add translation key
                rotations:insert(iom.get_rotation(e))    -- add rotation key
            end
        end

        ratio = 0
        times = 0

        remove_debug_prefab(2)
        -- add lorry
        local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"
        local prefab_file_name = "/pkg/vaststars.resources/lorry.prefab"
        local prefab = ecs.create_instance(prefab_file_name)
        prefab.on_message = function()
        end
        igame_object.new(prefab, {
            data = {debug_component = 2},
        })
    end

    local ltask = require "ltask"
    local last_time = 0
    test_funcs[2] = function ()
        local prefab = get_debug_prefab(2)
        if not prefab then
            return
        end

        local _, now = ltask.now()
        if ratio <= 1 and now - last_time > 1 then
            local duration = 10.0
            local mat = get_track_joint(translations, rotations, duration, ratio)
            iom.set_srt(prefab.root, math3d.srt(mat))

            times = times + 1
            ratio = ratio + 0.01
            last_time = now

            -- print(times)
        end
    end
end

local test_ratio = 0
local pipe_fluid_cache = {}
funcs[5] = function()
    local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"
    local iprefab_object = ecs.import.interface "vaststars.gamerender|iprefab_object"
    local iom = ecs.import.interface "ant.objcontroller|iobj_motion"
    local imaterial = ecs.import.interface "ant.asset|imaterial"
    local math3d = require "math3d"

    test_ratio = test_ratio + 0.05
    if test_ratio > 0.5 then
        test_ratio = 0
    end
    for _, e in pairs(pipe_fluid_cache) do
        if e.remove then
            e:remove()
        else
            w:remove(e)
        end
    end
    pipe_fluid_cache = {}

    for game_object in w:select "pickup_show_set_pipe_arrow:in" do
        local prefab_object = igame_object.get_prefab_object(game_object)
        w:sync("scene:in", prefab_object.root)

        local mat = get_fluid_material_mat(game_object, test_ratio)
        if mat then
            local prefab = ecs.create_instance("/pkg/vaststars.resources/pipe/pipe_fluid.prefab")
            prefab.on_message = function() end
            prefab.on_ready = function(prefab)
                for _, e in ipairs(prefab.tag["*"]) do
                    if iprefab_object.has_tag(e, "uvmotion_pipe_fluid") then
                        imaterial.set_property(e, "u_uvmotion", {0, 0.1, 1.0, 1.0})
                    end
                end
            end
            pipe_fluid_cache[#pipe_fluid_cache+1] = world:create_object(prefab)

            local srt = math3d.mul(iom.worldmat(prefab_object.root), mat)
            iom.set_srt(prefab.root, math3d.srt(srt))
        end
    end
end

--------------
function m:ui_update()
    for _, i in debug_mb:unpack() do 
        local func = funcs[i]
        if func then
            func()
        end
    end

    for _, func in ipairs(test_funcs) do
        func()
    end
end
