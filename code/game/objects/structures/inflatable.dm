/obj/item/inflatable
	name = "inflatable wall"
	desc = "A folded membrane which rapidly expands into a large cubical shape on activation."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_wall"
	w_class = 3.0

	attack_self(mob/user)
		playsound(loc, 'sound/items/zip.ogg', 75, 1)
		to_chat(user, "\blue You inflate [src].")
		var/obj/structure/inflatable/R = new /obj/structure/inflatable(user.loc)
		src.transfer_fingerprints_to(R)
		R.add_fingerprint(user)
		qdel(src)

/obj/structure/inflatable
	name = "inflatable wall"
	desc = "An inflated membrane. Do not puncture."
	density = 1
	anchored = 1
	opacity = 0

	icon = 'icons/obj/inflatable.dmi'
	icon_state = "wall"

	var/health = 50.0


	New(location)
		..()
		update_nearby_tiles(need_rebuild=1)

	Destroy()
		update_nearby_tiles()
		return ..()

	proc/update_nearby_tiles(need_rebuild) //Copypasta from airlock code
		if(!SSair)
			return 0
		SSair.mark_for_update(get_turf(src))
		return 1



	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		return 0

	bullet_act(obj/item/projectile/Proj)
		health -= Proj.damage
		..()
		if(health <= 0)
			deflate(1)
		return


	ex_act(severity)
		switch(severity)
			if(1.0)
				qdel(src)
				return
			if(2.0)
				deflate(1)
				return
			if(3.0)
				if(prob(50))
					deflate(1)
					return


	blob_act()
		deflate(1)


	meteorhit()
	//world << "glass at [x],[y],[z] Mhit"
		deflate(1)

	attack_paw(mob/user)
		return attack_generic(user, 15)

	attack_hand(mob/user)
		add_fingerprint(user)
		return


	proc/attack_generic(mob/user, damage = 0)	//used by attack_alien, attack_animal, and attack_slime
		health -= damage
		if(health <= 0)
			user.visible_message("<span class='danger'>[user] tears open [src]!</span>")
			deflate(1)
		else	//for nicer text~
			user.visible_message("<span class='danger'>[user] tears at [src]!</span>")

	attack_alien(mob/user)
		if(islarva(user) || isfacehugger(user)) return
		attack_generic(user, 15)

	attack_animal(mob/user)
		if(!isanimal(user)) return
		var/mob/living/simple_animal/M = user
		if(M.melee_damage_upper <= 0) return
		attack_generic(M, M.melee_damage_upper)


	attack_slime(mob/user)
		if(!isslimeadult(user)) return
		attack_generic(user, rand(10, 15))


	attackby(obj/item/weapon/W, mob/user)
		if(!istype(W)) return

		if(W.can_puncture())
			visible_message("\red <b>[user] pierces [src] with [W]!</b>")
			deflate(1)
		if(W.damtype == BRUTE || W.damtype == BURN)
			hit(W.force)
			..()
		return

	proc/hit(damage, sound_effect = 1)
		health = max(0, health - damage)
		if(sound_effect)
			playsound(loc, 'sound/effects/Glasshit.ogg', 75, 1)
		if(health <= 0)
			deflate(1)


	proc/deflate(violent=0)
		playsound(loc, 'sound/machines/hiss.ogg', 75, 1)
		if(violent)
			visible_message("[src] rapidly deflates!")
			var/obj/item/inflatable/torn/R = new /obj/item/inflatable/torn(loc)
			src.transfer_fingerprints_to(R)
			qdel(src)
		else
			//user << "\blue You slowly deflate the inflatable wall."
			visible_message("[src] slowly deflates.")
			spawn(50)
				var/obj/item/inflatable/R = new /obj/item/inflatable(loc)
				src.transfer_fingerprints_to(R)
				qdel(src)

	verb/hand_deflate()
		set name = "Deflate"
		set category = "Object"
		set src in oview(1)

		if(isobserver(usr)) //to stop ghosts from deflating
			return

		deflate()

/obj/item/inflatable/door/
	name = "inflatable door"
	desc = "A folded membrane which rapidly expands into a simple door on activation."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_door"

	attack_self(mob/user)
		playsound(loc, 'sound/items/zip.ogg', 75, 1)
		to_chat(user, "\blue You inflate [src].")
		var/obj/structure/inflatable/door/R = new /obj/structure/inflatable/door(user.loc)
		src.transfer_fingerprints_to(R)
		R.add_fingerprint(user)
		qdel(src)

