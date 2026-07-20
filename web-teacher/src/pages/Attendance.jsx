import { useContext, useEffect, useMemo, useState } from 'react';
import {
  AlertCircle,
  CheckCircle,
  Download,
  Loader2,
  UserCheck
} from 'lucide-react';
import * as XLSX from 'xlsx';
import { AuthContext } from '../App';
import api from '../services/api';

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

const getLocalDateValue = () => {
  const now = new Date();
  const offset = now.getTimezoneOffset();
  return new Date(now.getTime() - offset * 60_000).toISOString().split('T')[0];
};

const Attendance = () => {
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
  const [students, setStudents] = useState([]);
  const [classes, setClasses] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [selectedClass, setSelectedClass] = useState('');
  const [selectedSubject, setSelectedSubject] = useState('');
  const [selectedDate, setSelectedDate] = useState(getLocalDateValue);

  const [attendance, setAttendance] = useState({});
  const [notes, setNotes] = useState({});
  const [isSaving, setIsSaving] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

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
    setStudents([]);
    setAttendance({});
    setNotes({});

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
    setSubjects([]);
    setSelectedSubject('');
    setStudents([]);
    setAttendance({});
    setNotes({});

    if (!activeTeacherId || !selectedClass) return;

    const fetchSubjects = async () => {
      try {
        const res = await api.get(`/teachers/${activeTeacherId}/schedules`);
        const schedules = Array.isArray(res.data?.data) ? res.data.data : [];
        const classSchedules = schedules.filter(
            (schedule) => schedule.className === selectedClass
        );
        const uniqueSubjects = [
          ...new Set(classSchedules.map((schedule) => schedule.subject).filter(Boolean))
        ];

        setSubjects(uniqueSubjects);
        setSelectedSubject(uniqueSubjects.length > 0 ? uniqueSubjects[0] : '');
      } catch (err) {
        console.error('Error fetching subjects', err.response?.data || err);
        setSubjects([]);
        setSelectedSubject('');
      }
    };

    fetchSubjects();
  }, [activeTeacherId, selectedClass]);

  useEffect(() => {
    if (!activeTeacherId || !selectedClass || !selectedSubject || !selectedDate) {
      setStudents([]);
      setAttendance({});
      setNotes({});
      return;
    }

    const fetchStudentsAndAttendance = async () => {
      setIsLoading(true);
      try {
        const studentResponse = await api.get(
            `/teachers/${activeTeacherId}/students`,
            { params: { className: selectedClass } }
        );
        const studentList = Array.isArray(studentResponse.data?.data)
            ? studentResponse.data.data
            : [];
        setStudents(studentList);

        let existingAttendance = [];
        try {
          const attendanceResponse = await api.get(
              `/attendance/class/${encodeURIComponent(selectedClass)}/date/${selectedDate}`
          );
          const allRecords = Array.isArray(attendanceResponse.data?.data)
              ? attendanceResponse.data.data
              : [];
          existingAttendance = allRecords.filter(
              (record) => record.subject === selectedSubject
          );
        } catch (err) {
          console.error(
              'Error fetching existing attendance',
              err.response?.data || err
          );
        }

        const initialAttendance = {};
        const initialNotes = {};

        studentList.forEach((student) => {
          const existing = existingAttendance.find(
              (record) => Number(record.studentId) === Number(student.id)
          );
          initialAttendance[student.id] = existing?.status ?? 'PRESENT';
          initialNotes[student.id] = existing?.note ?? '';
        });

        setAttendance(initialAttendance);
        setNotes(initialNotes);
      } catch (err) {
        console.error(
            'Error fetching students and attendance',
            err.response?.data || err
        );
        setStudents([]);
        setAttendance({});
        setNotes({});
      } finally {
        setIsLoading(false);
      }
    };

    fetchStudentsAndAttendance();
  }, [activeTeacherId, selectedClass, selectedSubject, selectedDate]);

  const handleStatusChange = (studentId, status) => {
    if (isAdmin) return;
    setAttendance((current) => ({ ...current, [studentId]: status }));
  };

  const handleNoteChange = (studentId, note) => {
    if (isAdmin) return;
    setNotes((current) => ({ ...current, [studentId]: note }));
  };

  const handleSave = async () => {
    if (!isTeacher || isAdmin) {
      alert('Admin chỉ được xem điểm danh.');
      return;
    }
    if (!user?.id || !selectedClass || !selectedSubject) {
      alert('Vui lòng chọn lớp và môn học!');
      return;
    }

    setIsSaving(true);
    try {
      const records = students.map((student) => ({
        studentId: student.id,
        status: attendance[student.id] || 'PRESENT',
        note: notes[student.id] || ''
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
      console.error('Error saving attendance', err.response?.data || err);
      alert(err.response?.data?.message || 'Có lỗi khi lưu điểm danh');
    } finally {
      setIsSaving(false);
    }
  };

  const downloadAttendance = () => {
    if (students.length === 0) {
      alert('Chưa có danh sách học sinh để xuất file!');
      return;
    }

    const data = students.map((student) => ({
      'ID Học sinh': student.id,
      'Tên Học sinh': student.name,
      'Số điện thoại': student.phoneNumber,
      'Trạng thái':
          attendance[student.id] === 'PRESENT'
              ? 'Có mặt'
              : attendance[student.id] === 'ABSENT'
                  ? 'Vắng mặt'
                  : 'Muộn',
      'Ghi chú': notes[student.id] || ''
    }));

    const worksheet = XLSX.utils.json_to_sheet(data);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'DiemDanh');
    XLSX.writeFile(
        workbook,
        `DiemDanh_${selectedClass}_${selectedSubject}_${selectedDate}.xlsx`
    );
  };

  return (
      <div className="attendance-page fade-in">
        <div className="page-header">
          <div className="header-info">
            <h2 className="section-title">Điểm danh</h2>
            <p className="section-desc">
              {isAdmin
                  ? 'Theo dõi sĩ số lớp học theo giáo viên'
                  : 'Ghi nhận sĩ số lớp học hằng ngày'}
            </p>
          </div>

          <div className="header-actions" style={{ display: 'flex', gap: '12px' }}>
            <button className="btn-secondary" onClick={downloadAttendance}>
              <Download size={20} />
              <span>Xuất file Excel</span>
            </button>

            {!isAdmin && (
                <button
                    className="btn-primary"
                    onClick={handleSave}
                    disabled={isSaving || !selectedSubject || students.length === 0}
                >
                  {isSaving ? (
                      <Loader2 className="spinner" size={20} />
                  ) : (
                      <CheckCircle size={20} />
                  )}
                  <span>{isSaving ? 'Đang lưu...' : 'Hoàn tất điểm danh'}</span>
                </button>
            )}
          </div>
        </div>

        <div className="filters-card glass" style={{ marginTop: '24px' }}>
          <div
              style={{
                display: 'flex',
                gap: '24px',
                alignItems: 'center',
                flexWrap: 'wrap'
              }}
          >
            {isAdmin && (
                <div className="input-group">
                  <label>Giáo viên</label>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
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
                </div>
            )}

            <div className="input-group">
              <label>Lớp học</label>
              <select
                  value={selectedClass}
                  onChange={(event) => setSelectedClass(event.target.value)}
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

            <div className="input-group">
              <label>Môn học</label>
              <select
                  value={selectedSubject}
                  onChange={(event) => setSelectedSubject(event.target.value)}
                  disabled={!selectedClass || subjects.length === 0}
              >
                {subjects.map((subject) => (
                    <option key={subject} value={subject}>
                      {subject}
                    </option>
                ))}
                {subjects.length === 0 && <option value="">Không có môn học</option>}
              </select>
            </div>

            <div className="input-group">
              <label>Ngày điểm danh</label>
              <input
                  type="date"
                  value={selectedDate}
                  onChange={(event) => setSelectedDate(event.target.value)}
              />
            </div>
          </div>
        </div>

        <div
            className="students-attendance-list glass"
            style={{
              marginTop: '32px',
              padding: '24px',
              borderRadius: 'var(--radius-xl)'
            }}
        >
          {isLoading ? (
              <div className="loading-state">
                <Loader2 className="spinner" size={48} />
              </div>
          ) : !activeTeacherId && isAdmin ? (
              <div className="empty-state">
                <AlertCircle size={48} color="var(--text-muted)" />
                <p style={{ marginTop: '16px', color: 'var(--text-muted)' }}>
                  Vui lòng chọn giáo viên để xem điểm danh.
                </p>
              </div>
          ) : !selectedSubject ? (
              <div className="empty-state">
                <AlertCircle size={48} color="var(--text-muted)" />
                <p style={{ marginTop: '16px', color: 'var(--text-muted)' }}>
                  Vui lòng chọn môn học để xem điểm danh.
                </p>
              </div>
          ) : students.length === 0 ? (
              <div className="empty-state">
                <AlertCircle size={48} color="var(--text-muted)" />
                <p style={{ marginTop: '16px', color: 'var(--text-muted)' }}>
                  Không có học sinh trong lớp này.
                </p>
              </div>
          ) : (
              <table className="grades-table">
                <thead>
                <tr>
                  <th>Học sinh</th>
                  <th>SĐT liên hệ</th>
                  <th style={{ textAlign: 'center' }}>Trạng thái &amp; Ghi chú</th>
                </tr>
                </thead>
                <tbody>
                {students.map((student) => (
                    <tr key={student.id}>
                      <td className="student-cell">
                        <div className="mini-avatar">
                          {String(student.name ?? '?').charAt(0)}
                        </div>
                        <span>{student.name ?? 'Không rõ tên'}</span>
                      </td>
                      <td style={{ color: 'var(--text-muted)' }}>
                        {student.phoneNumber || '-'}
                      </td>
                      <td>
                        <div
                            style={{
                              display: 'flex',
                              flexDirection: 'column',
                              gap: '8px',
                              alignItems: 'center'
                            }}
                        >
                          <div
                              style={{
                                display: 'flex',
                                gap: '16px',
                                justifyContent: 'center',
                                flexWrap: 'wrap'
                              }}
                          >
                            {[
                              ['PRESENT', 'Có mặt', 'var(--success)'],
                              ['ABSENT', 'Vắng mặt', 'var(--error)'],
                              ['LATE', 'Muộn', 'var(--warning)']
                            ].map(([status, label, color]) => (
                                <label
                                    key={status}
                                    style={{
                                      display: 'flex',
                                      alignItems: 'center',
                                      gap: '8px',
                                      cursor: isAdmin ? 'default' : 'pointer',
                                      color:
                                          attendance[student.id] === status
                                              ? color
                                              : 'var(--text-muted)',
                                      fontWeight:
                                          attendance[student.id] === status ? 700 : 400
                                    }}
                                >
                                  <input
                                      type="radio"
                                      name={`attendance-${student.id}`}
                                      checked={attendance[student.id] === status}
                                      disabled={isAdmin}
                                      onChange={() => handleStatusChange(student.id, status)}
                                      style={{ accentColor: color }}
                                  />
                                  {label}
                                </label>
                            ))}
                          </div>

                          {attendance[student.id] !== 'PRESENT' && (
                              <input
                                  type="text"
                                  placeholder="Ghi chú (lý do vắng/muộn...)"
                                  value={notes[student.id] || ''}
                                  disabled={isAdmin}
                                  onChange={(event) =>
                                      handleNoteChange(student.id, event.target.value)
                                  }
                                  style={{
                                    width: '80%',
                                    padding: '6px 12px',
                                    borderRadius: '6px',
                                    border: '1px solid var(--border)',
                                    fontSize: '13px',
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