import 'dart:math';

class WelcomeService {
  static const List<String> welcomeMessages = [
    "Qu'est-ce qu'on mange aujourd'hui ?",
    "Prêt pour un délicieux repas ?",
    "La faim vous tenaille ? On s'occupe de vous !",
    "Envie d'un bon petit plat ?",
    "Un festin vous attend !",
    "Découvrez nos délices du jour !"
  ];

  static String getRandomMessage() {
    final random = Random();
    return welcomeMessages[random.nextInt(welcomeMessages.length)];
  }
}
