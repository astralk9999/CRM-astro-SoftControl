import { createClient } from '@supabase/supabase-js';

// ==============================================
// TYPES - Single Company Model
// ==============================================

export type UserRole = 'super_admin' | 'admin' | 'staff';
export type SubscriptionType = 'monthly' | 'annual' | 'lifetime' | 'trial';
export type SubscriptionStatus = 'active' | 'inactive' | 'cancelled' | 'expired' | 'pending' | 'trial';
export type PaymentStatus = 'paid' | 'pending' | 'failed' | 'refunded';
export type LicenseStatus = 'active' | 'inactive' | 'expired' | 'revoked';

// Staff de SoftControl
export interface Profile {
  id: string;
  full_name: string;
  email?: string;
  phone?: string;
  avatar_url?: string;
  role: UserRole;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Clientes que compran licencias
export interface Customer {
  id: string;
  auth_user_id?: string;
  email: string;
  full_name: string;
  phone?: string;
  company_name?: string;
  address?: string;
  city?: string;
  country?: string;
  tax_id?: string;
  notes?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Productos/Planes
export interface Product {
  id: string;
  name: string;
  description?: string;
  sku?: string;
  subscription_type: SubscriptionType;
  price: number;
  currency: string;
  duration_days?: number;
  features: string[];
  stripe_price_id?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Suscripciones
export interface Subscription {
  id: string;
  customer_id: string;
  product_id: string;
  subscription_type: SubscriptionType;
  status: SubscriptionStatus;
  start_date?: string;
  end_date?: string;
  trial_ends_at?: string;
  auto_renew: boolean;
  stripe_subscription_id?: string;
  stripe_customer_id?: string;
  payment_status: PaymentStatus;
  last_payment_date?: string;
  next_payment_date?: string;
  amount?: number;
  currency?: string;
  created_at: string;
  updated_at: string;
}

export interface SubscriptionFull extends Subscription {
  customer_name: string;
  customer_email: string;
  customer_company?: string;
  product_name: string;
  subscription_type: SubscriptionType;
  product_price: number;
  is_valid: boolean;
}

// Ventas
export interface Sale {
  id: string;
  customer_id: string;
  subscription_id?: string;
  product_id: string;
  amount: number;
  currency: string;
  payment_status: PaymentStatus;
  payment_method?: string;
  stripe_payment_id?: string;
  stripe_invoice_id?: string;
  invoice_number?: string;
  notes?: string;
  sale_date: string;
  created_at: string;
}

export interface SaleFull extends Sale {
  customer_name: string;
  customer_email: string;
  customer_company?: string;
  product_name: string;
  subscription_type: SubscriptionType;
}

// Licencias
export interface License {
  id: string;
  customer_id: string;
  subscription_id?: string;
  product_id?: string | null;
  license_key: string;
  status: LicenseStatus;
  activation_date?: string;
  expiration_date?: string;
  max_activations: number;
  current_activations: number;
  created_at: string;
  updated_at: string;
}

export interface LicenseFull extends License {
  customer_name: string;
  customer_email: string;
  product_name: string;
  subscription_type: SubscriptionType;
  is_valid: boolean;
}

// Dashboard Stats
export interface DashboardStats {
  total_customers: number;
  new_customers_month: number;
  active_subscriptions: number;
  pending_subscriptions: number;
  expired_subscriptions: number;
  active_licenses: number;
  total_revenue: number;
  monthly_revenue: number;
  pending_revenue: number;
  sales_this_month: number;
}

// ==============================================
// SUPABASE CLIENT
// ==============================================

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl || '', supabaseAnonKey || '');

// ==============================================
// AUTH HELPERS
// ==============================================

export const signIn = async (email: string, password: string) => {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  return { data, error };
};

// Registro de STAFF (empleados de SoftControl)
export const signUpStaff = async (
  email: string, 
  password: string, 
  fullName: string,
  role: UserRole = 'staff'
) => {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: fullName,
        role: role,
        user_type: 'staff'
      }
    }
  });
  return { data, error };
};

