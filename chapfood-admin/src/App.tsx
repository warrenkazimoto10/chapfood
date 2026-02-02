import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AdminAuthProvider } from "@/hooks/useAdminAuth";
import Index from "./pages/Index";
import NotFound from "./pages/NotFound";
import Admin from "./pages/Admin";
import AdminLogin from "./pages/admin/AdminLogin";
import AdminDashboard from "./pages/admin/AdminDashboard";
import AdminClients from "./pages/admin/AdminClients";
import AdminReservations from "./pages/admin/AdminReservations";
import LiveDeliveryTracking from "./pages/admin/LiveDeliveryTracking";
import AdminLivreurs from "./pages/admin/AdminLivreurs";
import AdminStock from "./pages/admin/AdminStock";
import AdminEarnings from "./pages/admin/AdminEarnings";
import CashierSystem from "./pages/admin/CashierSystem";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <AdminAuthProvider>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/admin" element={<Admin />} />
            <Route path="/admin/login" element={<AdminLogin />} />
            <Route path="/admin/dashboard" element={<AdminDashboard />} />
            <Route path="/admin/clients" element={<AdminClients />} />
            <Route path="/admin/reservations" element={<AdminReservations />} />
            <Route path="/admin/live-tracking" element={<LiveDeliveryTracking />} />
            <Route path="/admin/livreurs" element={<AdminLivreurs />} />
            <Route path="/admin/stock" element={<AdminStock />} />
            <Route path="/admin/earnings" element={<AdminEarnings />} />
            <Route path="/admin/cashier" element={<CashierSystem />} />
            {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </TooltipProvider>
    </AdminAuthProvider>
  </QueryClientProvider>
);

export default App;
