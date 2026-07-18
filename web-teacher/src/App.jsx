import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useState, createContext, useEffect } from 'react';
import Login from './pages/Login';
import DashboardLayout from './components/DashboardLayout';
import Students from './pages/Students';
import ClassManagement from './pages/admin/ClassManagement';
import ScheduleManagement from './pages/admin/ScheduleManagement';

// Member 1 Pages
import Teachers from './pages/Teachers';
import Notifications from './pages/Notifications';

// Member 5 Pages
import Dashboard from './pages/Dashboard';
import ImportExcel from './pages/ImportExcel';

// Placeholders for other members' screens
const ScheduleMakerPlaceholder = () => (
  <div className="card fade-in" style={{ padding: '28px', background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
    <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '12px' }}>Xếp Thời khóa biểu</h3>
    <p style={{ color: 'var(--text-muted)' }}>Màn hình Xếp Thời khóa biểu của Thành viên 2. Đang phát triển...</p>
  </div>
);

const ReportsPlaceholder = () => (
  <div className="card fade-in" style={{ padding: '28px', background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
    <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '12px' }}>Báo cáo Điểm danh & Điểm số</h3>
    <p style={{ color: 'var(--text-muted)' }}>Màn hình Báo cáo Điểm danh & Điểm số (Chỉ xem - Read-only) của Thành viên 3. Đang phát triển...</p>
  </div>
);

const FinancePlaceholder = () => (
  <div className="card fade-in" style={{ padding: '28px', background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
    <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '12px' }}>Quản lý Thu/Chi & Hóa đơn</h3>
    <p style={{ color: 'var(--text-muted)' }}>Màn hình Quản lý Thu/Chi học phí của Thành viên 4. Đang phát triển...</p>
  </div>
);

// Theme Context
export const ThemeContext = createContext({
  theme: 'light',
  toggleTheme: () => {}
});

// Auth Context
export const AuthContext = createContext({
  user: null,
  login: () => {},
  logout: () => {}
});

function App() {
  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'light');
  const [user, setUser] = useState(() => {
    const savedUser = localStorage.getItem('user');
    return savedUser ? JSON.parse(savedUser) : null;
  });

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  const login = (userData) => {
    setUser(userData);
    localStorage.setItem('user', JSON.stringify(userData));
    localStorage.setItem('token', userData.accessToken);
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('user');
    localStorage.removeItem('token');
  };

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      <ThemeContext.Provider value={{ theme, toggleTheme }}>
        <Router>
          <Routes>
            <Route path="/login" element={!user ? <Login /> : <Navigate to="/" />} />

            <Route path="/" element={user ? <DashboardLayout /> : <Navigate to="/login" />}>
              <Route index element={<Dashboard />} />
              <Route path="import-excel" element={<ImportExcel />} />
              <Route path="students" element={<Students />} />

              {/* Member 1's routes */}
              <Route path="teachers" element={<Teachers />} />
              <Route path="notifications" element={<Notifications />} />
                <Route path="classes" element={<ClassManagement />} />
              <Route path="schedule" element={<ScheduleManagement />} />
              <Route path="grades" element={<ReportsPlaceholder />} />
              <Route path="finance" element={<FinancePlaceholder />} />
            </Route>

            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </Router>
      </ThemeContext.Provider>
    </AuthContext.Provider>
  );
}

export default App;
