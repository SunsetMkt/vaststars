require "register.types"

local status = require "status"
local prototype = require "prototype"
local vaststars = require "vaststars.world.core"
local container = require "vaststars.container.core"
local luaecs = import_package "vaststars.ecs"
local entity_visitor = require "entity_visitor"

local function pipeline(world, cworld, name)
    local p = status.pipelines[name]
    if not p then
        return
    end
    local systems = status.systems
    local csystems = status.csystems
    local funcs = {}
    for _, stage in ipairs(p) do
        for _, s in pairs(systems) do
            if s[stage] then
                funcs[#funcs+1] = function(...)
                    return s[stage](world, ...)
                end
            end
        end
        for _, s in pairs(csystems) do
            if s[stage] then
                funcs[#funcs+1] = function(...)
                    return s[stage](cworld, ...)
                end
            end
        end
    end
    local n = #funcs
    return function (...)
        for i = 1, n do
            funcs[i](...)
        end
    end
end

return function ()
    local world = {}
    local needBuild = false
    local ecs = luaecs.world()
    local timer = dofile(package.searchpath("timer", package.path))
    local components = {}
    for _, c in ipairs(status.components) do
        assert(c.type == nil)
        ecs:register(c)
        components[#components+1] = c.name
    end

    ecs:register {
        name = "id",
        type = "int",
    }
    ecs:register {
        name = "fluidbox_changed"
    }
    ecs:make_index "id"

    local context = ecs:context(components)
    local ptable = require "vaststars.prototype.core"
    local cworld = vaststars.create_world(context, ptable)
    world.ecs = ecs
    world._cworld = cworld
    world._context = context

    function world:create_entity(type)
        return function (init)
            local typeobject = assert(prototype.queryByName("entity", type), "unknown entity: " .. type)
            local types = typeobject.type
            local obj = {}
            for i = 1, #types do
                local funcs = status.typefuncs[types[i]]
                if funcs and funcs.ctor then
                    for k, v in pairs(funcs.ctor(world, init, typeobject)) do
                        if obj[k] == nil then
                            obj[k] = v
                        end
                    end
                end
            end
            obj.id = (obj.entity.y << 8) | obj.entity.x
            ecs:new(obj)
            needBuild = true
            return obj.id
        end
    end

    function world:remove_entity(v)
        ecs:remove(v)
        needBuild = true
    end

    world.entity = entity_visitor(ecs, "id")

    local pipeline_update = pipeline(world, cworld, "update")
    local pipeline_clean = pipeline(world, cworld, "clean")
    local pipeline_build = pipeline(world, cworld, "build")
    local pipeline_backup = pipeline(world, cworld, "backup")
    local pipeline_restore = pipeline(world, cworld, "restore")

    function world:update()
        assert(not needBuild)
        pipeline_update()
        timer.update(1)
        ecs:update()
    end
    function world:build()
        needBuild = false
        pipeline_clean()
        ecs:update()
        pipeline_build()
        ecs:update()
    end
    function world:backup(rootdir)
        local fs = require "bee.filesystem"
        fs.create_directories(rootdir)
        pipeline_backup(rootdir)
    end
    function world:restore(rootdir)
        cworld:reset()
        pipeline_restore(rootdir)
        for v in ecs:select "entity:in id:new" do
            v.id = (v.entity.y << 8) | v.entity.x
        end
        needBuild = true
    end

    function world:is_researched(tech)
        local pt = prototype.queryByName("tech", tech)
        assert(pt, "unknown tech: " .. tech)
        return cworld:is_researched(pt.id)
    end

    function world:research_queue(queue)
        if queue == nil then
            local q = cworld:research_queue()
            for i, v in ipairs(q) do
                local pt = prototype.queryById(v)
                assert(pt, "unknown tech: " .. v)
                q[i] = pt.name
            end
            return q
        else
            local q = {}
            for i, v in ipairs(queue) do
                local pt = prototype.queryByName("tech", v)
                assert(pt, "unknown tech: " .. v)
                q[i] = pt.id
            end
            return cworld:research_queue(q)
        end
    end

    function world:research_progress(tech)
        local pt = prototype.queryByName("tech", tech)
        assert(pt, "unknown tech: " .. tech)
        return cworld:research_progress(pt.id)
    end

    function world:manual(lst)
        if lst == nil then
            lst = {}
            for _, v in ipairs(cworld:manual()) do
                local type, id = v[1], v[2]
                local pt = prototype.queryById(id)
                assert(pt, "unknown ID: " .. id)
                lst[#lst+1] = {type, pt.name}
            end
            return lst
        end
        local todos = {}
        for i, v in ipairs(lst) do
            local type, id = v[1], v[2]
            if type == "crafting" then
                local pt = prototype.queryByName("recipe", id)
                assert(pt, "unknown recipe: " .. id)
                todos[i] = { type, pt.id }
            elseif type == "finish" then
                local pt = prototype.queryByName("item", id)
                assert(pt, "unknown item: " .. id)
                todos[i] = { type, pt.id }
            else
                error("unknown type: "..type)
            end
        end
        local errcode = cworld:manual(todos)
        if errcode == "failed" then
            return false
        end

        local STATUS_REBUILD <const> = 3
        for v in ecs:select "manual:update" do
            local manual = v.manual
            manual.status = STATUS_REBUILD
            if errcode == "reset" then
                manual.recipe = 0
                manual.progress = 0
            end
        end
        return true
    end

    function world:manual_container()
        local c = {}
        local cc = cworld:manual_container()
        for k, v in pairs(cc) do
            local pt = prototype.queryById(k)
            assert(pt, "unknown ID: " .. k)
            c[pt.name] = v
        end
        return c
    end

    function world:fluidflow_query(fluid, id)
        return cworld:fluidflow_query(fluid, id)
    end

    function world:container_create(...)
        return container.create(cworld, ...)
    end
    function world:container_pickup(...)
        return container.pickup(cworld, ...)
    end
    function world:container_place(...)
        return container.place(cworld, ...)
    end
    function world:container_get(...)
        return container.get(cworld, ...)
    end

    function world:wait(...)
        return timer.wait(...)
    end
    function world:loop(...)
        return timer.loop(...)
    end

    return world
end
