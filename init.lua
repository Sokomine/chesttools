-- 30.07.18 Removed pipeworks overlay on front side of chest.
-- 28.07.18 Works with newer unified_inventory as well.
-- 28.07.18 Added support for technic chests.
-- 27.07.18 Added support for shared locked chests and moved to set_node
--          with inventory copying for cleaner operation.
-- 05.10.14 Fixed bug in protection/access
chesttools = {}


-- data structure: new_node_name = { item_that_acts_as_price,
--                                   amount_of_price_item,
--                                   name_for_field_in_menu,
--                                   index_for_display_in_menu,
--                                   name of price item for showing the player,
--                                   new formspec string}
-- prices always refer to upgrading a default:chest to the desired new model
chesttools.update_price = {
	{'default:chest',             'default:steel_ingot', 0, 'normal', 1, 'nothing'},
	{'default:chest_locked',      'default:steel_ingot', 1, 'locked', 2, 'steel ingot'},
	{'chesttools:shared_chest',   'default:steel_ingot', 2, 'shared', 3, 'steel ingot(s)'},
	{'locks:shared_locked_chest', 'default:steel_ingot', 3, 'locks',  4, 'steel ingot(s)'},
	{'technic:iron_chest',          'technic:iron_chest',          1, 'iron',          5, 'Iron chest'},
	{'technic:iron_locked_chest',   'technic:iron_locked_chest',   1, 'iron_locked',   6, 'Iron locked chest'},
	{'technic:copper_chest',        'technic:copper_chest',        1, 'copper',        7, 'Copper chest'},
	{'technic:copper_locked_chest', 'technic:copper_locked_chest', 1, 'copper_locked', 8, 'Copper locked chest'},
	{'technic:silver_chest',        'technic:silver_chest',        1, 'silver',        9, 'Silver chest'},
	{'technic:silver_locked_chest', 'technic:silver_locked_chest', 1, 'silver_locked',10, 'Silver locked chest'},
	{'technic:gold_chest',          'technic:gold_chest',          1, 'gold',         11, 'Gold chest'},
	{'technic:gold_locked_chest',   'technic:gold_locked_chest',   1, 'gold_locked',  12, 'Gold locked chest'},
	{'technic:mithril_chest',       'technic:mithril_chest',       1, 'mithril',      13, 'Mithril chest'},
	{'technic:mithril_locked_chest','technic:mithril_locked_chest',1, 'mithril_locked',14, 'Mithril locked chest'},
	};

chesttools.chest_add = {};
chesttools.chest_add.tiles  = {
		"chesttools_blue_chest_top.png", "chesttools_blue_chest_top.png", "chesttools_blue_chest_side.png",
		"chesttools_blue_chest_side.png", "chesttools_blue_chest_side.png", "chesttools_blue_chest_lock.png"};
chesttools.chest_add.groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2};
chesttools.chest_add.tube   = {};


-- additional/changed definitions for pipeworks;
-- taken from pipeworks/compat.lua
if( minetest.get_modpath( 'pipeworks' )) then
	chesttools.chest_add.tiles = {
		"chesttools_blue_chest_top.png^pipeworks_tube_connection_wooden.png",
		"chesttools_blue_chest_top.png^pipeworks_tube_connection_wooden.png",
		"chesttools_blue_chest_side.png^pipeworks_tube_connection_wooden.png",
		"chesttools_blue_chest_side.png^pipeworks_tube_connection_wooden.png",
		"chesttools_blue_chest_side.png^pipeworks_tube_connection_wooden.png",
		"chesttools_blue_chest_lock.png"};
	chesttools.chest_add.groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,
			tubedevice = 1, tubedevice_receiver = 1 };
	chesttools.chest_add.tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("main", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("main", stack)
		end,
		input_inventory = "main",
		connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1}
	};
end

chesttools.formspec = "size[9,10]"..
			"list[current_name;main;0.5,0.3;8,4;]"..
			"label[0.0,9.7;Title/Content:]"..
			"field[1.8,10.0;6,0.5;chestname;;]"..
			"button[7.5,9.7;1,0.5;set_chestname;Store]"..
			"label[0.0,4.4;Main]"..
			"button[1.0,4.5;1,0.5;craft;Craft]"..
			"button[7.0,4.5;0.5,0.5;drop_all;DA]"..
			"button[7.5,4.5;0.5,0.5;take_all;TA]"..
			"button[8.0,4.5;0.5,0.5;swap_all;SA]"..
			"button[8.5,4.5;0.5,0.5;filter_all;FA]"..
			"list[current_player;main;0.5,5.5;8,4;]";