// Registro de CLIENTE (personas que compran licencias)
export const signUpCustomer = async (
  email: string, 
  password: string, 
  fullName: string,
  companyName?: string
) => {
  console.log('SignUpCustomer called for:', email);
  
  // 1. Crear usuario en Auth
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: fullName,
        company_name: companyName,
        user_type: 'customer'
      },
      emailRedirectTo: `${window.location.origin}/login`
    }
  });

  console.log('Auth signUp response:', { user: data?.user?.id, session: data?.session?.access_token ? 'exists' : 'none', error });

  if (error) {
    console.error('Auth signUp error:', error);
    return { data, error, customerId: null };
  }

  // Check if user was actually created or if it's a fake signup (user exists but no session)
  if (!data.user) {
    console.error('No user returned from signUp');
    return { data, error: new Error('No se pudo crear el usuario'), customerId: null };
  }

  // If identities is empty, the user already exists
  if (data.user.identities && data.user.identities.length === 0) {
    console.error('User already exists (empty identities)');
    return { data, error: new Error('Este email ya está registrado'), customerId: null };
  }

  let customerId: string | null = null;

  // 2. Crear registro en customers manualmente (backup del trigger)
  console.log('Creating customer record for user:', data.user.id);
  
  const { data: customerData, error: customerError } = await supabase
    .from('customers')
    .insert({
      email: email,
      full_name: fullName,
      company_name: companyName || null,
      is_active: true
    })
    .select('id')
    .single();
  
  if (customerData) {
    customerId = customerData.id;
    console.log('Customer created with ID:', customerId);
  } else if (customerError) {
    console.error('Error creating customer record:', customerError);
    // Try to fetch existing customer by email if it was a duplicate
    if (customerError.message.includes('duplicate') || customerError.code === '23505') {
      const { data: existingCustomer } = await supabase
        .from('customers')
        .select('id')
        .eq('email', email)
        .single();
      if (existingCustomer) {
        customerId = existingCustomer.id;
        console.log('Found existing customer:', customerId);
      }
    }
  }

  return { data, error: null, customerId };
};

export const signOut = async () => {
  const { error } = await supabase.auth.signOut();
  return { error };
};

export const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
};

export const getCurrentSession = async () => {
  const { data: { session } } = await supabase.auth.getSession();
  return session;
};

// ==============================================
// PROFILE HELPERS (Staff)
// ==============================================

export const getProfile = async (userId: string): Promise<Profile | null> => {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .maybeSingle();
  
  if (error) {
    console.error('Error fetching profile:', error);
    return null;
  }
  return data ?? null;
};

export const getProfiles = async (): Promise<Profile[]> => {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .order('full_name');
  
  if (error) {
    console.error('Error fetching profiles:', error);
    return [];
  }
  return data || [];
};

export const updateProfile = async (userId: string, profile: Partial<Profile>) => {
  const { data, error } = await supabase
    .from('profiles')
    .update(profile)
    .eq('id', userId)
    .select()
    .single();
  return { data, error };
};

// ==============================================
// CUSTOMER HELPERS
// ==============================================

export const getCustomers = async (): Promise<Customer[]> => {
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching customers:', error);
    return [];
  }
  return data || [];
};

export const getCustomer = async (id: string): Promise<Customer | null> => {
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .eq('id', id)
    .single();
  
  if (error) {
    console.error('Error fetching customer:', error);
    return null;
  }
  return data;
};

export const getCustomerByEmail = async (email: string): Promise<Customer | null> => {
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .eq('email', email)
    .single();
  
  if (error) {
    return null;
  }
  return data;
};

export const getCustomerByAuthUser = async (authUserId: string, email?: string): Promise<Customer | null> => {
  // Try to find by email first (more reliable)
  if (email) {
    const { data: byEmail } = await supabase
      .from('customers')
      .select('*')
      .eq('email', email)
      .single();
    
    if (byEmail) return byEmail;
  }
  
  // Fallback: try auth_user_id if column exists
  try {
    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .eq('auth_user_id', authUserId)
      .single();
    
    if (!error && data) return data;
  } catch (e) {
    // Column might not exist, ignore error
  }
  
  return null;
};

export const searchCustomers = async (term: string): Promise<Customer[]> => {
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .or(`full_name.ilike.%${term}%,email.ilike.%${term}%,company_name.ilike.%${term}%`)
    .order('full_name');
  
  if (error) {
    console.error('Error searching customers:', error);
    return [];
  }
  return data || [];
};

