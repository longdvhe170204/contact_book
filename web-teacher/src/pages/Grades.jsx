import { useState, useEffect, useContext, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import * as XLSX from 'xlsx';
import { 
  FileSpreadsheet, 
  Upload, 
  Download, 
  Save, 
  Search, 
  Filter, 
  AlertCircle, 
  CheckCircle2, 
  Loader2,
  Table as TableIcon,
  X,
  Plus,
  BookOpen,
  Calendar
} from 'lucide-react';
import { AuthContext } from '../App';
import api from '../services/api';
import './Grades.css';

const Grades = () => {
  const { user } = useContext(AuthContext);
  const [grades, setGrades] = useState([]);
  const [classes, setClasses] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [selectedClass, setSelectedClass] = useState('');
  const [selectedSubject, setSelectedSubject] = useState('');
  const [selectedSemester, setSelectedSemester] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // Edit Modal State
  const [editingGrade, setEditingGrade] = useState(null);
  const [editFormData, setEditFormData] = useState({ tx15: '', tx1tiet: '', giuaKy: '', cuoiKy: '' });
  const [editErrors, setEditErrors] = useState({});
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    fetchClasses();
  }, [user]);

  useEffect(() => {
    if (selectedClass) {
      fetchGrades();
    }
  }, [user, selectedClass, selectedSubject, selectedSemester]);

  const fetchClasses = async () => {
    try {
      const res = await api.get(`/teachers/${user.id}/classes`);
      setClasses(res.data.data);
      if (res.data.data.length > 0) {
        setSelectedClass(res.data.data[0]);
      }
    } catch (err) {
      console.error('Error fetching classes', err);
    }
  };

  const fetchGrades = async () => {
    setIsLoading(true);
    try {
      const res = await api.get(`/teachers/${user.id}/grades`, {
        params: { 
          className: selectedClass, 
          semester: selectedSemester,
          subject: selectedSubject || undefined
        }
      });
      setGrades(res.data.data);
      
      // Extract unique subjects from grades to show in filter
      const uniqueSubjects = [...new Set(res.data.data.map(g => g.subject))];
      setSubjects(uniqueSubjects);
    } catch (err) {
      console.error('Error fetching grades', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleEditClick = (grade) => {
    setEditingGrade(grade);
    setEditFormData({
      tx15: grade.tx15.join(', '),
      tx1tiet: grade.tx1tiet.join(', '),
      giuaKy: grade.giuaKy ?? '',
      cuoiKy: grade.cuoiKy ?? ''
    });
    setEditErrors({});
  };

  const validateMultipleScores = (val) => {
    if (!val || !val.trim()) return null;
    if (/[a-zA-Z]/.test(val)) return 'Không nhập chữ, chỉ nhập số';
    const parts = val.split(',');
    for (let p of parts) {
      if (!p.trim()) continue;
      const n = Number(p.trim());
      if (isNaN(n)) return 'Sai định dạng số';
      if (n < 0 || n > 10) return 'Điểm phải từ 0 đến 10';
    }
    return null;
  };

  const validateSingleScore = (val) => {
    if (val === null || val === undefined || String(val).trim() === '') return null;
    if (/[a-zA-Z]/.test(val)) return 'Không nhập chữ, chỉ nhập số';
    const n = Number(String(val).trim());
    if (isNaN(n)) return 'Sai định dạng số';
    if (n < 0 || n > 10) return 'Điểm phải từ 0 đến 10';
    return null;
  };

  const validateForm = () => {
    const errs = {};
    const e15 = validateMultipleScores(editFormData.tx15);
    if (e15) errs.tx15 = e15;
    const e1t = validateMultipleScores(editFormData.tx1tiet);
    if (e1t) errs.tx1tiet = e1t;
    const egk = validateSingleScore(editFormData.giuaKy);
    if (egk) errs.giuaKy = egk;
    const eck = validateSingleScore(editFormData.cuoiKy);
    if (eck) errs.cuoiKy = eck;
    setEditErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSaveEdit = async () => {
    if (!validateForm()) return;
    setIsSaving(true);
    try {
      const tx15 = editFormData.tx15 ? editFormData.tx15.split(',').map(s=>s.trim()).filter(s=>s).map(Number) : [];
      const tx1tiet = editFormData.tx1tiet ? editFormData.tx1tiet.split(',').map(s=>s.trim()).filter(s=>s).map(Number) : [];
      const giuaKy = (editFormData.giuaKy !== null && editFormData.giuaKy !== '') ? Number(editFormData.giuaKy) : null;
      const cuoiKy = (editFormData.cuoiKy !== null && editFormData.cuoiKy !== '') ? Number(editFormData.cuoiKy) : null;

      const payload = {
        studentId: editingGrade.studentId,
        subject: editingGrade.subject,
        semester: selectedSemester,
        tx15,
        tx1tiet,
        giuaKy,
        cuoiKy
      };

      await api.post(`/teachers/${user.id}/grades/bulk`, [payload]);
      setEditingGrade(null);
      fetchGrades();
    } catch (err) {
      alert('Lỗi khi lưu điểm');
    } finally {
      setIsSaving(false);
    }
  };



  const exportGrades = () => {
    const templateData = grades.map(g => ({
      'ID Học sinh': g.studentId,
      'Tên Học sinh': g.studentName,
      'Môn học': g.subject,
      'ĐTX15': g.tx15.join(','),
      'ĐTX1Tiet': g.tx1tiet.join(','),
      'Giữa kỳ': g.giuaKy,
      'Cuối kỳ': g.cuoiKy
    }));

    const ws = XLSX.utils.json_to_sheet(templateData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "BangDiem");
    XLSX.writeFile(wb, `BangDiem_${selectedClass}_S${selectedSemester}.xlsx`);
  };

  const filteredGrades = grades.filter(g => 
    g.studentName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="grades-page fade-in">
      <div className="page-header">
        <div className="header-info">
          <h2 className="section-title">Quản lý Điểm số</h2>
          <p className="section-desc">Cập nhật và theo dõi kết quả học tập của học sinh</p>
        </div>
        <div className="header-actions">
          <button className="btn-secondary" onClick={exportGrades}>
            <Download size={20} />
            <span>Xuất file Excel</span>
          </button>
        </div>
      </div>

      <div className="filters-card glass">
        <div className="search-box">
          <Search size={20} />
          <input 
            type="text" 
            placeholder="Tìm theo tên học sinh..." 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="filters-group">
          <div className="filter-item">
            <TableIcon size={18} />
            <select value={selectedClass} onChange={(e) => setSelectedClass(e.target.value)}>
              {classes.map(c => <option key={c} value={c}>Lớp {c}</option>)}
            </select>
          </div>
          <div className="filter-item">
            <BookOpen size={18} />
            <select value={selectedSubject} onChange={(e) => setSelectedSubject(e.target.value)}>
              <option value="">Tất cả môn học</option>
              {subjects.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>
          <div className="filter-item">
            <Calendar size={18} />
            <select value={selectedSemester} onChange={(e) => setSelectedSemester(Number(e.target.value))}>
              <option value={1}>Học kỳ 1</option>
              <option value={2}>Học kỳ 2</option>
            </select>
          </div>
        </div>
      </div>

      <div className="grades-container glass">
        {isLoading ? (
          <div className="loading-state">
            <Loader2 className="spinner" size={48} />
            <p>Đang tải bảng điểm...</p>
          </div>
        ) : filteredGrades.length > 0 ? (
          <table className="grades-table">
            <thead>
              <tr>
                <th>Học sinh</th>
                <th>Môn học</th>
                <th>TX 15'</th>
                <th>TX 1 Tiết</th>
                <th>Giữa kỳ</th>
                <th>Cuối kỳ</th>
                <th>Trung bình</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredGrades.map((grade) => (
                <tr key={grade.gradeId}>
                  <td className="student-cell">
                    <div className="mini-avatar">{grade.studentName.charAt(0)}</div>
                    <span>{grade.studentName}</span>
                  </td>
                  <td><span className="subject-badge">{grade.subject}</span></td>
                  <td>{grade.tx15.join(', ') || '-'}</td>
                  <td>{grade.tx1tiet.join(', ') || '-'}</td>
                  <td>{grade.giuaKy ?? '-'}</td>
                  <td>{grade.cuoiKy ?? '-'}</td>
                  <td className="avg-cell">{grade.average ?? '-'}</td>
                  <td>
                    <button className="edit-btn" onClick={() => handleEditClick(grade)}>Sửa</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="empty-state">
            <AlertCircle size={64} />
            <h3>Chưa có dữ liệu điểm</h3>
            <p>Vui lòng chọn lớp và môn học để xem điểm hoặc tải lên file Excel.</p>
          </div>
        )}
      </div>



      <AnimatePresence>
        {/* Edit Modal */}
        {editingGrade && (
          <div className="modal-overlay">
            <motion.div 
              className="modal-content glass edit-modal"
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              style={{ maxWidth: '500px' }}
            >
              <div className="modal-header">
                <h3>Sửa điểm: {editingGrade.studentName}</h3>
                <button onClick={() => setEditingGrade(null)}><X size={24} /></button>
              </div>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <div className="form-group">
                  <label style={{ fontSize: '14px', fontWeight: '500', color: 'var(--text)', marginBottom: '8px', display: 'block' }}>Điểm 15 phút (cách nhau bởi dấu phẩy)</label>
                  <input 
                    type="text" 
                    value={editFormData.tx15} 
                    onChange={e => setEditFormData({...editFormData, tx15: e.target.value})}
                    style={{ 
                      width: '100%', padding: '10px 14px', borderRadius: '8px', 
                      border: `1px solid ${editErrors.tx15 ? 'var(--error)' : 'var(--border)'}`, 
                      background: 'var(--background)', color: 'var(--text)' 
                    }}
                  />
                  {editErrors.tx15 && <span style={{color: 'var(--error)', fontSize: '12px', marginTop: '4px', display: 'block'}}>{editErrors.tx15}</span>}
                </div>
                <div className="form-group">
                  <label style={{ fontSize: '14px', fontWeight: '500', color: 'var(--text)', marginBottom: '8px', display: 'block' }}>Điểm 1 tiết (cách nhau bởi dấu phẩy)</label>
                  <input 
                    type="text" 
                    value={editFormData.tx1tiet} 
                    onChange={e => setEditFormData({...editFormData, tx1tiet: e.target.value})}
                    style={{ 
                      width: '100%', padding: '10px 14px', borderRadius: '8px', 
                      border: `1px solid ${editErrors.tx1tiet ? 'var(--error)' : 'var(--border)'}`, 
                      background: 'var(--background)', color: 'var(--text)' 
                    }}
                  />
                  {editErrors.tx1tiet && <span style={{color: 'var(--error)', fontSize: '12px', marginTop: '4px', display: 'block'}}>{editErrors.tx1tiet}</span>}
                </div>
                <div className="form-group">
                  <label style={{ fontSize: '14px', fontWeight: '500', color: 'var(--text)', marginBottom: '8px', display: 'block' }}>Giữa kỳ</label>
                  <input 
                    type="text" 
                    value={editFormData.giuaKy} 
                    onChange={e => setEditFormData({...editFormData, giuaKy: e.target.value})}
                    style={{ 
                      width: '100%', padding: '10px 14px', borderRadius: '8px', 
                      border: `1px solid ${editErrors.giuaKy ? 'var(--error)' : 'var(--border)'}`, 
                      background: 'var(--background)', color: 'var(--text)' 
                    }}
                  />
                  {editErrors.giuaKy && <span style={{color: 'var(--error)', fontSize: '12px', marginTop: '4px', display: 'block'}}>{editErrors.giuaKy}</span>}
                </div>
                <div className="form-group">
                  <label style={{ fontSize: '14px', fontWeight: '500', color: 'var(--text)', marginBottom: '8px', display: 'block' }}>Cuối kỳ</label>
                  <input 
                    type="text" 
                    value={editFormData.cuoiKy} 
                    onChange={e => setEditFormData({...editFormData, cuoiKy: e.target.value})}
                    style={{ 
                      width: '100%', padding: '10px 14px', borderRadius: '8px', 
                      border: `1px solid ${editErrors.cuoiKy ? 'var(--error)' : 'var(--border)'}`, 
                      background: 'var(--background)', color: 'var(--text)' 
                    }}
                  />
                  {editErrors.cuoiKy && <span style={{color: 'var(--error)', fontSize: '12px', marginTop: '4px', display: 'block'}}>{editErrors.cuoiKy}</span>}
                </div>
                <div style={{ padding: '12px', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '8px', display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <AlertCircle size={20} color="var(--primary)" />
                  <span style={{ fontSize: '13px', color: 'var(--primary)', lineHeight: '1.4' }}>
                    Điểm trung bình hiện tại: {editingGrade.average ?? '--'}.<br/>
                    Hệ thống sẽ tự động tính lại điểm trung bình sau khi lưu.
                  </span>
                </div>
              </div>
              <div className="modal-actions" style={{ marginTop: '24px' }}>
                <button className="btn-secondary" onClick={() => setEditingGrade(null)}>Hủy bỏ</button>
                <button className="btn-primary" onClick={handleSaveEdit} disabled={isSaving}>
                  {isSaving ? <Loader2 className="spinner" size={20} /> : <Save size={20} />}
                  <span>{isSaving ? 'Đang lưu...' : 'Lưu điểm'}</span>
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default Grades;
