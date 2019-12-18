
/mob/living/silicon/pai/proc/fold_out(force = FALSE)
	if(emitterhealth < 0)
		to_chat(src, "<span class='warning'>Your holochassis emitters are still too unstable! Please wait for automatic repair.</span>")
		return FALSE

	if(!canholo && !force)
		to_chat(src, "<span class='warning'>Your master or another force has disabled your holochassis emitters!</span>")
		return FALSE

	if(holoform)
		. = fold_in(force)
		return

	if(world.time < emitter_next_use)
		to_chat(src, "<span class='warning'>Error: Holochassis emitters recycling. Please try again later.</span>")
		return FALSE

	emitter_next_use = world.time + emittercd
	canmove = TRUE
	density = TRUE
	if(istype(card.loc, /obj/item/pda))
		var/obj/item/pda/P = card.loc
		P.pai = null
		P.visible_message("<span class='notice'>[src] ejects itself from [P]!</span>")
	if(isliving(card.loc))
		var/mob/living/L = card.loc
		if(!L.temporarilyRemoveItemFromInventory(card))
			to_chat(src, "<span class='warning'>Error: Unable to expand to mobile form. Chassis is restrained by some device or person.</span>")
			return FALSE
	if(istype(card.loc, /obj/item/integrated_circuit/input/pAI_connector))
		var/obj/item/integrated_circuit/input/pAI_connector/C = card.loc
		C.RemovepAI()
		C.visible_message("<span class='notice'>[src] ejects itself from [C]!</span>")
		playsound(src, 'sound/items/Crowbar.ogg', 50, 1)
		C.installed_pai = null
		C.push_data()
	forceMove(get_turf(card))
	card.forceMove(src)
	if(client)
		client.perspective = EYE_PERSPECTIVE
		client.eye = src
	set_light(0)
	icon_state = "[chassis]"
	visible_message("<span class='boldnotice'>[src] folds out its holochassis emitter and forms a holoshell around itself!</span>")
	holoform = TRUE

/mob/living/silicon/pai/proc/fold_in(force = FALSE)
	emitter_next_use = world.time + (force? emitteroverloadcd : emittercd)
	icon_state = "[chassis]"
	if(!holoform)
		. = fold_out(force)
		return
	if(force)
		short_radio()
		visible_message("<span class='warning'>[src] shorts out, collapsing back into their storage card, sparks emitted from their radio antenna!</span>")
	else
		visible_message("<span class='notice'>[src] deactivates its holochassis emitter and folds back into a compact card!</span>")
	stop_pulling()
	if(client)
		client.perspective = EYE_PERSPECTIVE
		client.eye = card
	var/turf/T = drop_location()
	card.forceMove(T)
	forceMove(card)
	canmove = FALSE
	density = FALSE
	set_light(0)
	holoform = FALSE
	if(resting)
		lay_down()

/mob/living/silicon/pai/proc/choose_chassis()
	if(!isturf(loc) && loc != card)
		to_chat(src, "<span class='boldwarning'>You can not change your holochassis composite while not on the ground or in your card!</span>")
		return FALSE
	var/list/choices = list("Preset - Basic", "Preset - Dynamic")
	if(CONFIG_GET(flag/pai_custom_holoforms))
		choices += "Custom"
	var/choicetype = input(src, "What type of chassis do you want to use?") as null|anything in choices
	if(!choicetype)
		return FALSE
	switch(choicetype)
		if("Custom")
			chassis = "custom"
		if("Preset - Basic")
			var/choice = input(src, "What would you like to use for your holochassis composite?") as null|anything in possible_chassis
			if(!choice)
				return FALSE
			chassis = choice
		if("Preset - Dynamic")
			var/choice = input(src, "What would you like to use for your holochassis composite?") as null|anything in dynamic_chassis_icons
			if(!choice)
				return FALSE
			chassis = "dynamic"
			dynamic_chassis = choice
	resist_a_rest(FALSE, TRUE)
	update_icon()
	to_chat(src, "<span class='boldnotice'>You switch your holochassis projection composite to [chassis]</span>")

/mob/living/silicon/pai/lay_down()
	. = ..()
	if(loc != card)
		visible_message("<span class='notice'>[src] [resting? "lays down for a moment..." : "perks up from the ground"]</span>")
	update_icon()

/mob/living/silicon/pai/start_pulling(atom/movable/AM, gs)
	if(ispAI(AM))
		return ..()
	return FALSE

/mob/living/silicon/pai/proc/toggle_integrated_light()
	if(!light_range)
		set_light(brightness_power)
		to_chat(src, "<span class='notice'>You enable your integrated light.</span>")
	else
		set_light(0)
		to_chat(src, "<span class='notice'>You disable your integrated light.</span>")

/mob/living/silicon/pai/mob_pickup(mob/living/L)
	var/obj/item/clothing/head/mob_holder/holder = new(get_turf(src), src, chassis, item_head_icon, item_lh_icon, item_rh_icon)
	if(!L.put_in_hands(holder))
		qdel(holder)
	else
		L.visible_message("<span class='warning'>[L] scoops up [src]!</span>")

/mob/living/silicon/pai/mob_try_pickup(mob/living/user)
	if(!possible_chassis[chassis])
		to_chat(user, "<span class='warning'>[src]'s current form isn't able to be carried!</span>")
		return FALSE
	return ..()

/mob/living/silicon/pai/verb/toggle_chassis_sit()
	set name = "Toggle Chassis Sit"
	set category = "IC"
	set desc = "Whether or not to try to use a sitting icon versus a resting icon. Takes priority over belly-up resting."
	dynamic_chassis_sit = !dynamic_chassis_sit
	to_chat(usr, "<span class='boldnotice'>You are now [dynamic_chassis_sit? "sitting" : "lying down"].</span>")
	update_icon()

/mob/living/silicon/pai/verb/toggle_chassis_bellyup()
	set name = "Toggle Chassis Belly Up"
	set category = "IC"
	set desc = "Whether or not to try to use a belly up icon while resting. Overridden by sitting."
	dynamic_chassis_bellyup = !dynamic_chassis_bellyup
	to_chat(usr, "<span class='boldnotice'>You are now lying on your [dynamic_chassis_bellyup? "back" : "front"].</span>")
	update_icon()