if( minetest.get_modpath( 'unified_inventory')) then
	chesttools.formspec = chesttools.formspec..
			"button[2.0,4.5;1,0.5;bag1;Bag 1]"..
			"button[3.0,4.5;1,0.5;bag2;Bag 2]"..
			"button[4.0,4.5;1,0.5;bag3;Bag 3]"..
			"button[5.0,4.5;1,0.5;bag4;Bag 4]";
end


chesttools.may_use = function( pos, player )
	if( not( player )) then
		return false;
	end
	local name = player:get_player_name();
	local meta = minetest.get_meta( pos );
	local owner = meta:get_string( 'owner' )
	-- the owner can access the chest
	if( owner == name or owner == "" ) then
		return true;
	end
	-- the shared function only kicks in if the area is protected
	if(   not( minetest.is_protected(pos, name ))
	      and  minetest.is_protected(pos, ' _DUMMY_PLAYER_ ')) then
		return true;
	end
	return false;
end


chesttools.on_receive_fields = function(pos, formname, fields, player)
	if( fields.quit and fields.quit ~= "") then
		return;
	end

	local meta = minetest.get_meta( pos );
	local chestname = meta:get_string( 'chestname' );
	if( fields.set_chestname and fields.chestname ) then
		chestname = tostring( fields.chestname );
		meta:set_string( 'chestname', chestname );
		meta:set_string("infotext", "\""..chestname.."\" Chest (owned by "..meta:get_string("owner")..")")
		-- update the normal formspec
		meta:set_string("formspec", chesttools.formspec..
				    "field[1.8,10.0;6,0.5;chestname;;"..chestname.."]");
	end

	local formspec = "size[9,10]"..
			"label[0.0,9.7;Title/Content:]"..
			"field[1.8,10.0;6,0.5;chestname;;"..tostring( chestname or "unconfigured").."]"..
			"button[7.5,9.7;1,0.5;set_chestname;Store]"..
			"list[current_name;main;0.5,0.3;8,4;]"..
			"button[7.0,4.5;0.5,0.5;drop_all;DA]"..
			"button[7.5,4.5;0.5,0.5;take_all;TA]"..
			"button[8.0,4.5;0.5,0.5;swap_all;SA]"..
			"button[8.5,4.5;0.5,0.5;filter_all;FA]";
	local bm = "button[0.0,4.5;1,0.5;main;Main]";
	local bc = "button[1.0,4.5;1,0.5;craft;Craft]";
	local b1 = "button[2.0,4.5;1,0.5;bag1;Bag 1]";
	local b2 = "button[3.0,4.5;1,0.5;bag2;Bag 2]";
	local b3 = "button[4.0,4.5;1,0.5;bag3;Bag 3]";
	local b4 = "button[5.0,4.5;1,0.5;bag4;Bag 4]";

	local selected = '';
	if( fields.drop_all or fields.take_all or fields.swap_all or fields.filter_all ) then
		-- check if the player has sufficient access to the chest
		local node = minetest.get_node( pos );
		local pname = player:get_player_name();
		-- deny access for unsupported chests
		if( not( node )
		    or (node.name == 'chesttools:shared_chest' and not( chesttools.may_use( pos, player )))
		    or (node.name == 'locks:shared_locked_chest'and pname ~= meta:get_string('owner' ))
		    or (node.name == 'default:chest_locked'and pname ~= meta:get_string('owner' ))) then
			if( node.name ~= 'default:chest' ) then
				minetest.chat_send_player( pname, 'Sorry, you do not have access to the content of this chest.');
				return;
			end
		end
		selected = fields.selected;
		if( not( selected ) or selected == '') then
			selected = 'main';
		end
		local inv_list = 'main';
		if(     selected == 'main' ) then		
			inv_list = 'main';
		elseif( selected == 'craft' ) then
			inv_list = 'craft';
		elseif( selected == 'bag1' or selected == 'bag2' or selected == 'bag3' or selected=='bag4') then
			inv_list = selected.."contents";
		end

		local player_inv = player:get_inventory();
		local chest_inv  = meta:get_inventory();

		if( fields.drop_all ) then
			for i,v in ipairs( player_inv:get_list( inv_list ) or {}) do
				if( chest_inv and chest_inv:room_for_item('main', v)) then
					local leftover = chest_inv:add_item( 'main', v );
					player_inv:remove_item( inv_list, v );
					if( leftover and not( leftover:is_empty() )) then
						player_inv:add_item( inv_list, v );
					end
				end
			end
		elseif( fields.take_all ) then
			for i,v in ipairs( chest_inv:get_list( 'main' ) or {}) do
				if( player_inv:room_for_item( inv_list, v)) then
					local leftover = player_inv:add_item( inv_list, v );
					chest_inv:remove_item( 'main', v );
					if( leftover and not( leftover:is_empty() )) then
						chest_inv:add_item( 'main', v );
					end
				end
			end

		elseif( fields.swap_all ) then
			for i,v in ipairs( player_inv:get_list( inv_list ) or {}) do
				if( chest_inv ) then
					local tmp = player_inv:get_stack( inv_list, i );
					player_inv:set_stack(   inv_list, i, chest_inv:get_stack( 'main', i ));
					chest_inv:set_stack(    'main',   i, v );
				end
			end

		elseif( fields.filter_all ) then
			for i,v in ipairs( player_inv:get_list( inv_list ) or {}) do
				if( chest_inv and chest_inv:room_for_item('main', v) and chest_inv:contains_item( 'main', v:get_name())) then
					local leftover = chest_inv:add_item( 'main', v );
					player_inv:remove_item( inv_list, v );
					if( leftover and not( leftover:is_empty() )) then
						player_inv:add_item( inv_list, v );
					end
				end
			end
		end
	end

	local bag_nr = 0;
	if(     fields[ 'main'] or selected=='main' or fields['set_chestname']) then
		bag_nr = 0;
		formspec = formspec..
			"list[current_player;main;0.5,5.5;8,4;]";
		bm = "label[0.0,4.4;Main]";
		selected = 'main';

	elseif( fields[ 'craft'] or selected=='craft') then
		bag_nr = 0;
		formspec = formspec..
			"label[0,5.5;Crafting]"..
			"list[current_player;craftpreview;6.5,6.5;1,1;]"..
			"list[current_player;craft;2.5,6.5;3,3;]";
		bc = "label[1.0,4.4;Craft]";
		selected = 'craft';

	elseif( fields[ 'bag1' ] or selected=='bag1') then
		bag_nr = 1;
		b1     = "label[2.0,4.4;Bag 1]";
		selected = 'bag1';
	elseif( fields[ 'bag2' ] or selected=='bag2') then
		bag_nr = 2;
		b2     = "label[3.0,4.4;Bag 2]";
		selected = 'bag2';
	elseif( fields[ 'bag3' ] or selected=='bag3') then
		bag_nr = 3;
		b3     = "label[4.0,4.4;Bag 3]";
		selected = 'bag3';
	elseif( fields[ 'bag4' ] or selected=='bag4') then
		bag_nr = 4;
		b4     = "label[5.0,4.4;Bag 4]";
		selected = 'bag4';
	end

	if( bag_nr >= 1 and bag_nr <= 4 ) then
		formspec = formspec..
			"label[0.5,5.5;Bag "..bag_nr.."]";
		local stack = player:get_inventory():get_stack( "bag"..bag_nr, 1)
		if( stack ) then
			local pname_esc = minetest.formspec_escape(player:get_player_name());
			formspec = formspec.."list[detached:"..pname_esc.."_bags;bag"..
				   tostring(bag_nr)..";1.5,5.5;1,1;]";
			local slots = 4*8;
			if( slots and slots>0 ) then -- no bag present?
				formspec = formspec..
					"list[current_player;bag"..tostring(bag_nr).."contents;0.5,6.5;8,"..tostring(slots/8)..";]";
			end
		end
	end


	formspec = formspec..bm..bc..b1..b2..b3..b4..
		-- provide the position of the chest
		"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
		-- which inventory was selected?
		"field[20,20;0.1,0.1;selected;selected;"..selected.."]";

	-- instead of updating the formspec of the chest - which would be slow - we display
	-- the new formspec directly to the player who asked for it;
	-- this is also necessary because players may have bags with diffrent sizes
	minetest.show_formspec( player:get_player_name(), "chesttools:shared_chest", formspec );