/obj/structure/inflatable/door //Based on mineral door code
	name = "inflatable door"
	density = 1
	anchored = 1
	opacity = 0

	icon = 'icons/obj/inflatable.dmi'
	icon_state = "door_closed"
	var/opening_state = "door_opening"
	var/closing_state = "door_closing"
	var/open_state = "door_open"
	var/closed_state = "door_closed"

	var/state = 0 //closed, 1 == open
	var/isSwitchingStates = 0

	//Bumped(atom/user)
	//	..()
	//	if(!state)
	//		return TryToSwitchState(user)
	//	return

	attack_ai(mob/user) //those aren't machinery, they're just big fucking slabs of a mineral
		if(isAI(user)) //so the AI can't open it
			return
		else if(isrobot(user)) //but cyborgs can
			if(get_dist(user,src) <= 1) //not remotely though
				return TryToSwitchState(user)

	attack_paw(mob/user)
		return TryToSwitchState(user)

	attack_hand(mob/user)
		return TryToSwitchState(user)

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if(air_group)
			return state
		if(istype(mover, /obj/effect/beam))
			return !opacity
		return !density

	proc/TryToSwitchState(atom/user)
		if(isSwitchingStates) return
		if(ismob(user))
			var/mob/M = user
			if(world.time - user.last_bumped <= 60) return //NOTE do we really need that?
			if(M.client)
				if(iscarbon(M))
					var/mob/living/carbon/C = M
					if(!C.handcuffed)
						SwitchState()
				else
					SwitchState()
		else if(istype(user, /obj/mecha))
			SwitchState()

	proc/SwitchState()
		if(state)
			Close()
		else
			Open()
		update_nearby_tiles()

	proc/Open()
		isSwitchingStates = 1
		//playsound(loc, 'sound/effects/stonedoor_openclose.ogg', 100, 1)
		flick(opening_state,src)
		sleep(10)
		density = 0
		opacity = 0
		state = 1
		update_icon()
		isSwitchingStates = 0

	proc/Close()
		isSwitchingStates = 1
		//playsound(loc, 'sound/effects/stonedoor_openclose.ogg', 100, 1)
		flick(closing_state,src)
		sleep(10)
		density = 1
		opacity = 0
		state = 0
		update_icon()
		isSwitchingStates = 0

	update_icon()
		if(state)
			icon_state = open_state
		else
			icon_state = closed_state

	deflate(violent=0)
		playsound(loc, 'sound/machines/hiss.ogg', 75, 1)
		if(violent)
			visible_message("[src] rapidly deflates!")
			var/obj/item/inflatable/door/torn/R = new /obj/item/inflatable/door/torn(loc)
			src.transfer_fingerprints_to(R)
			qdel(src)
		else
			//user << "\blue You slowly deflate the inflatable wall."
			visible_message("[src] slowly deflates.")
			spawn(50)
				var/obj/item/inflatable/door/R = new /obj/item/inflatable/door(loc)
				src.transfer_fingerprints_to(R)
				qdel(src)


/obj/item/inflatable/torn
	name = "torn inflatable wall"
	desc = "A folded membrane which rapidly expands into a large cubical shape on activation. It is too torn to be usable."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_wall_torn"

	attack_self(mob/user)
		to_chat(user, "\blue The inflatable wall is too torn to be inflated!")
		add_fingerprint(user)

/obj/item/inflatable/door/torn
	name = "torn inflatable door"
	desc = "A folded membrane which rapidly expands into a simple door on activation. It is too torn to be usable."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_door_torn"

	attack_self(mob/user)
		to_chat(user, "\blue The inflatable door is too torn to be inflated!")
		add_fingerprint(user)

/obj/item/weapon/storage/briefcase/inflatable
	name = "inflatable barrier box"
	desc = "Contains inflatable walls and doors."
	icon_state = "inf_box"
	item_state = "syringe_kit"
	max_combined_w_class = 21

	New()
		..()
		new /obj/item/inflatable/door(src)
		new /obj/item/inflatable/door(src)
		new /obj/item/inflatable/door(src)
		new /obj/item/inflatable(src)
		new /obj/item/inflatable(src)
		new /obj/item/inflatable(src)
		new /obj/item/inflatable(src)
