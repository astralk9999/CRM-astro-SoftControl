import type { APIRoute } from 'astro';
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client with service role key for admin operations
const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
const supabaseServiceKey = import.meta.env.SUPABASE_SERVICE_ROLE_KEY;

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();
    const { email, password, fullName, phone, role } = body;

    console.log('Create staff request:', { email, fullName, role });

    if (!email || !password || !fullName) {
      return new Response(JSON.stringify({ 
        error: 'Email, contraseña y nombre son requeridos' 
      }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    if (password.length < 6) {
      return new Response(JSON.stringify({ 
        error: 'La contraseña debe tener al menos 6 caracteres' 
      }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    if (!supabaseServiceKey) {
      console.error('Missing SUPABASE_SERVICE_ROLE_KEY');
      return new Response(JSON.stringify({ 
        error: 'Error de configuración del servidor' 
      }), { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Create admin client with service role
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });

    // First check if user already exists
    const { data: existingUsers } = await supabaseAdmin
      .from('profiles')
      .select('id, email')
      .eq('email', email)
      .limit(1);

    if (existingUsers && existingUsers.length > 0) {
      return new Response(JSON.stringify({ 
        error: 'Ya existe un usuario con este email' 
      }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Try creating user with admin API first
    let userId: string | null = null;

    try {
      const { data: userData, error: userError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          user_type: 'staff',
          role: role || 'staff'
        }
      });

      if (userError) {
        console.error('Admin createUser error:', userError);
        
        // If it's a database trigger error, the user might still have been created
        // Try to find the user by email
        const { data: users } = await supabaseAdmin.auth.admin.listUsers();
        const existingUser = users?.users?.find(u => u.email === email);
        
        if (existingUser) {
          console.log('User was created despite error, ID:', existingUser.id);
          userId = existingUser.id;
        } else {
          return new Response(JSON.stringify({ 
            error: userError.message 
          }), { 
            status: 400,
            headers: { 'Content-Type': 'application/json' }
          });
        }
      } else if (userData?.user) {
        userId = userData.user.id;
      }
    } catch (authError: any) {
      console.error('Auth error:', authError);
      return new Response(JSON.stringify({ 
        error: 'Error de autenticación: ' + authError.message 
      }), { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    if (!userId) {
      return new Response(JSON.stringify({ 
        error: 'No se pudo crear el usuario' 
      }), { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    console.log('User created with ID:', userId);

    // Create or update profile
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .upsert({
        id: userId,
        full_name: fullName,
        email: email,
        phone: phone || null,
        role: role || 'staff',
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }, { onConflict: 'id' });

    if (profileError) {
      console.error('Profile upsert error:', profileError);
      return new Response(JSON.stringify({ 
        success: true,
        warning: 'Usuario creado pero error en perfil: ' + profileError.message,
        userId
      }), { 
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    console.log('Profile created successfully');

    return new Response(JSON.stringify({ 
      success: true,
      userId
    }), { 
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error: any) {
    console.error('Create staff error:', error);
    return new Response(JSON.stringify({ 
      error: error.message || 'Error interno del servidor' 
    }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
