import { supabase, getProfile, getCustomerByAuthUser } from './supabase';
import type { Profile, Customer, UserRole } from './supabase';

// Tipo de usuario: staff (empleado) o customer (cliente)
export type UserType = 'staff' | 'customer' | null;

export interface AuthUser {
  id: string;
  email: string;
  userType: UserType;
  profile: Profile | null;  // Solo para staff
  customer: Customer | null; // Solo para customers
}

export const checkAuth = async (): Promise<AuthUser | null> => {
  const { data: { session }, error } = await supabase.auth.getSession();
  
  if (error || !session) {
    return null;
  }
  
  // Intentar obtener perfil de staff
  const profile = await getProfile(session.user.id);
  
  // Intentar obtener perfil de customer (por email, más fiable)
  let customer = await getCustomerByAuthUser(session.user.id, session.user.email);
  
  // Si no es staff y no tiene customer record, crear uno automáticamente
  if (!profile && !customer && session.user.email) {
    console.log('Creating customer record for user without one:', session.user.id);
    const userMeta = session.user.user_metadata || {};
    
    // Crear sin auth_user_id ya que la columna puede no existir
    const { data: newCustomer, error: createError } = await supabase
      .from('customers')
      .insert({
        email: session.user.email,
        full_name: userMeta.full_name || session.user.email.split('@')[0],
        company_name: userMeta.company_name || null,
        is_active: true
      })
      .select()
      .single();
    
    if (newCustomer) {
      customer = newCustomer;
      console.log('Customer record created:', newCustomer.id);
    } else if (createError) {
      console.error('Error creating customer on login:', createError);
    }
  }
  
  let userType: UserType = null;
  if (profile) {
    userType = 'staff';
  } else if (customer) {
    userType = 'customer';
  }
  
  return {
    id: session.user.id,
    email: session.user.email || '',
    userType,
    profile,
    customer,
  };
};

// Verifica si el usuario es staff de SoftControl
export const isStaffUser = (user: AuthUser | null): boolean => {
  return user?.userType === 'staff' && user?.profile?.is_active === true;
};

// Verifica si es admin
export const isAdmin = (user: AuthUser | null): boolean => {
  return isStaffUser(user) && (user?.profile?.role === 'admin' || user?.profile?.role === 'super_admin');
};

// Verifica si es super admin
export const isSuperAdmin = (user: AuthUser | null): boolean => {
  return isStaffUser(user) && user?.profile?.role === 'super_admin';
};

// Verifica si es staff (cualquier rol de empleado)
export const isStaff = (user: AuthUser | null): boolean => {
  return isStaffUser(user);
};

// Verifica si es cliente
export const isCustomer = (user: AuthUser | null): boolean => {
  return user?.userType === 'customer' && user?.customer?.is_active === true;
};

export const hasRole = (user: AuthUser | null, roles: UserRole[]): boolean => {
  if (!user?.profile) return false;
  return roles.includes(user.profile.role);
};

export const requireAuth = async (redirectTo: string = '/login'): Promise<AuthUser> => {
  const user = await checkAuth();
  
  if (!user) {
    if (typeof window !== 'undefined') {
      window.location.href = redirectTo;
    }
    throw new Error('Not authenticated');
  }
  
  return user;
};

// Requiere que el usuario sea staff de SoftControl
export const requireStaff = async (redirectTo: string = '/login'): Promise<AuthUser> => {
  const user = await requireAuth();
  
  if (!isStaffUser(user)) {
    if (typeof window !== 'undefined') {
      window.location.href = redirectTo;
    }
    throw new Error('Not authorized - Staff only');
  }
  
  return user;
};

// Requiere que el usuario sea admin
export const requireAdmin = async (redirectTo: string = '/dashboard'): Promise<AuthUser> => {
  const user = await requireStaff();
  
  if (!isAdmin(user)) {
    if (typeof window !== 'undefined') {
      window.location.href = redirectTo;
    }
    throw new Error('Not authorized - Admin only');
  }
  
  return user;
};

// Requiere que el usuario sea cliente
export const requireCustomer = async (redirectTo: string = '/login'): Promise<AuthUser> => {
  const user = await requireAuth();
  
  if (!isCustomer(user)) {
    if (typeof window !== 'undefined') {
      window.location.href = redirectTo;
    }
    throw new Error('Not authorized - Customer only');
  }
  
  return user;
};
