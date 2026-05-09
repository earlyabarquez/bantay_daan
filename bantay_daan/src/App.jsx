import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ReportsPage from './pages/ReportsPage';
import ReportDetailPage from './pages/ReportDetailPage';
import ArchivePage from './pages/ArchivePage';
import ProtectedRoute from './components/ProtectedRoute';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/dashboard" element={
          <ProtectedRoute><DashboardPage /></ProtectedRoute>
        } />
        <Route path="/reports" element={
          <ProtectedRoute><ReportsPage /></ProtectedRoute>
        } />
        <Route path="/reports/:id" element={
          <ProtectedRoute><ReportDetailPage /></ProtectedRoute>
        } />
        <Route path="*" element={<Navigate to="/login" />} />
        <Route path="/archive" element={
          <ProtectedRoute><ArchivePage /></ProtectedRoute>
        } />
      </Routes>
    </BrowserRouter>
  );
}
