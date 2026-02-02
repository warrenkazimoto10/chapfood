import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../utils/text_styles.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getUserProfile();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement du profil: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    // Afficher une boîte de dialogue de confirmation
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await AuthService.signOut();
        
        // Naviguer vers l'écran de connexion
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        print('Erreur lors de la déconnexion: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la déconnexion'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Mon Profil',
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
        backgroundColor: AppColors.getCardColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildProfileInfo(),
                  const SizedBox(height: 24),
                  _buildMenuOptions(),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white,
              child: _user?.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _user!.avatarUrl!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primaryRed,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Nom
          Text(
            _user?.fullName ?? 'Utilisateur',
            style: AppTextStyles.servicesTitle.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Email
          Text(
            _user?.email ?? 'email@example.com',
            style: AppTextStyles.serviceCardDescription.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          // Téléphone
          if (_user?.phone != null)
            Text(
              _user!.phone!,
              style: AppTextStyles.serviceCardDescription.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations du compte',
            style: AppTextStyles.servicesTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Nom complet',
            value: _user?.fullName ?? 'Non renseigné',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _user?.email ?? 'Non renseigné',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            value: _user?.phone ?? 'Non renseigné',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Membre depuis',
            value: _user?.createdAt != null
                ? _formatDate(_user!.createdAt!)
                : 'Non renseigné',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryRed,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.serviceCardDescription.copyWith(
                  fontSize: 12,
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.serviceCardDescription.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOptions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuOption(
            icon: FontAwesomeIcons.bell,
            title: 'Notifications',
            subtitle: 'Gérer vos préférences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuOption(
            icon: FontAwesomeIcons.shield,
            title: 'Confidentialité',
            subtitle: 'Sécurité et données',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuOption(
            icon: FontAwesomeIcons.headset,
            title: 'Support',
            subtitle: 'Aide et contact',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuOption(
            icon: FontAwesomeIcons.infoCircle,
            title: 'À propos',
            subtitle: 'Version et informations',
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryYellow.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FaIcon(
          icon,
          color: AppColors.primaryRed,
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.serviceCardDescription.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.serviceCardDescription.copyWith(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryRed, AppColors.primaryYellow],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.rightFromBracket,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Se déconnecter',
                style: AppTextStyles.serviceCardAction.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'ChapFood',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/images/logo-chapfood.png',
        width: 64,
        height: 64,
      ),
      children: [
        const Text('Application mobile pour le restaurant ChapFood de Grand Bassam.'),
        const SizedBox(height: 16),
        const Text('Développé avec ❤️ pour la meilleure cuisine africaine.'),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
