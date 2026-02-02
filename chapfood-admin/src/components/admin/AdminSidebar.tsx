import { Users, Calendar, Truck, Package, BarChart3, Settings, MapPin } from "lucide-react";
import { NavLink, useLocation } from "react-router-dom";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarTrigger,
  useSidebar,
} from "@/components/ui/sidebar";

const adminItems = [
  { title: "Tableau de bord", url: "/admin", icon: BarChart3 },
  { title: "Clients", url: "/admin/clients", icon: Users },
  { title: "Réservations", url: "/admin/reservations", icon: Calendar },
  { title: "Suivi des Livraisons", url: "/admin/live-tracking", icon: MapPin },
  { title: "Livreurs", url: "/admin/livreurs", icon: Truck },
  { title: "Stock & Menu", url: "/admin/stock", icon: Package },
  { title: "Paramètres", url: "/admin/settings", icon: Settings },
];

export function AdminSidebar() {
  const { state } = useSidebar();
  const location = useLocation();
  const currentPath = location.pathname;
  const collapsed = state === "collapsed";

  const isActive = (path: string) => currentPath === path || (path === "/admin" && currentPath === "/admin");
  const getNavCls = ({ isActive }: { isActive: boolean }) =>
    isActive ? "bg-sidebar-accent text-sidebar-accent-foreground font-medium" : "hover:bg-sidebar-accent/50";

  return (
    <Sidebar className={collapsed ? "w-14" : "w-60"}>
      <div className="p-4 border-b border-sidebar-border">
        <SidebarTrigger className="mb-2" />
        {!collapsed && (
          <h2 className="text-xl font-bold text-sidebar-foreground">ChapFood Admin</h2>
        )}
      </div>

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Administration</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {adminItems.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton asChild>
                    <NavLink to={item.url} className={getNavCls}>
                      <item.icon className="h-4 w-4" />
                      {!collapsed && <span>{item.title}</span>}
                    </NavLink>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
    </Sidebar>
  );
}