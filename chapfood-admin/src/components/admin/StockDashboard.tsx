import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Package, Utensils, Plus, TrendingUp, AlertTriangle } from "lucide-react";
import { useStockPermissions } from "@/hooks/useStockPermissions";

interface StockStats {
  totalCategories: number;
  totalMenuItems: number;
  totalSupplements: number;
  availableItems: number;
  popularItems: number;
  lowStockItems: number;
}

interface StockDashboardProps {
  stats: StockStats;
  onAddCategory?: () => void;
  onAddMenuItem?: () => void;
  onAddSupplement?: () => void;
}

export const StockDashboard = ({ 
  stats, 
  onAddCategory, 
  onAddMenuItem, 
  onAddSupplement 
}: StockDashboardProps) => {
  const permissions = useStockPermissions();

  const statCards = [
    {
      title: "Catégories",
      value: stats.totalCategories,
      icon: Package,
      description: "Catégories actives",
      color: "text-blue-600",
      action: permissions.canCreate ? onAddCategory : undefined,
      actionLabel: "Ajouter une catégorie"
    },
    {
      title: "Articles du Menu",
      value: stats.totalMenuItems,
      icon: Utensils,
      description: "Plats disponibles",
      color: "text-green-600",
      action: permissions.canCreate ? onAddMenuItem : undefined,
      actionLabel: "Ajouter un article"
    },
    {
      title: "Suppléments",
      value: stats.totalSupplements,
      icon: Plus,
      description: "Garnitures et extras",
      color: "text-purple-600",
      action: permissions.canCreate ? onAddSupplement : undefined,
      actionLabel: "Ajouter un supplément"
    },
    {
      title: "Articles Disponibles",
      value: stats.availableItems,
      icon: TrendingUp,
      description: "En stock",
      color: "text-emerald-600"
    },
    {
      title: "Articles Populaires",
      value: stats.popularItems,
      icon: TrendingUp,
      description: "Très demandés",
      color: "text-orange-600"
    },
    {
      title: "Stock Faible",
      value: stats.lowStockItems,
      icon: AlertTriangle,
      description: "À réapprovisionner",
      color: "text-red-600"
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {statCards.map((stat, index) => (
        <Card key={index} className="hover:shadow-lg transition-shadow">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
              <stat.icon className={`h-4 w-4 ${stat.color}`} />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stat.value}</div>
            <CardDescription className="text-xs">{stat.description}</CardDescription>
            {stat.action && (
              <button
                onClick={stat.action}
                className="mt-2 text-xs text-blue-600 hover:text-blue-800 underline cursor-pointer"
              >
                {stat.actionLabel}
              </button>
            )}
          </CardContent>
        </Card>
      ))}
    </div>
  );
};