export const addCustomer = async (customer: Omit<Customer, 'id' | 'created_at' | 'updated_at'>) => {
  const { data, error } = await supabase
    .from('customers')
    .insert(customer)
    .select()
    .single();
  return { data, error };
};

export const updateCustomer = async (id: string, customer: Partial<Customer>) => {
  const { data, error } = await supabase
    .from('customers')
    .update(customer)
    .eq('id', id)
    .select()
    .single();
  return { data, error };
};

export const deleteCustomer = async (id: string) => {
  const { error } = await supabase.from('customers').delete().eq('id', id);
  return { error };
};

// ==============================================
// PRODUCT HELPERS
// ==============================================

export const getProducts = async (): Promise<Product[]> => {
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .order('price');
  
  if (error) {
    console.error('Error fetching products:', error);
    return [];
  }
  return data || [];
};

export const getActiveProducts = async (): Promise<Product[]> => {
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .eq('is_active', true)
    .order('price');
  
  if (error) {
    console.error('Error fetching active products:', error);
    return [];
  }
  return data || [];
};

export const getProduct = async (id: string): Promise<Product | null> => {
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .eq('id', id)
    .single();
  
  if (error) {
    console.error('Error fetching product:', error);
    return null;
  }
  return data;
};

export const getProductBySku = async (sku: string): Promise<Product | null> => {
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .eq('sku', sku)
    .single();
  
  if (error) {
    return null;
  }
  return data;
};

export const addProduct = async (product: Omit<Product, 'id' | 'created_at' | 'updated_at'>) => {
  const { data, error } = await supabase
    .from('products')
    .insert(product)
    .select()
    .single();
  return { data, error };
};

export const updateProduct = async (id: string, product: Partial<Product>) => {
  const { data, error } = await supabase
    .from('products')
    .update(product)
    .eq('id', id)
    .select()
    .single();
  return { data, error };
};

export const deleteProduct = async (id: string) => {
  const { error } = await supabase.from('products').delete().eq('id', id);
  return { error };
};

// Helper para obtener usuario actual con su perfil
export const getCurrentUserWithProfile = async (): Promise<{ user: any; profile: Profile | null }> => {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { user: null, profile: null };
  
  const profile = await getProfile(user.id);
  return { user, profile };
};

// ==============================================
// SUBSCRIPTION HELPERS
// ==============================================

export const getSubscriptions = async (): Promise<SubscriptionFull[]> => {
  const { data, error } = await supabase
    .from('subscriptions_full')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching subscriptions:', error);
    return [];
  }
  return data || [];
};

export const getActiveSubscriptions = async (): Promise<SubscriptionFull[]> => {
  const { data, error } = await supabase
    .from('subscriptions_full')
    .select('*')
    .eq('status', 'active')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching active subscriptions:', error);
    return [];
  }
  return data || [];
};

export const getSubscriptionsByCustomer = async (customerId: string): Promise<SubscriptionFull[]> => {
  const { data, error } = await supabase
    .from('subscriptions_full')
    .select('*')
    .eq('customer_id', customerId)
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching customer subscriptions:', error);
    return [];
  }
  return data || [];
};

export const getSubscription = async (id: string): Promise<SubscriptionFull | null> => {
  const { data, error } = await supabase
    .from('subscriptions_full')
    .select('*')
    .eq('id', id)
    .single();
  
  if (error) {
    console.error('Error fetching subscription:', error);
    return null;
  }
  return data;
};

export const addSubscription = async (subscription: Omit<Subscription, 'id' | 'created_at' | 'updated_at'>) => {
  const { data, error } = await supabase
    .from('subscriptions')
    .insert(subscription)
    .select()
    .single();
  return { data, error };
};

export const updateSubscription = async (id: string, subscription: Partial<Subscription>) => {
  const { data, error } = await supabase
    .from('subscriptions')
    .update(subscription)
    .eq('id', id)
    .select()
    .single();
  return { data, error };
};

export const deleteSubscription = async (id: string) => {
  const { error } = await supabase.from('subscriptions').delete().eq('id', id);
  return { error };
};

