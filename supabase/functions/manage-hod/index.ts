import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type RequestBody = {
  action?: string;
  id?: string;
  name?: string;
  email?: string;
  password?: string;
  college?: string;
  department?: string;
  is_active?: boolean;
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function required(value: unknown, label: string, max = 150) {
  const text = typeof value === "string" ? value.trim() : "";
  if (!text) throw new Error(`${label} is required.`);
  if (text.length > max) {
    throw new Error(`${label} must be ${max} characters or fewer.`);
  }
  return text;
}

function safeBody(body: RequestBody) {
  return { ...body, password: body.password ? "<redacted>" : undefined };
}

async function findAuthUserId(
  adminClient: ReturnType<typeof createClient>,
  id: string,
  email?: string,
) {
  const { data: byId, error: byIdError } =
    await adminClient.auth.admin.getUserById(id);
  if (!byIdError && byId?.user) return byId.user.id;

  const normalizedEmail = email?.trim().toLowerCase();
  if (!normalizedEmail) return null;

  for (let page = 1; page <= 20; page++) {
    const { data, error } = await adminClient.auth.admin.listUsers({
      page,
      perPage: 1000,
    });
    if (error) {
      console.warn("[manage-hod] Unable to list Auth users", {
        page,
        error,
      });
      return null;
    }

    const user = data.users.find((user) =>
      user.email?.toLowerCase() === normalizedEmail
    );
    if (user) return user.id;
    if (data.users.length < 1000) break;
  }

  return null;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let body: RequestBody = {};
  let createdUserId: string | null = null;

  try {
    body = await request.json();
    console.log("[manage-hod] Request received", safeBody(body));

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      throw new Error("Required Supabase environment variables are missing.");
    }

    const authorization = request.headers.get("Authorization");
    if (!authorization) {
      return json(401, { error: "Admin authentication is required." });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    console.log("[manage-hod] Reading authenticated admin user");
    const { data: authData, error: authError } =
      await userClient.auth.getUser();
    if (authError || !authData.user) {
      console.error("[manage-hod] Admin auth failed", authError);
      return json(401, {
        error: authError?.message ?? "Invalid admin session.",
      });
    }

    const adminId = authData.user.id;
    console.log("[manage-hod] Verifying public.admins", { adminId });
    const { data: admin, error: adminError } = await adminClient
      .from("admins")
      .select("id, role, is_active")
      .eq("id", adminId)
      .maybeSingle();
    if (adminError) {
      console.error("[manage-hod] Admin verification failed", adminError);
      return json(500, { error: adminError.message });
    }
    if (
      !admin ||
      String(admin.role).toLowerCase() !== "admin" ||
      admin.is_active !== true
    ) {
      return json(403, { error: "Active admin access is required." });
    }
    console.log("[manage-hod] Admin verified", { adminId });

    switch (body.action) {
      case "create": {
        const name = required(body.name, "Full name");
        const email = required(body.email, "Email", 254).toLowerCase();
        const password = required(body.password, "Password", 128);
        const college = required(body.college, "College");
        const department = required(body.department, "Department");
        if (password.length < 8) {
          return json(400, {
            error: "Password must be at least 8 characters.",
          });
        }

        console.log("[manage-hod] Creating Supabase Auth user", { email });
        const { data: created, error: createError } =
          await adminClient.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
            user_metadata: { name, role: "hod" },
            app_metadata: { role: "hod" },
          });
        if (createError || !created.user) {
          console.error("[manage-hod] Auth user creation failed", createError);
          return json(400, {
            error: createError?.message ?? "Auth user creation failed.",
          });
        }
        createdUserId = created.user.id;
        console.log("[manage-hod] Auth user created", {
          id: createdUserId,
          email,
        });

        const profile = {
          id: createdUserId,
          name,
          email,
          college,
          department,
          role: "hod",
          is_active: true,
          created_by: adminId,
          updated_at: new Date().toISOString(),
        };
        console.log("[manage-hod] Inserting public.hods profile", profile);
        const { error: insertError } = await adminClient
          .from("hods")
          .insert(profile);
        if (insertError) {
          console.error("[manage-hod] HOD profile insert failed", insertError);
          console.warn("[manage-hod] Rolling back Auth user", {
            id: createdUserId,
          });
          const { error: rollbackError } =
            await adminClient.auth.admin.deleteUser(createdUserId);
          if (rollbackError) {
            console.error("[manage-hod] Auth rollback failed", rollbackError);
            return json(500, {
              error:
                `${insertError.message}; Auth rollback failed: ` +
                rollbackError.message,
              id: createdUserId,
            });
          }
          return json(400, { error: insertError.message });
        }
        console.log("[manage-hod] HOD profile inserted", {
          id: createdUserId,
        });
        return json(200, { id: createdUserId, success: true });
      }

      case "update": {
        const id = required(body.id, "HOD ID");
        const name = required(body.name, "Full name");
        const email = required(body.email, "Email", 254).toLowerCase();
        const college = required(body.college, "College");
        const department = required(body.department, "Department");

        console.log("[manage-hod] Reading existing HOD profile", { id });
        const { data: existing, error: existingError } = await adminClient
          .from("hods")
          .select("id, name, email, college, department")
          .eq("id", id)
          .maybeSingle();
        if (existingError) return json(400, { error: existingError.message });
        if (!existing) return json(404, { error: "HOD profile not found." });

        const authUserId = await findAuthUserId(adminClient, id, existing.email);
        console.log("[manage-hod] Updating Auth user", {
          profileId: id,
          authUserId,
          email,
        });
        if (authUserId) {
          const { error: authUpdateError } =
            await adminClient.auth.admin.updateUserById(authUserId, {
            email,
            user_metadata: { name, role: "hod" },
            app_metadata: { role: "hod" },
          });
          if (authUpdateError) {
            return json(400, { error: authUpdateError.message });
          }
        } else {
          console.warn("[manage-hod] No matching Auth user for HOD profile", {
            id,
            email: existing.email,
          });
        }

        console.log("[manage-hod] Updating public.hods profile", { id });
        const { error: updateError } = await adminClient
          .from("hods")
          .update({
            name,
            email,
            college,
            department,
            updated_at: new Date().toISOString(),
          })
          .eq("id", id);
        if (updateError) {
          console.error("[manage-hod] Profile update failed", updateError);
          if (!authUserId) return json(400, { error: updateError.message });
          console.warn("[manage-hod] Rolling back Auth user update", {
            id,
            authUserId,
          });
          const { error: rollbackError } =
            await adminClient.auth.admin.updateUserById(authUserId, {
              email: existing.email,
              user_metadata: { name: existing.name, role: "hod" },
              app_metadata: { role: "hod" },
            });
          if (rollbackError) {
            return json(500, {
              error:
                `${updateError.message}; Auth rollback failed: ` +
                rollbackError.message,
            });
          }
          return json(400, { error: updateError.message });
        }
        console.log("[manage-hod] HOD update completed", { id, email });
        return json(200, { id, success: true });
      }

      case "set_active": {
        const id = required(body.id, "HOD ID");
        if (typeof body.is_active !== "boolean") {
          return json(400, { error: "Active status is required." });
        }

        console.log("[manage-hod] Reading existing HOD status", { id });
        const { data: existing, error: existingError } = await adminClient
          .from("hods")
          .select("id, email, is_active")
          .eq("id", id)
          .maybeSingle();
        if (existingError) return json(400, { error: existingError.message });
        if (!existing) return json(404, { error: "HOD profile not found." });

        const authUserId = await findAuthUserId(adminClient, id, existing.email);
        console.log("[manage-hod] Updating Auth ban status", {
          id,
          authUserId,
          isActive: body.is_active,
        });
        if (authUserId) {
          const { error: statusError } =
            await adminClient.auth.admin.updateUserById(authUserId, {
            ban_duration: body.is_active ? "none" : "876000h",
          });
          if (statusError) return json(400, { error: statusError.message });
        } else {
          console.warn("[manage-hod] No matching Auth user for HOD status", {
            id,
            email: existing.email,
          });
        }

        const { error: profileStatusError } = await adminClient
          .from("hods")
          .update({
            is_active: body.is_active,
            updated_at: new Date().toISOString(),
          })
          .eq("id", id);
        if (profileStatusError) {
          console.error(
              "[manage-hod] Profile status update failed",
              profileStatusError,
          );
          if (!authUserId) {
            return json(400, { error: profileStatusError.message });
          }
          console.warn("[manage-hod] Rolling back Auth ban status", { id });
          const { error: rollbackError } =
            await adminClient.auth.admin.updateUserById(authUserId, {
              ban_duration: existing.is_active ? "none" : "876000h",
            });
          if (rollbackError) {
            return json(500, {
              error:
                `${profileStatusError.message}; Auth rollback failed: ` +
                rollbackError.message,
            });
          }
          return json(400, { error: profileStatusError.message });
        }
        console.log("[manage-hod] HOD active status updated", {
          id,
          isActive: body.is_active,
        });
        return json(200, { id, is_active: body.is_active, success: true });
      }

      case "repair_legacy": {
        console.log("[manage-hod] Repairing legacy HOD profiles");
        const { data: hods, error: hodsError } = await adminClient
          .from("hods")
          .select("id, email");
        if (hodsError) return json(400, { error: hodsError.message });

        const repaired: Array<Record<string, string>> = [];
        const skipped: Array<Record<string, string>> = [];

        for (const hod of hods ?? []) {
          const id = String(hod.id);
          const email = String(hod.email ?? "").trim().toLowerCase();
          const authUserId = await findAuthUserId(adminClient, id, email);
          if (!authUserId || authUserId === id) continue;

          const { data: conflict, error: conflictError } = await adminClient
            .from("hods")
            .select("id")
            .eq("id", authUserId)
            .maybeSingle();
          if (conflictError) {
            skipped.push({ id, email, reason: conflictError.message });
            continue;
          }
          if (conflict) {
            skipped.push({
              id,
              email,
              reason: "A HOD profile already exists for the Auth user.",
            });
            continue;
          }

          const { error: repairError } = await adminClient
            .from("hods")
            .update({
              id: authUserId,
              updated_at: new Date().toISOString(),
            })
            .eq("id", id);
          if (repairError) {
            skipped.push({ id, email, reason: repairError.message });
            continue;
          }
          repaired.push({ previousId: id, id: authUserId, email });
        }

        console.log("[manage-hod] Legacy HOD repair completed", {
          repaired,
          skipped,
        });
        return json(200, { success: true, repaired, skipped });
      }

      case "delete": {
        const id = required(body.id, "HOD ID");
        const { data: existing, error: existingError } = await adminClient
          .from("hods")
          .select("id, email")
          .eq("id", id)
          .maybeSingle();
        if (existingError) return json(400, { error: existingError.message });

        const authUserId = await findAuthUserId(adminClient, id, existing?.email);
        console.log("[manage-hod] Deleting public.hods profile", {
          id,
          authUserId,
          note: "Auth deletion cascades the profile row",
        });
        if (authUserId) {
          console.log("[manage-hod] Deleting Auth user", { authUserId });
          const { error: deleteAuthError } =
            await adminClient.auth.admin.deleteUser(authUserId);
          if (deleteAuthError) {
            console.error(
                "[manage-hod] Auth user deletion failed",
                deleteAuthError,
            );
            return json(400, { error: deleteAuthError.message });
          }
        } else {
          console.warn("[manage-hod] No matching Auth user for HOD delete", {
            id,
            email: existing?.email,
          });
        }

        // The FK uses ON DELETE CASCADE. This explicit delete is idempotent and
        // also supports pre-existing tables without the cascade constraint.
        const { error: deleteProfileError } = await adminClient
          .from("hods")
          .delete()
          .eq("id", id);
        if (deleteProfileError) {
          return json(500, { error: deleteProfileError.message });
        }
        console.log("[manage-hod] HOD deleted", { id });
        return json(200, { id, success: true });
      }

      default:
        return json(400, { error: "Unsupported HOD action." });
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("[manage-hod] Unhandled error", {
      body: safeBody(body),
      message,
      stack: error instanceof Error ? error.stack : null,
      createdUserId,
    });
    return json(500, { error: message });
  }
});
