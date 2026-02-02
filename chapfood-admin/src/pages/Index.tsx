import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Link } from "react-router-dom";
import { 
  Shield, 
  Users, 
  Calendar, 
  Truck, 
  Package, 
  ChefHat, 
  MapPin, 
  Clock, 
  Star,
  ArrowRight,
  CheckCircle,
  TrendingUp,
  Smartphone
} from "lucide-react";

const Index = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50">
      {/* Header avec logo */}
      <div className="relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-r from-orange-600/10 to-red-600/10"></div>
        <div className="relative container mx-auto px-4 py-20">
          <div className="text-center mb-16">
            <div className="flex justify-center mb-8">
              <div className="relative">
                <img 
                  src="/logo-chapfood.png" 
                  alt="ChapFood Logo" 
                  className="h-32 w-32 object-contain"
                />
                <div className="absolute -top-2 -right-2">
                  <Badge className="bg-green-500 text-white animate-pulse">
                    <CheckCircle className="h-3 w-3 mr-1" />
                    Actif
                  </Badge>
                </div>
              </div>
            </div>
            <h1 className="text-6xl font-bold mb-6 bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
              ChapFood
            </h1>
            <p className="text-2xl text-gray-700 mb-4 font-medium">
              Votre partenaire digital pour la restauration
            </p>
            <p className="text-lg text-gray-600 mb-12 max-w-2xl mx-auto">
              Gestion complète de restaurant avec suivi en temps réel, 
              livraisons optimisées et système de caisse intégré
            </p>
            
            <div className="flex flex-col sm:flex-row justify-center gap-4 mb-12">
              <Button asChild size="lg" className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white shadow-lg">
                <Link to="/admin/login">
                  <Shield className="h-5 w-5 mr-2" />
                  Administration
                  <ArrowRight className="h-4 w-4 ml-2" />
                </Link>
              </Button>
              <Button asChild variant="outline" size="lg" className="border-orange-300 text-orange-600 hover:bg-orange-50">
                <Link to="/admin/login">
                  <Smartphone className="h-5 w-5 mr-2" />
                  Application Mobile
                </Link>
              </Button>
            </div>

            {/* Stats rapides */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 max-w-2xl mx-auto">
              <div className="bg-white/80 backdrop-blur-sm rounded-lg p-4 border border-orange-200">
                <div className="text-2xl font-bold text-orange-600">24/7</div>
                <div className="text-sm text-gray-600">Disponibilité</div>
              </div>
              <div className="bg-white/80 backdrop-blur-sm rounded-lg p-4 border border-red-200">
                <div className="text-2xl font-bold text-red-600">GPS</div>
                <div className="text-sm text-gray-600">Suivi Temps Réel</div>
              </div>
              <div className="bg-white/80 backdrop-blur-sm rounded-lg p-4 border border-yellow-200">
                <div className="text-2xl font-bold text-yellow-600">5★</div>
                <div className="text-sm text-gray-600">Satisfaction</div>
              </div>
              <div className="bg-white/80 backdrop-blur-sm rounded-lg p-4 border border-green-200">
                <div className="text-2xl font-bold text-green-600">100%</div>
                <div className="text-sm text-gray-600">Sécurisé</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Fonctionnalités principales */}
      <div className="container mx-auto px-4 py-16">
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold text-gray-800 mb-4">
            Fonctionnalités Complètes
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Tout ce dont vous avez besoin pour gérer efficacement votre restaurant
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 mb-16">
          <Card className="hover:shadow-xl transition-all duration-300 border-orange-200 hover:border-orange-300 bg-white/90 backdrop-blur-sm">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 bg-gradient-to-br from-orange-100 to-orange-200 rounded-full flex items-center justify-center mb-4">
                <Users className="h-8 w-8 text-orange-600" />
              </div>
              <CardTitle className="text-xl text-gray-800">Gestion Clients</CardTitle>
              <CardDescription className="text-gray-600">
                Base client complète avec historique
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className="space-y-2 text-sm text-gray-600">
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Profils détaillés
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Historique commandes
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Préférences clients
                </li>
              </ul>
            </CardContent>
          </Card>

          <Card className="hover:shadow-xl transition-all duration-300 border-red-200 hover:border-red-300 bg-white/90 backdrop-blur-sm">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 bg-gradient-to-br from-red-100 to-red-200 rounded-full flex items-center justify-center mb-4">
                <Calendar className="h-8 w-8 text-red-600" />
              </div>
              <CardTitle className="text-xl text-gray-800">Commandes</CardTitle>
              <CardDescription className="text-gray-600">
                Suivi en temps réel des commandes
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className="space-y-2 text-sm text-gray-600">
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Statuts en temps réel
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Planning automatique
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Codes de livraison
                </li>
              </ul>
            </CardContent>
          </Card>

          <Card className="hover:shadow-xl transition-all duration-300 border-yellow-200 hover:border-yellow-300 bg-white/90 backdrop-blur-sm">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 bg-gradient-to-br from-yellow-100 to-yellow-200 rounded-full flex items-center justify-center mb-4">
                <Truck className="h-8 w-8 text-yellow-600" />
              </div>
              <CardTitle className="text-xl text-gray-800">Livreurs</CardTitle>
              <CardDescription className="text-gray-600">
                Gestion optimisée des livraisons
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className="space-y-2 text-sm text-gray-600">
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  GPS en temps réel
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Assignation intelligente
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Suivi des performances
                </li>
              </ul>
            </CardContent>
          </Card>

          <Card className="hover:shadow-xl transition-all duration-300 border-green-200 hover:border-green-300 bg-white/90 backdrop-blur-sm">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 bg-gradient-to-br from-green-100 to-green-200 rounded-full flex items-center justify-center mb-4">
                <Package className="h-8 w-8 text-green-600" />
              </div>
              <CardTitle className="text-xl text-gray-800">Stock & Menu</CardTitle>
              <CardDescription className="text-gray-600">
                Gestion complète du menu
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className="space-y-2 text-sm text-gray-600">
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Articles dynamiques
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Catégories organisées
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  Gestion des stocks
                </li>
              </ul>
            </CardContent>
          </Card>
        </div>

        {/* Section Caisse */}
        <div className="bg-gradient-to-r from-orange-500 to-red-500 rounded-2xl p-8 text-white mb-16">
          <div className="text-center mb-8">
            <div className="mx-auto w-20 h-20 bg-white/20 rounded-full flex items-center justify-center mb-4">
              <ChefHat className="h-10 w-10" />
            </div>
            <h3 className="text-3xl font-bold mb-4">Système de Caisse Intégré</h3>
            <p className="text-xl opacity-90 max-w-2xl mx-auto">
              Gestion des commandes WhatsApp avec interface tactile moderne
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="text-center">
              <Smartphone className="h-8 w-8 mx-auto mb-2 opacity-80" />
              <h4 className="font-semibold mb-1">Interface Tactile</h4>
              <p className="text-sm opacity-80">Design optimisé pour tablettes</p>
            </div>
            <div className="text-center">
              <MapPin className="h-8 w-8 mx-auto mb-2 opacity-80" />
              <h4 className="font-semibold mb-1">Géolocalisation</h4>
              <p className="text-sm opacity-80">Sélection GPS précise</p>
            </div>
            <div className="text-center">
              <TrendingUp className="h-8 w-8 mx-auto mb-2 opacity-80" />
              <h4 className="font-semibold mb-1">Analytics</h4>
              <p className="text-sm opacity-80">Suivi des performances</p>
            </div>
          </div>

          <div className="text-center">
            <Button asChild size="lg" variant="secondary" className="bg-white text-orange-600 hover:bg-gray-100">
              <Link to="/admin/login">
                <ChefHat className="h-5 w-5 mr-2" />
                Accéder à la Caisse
              </Link>
            </Button>
          </div>
        </div>

        {/* CTA Final */}
        <div className="text-center">
          <Card className="max-w-3xl mx-auto bg-white/90 backdrop-blur-sm border-orange-200">
            <CardHeader>
              <CardTitle className="text-3xl text-gray-800 mb-4">
                Prêt à digitaliser votre restaurant ?
              </CardTitle>
              <CardDescription className="text-lg text-gray-600">
                Rejoignez ChapFood et transformez votre gestion quotidienne
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex flex-col sm:flex-row justify-center gap-4">
                <Button asChild size="lg" className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white shadow-lg">
                  <Link to="/admin/login">
                    <Shield className="h-5 w-5 mr-2" />
                    Commencer Maintenant
                  </Link>
                </Button>
                <Button asChild variant="outline" size="lg" className="border-orange-300 text-orange-600 hover:bg-orange-50">
                  <Link to="/admin/login">
                    <Star className="h-5 w-5 mr-2" />
                    Voir la Démo
                  </Link>
                </Button>
              </div>
              <div className="flex justify-center items-center gap-6 text-sm text-gray-500">
                <div className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  <span>Configuration rapide</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  <span>Support 24/7</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  <span>Sécurisé</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Footer */}
      <div className="bg-gray-800 text-white py-12">
        <div className="container mx-auto px-4 text-center">
          <div className="flex justify-center mb-4">
            <img 
              src="/logo-chapfood.png" 
              alt="ChapFood Logo" 
              className="h-16 w-16 object-contain filter brightness-0 invert"
            />
          </div>
          <h4 className="text-xl font-bold mb-2">ChapFood</h4>
          <p className="text-gray-400 mb-4">
            Votre partenaire digital pour la restauration moderne
          </p>
          <p className="text-sm text-gray-500">
            © 2024 ChapFood. Tous droits réservés.
          </p>
        </div>
      </div>
    </div>
  );
};

export default Index;