export const getExpiredTrials = async (): Promise<SubscriptionFull[]> => {
  const today = new Date().toISOString();
  const { data, error } = await supabase
    .from('subscriptions_full')
    .select('*')
    .eq('status', 'trial')
    .lt('trial_ends_at', today)
    .order('trial_ends_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching expired trials:', error);
    return [];
  }
  return data || [];
};

export const getActiveTrials = async (): Promise<SubscriptionFull[]> => {
  const today = new Date().toISOString();
  const { data, error } = await supabase
    .from('subscriptions_full')
    .select('*')
    .eq('status', 'trial')
    .gte('trial_ends_at', today)
    .order('trial_ends_at', { ascending: true });
  
  if (error) {
    console.error('Error fetching active trials:', error);
    return [];
  }
  return data || [];
};

// ==============================================
// SALES HELPERS
// ==============================================

export const getSales = async (): Promise<SaleFull[]> => {
  const { data, error } = await supabase
    .from('sales_full')
    .select('*')
    .order('sale_date', { ascending: false });
  
  if (error) {
    console.error('Error fetching sales:', error);
    return [];
  }
  return data || [];
};

export const getSalesByCustomer = async (customerId: string): Promise<SaleFull[]> => {
  const { data, error } = await supabase
    .from('sales_full')
    .select('*')
    .eq('customer_id', customerId)
    .order('sale_date', { ascending: false });
  
  if (error) {
    console.error('Error fetching customer sales:', error);
    return [];
  }
  return data || [];
};

export const searchSales = async (params: {
  searchTerm?: string;
  startDate?: string;
  endDate?: string;
  status?: PaymentStatus;
}): Promise<SaleFull[]> => {
  let query = supabase.from('sales_full').select('*');
  
  if (params.startDate) {
    query = query.gte('sale_date', params.startDate);
  }
  if (params.endDate) {
    query = query.lte('sale_date', params.endDate);
  }
  if (params.status) {
    query = query.eq('payment_status', params.status);
  }
  
  const { data, error } = await query.order('sale_date', { ascending: false });
  
  if (error) {
    console.error('Error searching sales:', error);
    return [];
  }
  
  let results = data || [];
  if (params.searchTerm) {
    const term = params.searchTerm.toLowerCase();
    results = results.filter(s => 
      s.customer_name?.toLowerCase().includes(term) ||
      s.customer_email?.toLowerCase().includes(term) ||
      s.product_name?.toLowerCase().includes(term)
    );
  }
  
  return results;
};

export const addSale = async (sale: Omit<Sale, 'id' | 'created_at'>) => {
  const { data, error } = await supabase
    .from('sales')
    .insert(sale)
    .select()
    .single();
  return { data, error };
};

export const updateSale = async (id: string, sale: Partial<Sale>) => {
  const { data, error } = await supabase
    .from('sales')
    .update(sale)
    .eq('id', id)
    .select()
    .single();
  return { data, error };
};

export const deleteSale = async (id: string) => {
  const { error } = await supabase.from('sales').delete().eq('id', id);
  return { error };
};

// ==============================================
// LICENSE HELPERS
// ==============================================

export const getLicenses = async (): Promise<LicenseFull[]> => {
  const { data, error } = await supabase
    .from('licenses_full')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching licenses:', error);
    return [];
  }
  return data || [];
};

export const getActiveLicenses = async (): Promise<LicenseFull[]> => {
  const { data, error } = await supabase
    .from('licenses_full')
    .select('*')
    .eq('status', 'active')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching active licenses:', error);
    return [];
  }
  return data || [];
};

export const getLicensesByCustomer = async (customerId: string): Promise<LicenseFull[]> => {
  const { data, error } = await supabase
    .from('licenses_full')
    .select('*')
    .eq('customer_id', customerId)
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching customer licenses:', error);
    return [];
  }
  return data || [];
};

export const getLicense = async (id: string): Promise<LicenseFull | null> => {
  const { data, error } = await supabase
    .from('licenses_full')
    .select('*')
    .eq('id', id)
    .single();
  
  if (error) {
    console.error('Error fetching license:', error);
    return null;
  }
  return data;
};

export const getLicenseByKey = async (licenseKey: string): Promise<LicenseFull | null> => {
  const { data, error } = await supabase
    .from('licenses_full')
    .select('*')
    .eq('license_key', licenseKey)
    .single();
  
  if (error) {
    return null;
  }
  return data;
};

