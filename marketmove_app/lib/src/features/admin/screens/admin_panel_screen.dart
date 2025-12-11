import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/models/user_model.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await SupabaseService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showChangeRoleDialog(UserModel user) {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    // Check permissions
    if (!currentUser.canManageUsers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para cambiar roles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Super admin can change anyone
    // Admin can only change staff and users
    // Staff can only change users
    List<String> availableRoles = [];
    
    if (currentUser.isSuperAdmin) {
      availableRoles = [UserRoles.user, UserRoles.staff, UserRoles.admin, UserRoles.superAdmin];
    } else if (currentUser.isAdmin) {
      availableRoles = [UserRoles.user, UserRoles.staff];
    } else if (currentUser.isStaff) {
      availableRoles = [UserRoles.user];
    }

    // Can't change own role (except super admin)
    if (user.id == currentUser.id && !currentUser.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes cambiar tu propio rol'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Can't change role of higher or equal level user (except super admin)
    if (!currentUser.isSuperAdmin && 
        UserRoles.getRoleLevel(user.role) >= UserRoles.getRoleLevel(currentUser.role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes modificar usuarios de igual o mayor nivel'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Cambiar rol de ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rol actual: ${user.role}',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Nuevo rol',
                  border: OutlineInputBorder(),
                ),
                items: availableRoles.map((role) => 
                  DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(_getRoleIcon(role), size: 20),
                        const SizedBox(width: 8),
                        Text(_getRoleDisplayName(role)),
                      ],
                    ),
                  )
                ).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedRole = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await SupabaseService.updateUserRole(user.id, selectedRole);
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rol actualizado a ${_getRoleDisplayName(selectedRole)}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.shield;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'staff':
        return Icons.badge;
      default:
        return Icons.person;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Administrador';
      case 'staff':
        return 'Staff';
      default:
        return 'Usuario';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return AppTheme.errorColor;
      case 'staff':
        return AppTheme.warningColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.settings), text: 'Configuración'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users Tab
          RefreshIndicator(
            onRefresh: _loadUsers,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isCurrentUser = user.id == currentUser?.id;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                            child: Icon(
                              _getRoleIcon(user.role),
                              color: _getRoleColor(user.role),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (isCurrentUser)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Tú',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user.role).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getRoleDisplayName(user.role),
                                  style: TextStyle(
                                    color: _getRoleColor(user.role),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (user.planType != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Plan: ${user.planType}',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: (currentUser?.canManageUsers ?? false)
                              ? IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showChangeRoleDialog(user),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),

          // Settings Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración del Sistema',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Role info cards
                _InfoCard(
                  title: 'Niveles de Acceso',
                  icon: Icons.security,
                  children: [
                    _RoleInfoRow(
                      role: 'Super Admin',
                      description: 'Control total del sistema',
                      icon: Icons.shield,
                      color: Colors.purple,
                    ),
                    _RoleInfoRow(
                      role: 'Admin',
                      description: 'Gestiona productos, staff y usuarios',
                      icon: Icons.admin_panel_settings,
                      color: AppTheme.errorColor,
                    ),
                    _RoleInfoRow(
                      role: 'Staff',
                      description: 'Gestiona usuarios básicos',
                      icon: Icons.badge,
                      color: AppTheme.warningColor,
                    ),
                    _RoleInfoRow(
                      role: 'Usuario',
                      description: 'Acceso a funciones básicas',
                      icon: Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (currentUser?.isSuperAdmin ?? false)
                  _InfoCard(
                    title: 'Estadísticas',
                    icon: Icons.analytics,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.people),
                        title: const Text('Total Usuarios'),
                        trailing: Text(
                          _users.length.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: const Text('Administradores'),
                        trailing: Text(
                          _users.where((u) => u.isAdmin || u.isSuperAdmin).length.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.badge),
                        title: const Text('Staff'),
                        trailing: Text(
                          _users.where((u) => u.isStaff).length.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RoleInfoRow extends StatelessWidget {
  final String role;
  final String description;
  final IconData icon;
  final Color color;

  const _RoleInfoRow({
    required this.role,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
