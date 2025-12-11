class AppConstants {
  static const String appName = 'MarketMove';
  static const String appVersion = '1.0.0';
  
  // Supabase
  static const String supabaseUrl = 'https://lehtlbwhdqntxlyuyloy.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlaHRsYndoZHFudHhseXV5bG95Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1OTAwOTUsImV4cCI6MjA3OTE2NjA5NX0.W3H2zku981fcFeLOtM1iszlePNF3mAlQrI9GS48qVm0';
  
  // Stripe Payment Links
  static const String stripeAnnualPlan = 'https://buy.stripe.com/test_5kQ14g1uf476fb51xK08g02';
  static const String stripeBasicPlan = 'https://buy.stripe.com/test_9B6cMY6Oz9rqbYTcco08g00';
  static const String stripeLifetimePlan = 'https://buy.stripe.com/test_eVq14g7SD7ji6EzgsE08g01';
  
  // Pricing
  static const double annualPrice = 99.99;
  static const double basicMonthlyPrice = 9.99;
  static const double lifetimePrice = 199.99;
}

class UserRoles {
  static const String user = 'user';
  static const String staff = 'staff';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';
  
  static List<String> get allRoles => [user, staff, admin, superAdmin];
  
  static int getRoleLevel(String role) {
    switch (role) {
      case superAdmin:
        return 4;
      case admin:
        return 3;
      case staff:
        return 2;
      case user:
      default:
        return 1;
    }
  }
  
  static bool canManageUsers(String role) {
    return getRoleLevel(role) >= getRoleLevel(staff);
  }
  
  static bool canManageProducts(String role) {
    return getRoleLevel(role) >= getRoleLevel(admin);
  }
  
  static bool canManageAdmins(String role) {
    return role == superAdmin;
  }
}
