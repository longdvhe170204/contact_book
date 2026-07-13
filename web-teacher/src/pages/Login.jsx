import { useState, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { GraduationCap, LogIn, Phone, Lock, Eye, EyeOff, Loader2 } from 'lucide-react';
import { AuthContext } from '../App';
import api from '../services/api';
import './Login.css';

const Login = () => {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  
  const { login } = useContext(AuthContext);
  const navigate = useNavigate();

  const handleForgotPassword = async () => {
    if (!phoneNumber) {
      setError('Vui lòng nhập số điện thoại để đặt lại mật khẩu');
      return;
    }
    
    setIsLoading(true);
    setError('');
    setSuccessMsg('');
    
    try {
      const res = await api.post('/auth/forgot-password', null, { params: { phoneNumber } });
      if (res.data.success) {
        setSuccessMsg(res.data.message);
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Có lỗi khi reset mật khẩu');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const response = await api.post('/auth/login', { phoneNumber, password });
      if (response.data.success) {
        const { token, user } = response.data.data;
        login({ ...user, accessToken: token });
        navigate('/');
      } else {
        setError(response.data.message || 'Login failed');
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Số điện thoại hoặc mật khẩu không chính xác');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-background">
        <div className="blob blob-1"></div>
        <div className="blob blob-2"></div>
        <div className="blob blob-3"></div>
      </div>

      <motion.div 
        className="login-card glass"
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5 }}
      >
        <div className="login-header">
          <div className="logo">
            <GraduationCap size={48} color="var(--primary)" />
          </div>
          <h2 className="title">Chào mừng trở lại</h2>
          <p className="subtitle">Hệ thống quản lý giáo dục F-School</p>
        </div>

        {error && (
          <motion.div 
            className="login-error"
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
          >
            {error}
          </motion.div>
        )}

        <form className="login-form" onSubmit={handleSubmit}>
          <div className="input-group">
            <label htmlFor="phoneNumber">Số điện thoại</label>
            <div className="input-wrapper">
              <Phone size={20} className="input-icon" />
              <input 
                id="phoneNumber"
                type="text" 
                placeholder="0912345678"
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                required
              />
            </div>
          </div>

          <div className="input-group">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <label htmlFor="password">Mật khẩu</label>
              <button 
                type="button" 
                className="forgot-link"
                onClick={handleForgotPassword}
                style={{ background: 'none', border: 'none', color: 'var(--primary)', fontSize: '0.85rem', cursor: 'pointer', fontWeight: 600 }}
              >
                Quên mật khẩu?
              </button>
            </div>
            <div className="input-wrapper">
              <Lock size={20} className="input-icon" />
              <input 
                id="password"
                type={showPassword ? 'text' : 'password'} 
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required={!isLoading} 
              />
              <button 
                type="button" 
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
          </div>

          {successMsg && (
            <motion.div 
              className="login-success"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              style={{ color: 'var(--success)', fontSize: '0.85rem', textAlign: 'center', marginBottom: '16px', fontWeight: 600 }}
            >
              {successMsg}
            </motion.div>
          )}

          <button className="login-button" disabled={isLoading}>
            {isLoading ? (
              <Loader2 className="spinner" size={24} />
            ) : (
              <>
                <LogIn size={24} />
                <span>Đăng nhập</span>
              </>
            )}
          </button>
        </form>

        <div className="login-footer">
          <p>© 2026 F-School. All rights reserved.</p>
        </div>
      </motion.div>
    </div>
  );
};

export default Login;
