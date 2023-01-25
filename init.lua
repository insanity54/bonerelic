br = {}
br.purple = 0x800080
br.green = 0x7fff7f
br.storage = minetest.get_mod_storage()


-- player metadata schemea



-- bonerelic ItemStackMetaRef schema
-- time
-- pos
-- player_name

-- set the death object in db
-- if both player and time are nil, db object is deleted
-- 
function br.set_death (player, time)
    -- create death entry in db

    -- add entry to index
end


-- get the death object from db
function br.get_death (player, time)
end


function br.remove_hud (entity)
    if not entity:is_player() then return end
    local player = entity
    local player_meta = player:get_meta()
    local hud = player_meta:get_string("bonerelic:hud")
    if hud == nil or hud == "" then return end

    player:hud_remove(hud)
end



-- get_death_index
--
-- the death index stores the player's deaths
-- the value stored is the {number} gametime of death
--
-- @example: {[1] = 10276, [2] = 12181, [3] = 12219}
function br.get_death_index(player)
    local player_meta = player:get_meta()
    local index = player_meta:get_string('bonerelic:index')
    if index == "" then index = "{}" end
    index = minetest.parse_json(index)
    return index
end

-- get_latest_death
--
-- @param {PlayerRef}
-- @return {table} death
-- @return {Vector} death.pos
-- @return {string} death.hud_id
function br.get_latest_death(player)
    assert(type(player) == "userdata")
    local death_index = br.get_death_index(player)
    if death_index == nil then return {} end
    local latest_time = death_index[#death_index]
    local player_meta = player:get_meta()
    local death_json = player_meta:get_string('bonerelic:'..player_name..':'..latest_time)
    if death_json == "" then return {} end
    local death = minetest.parse_json(death_json)
    return death
end


function br.transfer_meta(from_meta, to_meta)
    local time = from_meta:get_string('time')
    local player_name = from_meta:get_string('player_name')
    local pos = from_meta:get_string('pos')
    local color = from_meta:get_int('color')

    
    to_meta:set_string("time", time)
    to_meta:set_string("player_name", player_name)
    to_meta:set_string("pos", minetest.write_json(pos))
    to_meta:set_int("color", color)
end

-- create_relic
-- @return {ItemStack}
function br.create_relic (player_name, time, world_pos, color)
    local relic = ItemStack("bonerelic:relic")
    local relic_meta = relic:get_meta()
    relic_meta:set_string("time", time)
    relic_meta:set_string("player_name", player_name)
    relic_meta:set_string("pos", minetest.write_json(world_pos))
    relic_meta:set_int("color", color)
    return relic
end



function br.create_hud(pos, player, color)
    if type(pos) ~= "table" then return end
    if type(player) ~= "userdata" then return end

    local hud_def = {
        hud_elem_type = "waypoint",
        name = player:get_player_name().." died here.",
        text = " meters away",
        precision = 10,
        number = color,
        world_pos = pos
    }
    local hud_id = player:hud_add(hud_def)
    return hud_id
end

-- HOOKS

-- on_joinplayer
minetest.register_on_joinplayer(function(player, last_login)
    -- for each bonerelic in inv, create HUD waypoint
end)


-- on_dieplayer
-- when the player dies, save the world_pos of the last death
-- to the player metadata storage as bonerelic:last_death
minetest.register_on_dieplayer(function(player)
    -- create death entry in db
    local time = minetest.get_gametime()
    local player_meta = player:get_meta()
    local pos = player:get_pos()
    local death = {}
    death['pos'] = pos
    death['time'] = time
    player_meta:set_string('bonerelic:last_death', minetest.write_json(death))
end)

minetest.register_node('bonerelic:relic', {
    description = "Bone Relic\nShows the location of previous death",
    short_description = "Bone Relic",
    tiles = {
        "bonerelic_top.png",
        "bonerelic_top.png",
        "bonerelic_top.png",
        "bonerelic_top.png",
        "bonerelic_face.png",
        "bonerelic_face.png"
    },
    light_source = 0,
    paramtype = "light",
    paramtype2 = "facedir",
    inventory_image = "bonerelic_face.png",
    wield_image = "bonerelic_face.png",
    walkable = false,
    groups = {
        dig_immediate = 3, 
        attached_node = 1,
        flammable = 1,
        choppy = 2
    },
    sound = {
        breaks = "break.ogg"
    },
    preserve_metadata = function(pos, oldnode, oldmetadata, drops)

        local target_item = drops[1]
        local target_meta = target_item:get_meta()

        target_meta:set_string('player_name', oldmetadata['player_name'])
        target_meta:set_string('pos', oldmetadata['pos'])
        target_meta:set_string('time', oldmetadata['time'])
        target_meta:set_int('color', oldmetadata['color'])


    end,
    on_punch = function(pos, node, puncher, pointed_thing)

        local bonerelic_meta = minetest.get_meta(pos)


    end,
    on_take = function ()
    end,
    on_put = function ()

    end,
    on_use = function(itemstack, user, pointed_thing)
        -- clear any existing hud
        -- create new hud


        if not user:is_player() then return end
        local player = user
        local player_meta = player:get_meta()
        local hud = player_meta:get_int("bonerelic:hud")
        if hud ~= nil and hud ~= 0 then 
            player:hud_remove(hud)
        end

        local relic_meta = itemstack:get_meta()
        local world_pos_json = relic_meta:get_string('pos')

        if world_pos_json ~= "" then
            local color = relic_meta:get_int("color")

            if color == br.purple then 
                color = br.green
            else 
                color = br.purple
            end

            local world_pos = minetest.parse_json(world_pos_json)

            hud = br.create_hud(world_pos, player, color)


            if hud ~= nil then
                player_meta:set_string("bonerelic:hud", hud)
                relic_meta:set_int("color", color)
            end

            minetest.sound_play("bonerelic_tap", {
                pos = player:get_pos(), 
                gain = 0.3,
                max_hear_distance = 10
            })
            minetest.sound_play("bonerelic_taps", {
                pos = world_pos,
                gain = 1.0,
                max_hear_distance = 32
            })

        end


        return itemstack

    end,
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        -- local node_meta = minetest.get_meta(pos)

        -- local relic = br.create_relic(
        --     node_meta:get_string('player_name'),
        --     node_meta:get_string('time'),
        --     node_meta:get_string('pos'),
        --     node_meta:get_int('color')
        -- )
        -- return relic
    end,
    on_drop = function(item, dropper, pos)

        br.remove_hud(dropper)
        

        return minetest.item_drop(item, player, pos)
    end,
    on_pickup = function(item, picker, pos)

        -- transfer metadata to the picked up item
        local node_meta = pos:get_meta()
        local item_meta = item:get_meta()
        local relic = br.create_relic(
            node_meta:get_string('player_name'),
            node_meta:get_string('time'),
            node_meta:get_string('pos'),
            node_meta:get_int('color')
        )

        -- return minetest.item_pickup(relic, picker, pos)
    end,
    on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        return minetest.item_move(item, mover, pos)
    end,
    on_put = function(item, taker, pos)
    end,
    on_place = function(itemstack, placer, pointed_thing)

        -- greets https://github.com/minetest/minetest_game/blob/master/mods/default/torch.lua
        local under = pointed_thing.under
        local node = minetest.get_node(under)
        local def = minetest.registered_nodes[node.name]
        if def and def.on_rightclick and
            not (placer and placer:is_player() and
            placer:get_player_control().sneak) then
            return def.on_rightclick(under, node, placer, itemstack,
                pointed_thing) or itemstack
        end


        local itemstack_meta = itemstack:get_meta()



        -- local returned_itemstack = minetest.item_place_node(
        --     ItemStack("bonerelic:relic"), 
        --     placer,
        --     pointed_thing
        -- )


        local placer_name = placer and placer:get_player_name() or ""


        -- abort if placing in protected area
        if minetest.is_protected(pointed_thing.above, placer_name) then
            return
        end


        -- abort if pointed_thing is not a node
        if pointed_thing.type ~= "node" then
            return
        end

        minetest.set_node(pointed_thing.above, {name = itemstack:get_name()})
        minetest.sound_play("default_place_node", {pos = pointed_thing.above, gain = 1.0})


        -- transfer metadata to the placed node
        local player_name = itemstack_meta:get_string('player_name');
        local placed_item_meta = minetest.get_meta(pointed_thing.above)
        placed_item_meta:set_string("infotext", player_name.."'s Bone Relic");
        placed_item_meta:set_string("player_name", player_name);
        placed_item_meta:set_string("pos", itemstack_meta:get_string('pos'));
        placed_item_meta:set_string("time", itemstack_meta:get_string('time'));
        placed_item_meta:set_int("color", itemstack_meta:get_int('color'));


        itemstack:take_item()

        -- local placed_meta = returned_itemstack:get_meta()
        -- placed_meta:set_string("infotext", itemstack_meta:get_string('player_name'));

        -- local relic_meta = itemstack:get_meta()
        -- placed_meta:set_string('pos', relic_meta:get_string('pos'))
        -- placed_meta:set_string('player_name', relic_meta:get_string('player_name'))

        -- -- br.transfer_meta(relic_meta, placed_meta)

        -- remove hud
        br.remove_hud(placer)

        return itemstack
    end,
})



-- on_respawnplayer
-- when the player respawns, create a bonerelic.
-- save into the bonerelic's metadata the world_pos of the last death from player metadata (bonerelic:last_death)
-- give the bonerelic to the player.
minetest.register_on_respawnplayer(function(player)
    local inv = player:get_inventory()
    local player_meta = player:get_meta()
    local last_death_json = player_meta:get_string('bonerelic:last_death')
    local last_death = minetest.parse_json(last_death_json)
    local pos = last_death['pos']

    -- remove any HUD from previous bonerelic
    br.remove_hud(player)


    -- create relic
    local relic = br.create_relic(player:get_player_name(), last_death['time'], last_death['pos'], br.purple)

    -- create HUD
    local hud = br.create_hud(pos, player, br.purple)
    player_meta:set_string('bonerelic:hud', hud)

    -- give relic
    if inv:room_for_item("main", "bonerelic:relic") then
        inv:add_item("main", relic)
    end
end)


-- on_player_inventory_action
minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    -- when a player moves the relic from their inventory,
    -- remove the HUD
    -- 


    

    -- proceed only if stack is defined
    if inventory_info.stack == nil then return end



    -- proceed only if item is bonerelic:relic
    local item = inventory_info.stack:get_name()
    if item ~= 'bonerelic:relic' then return end


    -- take I guess is from the perspective of the chest receiving the itemstack?
    -- in other words, the perspective of the verb is NOT from the player.
    if action == "take" then


        -- local player_meta = player:get_meta()
        -- local relic_meta = inventory

        -- -- player is moving a bonerelic from some other inventory to their main inventory
        if inventory_info.listname ~= 'main' then
            -- create HUD
            pos = minetest.parse_json(relic_meta.get_string('pos'))
            local hud = br.create_hud(pos, player, br.purple)
            player_meta:set_string('bonerelic:hud', hud)


        -- player is moving a bonerelic from their main inventory to some other inventory
        elseif inventory_info.listname == 'main' then
            -- hide hud
            -- local hud = player_meta:get_int('bonerelic:hud')
            -- if hud ~= nil and hud ~= 0 then 
            --     player:hud_remove(hud)
            -- end
            br.remove_hud(player)

        end
    end



end)



