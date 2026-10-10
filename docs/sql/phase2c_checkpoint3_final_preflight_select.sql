-- SELECT-only metadata preflight; no user/profile/session records are returned.
WITH targets AS (
  SELECT oid FROM pg_class WHERE relnamespace='public'::regnamespace
    AND relname IN ('workout_plans','workout_days','workout_day_exercises')
)
SELECT jsonb_build_object(
 'checked_at_utc', now(), 'project_ref', 'nbojicqbpqgotdmdayku', 'read_only', true,
 'server_version', current_setting('server_version'),
 'migration_history', (SELECT jsonb_agg(jsonb_build_object('version',version,'name',name) ORDER BY version) FROM supabase_migrations.schema_migrations),
 'enums', (SELECT jsonb_agg(jsonb_build_object('schema',n.nspname,'type',t.typname,'order',e.enumsortorder,'value',e.enumlabel)) FROM pg_enum e JOIN pg_type t ON t.oid=e.enumtypid JOIN pg_namespace n ON n.oid=t.typnamespace WHERE n.nspname='public'),
 'columns', (SELECT jsonb_agg(to_jsonb(c)) FROM information_schema.columns c WHERE table_schema='public' AND table_name IN ('workout_plans','workout_days','workout_day_exercises')),
 'grants', (SELECT jsonb_agg(to_jsonb(c)) FROM information_schema.role_table_grants c WHERE table_schema='public' AND table_name IN ('workout_plans','workout_days','workout_day_exercises')),
 'column_grants', (SELECT jsonb_agg(to_jsonb(c)) FROM information_schema.column_privileges c WHERE table_schema='public' AND table_name IN ('workout_plans','workout_days','workout_day_exercises') AND grantee IN ('anon','authenticated')),
 'indexes', (SELECT jsonb_agg(to_jsonb(c)) FROM pg_indexes c WHERE schemaname='public' AND tablename IN ('workout_plans','workout_days','workout_day_exercises')),
 'policies', (SELECT jsonb_agg(to_jsonb(c)) FROM pg_policies c WHERE schemaname='public' AND tablename IN ('workout_plans','workout_days','workout_day_exercises')),
 'triggers', (SELECT jsonb_agg(jsonb_build_object('table',c.relname,'function',pg_get_functiondef(t.tgfoid),'definition',pg_get_triggerdef(t.oid))) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid WHERE t.tgrelid IN (SELECT oid FROM targets) AND NOT t.tgisinternal),
 'constraints', (SELECT jsonb_agg(jsonb_build_object('name',co.conname,'table',c.relname,'definition',pg_get_constraintdef(co.oid))) FROM pg_constraint co JOIN pg_class c ON c.oid=co.conrelid WHERE co.conrelid IN (SELECT oid FROM targets)),
 'dependencies', (SELECT jsonb_agg(jsonb_build_object('table',c.relname,'definition',pg_get_constraintdef(co.oid))) FROM pg_constraint co JOIN pg_class c ON c.oid=co.conrelid WHERE co.contype='f' AND co.confrelid IN (SELECT oid FROM targets)),
 'activation_rpcs', (SELECT jsonb_agg(jsonb_build_object('schema',n.nspname,'name',p.proname,'definition',pg_get_functiondef(p.oid))) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE p.proname='activate_generated_training_plan'),
 'active_duplicates', (SELECT count(*) FROM (SELECT 1 FROM public.workout_plans WHERE status='active' GROUP BY user_id,plan_type HAVING count(*)>1) d),
 'rls', (SELECT jsonb_agg(jsonb_build_object('table',relname,'enabled',relrowsecurity,'forced',relforcerowsecurity)) FROM pg_class WHERE oid IN (SELECT oid FROM targets)),
 'functions_touching_plan_tables', (SELECT jsonb_agg(jsonb_build_object('schema',n.nspname,'proname',p.proname,'prosecdef',p.prosecdef,'proconfig',p.proconfig,'authenticated_execute',has_function_privilege('authenticated',p.oid,'EXECUTE'),'writes_plan_tables',pg_get_functiondef(p.oid) ~* '(insert\s+into|update|delete\s+from)\s+(public\.)?(workout_plans|workout_days|workout_day_exercises)')) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE p.prokind='f' AND n.nspname IN ('public','arc_private') AND p.prosrc ~* '(workout_plans|workout_days|workout_day_exercises)')
) AS preflight;