end


chesttools.update_chest = function(pos, formname, fields, player)
	local pname = player:get_player_name();
	if( not( pos ) or not( pos.x ) or not( pos.y ) or not( pos.z )) then
		return;
	end
	if( fields.abort and fields.abort ~= "") then
		return;
	end
	local node = minetest.get_node( pos );

	local old_nr = -1;
	local new_nr = -1;
	for nr, update_data in ipairs( chesttools.update_price ) do
		local link = tostring(update_data[4]);
		local chest_node_name = update_data[1];
		if(     chest_node_name == node.name ) then
			old_nr = nr;
		elseif( fields[ link ] and fields[ link ] ~= "") then
			new_nr = nr;
		end
	end
	-- no change necessary
	if( old_nr == -1 or new_nr == -1 or old_nr == new_nr ) then
		return;
	end
	local new_node_name= chesttools.update_price[ new_nr ][1];
	local price_item   = chesttools.update_price[ new_nr ][2];
	local price_amount = chesttools.update_price[ new_nr ][3];
	local price_name   = chesttools.update_price[ new_nr ][6];
	-- do they both use the same price?
	if( chesttools.update_price[ old_nr ][2] == price_item ) then
		-- the price for the old chest type gets substracted
		price_amount = price_amount - chesttools.update_price[ old_nr ][3];
	end

	-- only work on chests owned by the player (or unlocked ones)
	local meta = minetest.get_meta( pos );
	local owner = meta:get_string( 'owner' );
	if( node.name ~= 'default:chest' and owner and owner ~= pname and owner ~= "") then
		minetest.chat_send_player( pname, 'You can only upgrade your own chests.');
		return;
	end

	-- can the player build here (and thus change this chest)?
	if( minetest.is_protected(pos, pname )) then
		minetest.chat_send_player( pname, 'This chest is protected from digging.');
		return;
	end

	local player_inv = player:get_inventory();
	if( price_amount>0 and not( player_inv:contains_item( 'main', price_item..' '..price_amount))) then
		minetest.chat_send_player( pname, 'Sorry. You do not have '..tostring( price_amount )..
			' '..price_name..' for the update.');
		return;
	end

	if(     price_amount  > 0 ) then
		player_inv:remove_item( 'main', price_item..' '..tostring(price_amount));
	elseif( price_amount < 0 ) then
		price_amount = price_amount * -1;
		player_inv:add_item(    'main', price_item..' '..tostring(price_amount));
	end
	-- if the old chest type had a diffrent price: return that price
	if( chesttools.update_price[ old_nr ][2] ~= price_item ) then
		local old_price_item   = chesttools.update_price[ old_nr ][2];
		local old_price_amount = chesttools.update_price[ old_nr ][3];
		player_inv:add_item(    'main', old_price_item..' '..tostring(old_price_amount));
	end

	-- set the owner field
	meta:set_string( 'owner', pname );

	if( fields.locked ) then
		meta:set_string("infotext", "Locked Chest (owned by "..meta:get_string("owner")..")")
	elseif( fields.shared ) then
		meta:set_string("infotext", "Shared Chest (owned by "..meta:get_string("owner")..")")
	else
		meta:set_string("infotext", "Chest")
	end

	-- copy the old inventory
	local inv = meta:get_inventory();
	local main_inv = {};
	local inv_size = inv:get_size("main");
	for i=1, inv_size do
		main_inv[ i ] = inv:get_stack( "main", i);
		print("Found: "..tostring( main_inv[ i ]:get_name()));
	end

	-- actually change and initialize the new chest
	minetest.set_node( pos, { name = new_node_name, param2 = node.param2 });
	-- make sure the player owns the new chest
	meta:set_string("owner", pname);

	-- put the inventory back
	local new_inv      = meta:get_inventory();
	local new_inv_size = inv:get_size("main");
	for i=1, math.min( inv_size, new_inv_size ) do
		new_inv:set_stack( "main", i, main_inv[ i ]);
	end

	-- if the new chest has fewer slots than the old one had...
	if( new_inv_size < inv_size ) then
		-- try to put the inventory into the new chest anyway (there
		-- might be free slots or stacks that can take a bit more)
		for i=new_inv_size+1, inv_size do
			-- try to find free space elsewhere in the chest
			if( new_inv:room_for_item(         "main", main_inv[ i ])) then
				new_inv:add_item(          "main", main_inv[ i ]);
			-- ..or in the player's inventory
			elseif( player_inv:room_for_item( "main", main_inv[ i ])) then
				player_inv:add_item(      "main", main_inv[ i ]);
			-- drop the item above the chest
			else
				minetest.add_item({x=pos.x,y=pos.y+1,z=pos.z}, main_inv[i]);
			end
		end
	end

	minetest.chat_send_player( pname, 'Chest changed to '..tostring( minetest.registered_nodes[ new_node_name].description )..
			' for '..tostring( price_amount )..' '..price_name..'.');