-- minetest.register_tool("bonerelic:relic", {
--     description = "Bone Relic\nShows the location of previous death",
--     short_description = "Bone Relic",
--     groups = { 
--         shovel = 1
--     },
--     inventory_image = "relic.png",
--     tool_capabilities = {
--         full_punch_interval = 5,
--         groupcaps = {
--             crumbly = {
--                 maxlevel = 4,
--                 uses = 16
--             }
--         },
--         damage_groups = {
--             fleshy = 1
--         },
--         sound = {
--             breaks = "break.ogg"
--         }
--     },
    
-- })





































-- everything past here is old code
-- everything past here is old code
-- everything past here is old code
-- everything past here is old code
-- everything past here is old code
-- everything past here is old code





-- save_death_pos
--
-- save the death data to the player metadata db.
--
-- @param {PlayerRef}
-- @param {number} gametime
function br.save_death_pos(player, gametime)
    local player_meta = player:get_meta()
    local player_pos = player:get_pos()

    local br_index = br.get_death_index(player)
    if br_index == nil then br_index = {} end


    -- create new entry in the death index 
    -- the index keeps track of all gametimes at which a death occured
    -- this lets us use bonerelic:<gametime> to retrieve x,y,z
    player_meta:set_string('bonerelic:index', minetest.write_json(br_index))

    -- save the death data
    player_meta:set_string('bonerelic:'..gametime..':pos', minetest.write_json(player_pos))
