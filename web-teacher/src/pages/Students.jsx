import { useState, useEffect, useContext } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Plus, 
  Search, 
  Filter, 
  UserPlus, 
  MoreVertical, 
  Mail, 
  Phone, 
  MapPin, 
  Calendar,
  X,
  Loader2,
  CheckCircle2
} from 'lucide-react';
import { AuthContext } from '../App';
import api from '../services/api';
import './Students.css';

const Students = () => {
  const { user } = useContext(AuthContext);
  const [students, setStudents] = useState([]);
  const [classes, setClasses] = useState([]);
  const [selectedClass, setSelectedClass] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isAdding, setIsAdding] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    phoneNumber: '',
    email: '',
    className: '',
    dateOfBirth: '',
    address: '',
    parentName: '',
    parentPhone: ''
  });

  useEffect(() => {
    fetchClasses();
  }, [user]);

  useEffect(() => {
    fetchStudents();
  }, [user, selectedClass]);

  const fetchClasses = async () => {
    try {
      const res = await api.get('/admin/classes');
      setClasses(res.data.data);
    } catch (err) {
      console.error('Error fetching classes', err);
    }
  };

  const fetchStudents = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/students', {
        params: { className: selectedClass }
      });
      setStudents(res.data.data);
    } catch (err) {
      console.error('Error fetching students', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleAddStudent = async (e) => {
    e.preventDefault();
    setIsAdding(true);
    try {
      await api.post('/admin/students', formData);
      setIsAddModalOpen(false);
      setFormData({
        name: '', phoneNumber: '', email: '', className: '',
        dateOfBirth: '', address: '', parentName: '', parentPhone: ''
      });
      fetchStudents();
    } catch (err) {
      alert(err.response?.data?.message || 'Không thể thêm học sinh. Vui lòng thử lại.');
    } finally {
      setIsAdding(false);
    }
  };

  const filteredStudents = students.filter(s => 
    s.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    s.phoneNumber.includes(searchTerm)
  );

  return (
    <div className="students-page fade-in">
      <div className="page-header">
        <div className="header-info">
          <h2 className="section-title">Quản lý Học sinh</h2>
          <p className="section-desc">Danh sách học sinh trong các lớp bạn phụ trách</p>
        </div>
        <button className="add-btn btn-primary" onClick={() => setIsAddModalOpen(true)}>
          <Plus size={20} />
          <span>Thêm học sinh mới</span>
        </button>
      </div>

      <div className="filters-card glass">
        <div className="search-box">
          <Search size={20} />
          <input 
            type="text" 
            placeholder="Tìm kiếm theo tên hoặc số điện thoại..." 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="class-filter">
          <Filter size={20} />
          <select value={selectedClass} onChange={(e) => setSelectedClass(e.target.value)}>
            <option value="">Tất cả các lớp</option>
            {classes.map(c => (
              <option key={c} value={c}>Lớp {c}</option>
            ))}
          </select>
        </div>
      </div>

      <div className="students-grid">
        {isLoading ? (
          <div className="loading-state">
            <Loader2 className="spinner" size={48} />
            <p>Đang tải danh sách học sinh...</p>
          </div>
        ) : filteredStudents.length > 0 ? (
          filteredStudents.map((student, index) => (
            <motion.div 
              key={student.id} 
              className="student-card glass"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.05 }}
            >
              <div className="card-header">
                <div className="student-avatar">
                  {student.name.charAt(0).toUpperCase()}
                </div>
                <div className="student-basic">
                  <h3>{student.name}</h3>
                  <span className="badge-class">Lớp {student.className}</span>
                </div>
                <button className="more-btn"><MoreVertical size={20} /></button>
              </div>
              
              <div className="student-details">
                <div className="detail-item">
                  <Phone size={16} />
                  <span>{student.phoneNumber}</span>
                </div>
                {student.email && (
                  <div className="detail-item">
                    <Mail size={16} />
                    <span>{student.email}</span>
                  </div>
                )}
                {student.dateOfBirth && (
                  <div className="detail-item">
                    <Calendar size={16} />
                    <span>{new Date(student.dateOfBirth).toLocaleDateString('vi-VN')}</span>
                  </div>
                )}
                {student.address && (
                  <div className="detail-item">
                    <MapPin size={16} />
                    <span className="truncate">{student.address}</span>
                  </div>
                )}
              </div>

              <div className="card-footer">
                <div className="parent-info">
                  <p className="label">Phụ huynh</p>
                  <p className="name">{student.parentName || 'N/A'}</p>
                </div>
                <button className="contact-btn">Liên hệ</button>
              </div>
            </motion.div>
          ))
        ) : (
          <div className="empty-state">
            <UserPlus size={64} />
            <h3>Chưa có học sinh nào</h3>
            <p>Không tìm thấy học sinh nào phù hợp với tìm kiếm của bạn.</p>
          </div>
        )}
      </div>

      {/* Add Student Modal */}
      <AnimatePresence>
        {isAddModalOpen && (
          <div className="modal-overlay">
            <motion.div 
              className="modal-content glass"
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
            >
              <div className="modal-header">
                <h3>Thêm học sinh mới</h3>
                <button className="close-btn" onClick={() => setIsAddModalOpen(false)}>
                  <X size={24} />
                </button>
              </div>

              <form className="add-student-form" onSubmit={handleAddStudent}>
                <div className="form-grid">
                  <div className="input-group">
                    <label>Họ và tên *</label>
                    <input name="name" value={formData.name} onChange={handleInputChange} required placeholder="Nguyễn Văn A" />
                  </div>
                  <div className="input-group">
                    <label>Số điện thoại *</label>
                    <input name="phoneNumber" value={formData.phoneNumber} onChange={handleInputChange} required placeholder="09xxxxxxxx" />
                  </div>
                  <div className="input-group">
                    <label>Email</label>
                    <input name="email" type="email" value={formData.email} onChange={handleInputChange} placeholder="student@school.edu.vn" />
                  </div>
                  <div className="input-group">
                    <label>Lớp học *</label>
                    <select name="className" value={formData.className} onChange={handleInputChange} required>
                      <option value="">Chọn lớp</option>
                      {classes.map(c => <option key={c} value={c}>{c}</option>)}
                    </select>
                  </div>
                  <div className="input-group">
                    <label>Ngày sinh</label>
                    <input name="dateOfBirth" type="date" value={formData.dateOfBirth} onChange={handleInputChange} />
                  </div>
                  <div className="input-group">
                    <label>Địa chỉ</label>
                    <input name="address" value={formData.address} onChange={handleInputChange} placeholder="Phường, Quận, Thành phố" />
                  </div>
                  <div className="input-group">
                    <label>Tên phụ huynh</label>
                    <input name="parentName" value={formData.parentName} onChange={handleInputChange} placeholder="Họ tên cha/mẹ" />
                  </div>
                  <div className="input-group">
                    <label>SĐT phụ huynh</label>
                    <input name="parentPhone" value={formData.parentPhone} onChange={handleInputChange} placeholder="09xxxxxxxx" />
                  </div>
                </div>

                <div className="modal-actions">
                  <button type="button" className="btn-secondary" onClick={() => setIsAddModalOpen(false)}>Hủy</button>
                  <button type="submit" className="btn-primary" disabled={isAdding}>
                    {isAdding ? <Loader2 className="spinner" size={20} /> : <CheckCircle2 size={20} />}
                    <span>{isAdding ? 'Đang lưu...' : 'Lưu học sinh'}</span>
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default Students;