export const addLicense = async (license: Omit<License, 'id' | 'created_at' | 'updated_at'>) => {
  const { data, error } = await supabase
    .from('licenses')
    .insert(license)
    .select()
    .single();
  return { data, error };
};

export const updateLicense = async (id: string, license: Partial<License>) => {
  const { data, error } = await supabase
    .from('licenses')
    .update(license)
    .eq('id', id)
    .select()
    .single();
  return { data, error };
};

export const revokeLicense = async (id: string) => {
  return await updateLicense(id, { status: 'revoked' });
};

export const deleteLicense = async (id: string) => {
  const { error } = await supabase.from('licenses').delete().eq('id', id);
  return { error };
};

// ==============================================
// DASHBOARD STATS
// ==============================================

export const getDashboardStats = async (): Promise<DashboardStats | null> => {
  const { data, error } = await supabase
    .from('dashboard_stats')
    .select('*')
    .single();
  
  if (error) {
    console.error('Error fetching dashboard stats:', error);
    return null;
  }
  return data;
};

// ==============================================
// PAYMENT PROCESSING
// ==============================================

export const processPayment = async (
  customerEmail: string,
  customerName: string,
  productSku: string,
  stripePaymentId?: string
) => {
  const { data, error } = await supabase.rpc('process_payment', {
    p_customer_email: customerEmail,
    p_customer_name: customerName,
    p_product_sku: productSku,
    p_stripe_payment_id: stripePaymentId
  });
  
  return { data, error };
};

// ==============================================
// ROLE HELPERS
// ==============================================

export const isStaff = (profile: Profile | null): boolean => {
  return profile !== null && profile.is_active;
};

export const isAdmin = (profile: Profile | null): boolean => {
  return profile !== null && profile.role === 'admin' && profile.is_active;
};

export const getRoleLabel = (role: UserRole): string => {
  const labels: Record<UserRole, string> = {
    super_admin: 'Super Admin',
    admin: 'Administrador',
    staff: 'Staff'
  };
  return labels[role] || role;
};

// Devuelve los roles que el usuario actual puede crear
export const getCreatableRoles = (currentRole: UserRole): UserRole[] => {
  switch (currentRole) {
    case 'super_admin':
      return ['super_admin', 'admin', 'staff'];
    case 'admin':
      return ['staff']; // Admin solo puede crear staff
    case 'staff':
      return []; // Staff no puede crear usuarios
    default:
      return [];
  }
};

// Verifica si un rol puede editar a otro
export const canEditRole = (currentRole: UserRole, targetRole: UserRole): boolean => {
  if (currentRole === 'super_admin') return true; // Super admin puede editar todo
  if (currentRole === 'admin') return targetRole === 'staff'; // Admin solo puede editar staff
  return false; // Staff no puede editar nadie
};

// Verifica si un rol puede eliminar a otro
export const canDeleteRole = (currentRole: UserRole, targetRole: UserRole): boolean => {
  if (currentRole === 'super_admin') return targetRole !== 'super_admin'; // No puede eliminar otros super_admin
  if (currentRole === 'admin') return targetRole === 'staff'; // Admin solo puede eliminar staff
  return false; // Staff no puede eliminar nadie
};

// Verifica si el usuario tiene permisos de solo lectura (staff)
export const isReadOnly = (role: UserRole): boolean => {
  return role === 'staff';
};

// ==============================================
// RECENT ACTIVITY
// ==============================================

export const getRecentSales = async (limit: number = 5): Promise<SaleFull[]> => {
  const { data, error } = await supabase
    .from('sales_full')
    .select('*')
    .eq('payment_status', 'paid')
    .order('sale_date', { ascending: false })
    .limit(limit);
  
  if (error) {
    console.error('Error fetching recent sales:', error);
    return [];
  }
  return data || [];
};

export const getRecentCustomers = async (limit: number = 5): Promise<Customer[]> => {
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);
  
  if (error) {
    console.error('Error fetching recent customers:', error);
    return [];
  }
  return data || [];
};

export const getPendingPayments = async (): Promise<SaleFull[]> => {
  const { data, error } = await supabase
    .from('sales_full')
    .select('*')
    .eq('payment_status', 'pending')
    .order('sale_date', { ascending: false });
  
  if (error) {
    console.error('Error fetching pending payments:', error);
    return [];
  }
  return data || [];
};

