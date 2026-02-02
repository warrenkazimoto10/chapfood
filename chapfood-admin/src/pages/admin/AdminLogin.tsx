import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { 
  ChefHat, 
  Lock, 
  Mail, 
  Eye, 
  EyeOff, 
  ArrowLeft,
  Shield,
  CheckCircle,
  Smartphone,
  MapPin,
  Clock
} from 'lucide-react';

const AdminLogin = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  
  const { login } = useAdminAuth();
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    const result = await login(email, password);
    
    if (result.success) {
      toast({
        title: "Connexion réussie",
        description: "Bienvenue dans l'administration ChapFood",
      });
      navigate('/admin');
    } else {
      setError(result.error || 'Erreur de connexion');
    }
    
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50">
      {/* Header avec retour */}
      <div className="absolute top-6 left-6">
        <Button variant="ghost" asChild className="text-gray-600 hover:text-orange-600">
          <Link to="/">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Retour à l'accueil
          </Link>
        </Button>
      </div>

      <div className="min-h-screen flex items-center justify-center px-4 py-12">
        <div className="w-full max-w-6xl grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
          
          {/* Section gauche - Informations */}
          <div className="space-y-8">
            <div className="text-center lg:text-left">
              <div className="flex justify-center lg:justify-start mb-6">
                <div className="relative">
                  <img 
                    src="/logo-chapfood.png" 
                    alt="ChapFood Logo" 
                    className="h-28 w-28 object-contain"
                  />
                  <div className="absolute -top-1 -right-1">
                    <Badge className="bg-green-500 text-white animate-pulse">
                      <CheckCircle className="h-3 w-3 mr-1" />
                      Actif
                    </Badge>
                  </div>
                </div>
              </div>
              <h1 className="text-4xl lg:text-5xl font-bold mb-4 bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
                Administration ChapFood
              </h1>
              <p className="text-xl text-gray-600 mb-8">
                Accédez à votre tableau de bord complet pour gérer votre restaurant
              </p>
            </div>

            {/* Fonctionnalités */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="bg-white/80 backdrop-blur-sm rounded-lg p-4 border border-orange-200 text-center">
                <Shield className="h-8 w-8 text-orange-600 mx-auto mb-2" />
                <h3 className="font-semibold text-gray-800">Sécurisé</h3>
                <p className="text-sm text-gray-600">Accès protégé</p>
              </div>
              <div className="bg-white/80 backdrop-blur-sm rounded-lg p-4 border border-red-200 text-center">
                <Smartphone className="h-8 w-8 text-red-600 mx-auto mb-2" />
                <h3 className="font-semibold text-gray-800">Responsive</h3>
                <p className="text-sm text-gray-600">Mobile & Desktop</p>
              </div>
              <div className="bg-white/80 backdrop-blur-sm rounded-lg p-4 border border-yellow-200 text-center">
                <Clock className="h-8 w-8 text-yellow-600 mx-auto mb-2" />
                <h3 className="font-semibold text-gray-800">Temps Réel</h3>
                <p className="text-sm text-gray-600">Données live</p>
              </div>
            </div>

            {/* Avantages */}
            <div className="bg-white/90 backdrop-blur-sm rounded-2xl p-6 border border-orange-200">
              <h3 className="text-xl font-bold text-gray-800 mb-4">Fonctionnalités incluses</h3>
              <div className="space-y-3">
                <div className="flex items-center gap-3">
                  <CheckCircle className="h-5 w-5 text-green-500" />
                  <span className="text-gray-700">Gestion des commandes en temps réel</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="h-5 w-5 text-green-500" />
                  <span className="text-gray-700">Suivi GPS des livreurs</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="h-5 w-5 text-green-500" />
                  <span className="text-gray-700">Système de caisse intégré</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="h-5 w-5 text-green-500" />
                  <span className="text-gray-700">Gestion des stocks et menu</span>
                </div>
                <div className="flex items-center gap-3">
                  <CheckCircle className="h-5 w-5 text-green-500" />
                  <span className="text-gray-700">Analytics et rapports</span>
                </div>
              </div>
            </div>
          </div>

          {/* Section droite - Formulaire de connexion */}
          <div className="flex justify-center lg:justify-end">
            <Card className="w-full max-w-md shadow-2xl border-orange-200 bg-white/95 backdrop-blur-sm">
              <CardHeader className="text-center space-y-4 pb-8">
                <div className="mx-auto w-16 h-16 bg-gradient-to-br from-orange-100 to-red-100 rounded-full flex items-center justify-center">
                  <ChefHat className="w-8 h-8 text-orange-600" />
                </div>
                <div>
                  <CardTitle className="text-2xl font-bold text-gray-800">Connexion</CardTitle>
                  <CardDescription className="text-gray-600">
                    Connectez-vous à votre compte administrateur
                  </CardDescription>
                </div>
              </CardHeader>
              <CardContent className="space-y-6">
                <form onSubmit={handleSubmit} className="space-y-4">
                  {error && (
                    <Alert variant="destructive" className="border-red-200 bg-red-50">
                      <AlertDescription className="text-red-800">{error}</AlertDescription>
                    </Alert>
                  )}
                  
                  <div className="space-y-2">
                    <Label htmlFor="email" className="text-gray-700 font-medium">Email</Label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                      <Input
                        id="email"
                        type="email"
                        placeholder="admin@chapfood.com"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        className="pl-10 h-12 border-gray-300 focus:border-orange-500 focus:ring-orange-500"
                        required
                      />
                    </div>
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="password" className="text-gray-700 font-medium">Mot de passe</Label>
                    <div className="relative">
                      <Lock className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                      <Input
                        id="password"
                        type={showPassword ? "text" : "password"}
                        placeholder="••••••••"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="pl-10 pr-10 h-12 border-gray-300 focus:border-orange-500 focus:ring-orange-500"
                        required
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute right-3 top-3 h-4 w-4 text-gray-400 hover:text-gray-600"
                      >
                        {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                      </button>
                    </div>
                  </div>
                  
                  <Button 
                    type="submit" 
                    className="w-full h-12 bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white font-medium shadow-lg" 
                    disabled={loading}
                  >
                    {loading ? (
                      <div className="flex items-center gap-2">
                        <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent" />
                        Connexion...
                      </div>
                    ) : (
                      <div className="flex items-center gap-2">
                        <Shield className="h-4 w-4" />
                        Se connecter
                      </div>
                    )}
                  </Button>
                </form>

                {/* Informations supplémentaires */}
                <div className="pt-4 border-t border-gray-200">
                  <div className="text-center space-y-2">
                    <p className="text-sm text-gray-600">
                      Accès sécurisé pour les administrateurs
                    </p>
                    <div className="flex justify-center items-center gap-2 text-xs text-gray-500">
                      <MapPin className="h-3 w-3" />
                      <span>Grand-Bassam, Côte d'Ivoire</span>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2">
        <p className="text-sm text-gray-500 text-center">
          © 2024 ChapFood. Système de gestion de restaurant.
        </p>
      </div>
    </div>
  );
};

export default AdminLogin;