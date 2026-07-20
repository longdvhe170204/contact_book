import { useContext, useEffect, useMemo, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import * as XLSX from 'xlsx';
import {
  AlertCircle,
  BookOpen,
  Calendar,
  Download,
  Loader2,
  Save,
  Search,
  Table as TableIcon,
  UserCheck,
  X
} from 'lucide-react';
import { AuthContext } from '../App';
import api from '../services/api';
import './Grades.css';

const normalizeRoleName = (role) => {
  if (!role) return '';
  if (typeof role === 'string') return role.toUpperCase();
  return String(role.name ?? role.roleName ?? '').toUpperCase();
};

const getRoleNames = (user) => {
  const roles = Array.isArray(user?.roles) ? user.roles : [];
  const roleNames = roles.map(normalizeRoleName).filter(Boolean);

  if (user?.role) {
    roleNames.push(normalizeRoleName(user.role));
  }

  return [...new Set(roleNames)];
};

const Grades = () => {
  const { user } = useContext(AuthContext);

  const roleNames = useMemo(() => getRoleNames(user), [user]);
  const isAdmin = roleNames.some(
      (role) => role === 'ADMIN' || role === 'ROLE_ADMIN'
  );
  const isTeacher = roleNames.some(
      (role) => role === 'TEACHER' || role === 'ROLE_TEACHER'
  );

  const [teachers, setTeachers] = useState([]);
  const [selectedTeacherId, setSelectedTeacherId] = useState('');
  const [grades, setGrades] = useState([]);
  const [classes, setClasses] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [selectedClass, setSelectedClass] = useState('');
  const [selectedSubject, setSelectedSubject] = useState('');
  const [selectedSemester, setSelectedSemester] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  const [editingGrade, setEditingGrade] = useState(null);
  const [editFormData, setEditFormData] = useState({
    tx15: '',
    tx1tiet: '',
    giuaKy: '',
    cuoiKy: ''
  });
  const [editErrors, setEditErrors] = useState({});
  const [isSaving, setIsSaving] = useState(false);

  const activeTeacherId = isAdmin ? selectedTeacherId : user?.id;

  useEffect(() => {
    if (!isAdmin) {
      setTeachers([]);
      setSelectedTeacherId('');
      return;
    }

    const fetchTeachers = async () => {
      try {
        const res = await api.get('/teachers');
        const teacherList = Array.isArray(res.data?.data) ? res.data.data : [];
        setTeachers(teacherList);
        setSelectedTeacherId((current) => {
          if (teacherList.some((teacher) => String(teacher.id) === String(current))) {
            return current;
          }
          return teacherList.length > 0 ? String(teacherList[0].id) : '';
        });
      } catch (err) {
        console.error('Error fetching teachers', err.response?.data || err);
        setTeachers([]);
        setSelectedTeacherId('');
      }
    };

    fetchTeachers();
  }, [isAdmin]);

  useEffect(() => {
    setClasses([]);
    setSelectedClass('');
    setSubjects([]);
    setSelectedSubject('');
    setGrades([]);
    setEditingGrade(null);

    if (!activeTeacherId) return;

    const fetchClasses = async () => {
      try {
        const res = await api.get(`/teachers/${activeTeacherId}/classes`);
        const classList = Array.isArray(res.data?.data) ? res.data.data : [];
        setClasses(classList);
        setSelectedClass(classList.length > 0 ? classList[0] : '');
      } catch (err) {
        console.error('Error fetching classes', err.response?.data || err);
        setClasses([]);
        setSelectedClass('');
      }
    };

    fetchClasses();
  }, [activeTeacherId]);

  useEffect(() => {
    if (!activeTeacherId || !selectedClass) {
      setGrades([]);
      setSubjects([]);
      return;
    }

    const fetchGrades = async () => {
      setIsLoading(true);
      try {
        const res = await api.get(`/teachers/${activeTeacherId}/grades`, {
          params: {
            className: selectedClass,
            semester: selectedSemester,
            subject: selectedSubject || undefined
          }
        });

        const gradeList = Array.isArray(res.data?.data) ? res.data.data : [];
        setGrades(gradeList);

        const uniqueSubjects = [
          ...new Set(gradeList.map((grade) => grade.subject).filter(Boolean))
        ];
        setSubjects(uniqueSubjects);

        if (
            selectedSubject &&
            !uniqueSubjects.includes(selectedSubject)
        ) {
          setSelectedSubject('');
        }
      } catch (err) {
        console.error('Error fetching grades', err.response?.data || err);
        setGrades([]);
        setSubjects([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchGrades();
  }, [activeTeacherId, selectedClass, selectedSubject, selectedSemester]);

  const handleEditClick = (grade) => {
    if (!isTeacher || isAdmin) return;

    setEditingGrade(grade);
    setEditFormData({
      tx15: Array.isArray(grade.tx15) ? grade.tx15.join(', ') : '',
      tx1tiet: Array.isArray(grade.tx1tiet) ? grade.tx1tiet.join(', ') : '',
      giuaKy: grade.giuaKy ?? '',
      cuoiKy: grade.cuoiKy ?? ''
    });
    setEditErrors({});
  };

  const validateMultipleScores = (value) => {
    if (!value || !String(value).trim()) return null;
    if (/[a-zA-Z]/.test(String(value))) return 'Không nhập chữ, chỉ nhập số';

    for (const part of String(value).split(',')) {
      if (!part.trim()) continue;
      const score = Number(part.trim());
      if (Number.isNaN(score)) return 'Sai định dạng số';
      if (score < 0 || score > 10) return 'Điểm phải từ 0 đến 10';
    }

    return null;
  };

  const validateSingleScore = (value) => {
    if (value === null || value === undefined || String(value).trim() === '') {
      return null;
    }
    if (/[a-zA-Z]/.test(String(value))) return 'Không nhập chữ, chỉ nhập số';

    const score = Number(String(value).trim());
    if (Number.isNaN(score)) return 'Sai định dạng số';
    if (score < 0 || score > 10) return 'Điểm phải từ 0 đến 10';
    return null;
  };

  const validateForm = () => {
    const errors = {};
    const tx15Error = validateMultipleScores(editFormData.tx15);
    const tx1TietError = validateMultipleScores(editFormData.tx1tiet);
    const giuaKyError = validateSingleScore(editFormData.giuaKy);
    const cuoiKyError = validateSingleScore(editFormData.cuoiKy);

    if (tx15Error) errors.tx15 = tx15Error;
    if (tx1TietError) errors.tx1tiet = tx1TietError;
    if (giuaKyError) errors.giuaKy = giuaKyError;
    if (cuoiKyError) errors.cuoiKy = cuoiKyError;

    setEditErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSaveEdit = async () => {
    if (!isTeacher || isAdmin) {
      alert('Admin chỉ được xem điểm.');
      return;
    }
    if (!editingGrade || !user?.id || !validateForm()) return;

    setIsSaving(true);
    try {
      const tx15 = editFormData.tx15
          ? editFormData.tx15
              .split(',')
              .map((score) => score.trim())
              .filter(Boolean)
              .map(Number)
          : [];
      const tx1tiet = editFormData.tx1tiet
          ? editFormData.tx1tiet
              .split(',')
              .map((score) => score.trim())
              .filter(Boolean)
              .map(Number)
          : [];
      const giuaKy =
          editFormData.giuaKy !== null && editFormData.giuaKy !== ''
              ? Number(editFormData.giuaKy)
              : null;
      const cuoiKy =
          editFormData.cuoiKy !== null && editFormData.cuoiKy !== ''
              ? Number(editFormData.cuoiKy)
              : null;

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

      const res = await api.get(`/teachers/${user.id}/grades`, {
        params: {
          className: selectedClass,
          semester: selectedSemester,
          subject: selectedSubject || undefined
        }
      });
      setGrades(Array.isArray(res.data?.data) ? res.data.data : []);
    } catch (err) {
      console.error('Error saving grade', err.response?.data || err);
      alert(err.response?.data?.message || 'Lỗi khi lưu điểm');
    } finally {
      setIsSaving(false);
    }
  };

  const exportGrades = () => {
    if (grades.length === 0) {
      alert('Chưa có dữ liệu điểm để xuất file.');
      return;
    }

    const templateData = grades.map((grade) => ({
      'ID Học sinh': grade.studentId,
      'Tên Học sinh': grade.studentName,
      'Môn học': grade.subject,
      'ĐTX15': Array.isArray(grade.tx15) ? grade.tx15.join(',') : '',
      'ĐTX1Tiet': Array.isArray(grade.tx1tiet) ? grade.tx1tiet.join(',') : '',
      'Giữa kỳ': grade.giuaKy,
      'Cuối kỳ': grade.cuoiKy,
      'Trung bình': grade.average
    }));

    const worksheet = XLSX.utils.json_to_sheet(templateData);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'BangDiem');
    XLSX.writeFile(
        workbook,
        `BangDiem_${selectedClass || 'TatCa'}_S${selectedSemester}.xlsx`
    );
  };

  const filteredGrades = grades.filter((grade) =>
      String(grade.studentName ?? '')
          .toLowerCase()
          .includes(searchTerm.toLowerCase())
  );

  return (
      <div className="grades-page fade-in">
        <div className="page-header">
          <div className="header-info">
            <h2 className="section-title">Quản lý Điểm số</h2>
            <p className="section-desc">
              {isAdmin
                  ? 'Theo dõi kết quả học tập của học sinh theo giáo viên'
                  : 'Cập nhật và theo dõi kết quả học tập của học sinh'}
            </p>
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
                onChange={(event) => setSearchTerm(event.target.value)}
            />
          </div>

          <div className="filters-group">
            {isAdmin && (
                <div className="filter-item">
                  <UserCheck size={18} />
                  <select
                      value={selectedTeacherId}
                      onChange={(event) => setSelectedTeacherId(event.target.value)}
                  >
                    <option value="">Chọn giáo viên</option>
                    {teachers.map((teacher) => (
                        <option key={teacher.id} value={teacher.id}>
                          {teacher.name}
                        </option>
                    ))}
                  </select>
                </div>
            )}

            <div className="filter-item">
              <TableIcon size={18} />
              <select
                  value={selectedClass}
                  onChange={(event) => {
                    setSelectedClass(event.target.value);
                    setSelectedSubject('');
                  }}
                  disabled={!activeTeacherId || classes.length === 0}
              >
                {classes.length === 0 && <option value="">Không có lớp</option>}
                {classes.map((className) => (
                    <option key={className} value={className}>
                      Lớp {className}
                    </option>
                ))}
              </select>
            </div>

            <div className="filter-item">
              <BookOpen size={18} />
              <select
                  value={selectedSubject}
                  onChange={(event) => setSelectedSubject(event.target.value)}
                  disabled={!selectedClass}
              >
                <option value="">Tất cả môn học</option>
                {subjects.map((subject) => (
                    <option key={subject} value={subject}>
                      {subject}
                    </option>
                ))}
              </select>
            </div>

            <div className="filter-item">
              <Calendar size={18} />
              <select
                  value={selectedSemester}
                  onChange={(event) => setSelectedSemester(Number(event.target.value))}
              >
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
                  <th>TX 15&apos;</th>
                  <th>TX 1 Tiết</th>
                  <th>Giữa kỳ</th>
                  <th>Cuối kỳ</th>
                  <th>Trung bình</th>
                  {!isAdmin && <th>Thao tác</th>}
                </tr>
                </thead>
                <tbody>
                {filteredGrades.map((grade, index) => (
                    <tr
                        key={
                            grade.gradeId ??
                            `${grade.studentId}-${grade.subject}-${grade.semester}-${index}`
                        }
                    >
                      <td className="student-cell">
                        <div className="mini-avatar">
                          {String(grade.studentName ?? '?').charAt(0)}
                        </div>
                        <span>{grade.studentName ?? 'Không rõ tên'}</span>
                      </td>
                      <td>
                        <span className="subject-badge">{grade.subject}</span>
                      </td>
                      <td>{Array.isArray(grade.tx15) && grade.tx15.length ? grade.tx15.join(', ') : '-'}</td>
                      <td>{Array.isArray(grade.tx1tiet) && grade.tx1tiet.length ? grade.tx1tiet.join(', ') : '-'}</td>
                      <td>{grade.giuaKy ?? '-'}</td>
                      <td>{grade.cuoiKy ?? '-'}</td>
                      <td className="avg-cell">{grade.average ?? '-'}</td>
                      {!isAdmin && (
                          <td>
                            <button
                                className="edit-btn"
                                onClick={() => handleEditClick(grade)}
                            >
                              Sửa
                            </button>
                          </td>
                      )}
                    </tr>
                ))}
                </tbody>
              </table>
          ) : (
              <div className="empty-state">
                <AlertCircle size={64} />
                <h3>Chưa có dữ liệu điểm</h3>
                <p>
                  {isAdmin && !selectedTeacherId
                      ? 'Vui lòng chọn giáo viên để xem bảng điểm.'
                      : 'Vui lòng chọn lớp, học kỳ hoặc môn học để xem điểm.'}
                </p>
              </div>
          )}
        </div>

        <AnimatePresence>
          {editingGrade && !isAdmin && (
              <div className="modal-overlay">
                <motion.div
                    className="modal-content glass edit-modal"
                    initial={{ scale: 0.9, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    exit={{ scale: 0.9, opacity: 0 }}
                    style={{ maxWidth: '500px' }}
                >
                  <div className="modal-header">
                    <h3>Sửa điểm: {editingGrade.studentName}</h3>
                    <button onClick={() => setEditingGrade(null)}>
                      <X size={24} />
                    </button>
                  </div>

                  <div
                      className="modal-body"
                      style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}
                  >
                    {[
                      ['tx15', 'Điểm 15 phút (cách nhau bởi dấu phẩy)'],
                      ['tx1tiet', 'Điểm 1 tiết (cách nhau bởi dấu phẩy)'],
                      ['giuaKy', 'Giữa kỳ'],
                      ['cuoiKy', 'Cuối kỳ']
                    ].map(([field, label]) => (
                        <div className="form-group" key={field}>
                          <label
                              style={{
                                fontSize: '14px',
                                fontWeight: '500',
                                color: 'var(--text)',
                                marginBottom: '8px',
                                display: 'block'
                              }}
                          >
                            {label}
                          </label>
                          <input
                              type="text"
                              value={editFormData[field]}
                              onChange={(event) =>
                                  setEditFormData((current) => ({
                                    ...current,
                                    [field]: event.target.value
                                  }))
                              }
                              style={{
                                width: '100%',
                                padding: '10px 14px',
                                borderRadius: '8px',
                                border: `1px solid ${
                                    editErrors[field] ? 'var(--error)' : 'var(--border)'
                                }`,
                                background: 'var(--background)',
                                color: 'var(--text)'
                              }}
                          />
                          {editErrors[field] && (
                              <span
                                  style={{
                                    color: 'var(--error)',
                                    fontSize: '12px',
                                    marginTop: '4px',
                                    display: 'block'
                                  }}
                              >
                        {editErrors[field]}
                      </span>
                          )}
                        </div>
                    ))}

                    <div
                        style={{
                          padding: '12px',
                          background: 'rgba(59, 130, 246, 0.1)',
                          borderRadius: '8px',
                          display: 'flex',
                          gap: '8px',
                          alignItems: 'center'
                        }}
                    >
                      <AlertCircle size={20} color="var(--primary)" />
                      <span
                          style={{
                            fontSize: '13px',
                            color: 'var(--primary)',
                            lineHeight: '1.4'
                          }}
                      >
                    Điểm trung bình hiện tại: {editingGrade.average ?? '--'}.
                    <br />
                    Hệ thống sẽ tự động tính lại điểm trung bình sau khi lưu.
                  </span>
                    </div>
                  </div>

                  <div className="modal-actions" style={{ marginTop: '24px' }}>
                    <button
                        className="btn-secondary"
                        onClick={() => setEditingGrade(null)}
                    >
                      Hủy bỏ
                    </button>
                    <button
                        className="btn-primary"
                        onClick={handleSaveEdit}
                        disabled={isSaving}
                    >
                      {isSaving ? (
                          <Loader2 className="spinner" size={20} />
                      ) : (
                          <Save size={20} />
                      )}
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