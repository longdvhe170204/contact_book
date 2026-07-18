import { useState, useEffect, useContext } from 'react';
import { UserCheck, CheckCircle, XCircle, Clock, Loader2, AlertCircle, Download } from 'lucide-react';
import * as XLSX from 'xlsx';
import { AuthContext } from '../App';
import api from '../services/api';

const Attendance = () => {
  const { user } = useContext(AuthContext);
  const [students, setStudents] = useState([]);
  const [classes, setClasses] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [selectedClass, setSelectedClass] = useState('');
  const [selectedSubject, setSelectedSubject] = useState('');
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  
  const [attendance, setAttendance] = useState({}); // { studentId: status }
  const [notes, setNotes] = useState({}); // { studentId: note }
  
  const [isSaving, setIsSaving] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    fetchClasses();
  }, [user]);

  useEffect(() => {
    if (selectedClass) {
      fetchSubjects();
    }
  }, [user, selectedClass]);

  useEffect(() => {
    if (selectedClass && selectedSubject && selectedDate) {
      fetchStudentsAndAttendance();
    }
  }, [user, selectedClass, selectedSubject, selectedDate]);

  const fetchClasses = async () => {
    try {
      const res = await api.get(`/teachers/${user.id}/classes`);
      setClasses(res.data.data);
      if (res.data.data.length > 0) setSelectedClass(res.data.data[0]);
    } catch(err) { console.error(err); }
  };

  const fetchSubjects = async () => {
    try {
      const res = await api.get(`/teachers/${user.id}/schedules`);
      const classSchedules = res.data.data.filter(s => s.className === selectedClass);
      const uniqueSubjects = [...new Set(classSchedules.map(s => s.subject))];
      setSubjects(uniqueSubjects);
      if (uniqueSubjects.length > 0) {
        setSelectedSubject(uniqueSubjects[0]);
      } else {
        setSelectedSubject('');
      }
    } catch(err) { console.error(err); }
  };

  const fetchStudentsAndAttendance = async () => {
    setIsLoading(true);
    try {
      const resSt = await api.get(`/teachers/${user.id}/students`, { params: { className: selectedClass } });
      const studentList = resSt.data.data;
      setStudents(studentList);
      
      let existingAtt = [];
      try {
        const resAtt = await api.get(`/attendance/class/${selectedClass}/date/${selectedDate}`);
        existingAtt = resAtt.data.data.filter(a => a.subject === selectedSubject);
      } catch (e) {
        console.error("Error fetching existing attendance", e);
      }
      
      const initAttr = {};
      const initNotes = {};
      studentList.forEach(s => {
        const found = existingAtt.find(a => a.studentId === s.id);
        initAttr[s.id] = found ? found.status : 'PRESENT';
        initNotes[s.id] = found ? (found.note || '') : '';
      });
      setAttendance(initAttr);
      setNotes(initNotes);
    } catch(err) { console.error(err); }
    finally { setIsLoading(false); }
  };

  const handleStatusChange = (studentId, status) => {
    setAttendance(prev => ({ ...prev, [studentId]: status }));
  };

  const handleNoteChange = (studentId, note) => {
    setNotes(prev => ({ ...prev, [studentId]: note }));
  };

  const handleSave = async () => {
    if (!selectedClass || !selectedSubject) {
      alert("Vui lòng chọn lớp và môn học!");
      return;
    }
    
    setIsSaving(true);
    try {
      const records = students.map(s => ({
        studentId: s.id,
        status: attendance[s.id] || 'PRESENT',
        note: notes[s.id] || ''
      }));

      const payload = {
        className: selectedClass,
        subject: selectedSubject,
        date: selectedDate,
        records
      };

      await api.post(`/attendance?teacherId=${user.id}`, payload);
      alert('Lưu điểm danh thành công!');
    } catch (err) {
      alert('Có lỗi khi lưu điểm danh');
    } finally { setIsSaving(false); }
  };

  const downloadAttendance = () => {
    if (students.length === 0) {
      alert("Chưa có danh sách học sinh để xuất file!");
      return;
    }
    const data = students.map(s => ({
      'ID Học sinh': s.id,
      'Tên Học sinh': s.name,
      'Số điện thoại': s.phoneNumber,
      'Trạng thái': attendance[s.id] === 'PRESENT' ? 'Có mặt' : attendance[s.id] === 'ABSENT' ? 'Vắng mặt' : 'Muộn',
      'Ghi chú': notes[s.id] || ''
    }));
    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "DiemDanh");
    XLSX.writeFile(wb, `DiemDanh_${selectedClass}_${selectedSubject}_${selectedDate}.xlsx`);
  };

  return (
    <div className="attendance-page fade-in">
      <div className="page-header">
        <div className="header-info">
          <h2 className="section-title">Điểm danh</h2>
          <p className="section-desc">Ghi nhận sĩ số lớp học hằng ngày</p>
        </div>
        <div className="header-actions" style={{ display: 'flex', gap: '12px' }}>
          <button className="btn-secondary" onClick={downloadAttendance}>
            <Download size={20} />
            <span>Xuất file Excel</span>
          </button>
          <button className="btn-primary" onClick={handleSave} disabled={isSaving || !selectedSubject}>
            {isSaving ? <Loader2 className="spinner" size={20} /> : <CheckCircle size={20} />}
            <span>{isSaving ? 'Đang lưu...' : 'Hoàn tất điểm danh'}</span>
          </button>
        </div>
      </div>

      <div className="filters-card glass" style={{ marginTop: '24px' }}>
        <div style={{ display: 'flex', gap: '24px', alignItems: 'center', flexWrap: 'wrap' }}>
          <div className="input-group">
            <label>Lớp học</label>
            <select value={selectedClass} onChange={e => setSelectedClass(e.target.value)}>
              {classes.map(c => <option key={c} value={c}>Lớp {c}</option>)}
            </select>
          </div>
          <div className="input-group">
            <label>Môn học</label>
            <select value={selectedSubject} onChange={e => setSelectedSubject(e.target.value)}>
              {subjects.map(s => <option key={s} value={s}>{s}</option>)}
              {subjects.length === 0 && <option value="">Không có môn học</option>}
            </select>
          </div>
          <div className="input-group">
            <label>Ngày điểm danh</label>
            <input type="date" value={selectedDate} onChange={e => setSelectedDate(e.target.value)} />
          </div>
        </div>
      </div>

      <div className="students-attendance-list glass" style={{ marginTop: '32px', padding: '24px', borderRadius: 'var(--radius-xl)' }}>
        {isLoading ? (
          <div className="loading-state"><Loader2 className="spinner" size={48} /></div>
        ) : !selectedSubject ? (
          <div className="empty-state">
            <AlertCircle size={48} color="var(--text-muted)" />
            <p style={{ marginTop: '16px', color: 'var(--text-muted)' }}>Vui lòng chọn môn học để điểm danh.</p>
          </div>
        ) : (
          <table className="grades-table">
            <thead>
              <tr>
                <th>Học sinh</th>
                <th>SĐT liên hệ</th>
                <th style={{ textAlign: 'center' }}>Trạng thái & Ghi chú</th>
              </tr>
            </thead>
            <tbody>
              {students.map(s => (
                <tr key={s.id}>
                  <td className="student-cell">
                    <div className="mini-avatar">{s.name.charAt(0)}</div>
                    <span>{s.name}</span>
                  </td>
                  <td style={{ color: 'var(--text-muted)' }}>{s.phoneNumber}</td>
                  <td>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', alignItems: 'center' }}>
                      <div style={{ display: 'flex', gap: '16px', justifyContent: 'center' }}>
                        <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', color: attendance[s.id] === 'PRESENT' ? 'var(--success)' : 'var(--text-muted)', fontWeight: attendance[s.id] === 'PRESENT' ? 700 : 400 }}>
                          <input type="radio" checked={attendance[s.id] === 'PRESENT'} onChange={() => handleStatusChange(s.id, 'PRESENT')} style={{ accentColor: 'var(--success)' }} /> Có mặt
                        </label>
                        <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', color: attendance[s.id] === 'ABSENT' ? 'var(--error)' : 'var(--text-muted)', fontWeight: attendance[s.id] === 'ABSENT' ? 700 : 400 }}>
                          <input type="radio" checked={attendance[s.id] === 'ABSENT'} onChange={() => handleStatusChange(s.id, 'ABSENT')} style={{ accentColor: 'var(--error)' }} /> Vắng mặt
                        </label>
                        <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', color: attendance[s.id] === 'LATE' ? 'var(--warning)' : 'var(--text-muted)', fontWeight: attendance[s.id] === 'LATE' ? 700 : 400 }}>
                          <input type="radio" checked={attendance[s.id] === 'LATE'} onChange={() => handleStatusChange(s.id, 'LATE')} style={{ accentColor: 'var(--warning)' }} /> Muộn
                        </label>
                      </div>
                      {attendance[s.id] !== 'PRESENT' && (
                        <input 
                          type="text" 
                          placeholder="Ghi chú (lý do vắng/muộn...)" 
                          value={notes[s.id] || ''}
                          onChange={(e) => handleNoteChange(s.id, e.target.value)}
                          style={{
                            width: '80%', padding: '6px 12px', borderRadius: '6px',
                            border: '1px solid var(--border)', fontSize: '13px',
                            background: 'var(--background)'
                          }}
                        />
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default Attendance;

