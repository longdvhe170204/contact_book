import { useState, useContext } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { 
  Users, 
  GraduationCap, 
  Calendar, 
  BookOpen, 
  UserCheck, 
  LayoutDashboard, 
  LogOut, 
  Sun, 
  Moon,
  Menu,
  X,
  CreditCard,
  Target,
  MessageSquare,
  FileSpreadsheet,
  Bell,
  Layers,
  DollarSign
} from 'lucide-react';
import { AuthContext, ThemeContext } from '../App';
import './DashboardLayout.css';

const SidebarItem = ({ to, icon: Icon, label }) => (
  <NavLink 
    to={to} 
    className={({ isActive }) => `sidebar-item ${isActive ? 'active' : ''}`}
  >
    <Icon size={20} spellCheck={false} />
    <span>{label}</span>
  </NavLink>
);

const DashboardLayout = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const { user, logout } = useContext(AuthContext);
  const { theme, toggleTheme } = useContext(ThemeContext);
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);

  return (
    <div className={`layout-container ${isSidebarOpen ? 'sidebar-open' : 'sidebar-closed'}`}>
      {/* Sidebar Overlay for Mobile */}
      {isSidebarOpen && <div className="sidebar-overlay" onClick={toggleSidebar}></div>}

      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="logo">
            <GraduationCap className="logo-icon" size={32} color="var(--primary)" />
            <span>F-School</span>
          </div>
          <button className="sidebar-mobile-toggle" onClick={toggleSidebar}>
            <X size={24} />
          </button>
        </div>

        <nav className="sidebar-nav">
          <SidebarItem to="/" icon={LayoutDashboard} label="Trang chủ" />
          <SidebarItem to="/import-excel" icon={FileSpreadsheet} label="Import Excel" />
          <SidebarItem to="/students" icon={Users} label="Quản lý Học sinh" />
          <SidebarItem to="/teachers" icon={GraduationCap} label="Quản lý Giáo viên" />
          <SidebarItem to="/notifications" icon={Bell} label="Gửi Thông báo" />
          <SidebarItem to="/classes" icon={Layers} label="Quản lý Lớp học" />
          <SidebarItem to="/schedule" icon={Calendar} label="Xếp Thời khóa biểu" />
          <SidebarItem to="/grades" icon={Target} label="Báo cáo Điểm số" />
          <SidebarItem to="/attendance" icon={UserCheck} label="Báo cáo Điểm danh" />
          <SidebarItem to="/finance" icon={DollarSign} label="Quản lý Thu/Chi" />
        </nav>

        <div className="sidebar-footer">
          <div className="user-profile">
            <div className="user-avatar">
              {user?.name?.charAt(0).toUpperCase() || 'G'}
            </div>
            <div className="user-info">
              <p className="user-name">{user?.name || 'Giáo viên'}</p>
              <p className="user-role">Giáo viên</p>
            </div>
          </div>
          <button className="logout-btn" onClick={handleLogout}>
            <LogOut size={20} />
            <span>Đăng xuất</span>
          </button>
        </div>
      </aside>

      <main className="main-content">
        <header className="main-header glass">
          <div className="header-left">
            <button className="sidebar-toggle" onClick={toggleSidebar}>
              <Menu size={24} />
            </button>
            <h1 className="header-title">
              Cổng Quản Trị (Admin Portal)
            </h1>
          </div>
          
          <div className="header-actions">
            <button className="theme-toggle" onClick={toggleTheme}>
              {theme === 'light' ? <Moon size={20} /> : <Sun size={20} />}
            </button>
            <div className="notification-badge">
              <div className="badge-dot"></div>
            </div>
          </div>
        </header>

        <section className="content-area">
          <Outlet />
        </section>
      </main>
    </div>
  );
};


export default DashboardLayout;