export const getExpiringSubscriptions = async (daysAhead: number = 30): Promise<SubscriptionFull[]> => {
  const futureDate = new Date();
  futureDate.setDate(futureDate.getDate() + daysAhead);
  
  const { data, error } = await supabase
    .from('subscriptions_full')
    .select('*')
    .eq('status', 'active')
    .not('end_date', 'is', null)
    .lte('end_date', futureDate.toISOString().split('T')[0])
    .order('end_date');
  
  if (error) {
    console.error('Error fetching expiring subscriptions:', error);
    return [];
  }
  return data || [];
};

// ==============================================
// GOALS (Metas)
// ==============================================

export type GoalType = 'sales_revenue' | 'sales_count' | 'new_clients' | 'active_subscriptions' | 'active_licenses' | 'pending_payments' | 'pending_count' | 'products_sold' | 'mrr' | 'custom';
export type GoalStatus = 'active' | 'completed' | 'failed' | 'paused';
export type GoalPriority = 'low' | 'medium' | 'high' | 'critical';

export interface Goal {
  id: string;
  title: string;
  description?: string;
  type: GoalType;
  unit: string;
  target_value: number;
  current_value: number;
  start_date: string;
  end_date: string;
  status: GoalStatus;
  auto_calculate: boolean;
  notify_percentage: number;
  priority: GoalPriority;
  color: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
  progress_percentage?: number;
  progress_status?: string;
  days_remaining?: number;
}

export const getGoals = async (): Promise<Goal[]> => {
  const { data, error } = await supabase
    .from('goals')
    .select('*')
    .order('end_date', { ascending: true });
  
  if (error) {
    console.error('Error fetching goals:', error);
    return [];
  }
  
  return (data || []).map(goal => ({
    ...goal,
    progress_percentage: goal.target_value > 0 
      ? (goal.current_value / goal.target_value) * 100 
      : 0,
    progress_status: calculateGoalStatus(goal)
  }));
};

function calculateGoalStatus(goal: any): string {
  const progress = goal.target_value > 0 ? (goal.current_value / goal.target_value) * 100 : 0;
  const isOverdue = new Date(goal.end_date) < new Date();
  
  if (progress >= 100) return 'completed';
  if (isOverdue) return 'failed';
  return 'in_progress';
}

export const getGoal = async (id: string): Promise<Goal | null> => {
  const { data, error } = await supabase
    .from('goals')
    .select('*')
    .eq('id', id)
    .single();
  
  if (error) {
    console.error('Error fetching goal:', error);
    return null;
  }
  return data;
};

export const addGoal = async (goal: Omit<Goal, 'id' | 'created_at' | 'updated_at'>): Promise<Goal | null> => {
  const { data, error } = await supabase
    .from('goals')
    .insert(goal)
    .select()
    .single();
  
  if (error) {
    console.error('Error adding goal:', error);
    throw error;
  }
  return data;
};

export const updateGoal = async (id: string, updates: Partial<Goal>): Promise<Goal | null> => {
  const { data, error } = await supabase
    .from('goals')
    .update(updates)
    .eq('id', id)
    .select()
    .single();
  
  if (error) {
    console.error('Error updating goal:', error);
    throw error;
  }
  return data;
};

export const deleteGoal = async (id: string): Promise<boolean> => {
  const { error } = await supabase
    .from('goals')
    .delete()
    .eq('id', id);
  
  if (error) {
    console.error('Error deleting goal:', error);
    throw error;
  }
  return true;
};

export const canManageGoals = (role?: string): boolean => {
  return ['super_admin', 'admin', 'sales'].includes(role || '');
};

export const getGoalStats = async () => {
  const goals = await getGoals();
  const active = goals.filter(g => g.status === 'active' && g.progress_status !== 'completed' && g.progress_status !== 'failed').length;
  const completed = goals.filter(g => g.progress_status === 'completed').length;
  const failed = goals.filter(g => g.progress_status === 'failed').length;
  const avgProgress = goals.length > 0 
    ? goals.reduce((sum, g) => sum + (g.progress_percentage || 0), 0) / goals.length 
    : 0;
  
  return { active, completed, failed, avgProgress, total: goals.length };
};

