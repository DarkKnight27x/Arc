-- ARC curated catalog expansion v1. AUTHORIZED DATA INSERT ONLY; not a migration.
-- Target project: nbojicqbpqgotdmdayku. Reviewed baseline: 30 unchanged rows.
-- 53 proposed; 5 semantic overlaps skipped; 48 new rows. UUIDs use DB defaults.
-- Fail closed on baseline drift or replay. Never updates/deletes existing rows.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';
set local timezone = 'UTC';
lock table public.exercise_library in share row exclusive mode;
do $arc_preflight$
begin
  if (select count(*) from public.exercise_library) <> 30
    or (select md5(coalesce(string_agg(to_jsonb(e)::text,'' order by id),''))
        from public.exercise_library e) <> '79d359f6d599263fdd354489a92fa766' then
    raise exception 'ARC curated v1 baseline changed: repeat SELECT-only duplicate review before insertion';
  end if;
  if exists(select 1 from public.exercise_library
            where starts_with(source_external_id,'arc_curated_v1_')) then
    raise exception 'ARC curated v1 source IDs already exist: do not replay';
  end if;
end;
$arc_preflight$;
with reviewed as (
  select * from jsonb_to_recordset($arc_catalog_payload$
[
  {
    "name": "Barbell Bench Press",
    "body_part": "chest",
    "target_muscle": "pectorals",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_barbell_bench_press",
    "secondary_muscles": [
      "shoulders",
      "triceps"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Set a flat bench inside a rack with safety bars and arrange a spotter for the lift.",
      "Lie with your upper back supported, feet planted and hands evenly spaced on the bar.",
      "Unrack with straight arms and settle the bar above your chest while keeping your shoulders stable.",
      "Lower under control toward the mid chest, then press upward without bouncing or lifting your hips.",
      "Finish with the bar steady over the shoulders, guide it into both hooks and check it is secure."
    ]
  },
  {
    "name": "Dumbbell Bench Press",
    "body_part": "chest",
    "target_muscle": "pectorals",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_dumbbell_bench_press",
    "secondary_muscles": [
      "shoulders",
      "triceps"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Sit on a flat bench with the dumbbells supported on your thighs before lying back.",
      "Plant your feet and settle your upper back against the bench with the weights beside your chest.",
      "Keep your wrists aligned over your elbows and press the dumbbells upward without colliding them.",
      "Lower both weights slowly to a comfortable chest-level position while keeping your shoulders supported.",
      "Finish by bringing the weights close to your torso and returning to a seated position under control."
    ]
  },
  {
    "name": "Machine Chest Press",
    "body_part": "chest",
    "target_muscle": "pectorals",
    "equipment": "leverage machine",
    "source_external_id": "arc_curated_v1_machine_chest_press",
    "secondary_muscles": [
      "shoulders",
      "triceps"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the chest-press seat so the handles sit around mid-chest height.",
      "Sit with your back against the pad, feet planted and wrists straight on the handles.",
      "Press the handles forward smoothly without shrugging or lifting your back from the pad.",
      "Bend the elbows slowly to bring the handles back through a comfortable range.",
      "Let the machine settle before releasing the handles and standing up."
    ]
  },
  {
    "name": "Push-Up",
    "body_part": "chest",
    "target_muscle": "pectorals",
    "equipment": "body weight",
    "source_external_id": "arc_curated_v1_push_up",
    "secondary_muscles": [
      "triceps",
      "shoulders"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Place your palms on the floor just outside shoulder width and extend your legs behind you.",
      "Brace your abdomen and glutes to keep your head, torso and hips in one line.",
      "Bend your elbows and lower your chest between your hands without letting your hips sag.",
      "Press through your palms to return to straight arms while maintaining the same body line.",
      "Reset your stable position before repeating, then lower your knees to finish."
    ]
  },
  {
    "name": "Dumbbell Shoulder Press",
    "body_part": "shoulders",
    "target_muscle": "delts",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_dumbbell_shoulder_press",
    "secondary_muscles": [
      "triceps"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Sit on an upright bench with your back supported and feet planted.",
      "Bring the dumbbells beside your shoulders with wrists above elbows and palms facing forward.",
      "Brace your torso and press upward without arching your lower back or shrugging.",
      "Lower the weights slowly to the starting shoulder position while keeping your forearms controlled.",
      "Bring the weights down to your thighs before putting them away."
    ]
  },
  {
    "name": "Barbell Overhead Press",
    "body_part": "shoulders",
    "target_muscle": "delts",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_barbell_overhead_press",
    "secondary_muscles": [
      "triceps"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Position the bar on a rack around upper-chest height and clear the space above you.",
      "Grip slightly outside shoulder width, step out with the bar at the upper chest and plant your feet.",
      "Brace your abdomen and glutes, then press the bar overhead without leaning backward.",
      "Lower the bar under control to the upper chest, keeping your wrists supported over the forearms.",
      "Walk the bar back into both rack hooks and check that it is secure."
    ]
  },
  {
    "name": "Dumbbell Lateral Raise",
    "body_part": "shoulders",
    "target_muscle": "delts",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_dumbbell_lateral_raise",
    "secondary_muscles": [
      "trapezius"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Stand with feet planted and a dumbbell beside each thigh.",
      "Keep a slight elbow bend, a steady torso and your shoulders relaxed.",
      "Raise your arms out to the sides to a comfortable height around shoulder level without swinging.",
      "Lower slowly along the same path without lifting the shoulders toward the ears.",
      "Let the weights settle by your sides and reset your position before the next repetition."
    ]
  },
  {
    "name": "Dumbbell Rear Delt Fly",
    "body_part": "shoulders",
    "target_muscle": "delts",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_dumbbell_rear_delt_fly",
    "secondary_muscles": [
      "upper back"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Stand with knees softly bent and hinge at the hips until your torso inclines forward.",
      "Keep your back steady and let the dumbbells hang below your shoulders with palms facing each other.",
      "Raise your arms out to the sides with a soft elbow bend, keeping the torso still.",
      "Lower the dumbbells slowly beneath the shoulders without rounding your back.",
      "Finish by standing upright under control with the weights beside your legs."
    ]
  },
  {
    "name": "Reverse Pec Deck",
    "body_part": "shoulders",
    "target_muscle": "delts",
    "equipment": "leverage machine",
    "source_external_id": "arc_curated_v1_reverse_pec_deck",
    "secondary_muscles": [
      "upper back"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the reverse pec-deck seat so the handles line up near shoulder height.",
      "Face the pad, plant your feet and take the handles with your chest supported.",
      "Open your arms outward and backward through a comfortable range without lifting your chest off the pad.",
      "Bring the handles forward slowly while keeping your shoulders controlled.",
      "Allow the machine to settle before releasing the handles."
    ]
  },
  {
    "name": "Lat Pulldown",
    "body_part": "back",
    "target_muscle": "lats",
    "equipment": "cable",
    "source_external_id": "arc_curated_v1_lat_pulldown",
    "secondary_muscles": [
      "biceps",
      "upper back"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the pulldown seat and thigh pad, then take an even grip on the bar.",
      "Sit with feet planted, thighs supported and torso upright under the cable.",
      "Draw your elbows down to bring the bar toward the upper chest without swinging or pulling behind your neck.",
      "Let the bar rise slowly as the elbows straighten, keeping control of your shoulder position.",
      "Let the stack settle before standing and releasing the bar."
    ]
  },
  {
    "name": "Pull-Up",
    "body_part": "back",
    "target_muscle": "lats",
    "equipment": "body weight",
    "source_external_id": "arc_curated_v1_pull_up",
    "secondary_muscles": [
      "biceps",
      "upper back"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Use a secure overhead bar and a stable step to reach it if needed.",
      "Take an overhand grip and settle into a controlled hang with your torso braced.",
      "Pull your elbows downward to raise your body toward the bar without kicking or swinging.",
      "Lower slowly until your arms extend through a controlled range.",
      "Return to the step or floor carefully before releasing the bar."
    ]
  },
  {
    "name": "Assisted Pull-Up",
    "body_part": "back",
    "target_muscle": "lats",
    "equipment": "assisted",
    "source_external_id": "arc_curated_v1_assisted_pull_up",
    "secondary_muscles": [
      "biceps",
      "upper back"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the assistance machine and use its steps and handholds to mount it securely.",
      "Grip the pull-up handles and place your knees or feet on the support as the machine requires.",
      "Brace your torso and pull upward without swinging or jerking against the support.",
      "Lower slowly as your arms extend, keeping the support under control.",
      "Use the fixed steps to dismount without letting the moving support spring upward."
    ]
  },
  {
    "name": "Straight-Arm Cable Pulldown",
    "body_part": "back",
    "target_muscle": "lats",
    "equipment": "cable",
    "source_external_id": "arc_curated_v1_straight_arm_cable_pulldown",
    "secondary_muscles": [
      "upper back"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Attach a straight bar or rope to a high cable and stand facing it with feet planted.",
      "Hold the attachment in front of you with a soft elbow bend and a slight hip hinge.",
      "Pull toward your thighs by moving the arms at the shoulders while keeping the elbow bend steady.",
      "Let the attachment rise slowly to the starting position without arching your back.",
      "Step closer and let the stack settle before releasing the attachment."
    ]
  },
  {
    "name": "One-Arm Dumbbell Row",
    "body_part": "back",
    "target_muscle": "lats",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_one_arm_dumbbell_row",
    "secondary_muscles": [
      "upper back",
      "biceps"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Support one hand and knee on a stable bench, with the other foot planted on the floor.",
      "Keep your back steady and let a dumbbell hang beneath the free shoulder.",
      "Draw your elbow toward your hip without twisting your torso or shrugging.",
      "Lower the dumbbell slowly until the arm extends beneath the shoulder.",
      "Put the weight down under control and set up the same position on the other side."
    ]
  },
  {
    "name": "Seated Cable Row",
    "body_part": "back",
    "target_muscle": "upper back",
    "equipment": "cable",
    "source_external_id": "arc_curated_v1_seated_cable_row",
    "secondary_muscles": [
      "lats",
      "biceps"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Sit at a low-row station with feet securely placed and knees softly bent.",
      "Hold the handle with arms extended and settle your torso upright without rounding your back.",
      "Pull toward your lower ribs, moving your elbows backward without leaning or jerking.",
      "Extend the arms slowly as the handle moves forward, keeping the torso stable.",
      "Let the stack settle before releasing the handle and leaving the seat."
    ]
  },
  {
    "name": "Chest-Supported Dumbbell Row",
    "body_part": "back",
    "target_muscle": "upper back",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_chest_supported_dumbbell_row",
    "secondary_muscles": [
      "lats",
      "biceps"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Set an incline bench securely and lie face down with your chest supported.",
      "Plant your feet and let the dumbbells hang beneath your shoulders.",
      "Row the weights toward your ribs while keeping your chest against the pad.",
      "Lower slowly until the arms extend without lifting or swinging your torso.",
      "Put the weights down under control before getting off the bench."
    ]
  },
  {
    "name": "Machine High Row",
    "body_part": "back",
    "target_muscle": "upper back",
    "equipment": "leverage machine",
    "source_external_id": "arc_curated_v1_machine_high_row",
    "secondary_muscles": [
      "lats",
      "biceps"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the high-row seat and chest pad so you can reach the elevated handles securely.",
      "Plant your feet and take the handles with your chest supported and arms reaching upward.",
      "Draw the elbows down and back to bring the handles toward your upper ribs without lifting off the pad.",
      "Return the handles slowly along their diagonal path while keeping your torso stable.",
      "Allow the machine to settle before releasing the handles."
    ]
  },
  {
    "name": "Cable Face Pull",
    "body_part": "back",
    "target_muscle": "upper back",
    "equipment": "cable",
    "source_external_id": "arc_curated_v1_cable_face_pull",
    "secondary_muscles": [
      "delts"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Attach a rope near face height and stand facing the cable in a steady stance.",
      "Hold the rope ends with arms extended and brace your torso without leaning back.",
      "Pull toward your face while separating the rope ends and moving the elbows outward.",
      "Extend the arms slowly to return the rope in front of you while keeping your shoulders controlled.",
      "Let the stack settle before releasing the rope."
    ]
  },
  {
    "name": "EZ-Bar Curl",
    "body_part": "upper arms",
    "target_muscle": "biceps",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_ez_bar_curl",
    "secondary_muscles": [
      "forearms"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Stand with feet planted and hold the angled sections of an EZ bar with palms facing upward.",
      "Set your wrists comfortably and keep your elbows beside your torso.",
      "Curl the bar upward without swinging your hips or moving the elbows forward.",
      "Lower slowly until your elbows extend through a comfortable range.",
      "Keep your torso steady as you return the bar to the starting position."
    ]
  },
  {
    "name": "Dumbbell Preacher Curl",
    "body_part": "upper arms",
    "target_muscle": "biceps",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_dumbbell_preacher_curl",
    "secondary_muscles": [
      "forearms"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust a preacher bench so your upper arm rests securely on the pad.",
      "Hold a dumbbell with palm facing upward and keep the shoulder stable against the support.",
      "Bend the elbow to curl the weight toward your shoulder without lifting the upper arm.",
      "Lower slowly to a comfortable extended position without forcing the elbow straight.",
      "Put the dumbbell down under control before setting up the other arm."
    ]
  },
  {
    "name": "Cable Triceps Pushdown",
    "body_part": "upper arms",
    "target_muscle": "triceps",
    "equipment": "cable",
    "source_external_id": "arc_curated_v1_cable_triceps_pushdown",
    "secondary_muscles": [],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Attach a bar or rope to a high cable and stand facing the station.",
      "Plant your feet, hold the attachment and place your elbows beside your torso.",
      "Straighten your elbows to move the attachment downward without rocking your body.",
      "Bend the elbows slowly to bring the attachment back while keeping the upper arms still.",
      "Let the stack settle before releasing the attachment."
    ]
  },
  {
    "name": "Cable Overhead Triceps Extension",
    "body_part": "upper arms",
    "target_muscle": "triceps",
    "equipment": "cable",
    "source_external_id": "arc_curated_v1_cable_overhead_triceps_extension",
    "secondary_muscles": [],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Attach a rope to a cable positioned behind you and take a steady staggered stance.",
      "Hold the rope above and behind your head with elbows bent and torso braced.",
      "Straighten your elbows to move your hands forward and upward without arching your back.",
      "Bend the elbows slowly to return your hands behind the head through a comfortable range.",
      "Step back under control and let the stack settle before releasing the rope."
    ]
  },
  {
    "name": "Close-Grip Bench Press",
    "body_part": "upper arms",
    "target_muscle": "triceps",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_close_grip_bench_press",
    "secondary_muscles": [
      "pectorals",
      "delts"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Set a flat bench in a rack with safety bars and arrange a spotter for the lift.",
      "Lie with feet planted and take a grip slightly narrower than your usual bench-press grip, keeping wrists supported.",
      "Unrack over the chest and lower slowly with the elbows tracking close to your torso.",
      "Press upward without bouncing the bar, lifting your hips or folding the wrists backward.",
      "Guide the bar into both rack hooks and check it is secure before sitting up."
    ]
  },
  {
    "name": "Assisted Dip",
    "body_part": "upper arms",
    "target_muscle": "triceps",
    "equipment": "assisted",
    "source_external_id": "arc_curated_v1_assisted_dip",
    "secondary_muscles": [
      "pectorals",
      "delts"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the assisted-dip machine and use the fixed steps and handholds to mount it.",
      "Grip the parallel handles and place your knees or feet on the moving support as required.",
      "Bend the elbows to lower through a comfortable range without letting the shoulders roll forward.",
      "Press back upward smoothly without bouncing on the support or forcing the elbows past straight.",
      "Use the fixed steps to dismount while keeping the moving support controlled."
    ]
  },
  {
    "name": "Barbell Back Squat",
    "body_part": "upper legs",
    "target_muscle": "quadriceps",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_barbell_back_squat",
    "secondary_muscles": [
      "glutes",
      "hamstrings"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Set a squat rack with safety bars and position the bar on both hooks below shoulder height.",
      "Take the bar across the upper back, brace your torso and step out with feet securely planted.",
      "Bend the hips and knees to lower through a controlled range, keeping the whole foot grounded.",
      "Push through your feet to stand while keeping the bar balanced and knees tracking with the feet.",
      "Walk the bar into both rack hooks and check it is secure before stepping away."
    ]
  },
  {
    "name": "Barbell Front Squat",
    "body_part": "upper legs",
    "target_muscle": "quadriceps",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_barbell_front_squat",
    "secondary_muscles": [
      "glutes",
      "hamstrings"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Set a rack with safety bars and position the bar at a height you can unrack without tiptoeing.",
      "Support the bar across the front of the shoulders with elbows lifted, brace and step out steadily.",
      "Bend the hips and knees to lower through a comfortable range without dropping the elbows or heels.",
      "Drive through the whole foot to stand, keeping your torso and bar position controlled.",
      "Walk the bar into both rack hooks and check it is secure before releasing it."
    ]
  },
  {
    "name": "Leg Extension",
    "body_part": "upper legs",
    "target_muscle": "quadriceps",
    "equipment": "leverage machine",
    "source_external_id": "arc_curated_v1_leg_extension",
    "secondary_muscles": [],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the leg-extension seat so your knees align with the machine's pivot and the roller sits above the ankles.",
      "Sit with your back supported, feet behind the roller and hands holding the side handles.",
      "Straighten the knees smoothly to lift the roller without lifting your hips from the seat.",
      "Bend the knees slowly to return the roller through a comfortable range.",
      "Let the machine settle before moving your legs away from the roller."
    ]
  },
  {
    "name": "Bulgarian Split Squat",
    "body_part": "upper legs",
    "target_muscle": "quadriceps",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_bulgarian_split_squat",
    "secondary_muscles": [
      "glutes",
      "hamstrings"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Place a stable bench behind you and stand in front of it holding dumbbells by your sides.",
      "Rest the top of one foot on the bench and plant the front foot far enough forward to balance.",
      "Bend the front knee and hip to lower under control with your torso steady and the front foot grounded.",
      "Press through the front foot to rise without pushing or bouncing off the rear foot.",
      "Step away from the bench under control before setting up the other side."
    ]
  },
  {
    "name": "Walking Lunge",
    "body_part": "upper legs",
    "target_muscle": "quadriceps",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_walking_lunge",
    "secondary_muscles": [
      "glutes",
      "hamstrings"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Clear a level walking lane and stand with dumbbells beside your thighs.",
      "Step forward far enough to plant the leading foot securely and keep your torso upright.",
      "Bend both knees to lower under control without dropping the rear knee onto the floor.",
      "Press through the front foot to stand and bring the rear leg forward into the next stable step.",
      "Continue alternating with controlled landings, then stop with both feet planted before putting down the weights."
    ]
  },
  {
    "name": "Hack Squat",
    "body_part": "upper legs",
    "target_muscle": "quadriceps",
    "equipment": "sled machine",
    "source_external_id": "arc_curated_v1_hack_squat",
    "secondary_muscles": [
      "glutes",
      "hamstrings"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the hack-squat machine and check how its safety catches engage.",
      "Place your back against the pad, shoulders under the supports and feet securely on the platform.",
      "Release the catches and bend the hips and knees slowly while keeping your back and heels supported.",
      "Press through the whole foot to rise without bouncing or forcing the knees past straight.",
      "Re-engage the catches and check that the sled is held before stepping out."
    ]
  },
  {
    "name": "Romanian Deadlift",
    "body_part": "upper legs",
    "target_muscle": "hamstrings",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_romanian_deadlift",
    "secondary_muscles": [
      "glutes",
      "spine"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Stand with feet planted and hold a barbell in front of your thighs with an even grip.",
      "Brace your torso, soften your knees and keep the bar close to your legs.",
      "Move your hips backward to lower the bar only while you can maintain a steady back position.",
      "Drive the hips forward to stand without leaning backward at the top.",
      "Reset with the bar near your thighs and put it down under control when finished."
    ]
  },
  {
    "name": "Seated Leg Curl",
    "body_part": "upper legs",
    "target_muscle": "hamstrings",
    "equipment": "leverage machine",
    "source_external_id": "arc_curated_v1_seated_leg_curl",
    "secondary_muscles": [
      "calves"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the seated-curl machine so your knees align with its pivot and the lower roller sits above your heels.",
      "Sit with your back supported and secure the thigh pad as the machine requires.",
      "Bend the knees to draw the lower roller downward and back without lifting your hips.",
      "Extend the knees slowly to return through a comfortable range.",
      "Let the machine settle before releasing the thigh support and getting up."
    ]
  },
  {
    "name": "Lying Leg Curl",
    "body_part": "upper legs",
    "target_muscle": "hamstrings",
    "equipment": "leverage machine",
    "source_external_id": "arc_curated_v1_lying_leg_curl",
    "secondary_muscles": [
      "calves"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the lying-curl machine so the roller rests on the lower legs above the heels.",
      "Lie face down with hips supported and hands holding the handles.",
      "Bend your knees to bring your heels toward your hips without arching your back or lifting off the pad.",
      "Lower the roller slowly as the knees extend through a comfortable range.",
      "Let the machine settle before moving your legs clear of the roller."
    ]
  },
  {
    "name": "Barbell Good Morning",
    "body_part": "upper legs",
    "target_muscle": "hamstrings",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_barbell_good_morning",
    "secondary_muscles": [
      "glutes",
      "spine"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Set a bar on a rack with safety bars and place it securely across your upper back.",
      "Brace your torso and step out with feet planted and knees softly bent.",
      "Hinge at the hips, moving them backward while keeping your back steady and the bar balanced.",
      "Reverse the hinge to stand without rounding your back or leaning backward.",
      "Walk the bar into both rack hooks and confirm it is secure before stepping away."
    ]
  },
  {
    "name": "Single-Leg Romanian Deadlift",
    "body_part": "upper legs",
    "target_muscle": "hamstrings",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_single_leg_romanian_deadlift",
    "secondary_muscles": [
      "glutes"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Stand holding dumbbells beside your thighs and shift onto one securely planted foot.",
      "Keep the standing knee softly bent and brace your torso with your hips facing forward.",
      "Hinge at the hip as the free leg moves behind you, lowering only while you can maintain balance and a steady back.",
      "Drive the standing hip forward to return upright without twisting or leaning back.",
      "Place both feet down to reset, then set up the other side."
    ]
  },
  {
    "name": "Barbell Hip Thrust",
    "body_part": "upper legs",
    "target_muscle": "glutes",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_barbell_hip_thrust",
    "secondary_muscles": [
      "hamstrings"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Place a stable bench behind you and position a padded bar over your hip crease while seated on the floor.",
      "Set your upper back against the bench and plant both feet with room to drive through them.",
      "Brace your torso and lift the hips until your trunk and thighs align without arching your lower back.",
      "Lower the hips slowly while keeping the bar controlled over the hip crease.",
      "Return to the floor and move the bar away under control before standing up."
    ]
  },
  {
    "name": "Glute Bridge",
    "body_part": "upper legs",
    "target_muscle": "glutes",
    "equipment": "body weight",
    "source_external_id": "arc_curated_v1_glute_bridge",
    "secondary_muscles": [
      "hamstrings"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Lie on your back with knees bent, feet flat and arms resting beside you.",
      "Brace your abdomen and plant your feet without lifting the heels.",
      "Press through the feet to lift the hips until your torso and thighs align without arching the back.",
      "Lower the hips slowly toward the floor while keeping the knees steady.",
      "Reset your position on the floor before repeating."
    ]
  },
  {
    "name": "Cable Glute Kickback",
    "body_part": "upper legs",
    "target_muscle": "glutes",
    "equipment": "cable",
    "source_external_id": "arc_curated_v1_cable_glute_kickback",
    "secondary_muscles": [
      "hamstrings"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Attach an ankle strap to a low cable and fasten it securely around one ankle.",
      "Face the station, hold a fixed support and plant the other foot with the knee softly bent.",
      "Move the strapped leg backward from the hip without arching your back or turning the pelvis.",
      "Bring the leg forward slowly to the starting position without letting the cable pull you off balance.",
      "Let the stack settle before removing the strap and changing sides."
    ]
  },
  {
    "name": "Sumo Deadlift",
    "body_part": "upper legs",
    "target_muscle": "glutes",
    "equipment": "barbell",
    "source_external_id": "arc_curated_v1_sumo_deadlift",
    "secondary_muscles": [
      "hamstrings",
      "quadriceps",
      "spine"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Place the bar on level ground and stand close with feet wider than your hips and toes turned out comfortably.",
      "Bend the hips and knees to grip between your legs, then brace with a steady back and arms straight.",
      "Push through your feet and extend the hips and knees together to stand with the bar close to you.",
      "Lower by bending the hips and knees under control until the plates return to the ground.",
      "Reset your stance and brace before lifting again, without bouncing the bar from the floor."
    ]
  },
  {
    "name": "Dumbbell Step-Up",
    "body_part": "upper legs",
    "target_muscle": "glutes",
    "equipment": "dumbbell",
    "source_external_id": "arc_curated_v1_dumbbell_step_up",
    "secondary_muscles": [
      "quadriceps",
      "hamstrings"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Use a stable step with enough surface for your whole foot and hold dumbbells by your sides.",
      "Plant one foot fully on the step and keep your torso steady.",
      "Push through the raised foot to bring your body onto the step without jumping off the lower foot.",
      "Step down slowly while controlling the descent through the leg on the step.",
      "Place both feet on the floor to reset before changing sides."
    ]
  },
  {
    "name": "Standing Machine Calf Raise",
    "body_part": "lower legs",
    "target_muscle": "calves",
    "equipment": "leverage machine",
    "source_external_id": "arc_curated_v1_standing_machine_calf_raise",
    "secondary_muscles": [],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the standing calf-raise machine so its supports rest securely on your shoulders.",
      "Place the balls of your feet on the platform edge with heels free and hold the handles.",
      "Rise onto the balls of your feet without bouncing or bending the torso.",
      "Lower your heels slowly through a comfortable ankle range while keeping the knees softly extended.",
      "Return to a stable foot position and secure the machine before stepping out."
    ]
  },
  {
    "name": "Seated Calf Raise",
    "body_part": "lower legs",
    "target_muscle": "calves",
    "equipment": "leverage machine",
    "source_external_id": "arc_curated_v1_seated_calf_raise",
    "secondary_muscles": [],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Adjust the seated calf-raise pad to sit securely on the lower thighs rather than directly on the kneecaps.",
      "Sit with the balls of your feet on the platform edge and heels free to move.",
      "Release the catch and raise your heels smoothly while keeping your thighs against the pad.",
      "Lower the heels slowly through a comfortable ankle range without bouncing.",
      "Re-engage the catch and check that the support is held before taking your feet away."
    ]
  },
  {
    "name": "Leg Press Calf Press",
    "body_part": "lower legs",
    "target_muscle": "calves",
    "equipment": "sled machine",
    "source_external_id": "arc_curated_v1_leg_press_calf_press",
    "secondary_muscles": [],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Set up in a leg-press machine and check its safety catches before moving the sled.",
      "Keep your back and hips supported with the balls of both feet securely on the lower part of the footplate.",
      "Hold the knees softly extended and press through the balls of your feet to raise the heels.",
      "Lower the heels slowly through a controlled ankle range without letting your feet slide off the plate.",
      "Re-engage the catches and confirm the sled is held before getting out."
    ]
  },
  {
    "name": "Single-Leg Calf Raise",
    "body_part": "lower legs",
    "target_muscle": "calves",
    "equipment": "body weight",
    "source_external_id": "arc_curated_v1_single_leg_calf_raise",
    "secondary_muscles": [],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Stand beside a stable support and rest a hand on it for balance.",
      "Plant one foot firmly on the floor and lift the other foot clear.",
      "Raise the heel of the standing leg smoothly without leaning or bouncing.",
      "Lower the heel slowly back to the floor while keeping the knee and ankle controlled.",
      "Place both feet down before setting up the other side."
    ]
  },
  {
    "name": "Plank",
    "body_part": "waist",
    "target_muscle": "abs",
    "equipment": "body weight",
    "source_external_id": "arc_curated_v1_plank",
    "secondary_muscles": [
      "glutes"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Place your forearms on the floor with elbows under shoulders and extend your legs behind you.",
      "Plant your toes and brace your abdomen and glutes so your body forms a steady line.",
      "Maintain that position without sagging at the hips or lifting them upward.",
      "Breathe steadily and stop the hold when you can no longer maintain the position.",
      "Lower your knees to the floor and relax the brace to finish."
    ]
  },
  {
    "name": "Reverse Crunch",
    "body_part": "waist",
    "target_muscle": "abs",
    "equipment": "body weight",
    "source_external_id": "arc_curated_v1_reverse_crunch",
    "secondary_muscles": [
      "hip flexors"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Lie on your back with arms resting on the floor and lift your bent knees above the hips.",
      "Brace your abdomen and keep your shoulders relaxed against the floor.",
      "Curl the pelvis gently toward the ribs so your hips lift slightly without swinging the legs.",
      "Lower the pelvis slowly until it rests on the floor, keeping the knees bent.",
      "Reset the brace and repeat only while you can control the return."
    ]
  },
  {
    "name": "Dead Bug",
    "body_part": "waist",
    "target_muscle": "abs",
    "equipment": "body weight",
    "source_external_id": "arc_curated_v1_dead_bug",
    "secondary_muscles": [
      "hip flexors"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Lie on your back with arms reaching upward and hips and knees bent over your torso.",
      "Brace your abdomen while keeping a comfortable, steady lower-back position against the floor.",
      "Reach one arm overhead as the opposite leg extends only as far as you can keep the torso still.",
      "Bring both limbs back slowly to the starting position without changing your back position.",
      "Repeat on the other side with controlled breathing and no swinging."
    ]
  },
  {
    "name": "Hanging Knee Raise",
    "body_part": "waist",
    "target_muscle": "abs",
    "equipment": "body weight",
    "source_external_id": "arc_curated_v1_hanging_knee_raise",
    "secondary_muscles": [
      "hip flexors"
    ],
    "difficulty": null,
    "gif_path": null,
    "tags": [],
    "is_published": true,
    "instructions": [
      "Use a secure overhead bar and a stable step to take an even grip.",
      "Settle into a controlled hang with your torso braced and legs still.",
      "Bend your knees and draw them upward toward your torso without kicking or swinging.",
      "Lower the legs slowly back to the starting hang while controlling your pelvis.",
      "Return to the step or floor carefully before releasing the bar."
    ]
  }
]
$arc_catalog_payload$::jsonb) as r(
    source_external_id text, name text, body_part text, target_muscle text,
    secondary_muscles text[], equipment text, difficulty text,
    instructions text[], gif_path text, tags text[], is_published boolean)
)
insert into public.exercise_library(
  source_external_id,name,body_part,target_muscle,secondary_muscles,equipment,
  difficulty,instructions,gif_path,tags,is_published)
select source_external_id,name,body_part,target_muscle,secondary_muscles,equipment,
  difficulty,instructions,gif_path,tags,is_published from reviewed;
do $arc_verify$
begin
  if (select count(*) from public.exercise_library) <> 78
    or (select count(*) from public.exercise_library
        where starts_with(source_external_id,'arc_curated_v1_')) <> 48 then
    raise exception 'ARC curated v1 unexpected inserted count';
  end if;
  if (select md5(coalesce(string_agg(to_jsonb(e)::text,'' order by id),''))
      from public.exercise_library e
      where not coalesce(starts_with(source_external_id,'arc_curated_v1_'),false))
        <> '79d359f6d599263fdd354489a92fa766' then
    raise exception 'ARC curated v1 original catalog changed';
  end if;
  if exists(select 1 from public.exercise_library e
    where starts_with(source_external_id,'arc_curated_v1_') and
      (not is_published or gif_path is not null or difficulty is not null
       or cardinality(tags) <> 0 or cardinality(instructions) not between 4 and 7
       or exists(select 1 from unnest(instructions) i where i is null or btrim(i)=''))) then
    raise exception 'ARC curated v1 catalog validation failed';
  end if;
end;
$arc_verify$;
commit;