end


-- translate general formspec calls back to specific chests/locations
chesttools.form_input_handler = function( player, formname, fields)
	if( (formname == "chesttools:shared_chest" or formname == "chesttools:update") and fields.pos2str ) then
		local pos = minetest.string_to_pos( fields.pos2str );
		if( not( chesttools.may_use( pos, player ))) then
			return;
		end
		if(     formname == "chesttools:shared_chest") then
			chesttools.on_receive_fields(pos, formname, fields, player);
		elseif( formname == "chesttools:update") then
			chesttools.update_chest(     pos, formname, fields, player);
		end
		
		return;
	end
end


-- establish a callback so that input from the player-specific formspec gets handled
minetest.register_on_player_receive_fields( chesttools.form_input_handler );


minetest.register_node( 'chesttools:shared_chest', {
	description = 'Shared chest which can be used by all who can build at that spot',
	name   = 'shared chest',
	tiles  = chesttools.chest_add.tiles,
        groups = chesttools.chest_add.groups,
	tube   = chesttools.chest_add.tube,
        paramtype2 = "facedir",
        legacy_facedir_simple = true,
        is_ground_content = false,
        sounds = default.node_sound_wood_defaults(),

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", "Shared Chest (owned by "..meta:get_string("owner")..")")
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Shared Chest")
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
		meta:set_string("formspec", chesttools.formspec..
					"list[current_player;main;0.5,5.5;8,4;]");
	end,

	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main") and player:get_player_name() == meta:get_string('owner');
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index,
            to_list, to_index, count, player)

		-- the shared function only kicks in if the area is protected
		if( not( chesttools.may_use( pos, player ))) then
			return 0;
		end
		return count;
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)

		if( not( chesttools.may_use( pos, player ))) then
			return 0;
		end
		return stack:get_count();
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)

		if( not( chesttools.may_use( pos, player ))) then
			return 0;
		end
		return stack:get_count();
	end,

	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
			" puts "..tostring( stack:to_string() ).." to shared chest at "..minetest.pos_to_string(pos))
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
			" takes "..tostring( stack:to_string() ).." from shared chest at "..minetest.pos_to_string(pos))
	end,


	on_receive_fields = function(pos, formname, fields, sender)

		if( not( chesttools.may_use( pos, sender ))) then
			return;
		end
		chesttools.on_receive_fields( pos, formname, fields, sender);
	end,

	-- show chest upgrade formspec
	on_use = function(itemstack, user, pointed_thing)
		if( user == nil or pointed_thing == nil or pointed_thing.type ~= 'node') then
			return nil;
		end
		local name = user:get_player_name();

		local pos  = minetest.get_pointed_thing_position( pointed_thing, mode );
		local node = minetest.get_node_or_nil( pos );

		if( node == nil or not( node.name )) then
			return nil;
		end

		local formspec = "label[2,0.4;Change chest type:]"..
				 "field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
				 "button_exit[2,6.0;1.5,0.5;abort;Abort]";

		local can_be_upgraded = false;
		local offset = 0.5;
		local row_offset = 0;
		for nr, update_data in ipairs( chesttools.update_price ) do
			local link = tostring(update_data[4]);
			local chest_node_name = update_data[1];
			-- only offer possible updates
			if( minetest.registered_nodes[ chest_node_name ]) then
				if( node.name ~= chest_node_name ) then
					formspec = formspec..'item_image_button['..tostring(offset)..','..
								tostring(1+row_offset)..';1.5,1.5;'..
								chest_node_name..';'..link..';]'..
							'button_exit['..tostring(offset)..','..
								tostring(2.5+row_offset)..';1.5,0.5;'..
								link..';'..link..']';
				else
					can_be_upgraded = true;
					formspec = formspec..'item_image['..tostring(offset)..','..
								tostring(1+row_offset)..';1.5,1.5;'..
								chest_node_name..']'..
							'label['..tostring(offset)..','..
								tostring(2.5+row_offset)..';'..link..']';
				end
				offset = offset + 2;
				if( offset >= 15.5 ) then
					row_offset = 2.5;
					offset = 0.5;
				end
			end
		end
		offset = 16;
		-- make the formspec wide enough to show all chests centered
		formspec = 'size['..tostring(offset)..',6.5]'..formspec;
		-- only show the formspec if it really is a chest that can be updated
		if( can_be_upgraded ) then
			minetest.show_formspec( name, "chesttools:update", formspec );	
		end
		return nil;
	end,
})

minetest.register_craft({
	output = 'chesttools:shared_chest',
	type   = 'shapeless',
	recipe = { 'default:steel_ingot', 'default:chest_locked' },
})