end

function br.save_death_hud(player, gametime, hud_id)
    local player_meta = player:get_meta()
    local player_pos = player:get_pos()
    local br_index = br.get_death_index(player)
    player_meta:set_string('bonerelic:'..gametime..':hud', tostring(hud_id))
end

function br.load_death_location(player_name, gametime)
end




-- get_death_pos
--
-- @param {PlayerRef}
-- @param {number}
-- @return {boolean|Vector}
function br.get_death_pos(player, gametime)
    assert(type(player) == "userdata")
    assert(type(gametime) == "number")
    local player_meta = player:get_meta()
    local death_json = player_meta:get_string('bonerelic:'..gametime)
    local death = minetest.parse_json(death_json)
    return death.pos
end

-- get_death_hud_id
--
-- @param {PlayerRef}
-- @param {number}
-- @return {string}
function br.get_death_hud_id(player, gametime)
    assert(type(player) == "userdata")
    assert(type(gametime) == "number")
    local player_meta = player:get_meta()
    local death_json = player_meta:get_string('bonerelic:'..gametime)
    local death = minetest.parse_json(death_json)
    return death.hud_id
end






-- serialize_pos
--
-- take the pos data and make it a string
--
-- @param {PlayerRef} player
-- @returns {string} data
-- @example: {"x":-70.884002685546875,"y":3.3490002155303955,"z":123.19999694824219}
--
function br.serialize_pos(player)
end


