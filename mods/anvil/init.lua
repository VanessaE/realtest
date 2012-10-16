anvil = {}
realtest.registered_anvil_recipes = {}

function realtest.register_anvil_recipe(RecipeDef)
	local recipe = {
		type = RecipeDef.type or "forge",
		item1 = RecipeDef.item1 or "",
		item2 = RecipeDef.item2 or "",
		rmitem1 = RecipeDef.rmitem1,
		rmitem2 = RecipeDef.rmitem2,
		output = RecipeDef.output or "",
	}
	if recipe.rmitem1 == nil then
		recipe.rmitem1 = true
	end
	if recipe.rmitem2 == nil then
		recipe.rmitem2 = true
	end
	if recipe.output ~= "" and recipe.item1 ~= "" and (recipe.type == "forge" or recipe.type == "weld") then
		table.insert(realtest.registered_anvil_recipes, recipe)
	end
end

--Unshaped metals and buckets
for _, metal in ipairs(METALS_LIST) do
	realtest.register_anvil_recipe({
		item1 = "metals:"..metal.."_unshaped",
		output = "metals:"..metal.."_ingot",
	})
	realtest.register_anvil_recipe({
		item1 = "metals:"..metal.."_ingot",
		item2 = "metals:recipe_bucket",
		rmitem2 = false,
		output = "metals:bucket_empty_"..metal,
	})
end
--Pig iron --> Wrought iron
realtest.register_anvil_recipe({
	item1 = "metals:pig_iron_ingot",
	output = "metals:wrought_iron_ingot",
})
local instruments = {"axe", "pick", "shovel", "spear", "sword", "hammer"}
for _, instrument in ipairs(instruments) do
	for _, metal in ipairs(METALS_LIST) do
		realtest.register_anvil_recipe({
			item1 = "metals:"..metal.."_ingot",
			item2 = "metals:recipe_"..instrument,
			rmitem2 = false,
			output = "metals:tool_"..instrument.."_"..metal.."_head",
		})
	end
end


anvil.hammers={
	'anvil:hammer',
	'metals:tool_hammer_bismuth',
	'metals:tool_hammer_pig_iron',
	'metals:tool_hammer_wrought_iron',
	'metals:tool_hammer_steel',
	'metals:tool_hammer_gold',
	'metals:tool_hammer_nickel',
	'metals:tool_hammer_platinum',
	'metals:tool_hammer_tin',
	'metals:tool_hammer_silver',
	'metals:tool_hammer_lead',
	'metals:tool_hammer_copper',
	'metals:tool_hammer_zinc',
	'metals:tool_hammer_brass',
	'metals:tool_hammer_sterling_silver',
	'metals:tool_hammer_rose_gold',
	'metals:tool_hammer_black_bronze',
	'metals:tool_hammer_bismuth_bronze',
	'metals:tool_hammer_bronze',
	'metals:tool_hammer_black_steel',
}

minetest.register_craft({
	output = 'anvil:self',
	recipe = {
		{'default:stone','default:stone','default:stone'},
		{'','default:stone',''},
		{'default:stone','default:stone','default:stone'},
	}
})

minetest.register_craft({
	output = 'anvil:hammer',
	recipe = {
		{'default:cobble','default:cobble','default:cobble'},
		{'default:cobble','default:stick','default:cobble'},
		{'','default:stick',''},
	}
})

minetest.register_tool("anvil:hammer", {
	description = "Hammer",
	inventory_image = "anvil_hammer.png",
	tool_capabilities = {
		max_drop_level=1,
		groupcaps={
			cracky={times={[1]=6.00, [2]=4.30, [3]=3.00}, uses=20, maxlevel=1},
			fleshy={times={[1]=2.00, [2]=0.80, [3]=0.40}, uses=10, maxlevel=2},
		}
	},
})

minetest.register_node("anvil:self", {
	description = "Anvil",
	tiles = {"anvil_top.png","anvil_top.png","anvil_side.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.3,0.5,-0.4,0.3},
			{-0.35,-0.4,-0.25,0.35,-0.3,0.25},
			{-0.3,-0.3,-0.15,0.3,-0.1,0.15},
			{-0.35,-0.1,-0.2,0.35,0.1,0.2},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.3,0.5,-0.4,0.3},
			{-0.35,-0.4,-0.25,0.35,-0.3,0.25},
			{-0.3,-0.3,-0.15,0.3,-0.1,0.15},
			{-0.35,-0.1,-0.2,0.35,0.1,0.2},
		},
	},
	groups = {oddly_breakable_by_hand=2, cracky=3, dig_immediate=1},
	sounds = default.node_sound_stone_defaults(),
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		if inv:is_empty("src1") and inv:is_empty("src2") and inv:is_empty("hammer")
			and inv:is_empty("output") and inv:is_empty("flux") then
			return true
		end
		return false
	end,
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec", "invsize[8,7;]"..
				"button[0.5,0.25;2,1;buttonForge;Forge]"..
				"list[current_name;src1;2.9,0.25;1,1;]"..
				"image[3.69,0.22;0.54,1.5;anvil_arrow.png]"..
				"list[current_name;src2;4.1,0.25;1,1;]"..
				"button[5.5,0.25;2,1;buttonWeld;Weld]"..
				"list[current_name;hammer;1,1.5;1,1;]"..
				"list[current_name;output;3.5,1.5;1,1;]"..
				"list[current_name;flux;6,1.5;1,1;]"..
				"list[current_player;main;0,3;8,4;]")
		meta:set_string("infotext", "Anvil")
		local inv = meta:get_inventory()
		inv:set_size("src1", 1)
		inv:set_size("src2", 1)
		inv:set_size("hammer", 1)
		inv:set_size("output", 1)
		inv:set_size("flux", 1)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		
		local src1, src2 = inv:get_stack("src1", 1), inv:get_stack("src2", 1)
		local hammer, flux = inv:get_stack("hammer", 1), inv:get_stack("flux", 1)
		local output = inv:get_stack("output", 1)

		if fields["buttonForge"] then
			if table.contains(anvil.hammers, hammer:get_name()) then
				for _, recipe in ipairs(realtest.registered_anvil_recipes) do
					if recipe.type == "forge" and recipe.item1 == src1:get_name() and recipe.item2 == src2:get_name() then
						if inv:room_for_item("output", recipe.output) then
							if recipe.rmitem1 then
								src1:take_item()
								inv:set_stack("src1", 1, src1)
							end
							if recipe.item2 ~= "" and recipe.rmitem2 then
								src2:take_item()
								inv:set_stack("src2", 1, src2)
							end
							output:add_item(recipe.output)
							inv:set_stack("output", 1, output)
							hammer:add_wear(65535/30)
							inv:set_stack("hammer", 1, hammer)
						end
						return
					end
				end 
			end
		elseif fields["buttonWeld"] then
			
		end
	end,
})
