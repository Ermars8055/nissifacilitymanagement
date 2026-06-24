import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './auth/AuthContext'
import Layout from './components/Layout'
import LoginPage from './pages/LoginPage'
import Dashboard from './pages/Dashboard'
import Clients from './pages/Clients'
import Buildings from './pages/Buildings'
import BuildingDetail from './pages/BuildingDetail'
import Users from './pages/Users'
import WorkOrders from './pages/WorkOrders'
import Complaints from './pages/Complaints'
import Assets from './pages/Assets'
import PmScheduler from './pages/PmScheduler'
import Checklists from './pages/Checklists'
import Reports from './pages/Reports'
import Settings from './pages/Settings'

function ProtectedRoutes() {
  const { user, loading } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="flex flex-col items-center gap-3">
          <div className="w-6 h-6 border-2 border-gray-200 border-t-brand-600 rounded-full animate-spin" />
          <p className="text-sm text-gray-400">Loading...</p>
        </div>
      </div>
    )
  }

  if (!user) return <LoginPage />

  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="clients" element={<Clients />} />
        <Route path="buildings" element={<Buildings />} />
        <Route path="buildings/:id" element={<BuildingDetail />} />
        <Route path="assets" element={<Assets />} />
        <Route path="work-orders" element={<WorkOrders />} />
        <Route path="complaints" element={<Complaints />} />
        <Route path="users" element={<Users />} />
        <Route path="pm-scheduler" element={<PmScheduler />} />
        <Route path="checklists" element={<Checklists />} />
        <Route path="reports" element={<Reports />} />
        <Route path="settings" element={<Settings />} />
      </Route>
    </Routes>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <ProtectedRoutes />
      </BrowserRouter>
    </AuthProvider>
  )
}
