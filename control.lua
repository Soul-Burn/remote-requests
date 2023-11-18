local function perform_request(event)
    local player = game.get_player(event.player_index)
    local entity = player.opened or player.selected
    if entity and entity.name == "item-request-proxy" then
        entity = entity.proxy_target
    end
    if not entity then
        return
    end

    local stack_request = event.input_name == "rr-perform-alt-request"
    local item_to_insert = (player.cursor_ghost and player.cursor_ghost.name) or (player.cursor_stack.valid_for_read and player.cursor_stack.name)
    if item_to_insert then
        -- insert
        if not entity.can_insert { name = item_to_insert, count = 1 } then
            return
        end
        local amount_to_insert = game.item_prototypes[item_to_insert].stack_size
        local module_inventory = entity.get_module_inventory()
        if module_inventory and module_inventory.can_insert { name = item_to_insert, count = 1 } then
            amount_to_insert = #module_inventory
        end
        if not stack_request then
            amount_to_insert = 1
        end
        local proxies = player.surface.find_entities_filtered { position = entity.position, name = "item-request-proxy", limit = 1 }
        if #proxies > 0 then
            local item_requests = proxies[1].item_requests
            item_requests[item_to_insert] = (item_requests[item_to_insert] or 0) + amount_to_insert
            proxies[1].item_requests = item_requests
        else
            player.surface.create_entity {
                name = "item-request-proxy",
                position = entity.position,
                target = entity,
                force = player.force,
                modules = { [item_to_insert] = amount_to_insert },
            }
        end
        player.play_sound { path = "utility/inventory_move" }
    else
        -- remove
        local item_to_remove
        if event.selected_prototype and player.opened then
            item_to_remove = event.selected_prototype.name
            if not game.item_prototypes[item_to_remove] then
                return
            end
        elseif player.selected then
            local inventory = entity.get_output_inventory()
            if not inventory or inventory.is_empty() then
                return
            end
            item_to_remove, _ = next(inventory.get_contents())
        else
            return
        end
        local removed_items = entity.remove_item { name = item_to_remove, count = stack_request and game.item_prototypes[item_to_remove].stack_size or 1 }
        if removed_items > 0 then
            entity.surface.spill_item_stack(entity.position, { name = item_to_remove, count = removed_items }, true, entity.force, false)
            player.play_sound { path = "utility/inventory_move" }
        end
    end
end

script.on_event("rr-perform-request", perform_request)
script.on_event("rr-perform-alt-request", perform_request)