function br.serialze_index(player, gametime)
end


function br.deserialize_pos()
end


function br.deserialize_index()
end


-- is_death_known
-- returns true if we have a registered death for this player
-- returns false if we do not have a registered death for this player
function br.is_death_known(player)
    assert(type(player) == 'userdata')

    local death_index = br.get_death_index(player)
    if death_index == nil or #death_index == 0 then 
        return false
    else 
        return true
    end
end

function br.get_death_hud(player, time)
    local death = br.get_latest_death(player)
    return death['hud_id']
end





-- -- when a player dies
-- minetest.register_on_dieplayer(function(player)

--     -- get timestamp
--     local gametime = minetest.get_gametime()

--     -- save pos to db
--     br.save_death_pos(player, gametime)
--end)

-- -- when a player respawns
-- minetest.register_on_respawnplayer(function(player)
--     local inv = player:get_inventory()

--     -- give relic
--     if inv:room_for_item("main", "bonerelic:relic") then
--         local relic = ItemStack("bonerelic:relic")

--         inv:add_item("main", relic)
--     end
-- end)



-- When a player joins the server,
-- clear the hud_ids
-- this is because the ids are no longer valid
minetest.register_on_joinplayer(function(player, last_login)
    local death_index = br.get_death_index(player)
    if death_index == nil or #death_index == 0 then return end
    for i = 1, #death_index do
        local hud_id = br.get_death_hud_id(player, death_index[i])
        local death_pos = br.get_death_pos(player, death_index[i])
        local time = death_index[i]
        player:hud_remove(hud_id)
        hud_id = br.create_hud(death_pos, player, br.purple)
        br.save_death_hud(player, time, hud_id)
    end
end)