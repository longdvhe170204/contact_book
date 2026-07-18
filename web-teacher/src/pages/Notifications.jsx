import React, { useState, useEffect } from 'react';
import { Bell, Send, Trash2 } from 'lucide-react';
import { adminNotificationApi } from '../services/adminNotificationApi';
import { IconButton } from '@mui/material';

const Notifications = () => {
  const [notifications, setNotifications] = useState([]);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [category, setCategory] = useState('SCHOOL');
  const [loading, setLoading] = useState(false);

  const fetchNotifications = async () => {
    try {
      const res = await adminNotificationApi.getAllNotifications();
      if (res.data.success) {
        setNotifications(res.data.data);
      }
    } catch (error) {
      console.error('Error fetching notifications', error);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  const handleSend = async () => {
    if (!title.trim() || !content.trim()) {
      alert('Vui lòng nhập đầy đủ tiêu đề và nội dung');
      return;
    }
    
    try {
      setLoading(true);
      await adminNotificationApi.createNotification({
        title,
        content,
        category,
        sender: 'Ban Giám Hiệu'
      });
      alert('Gửi thông báo thành công');
      setTitle('');
      setContent('');
      fetchNotifications();
    } catch (error) {
      console.error('Error creating notification', error);
      alert('Lỗi khi gửi thông báo');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa thông báo này?')) {
      try {
        await adminNotificationApi.deleteNotification(id);
        alert('Xóa thành công');
        fetchNotifications();
      } catch (error) {
        console.error('Error deleting notification', error);
        alert('Lỗi khi xóa thông báo');
      }
    }
  };

  return (
    <div className="page-container">
      <div className="page-header" style={{ marginBottom: '20px' }}>
        <h2><Bell className="inline-icon" /> Quản lý Thông báo</h2>
      </div>
      
      <div className="card glass" style={{ padding: '20px', marginBottom: '20px' }}>
        <h3>Gửi thông báo mới</h3>
        <div style={{ marginTop: '15px' }}>
          <label style={{ display: 'block', marginBottom: '5px', fontWeight: 500 }}>Chuyên mục</label>
          <select 
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            style={{ width: '100%', padding: '12px', border: '1px solid #ddd', borderRadius: '8px', marginBottom: '15px' }}
          >
            <option value="SCHOOL">Chung (Nhà trường)</option>
            <option value="IMPORTANT">Quan trọng</option>
            <option value="FEE">Học phí</option>
          </select>
          
          <label style={{ display: 'block', marginBottom: '5px', fontWeight: 500 }}>Tiêu đề</label>
          <input 
            type="text" 
            placeholder="Nhập tiêu đề thông báo" 
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            style={{ width: '100%', padding: '12px', border: '1px solid #ddd', borderRadius: '8px' }} 
          />
        </div>
        <div style={{ marginTop: '15px' }}>
          <label style={{ display: 'block', marginBottom: '5px', fontWeight: 500 }}>Nội dung</label>
          <textarea 
            placeholder="Nhập nội dung thông báo" 
            value={content}
            onChange={(e) => setContent(e.target.value)}
            style={{ width: '100%', padding: '12px', border: '1px solid #ddd', borderRadius: '8px', minHeight: '120px' }}
          ></textarea>
        </div>
        <button 
          onClick={handleSend}
          disabled={loading}
          style={{
            marginTop: '15px', display: 'flex', alignItems: 'center', gap: '8px',
            backgroundColor: loading ? '#ccc' : 'var(--primary)', color: 'white', 
            border: 'none', padding: '10px 16px', borderRadius: '8px', cursor: loading ? 'not-allowed' : 'pointer'
        }}>
          <Send size={18} /> {loading ? 'Đang gửi...' : 'Gửi thông báo'}
        </button>
      </div>

      <div className="card glass" style={{ padding: '20px' }}>
        <h3>Lịch sử thông báo</h3>
        {notifications.length === 0 ? (
          <p style={{ marginTop: '15px', color: '#888', textAlign: 'center', padding: '20px' }}>
            Chưa có thông báo nào được gửi.
          </p>
        ) : (
          <div style={{ marginTop: '15px' }}>
            {notifications.map(noti => (
              <div key={noti.id} style={{ 
                borderBottom: '1px solid #eee', 
                padding: '15px 0', 
                display: 'flex', 
                justifyContent: 'space-between',
                alignItems: 'flex-start'
              }}>
                <div>
                  <h4 style={{ margin: '0 0 5px 0', color: '#333' }}>
                    <span style={{ 
                      fontSize: '12px', 
                      backgroundColor: noti.category === 'IMPORTANT' ? '#fee2e2' : '#e0e7ff',
                      color: noti.category === 'IMPORTANT' ? '#dc2626' : '#4f46e5',
                      padding: '2px 8px',
                      borderRadius: '12px',
                      marginRight: '8px'
                    }}>
                      {noti.category}
                    </span>
                    {noti.title}
                  </h4>
                  <p style={{ margin: '0 0 5px 0', fontSize: '14px', color: '#666' }}>{noti.content}</p>
                  <small style={{ color: '#999' }}>{noti.date || new Date(noti.createdAtCustom).toLocaleString()}</small>
                </div>
                <IconButton color="error" onClick={() => handleDelete(noti.id)} size="small">
                  <Trash2 size={18} />
                </IconButton>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Notifications;
