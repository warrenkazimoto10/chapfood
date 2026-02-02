import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/text_styles.dart';

/// Modal pour saisir le code de confirmation de livraison
class DeliveryCodeModal extends StatefulWidget {
  final String orderId;
  final String customerName;
  final Function(String code) onConfirm;
  final VoidCallback onCancel;

  const DeliveryCodeModal({
    Key? key,
    required this.orderId,
    required this.customerName,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<DeliveryCodeModal> createState() => _DeliveryCodeModalState();
}

class _DeliveryCodeModalState extends State<DeliveryCodeModal> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleConfirm() async {
    final code = _codeController.text.trim();
    
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir le code de livraison';
      });
      return;
    }
    
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Le code doit contenir 6 chiffres';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      widget.onConfirm(code);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la validation du code';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône de livraison
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: AppColors.primaryRed,
                size: 30,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Titre
            Text(
              'Confirmer la livraison',
              style: AppTextStyles.loginTitle.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              'Commande #${widget.orderId}',
              style: AppTextStyles.loginSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            Text(
              'Client: ${widget.customerName}',
              style: AppTextStyles.loginSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryRed.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryRed,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Demandez le code de confirmation au client pour valider la livraison',
                        style: AppTextStyles.helperText.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Champ de saisie du code
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: AppTextStyles.loginTitle.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: AppTextStyles.loginTitle.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  letterSpacing: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.lightGray,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.lightGray,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryRed,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
                counterText: '', // Masquer le compteur
              ),
              onChanged: (value) {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Message d'erreur
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child:                       Text(
                        _errorMessage!,
                        style: AppTextStyles.helperText.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_errorMessage != null) const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              children: [
                // Bouton Annuler
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.lightGray,
                        width: 1,
                      ),
                    ),
                    child:                       Text(
                        'Annuler',
                        style: AppTextStyles.buttonSecondary.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Bouton Confirmer
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        :                             Text(
                              'Confirmer',
                              style: AppTextStyles.buttonPrimary.copyWith(
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
