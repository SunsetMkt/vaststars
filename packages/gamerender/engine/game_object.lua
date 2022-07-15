local ecs = ...
local world = ecs.world
local w = world.w

local cr = import_package "ant.compile_resource"
local serialize = import_package "ant.serialize"
local prefab_path <const> = "/pkg/vaststars.resources/%s"
local game_object_event = ecs.require "engine.game_object_event"

local function _replace_material(template)
    for _, v in ipairs(template) do
        for _, policy in ipairs(v.policy) do
            if policy == "ant.render|render" or policy == "ant.render|simplerender" then
                v.data.material = "/pkg/vaststars.resources/materials/translucent.material"
            end
        end
    end

    return template
end

local function _is_animation_entity(e)
    return e.anim_ctrl and e.meshskin
end

local function on_prefab_ready(prefab, binding)
    for _, eid in ipairs(prefab.tag["*"]) do
        local e = world:entity(eid)
        if _is_animation_entity(e) then
            binding.animation_eid = eid
        end
        if e.slot then
            binding.slot[e.name] = e.slot
        end
    end
end

local function on_prefab_message(prefab, binding, cmd, ...)
    local event = game_object_event[cmd]
    if event then
        event(prefab, binding, ...)
    else
        log.error(("game_object unknown event `%s`"):format(cmd))
    end
end

local _instance_hash ; do
    local get_hash_func; do
        function get_hash_func()
            local cache = {}
            local n = 0
            return function(s)
                if cache[s] then
                    return cache[s]
                else
                    n = n + 1
                    assert(n <= 0xff)
                    cache[s] = n
                    return n
                end
            end
        end
    end

    local prefab_name_hash = get_hash_func()
    local state_hash = get_hash_func()
    local color_hash = get_hash_func()
    local animation_hash = get_hash_func()
    local process_hash = get_hash_func()

    function _instance_hash(prefab_file_name, state, color, animation_name, process)
        local h1 = prefab_name_hash(prefab_file_name or 0)
        local h2 = state_hash(state or 0)
        local h3 = color_hash(color or 0)
        local h4 = animation_hash(animation_name or 0)
        local h5 = process_hash(process or 0)

        return h1 | (h2 << 8) | (h3 << 16) | (h4 << 24) | (h5 << 32) -- assuming 255 types of every parameter at most
    end
end

local _get_hitch_children ; do
    local cache = {} -- prefab_file_name + state + color -> object
    local hitch_group_id = 10000 -- see also: terrain.lua -> TERRAIN_MAX_GROUP_ID

    function _get_hitch_children(prefab_file_name, state, color, animation_name, process)
        local param = _instance_hash(prefab_file_name, state, tostring(color), animation_name, process)
        if cache[param] then
            return cache[param].hitch_group_id
        end

        log.info(("game_object.new_instance: %s"):format(table.concat({prefab_file_name, state, require("math3d").tostring(color), animation_name, process}, " "))) -- TODO: remove this line

        local f = prefab_path:format(prefab_file_name)
        local template

        if state == "translucent" then -- translucent or opaque
            template = _replace_material(serialize.parse(f, cr.read_file(f)))
        else
            template = f
        end

        local binding = {
            prefab_file_name = prefab_file_name, -- for debug
            animation_eid = 0, -- equal to 0 means no animation, will be set later in on_prefab_ready()
            slot = {}, -- slot[name] = slot
        }

        hitch_group_id = hitch_group_id + 1
        ecs.group(hitch_group_id):enable "scene_update"

        local g = ecs.group(hitch_group_id)
        local prefab = g:create_instance(template)
        prefab.on_ready = function(prefab)
            world:entity(prefab.root).standalone_scene_object = true
            for _, eid in ipairs(prefab.tag["*"]) do
                world:entity(eid).standalone_scene_object = true
            end
            on_prefab_ready(prefab, binding)
        end
        prefab.on_message = function(prefab, ...)
            on_prefab_message(prefab, binding, ...)
        end

        local instance = world:create_object(prefab)
        if state == "translucent" then
            instance:send("set_material_property", "u_basecolor_factor", color)
        end
        if animation_name and process then
            instance:send("animation_play", {name = animation_name, process = process, loop = false, manual = true})
            instance:send("animation_set_time", animation_name, process)
        end

        cache[param] = {instance = instance, hitch_group_id = hitch_group_id }
        return hitch_group_id
    end
end

local M = {}
function M.create(prefab_file_name, cull_group_id, state, color, srt)
    local children = _get_hitch_children(prefab_file_name, state, color, nil, nil)
    local hitch_eid = ecs.group(cull_group_id):create_entity{
        policy = {
            "ant.scene|hitch_object",
            "ant.general|name",
        },
        data = {
            name = prefab_file_name,
            scene = {
                s = srt.s,
                t = srt.t,
                r = srt.r,
            },
            hitch = {
                group = children,
            },
        }
    }

    local function remove(self)
        world:remove_entity(self.hitch_eid)
    end
    local function update(self, prefab_file_name, state, color, animation_name, process)
        local hitch = world:entity(self.hitch_eid)
        hitch.hitch.group = _get_hitch_children(prefab_file_name, state, color, animation_name, process)
    end
    local function attach(self, slot_name, model)
        -- get the annimation entity by slot_name?
        -- world:entity(hitch_eid).slot.anim_eid = anim_eid
    end
    local function detach(self)
    end

    local outer = {hitch_eid = hitch_eid, slot_attach = {}}
    outer.remove = remove
    outer.update = update
    outer.attach = attach
    outer.detach = detach
    return outer
end
return M