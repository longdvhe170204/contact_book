import { useEffect, useMemo, useState } from 'react';
import { adminClassApi } from '../../services/adminClassApi';
import './ClassManagement.css';

const today = new Date().toISOString().slice(0, 10);
const initialForm = {
  code: '', name: '', gradeLevel: 10, schoolYear: '2026-2027',
  homeroomTeacherId: '', maximumStudents: 45,
};

const unwrap = (response) => response?.data?.data ?? response?.data ?? [];
const errorMessage = (error, fallback) => error?.response?.data?.message || fallback;

export default function ClassManagement() {
  const [classes, setClasses] = useState([]);
  const [teachers, setTeachers] = useState([]);
  const [selected, setSelected] = useState(null);
  const [students, setStudents] = useState([]);
  const [unassignedStudents, setUnassignedStudents] = useState([]);
  const [selectedStudentIds, setSelectedStudentIds] = useState([]);
  const [form, setForm] = useState(initialForm);
  const [teacherId, setTeacherId] = useState('');
  const [editForm, setEditForm] = useState({ name: '', gradeLevel: 10, maximumStudents: 45 });
  const [joinedDate, setJoinedDate] = useState(today);
  const [transferTargetId, setTransferTargetId] = useState('');
  const [transferStudent, setTransferStudent] = useState(null);
  const [actionDate, setActionDate] = useState(today);
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const activeClasses = useMemo(
      () => classes.filter((item) => item.status === 'ACTIVE'),
      [classes],
  );

  const targetClasses = useMemo(
      () => activeClasses.filter((item) => item.id !== selected?.id),
      [activeClasses, selected],
  );

  const showSuccess = (message) => {
    setSuccess(message);
    window.setTimeout(() => setSuccess(''), 2500);
  };

  const loadBaseData = async () => {
    setLoading(true);
    setError('');
    try {
      const [classRes, teacherRes] = await Promise.all([
        adminClassApi.getClasses(),
        adminClassApi.getTeachers(),
      ]);
      setClasses(unwrap(classRes));
      setTeachers(unwrap(teacherRes));
    } catch (requestError) {
      setError(errorMessage(requestError, 'Không tải được dữ liệu lớp học'));
    } finally {
      setLoading(false);
    }
  };

  const loadClassData = async (classItem) => {
    if (!classItem) return;
    setError('');
    try {
      const [detailRes, studentRes, unassignedRes] = await Promise.all([
        adminClassApi.getClass(classItem.id),
        adminClassApi.getStudents(classItem.id),
        adminClassApi.getUnassignedStudents(classItem.schoolYear),
      ]);
      const detail = unwrap(detailRes);
      setSelected(detail);
      setTeacherId(detail.homeroomTeacherId ? String(detail.homeroomTeacherId) : '');
      setEditForm({
        name: detail.name || '',
        gradeLevel: detail.gradeLevel || 10,
        maximumStudents: detail.maximumStudents ?? '',
      });
      setStudents(unwrap(studentRes));
      setUnassignedStudents(unwrap(unassignedRes));
      setSelectedStudentIds([]);
    } catch (requestError) {
      setError(errorMessage(requestError, 'Không tải được chi tiết lớp'));
    }
  };

  useEffect(() => {
    loadBaseData();
  }, []);

  const refreshSelected = async () => {
    const classId = selected?.id;
    await loadBaseData();
    if (classId) {
      const latest = unwrap(await adminClassApi.getClass(classId));
      await loadClassData(latest);
    }
  };

  const createClass = async (event) => {
    event.preventDefault();
    setActionLoading(true);
    setError('');
    try {
      await adminClassApi.createClass({
        ...form,
        code: form.code.trim().toUpperCase(),
        name: form.name.trim(),
        gradeLevel: Number(form.gradeLevel),
        maximumStudents: form.maximumStudents ? Number(form.maximumStudents) : null,
        homeroomTeacherId: form.homeroomTeacherId ? Number(form.homeroomTeacherId) : null,
      });
      setForm(initialForm);
      await loadBaseData();
      showSuccess('Tạo lớp thành công');
    } catch (requestError) {
      setError(errorMessage(requestError, 'Tạo lớp thất bại'));
    } finally {
      setActionLoading(false);
    }
  };


  const updateClass = async () => {
    if (!selected) return;
    setActionLoading(true);
    setError('');
    try {
      await adminClassApi.updateClass(selected.id, {
        name: editForm.name.trim(),
        gradeLevel: Number(editForm.gradeLevel),
        maximumStudents: editForm.maximumStudents ? Number(editForm.maximumStudents) : null,
        status: selected.status,
      });
      showSuccess('Cập nhật thông tin lớp thành công');
      await refreshSelected();
    } catch (requestError) {
      setError(errorMessage(requestError, 'Cập nhật lớp thất bại'));
    } finally {
      setActionLoading(false);
    }
  };

  const saveTeacher = async () => {
    if (!selected) return;
    setActionLoading(true);
    setError('');
    try {
      if (teacherId) {
        await adminClassApi.assignHomeroomTeacher(selected.id, Number(teacherId));
        showSuccess('Đã cập nhật giáo viên chủ nhiệm');
      } else {
        await adminClassApi.removeHomeroomTeacher(selected.id);
        showSuccess('Đã gỡ giáo viên chủ nhiệm');
      }
      await refreshSelected();
    } catch (requestError) {
      setError(errorMessage(requestError, 'Cập nhật giáo viên chủ nhiệm thất bại'));
    } finally {
      setActionLoading(false);
    }
  };

  const toggleStudent = (studentId) => {
    setSelectedStudentIds((current) => (
        current.includes(studentId)
            ? current.filter((id) => id !== studentId)
            : [...current, studentId]
    ));
  };

  const addStudents = async () => {
    if (!selected || selectedStudentIds.length === 0) {
      setError('Hãy chọn ít nhất một học sinh');
      return;
    }
    setActionLoading(true);
    setError('');
    try {
      await adminClassApi.addStudents(selected.id, {
        studentIds: selectedStudentIds,
        joinedDate,
      });
      showSuccess('Đã thêm học sinh vào lớp');
      await refreshSelected();
    } catch (requestError) {
      setError(errorMessage(requestError, 'Thêm học sinh thất bại'));
    } finally {
      setActionLoading(false);
    }
  };

  const removeStudent = async (student) => {
    if (!selected || !window.confirm(`Gỡ ${student.name} khỏi lớp ${selected.code}?`)) return;
    setActionLoading(true);
    setError('');
    try {
      await adminClassApi.removeStudent(selected.id, student.id, {
        effectiveDate: today,
        reason: 'Gỡ khỏi lớp bởi quản trị viên',
      });
      showSuccess('Đã gỡ học sinh khỏi lớp');
      setReason('');
      await refreshSelected();
    } catch (requestError) {
      setError(errorMessage(requestError, 'Gỡ học sinh thất bại'));
    } finally {
      setActionLoading(false);
    }
  };

  const openTransfer = (student) => {
    setTransferStudent(student);
    setTransferTargetId(targetClasses[0]?.id ? String(targetClasses[0].id) : '');
    setActionDate(today);
    setReason('');
  };

  const submitTransfer = async () => {
    if (!transferStudent || !transferTargetId) {
      setError('Hãy chọn lớp đích');
      return;
    }
    setActionLoading(true);
    setError('');
    try {
      await adminClassApi.transferStudent(transferStudent.id, {
        targetClassId: Number(transferTargetId),
        effectiveDate: actionDate,
        reason: reason || 'Chuyển lớp bởi quản trị viên',
      });
      setTransferStudent(null);
      showSuccess('Chuyển lớp thành công');
      await refreshSelected();
    } catch (requestError) {
      setError(errorMessage(requestError, 'Chuyển lớp thất bại'));
    } finally {
      setActionLoading(false);
    }
  };

  const closeClass = async () => {
    if (!selected || !window.confirm(`Đóng lớp ${selected.code}?`)) return;
    setActionLoading(true);
    setError('');
    try {
      await adminClassApi.closeClass(selected.id);
      setSelected(null);
      setStudents([]);
      await loadBaseData();
      showSuccess('Đã đóng lớp');
    } catch (requestError) {
      setError(errorMessage(requestError, 'Đóng lớp thất bại'));
    } finally {
      setActionLoading(false);
    }
  };

  return (
      <div className="class-management">
        <header>
          <div>
            <h1>Quản lý lớp học</h1>
          </div>
          <span className="class-count">{activeClasses.length} lớp hoạt động</span>
        </header>

        {error && <div className="class-message class-error">{error}</div>}
        {success && <div className="class-message class-success">{success}</div>}

        <section className="class-grid">
          <form className="class-card class-form" onSubmit={createClass}>
            <h2>Tạo lớp mới</h2>
            <label>Mã lớp<input value={form.code} required onChange={(event) => setForm({ ...form, code: event.target.value })} placeholder="10A" /></label>
            <label>Tên lớp<input value={form.name} required onChange={(event) => setForm({ ...form, name: event.target.value })} placeholder="Lớp 10A" /></label>
            <div className="class-row">
              <label>Khối<input type="number" min="1" max="12" value={form.gradeLevel} onChange={(event) => setForm({ ...form, gradeLevel: event.target.value })} /></label>
              <label>Năm học<input value={form.schoolYear} pattern="\d{4}-\d{4}" onChange={(event) => setForm({ ...form, schoolYear: event.target.value })} /></label>
            </div>
            <label>Giáo viên chủ nhiệm
              <select value={form.homeroomTeacherId} onChange={(event) => setForm({ ...form, homeroomTeacherId: event.target.value })}>
                <option value="">Chưa gán</option>
                {teachers.map((teacher) => <option key={teacher.id} value={teacher.id}>{teacher.name}</option>)}
              </select>
            </label>
            <label>Sĩ số tối đa<input type="number" min="1" value={form.maximumStudents} onChange={(event) => setForm({ ...form, maximumStudents: event.target.value })} /></label>
            <button type="submit" disabled={actionLoading}>Tạo lớp</button>
          </form>

          <div className="class-card class-list">
            <h2>Danh sách lớp</h2>
            {loading && <p>Đang tải...</p>}
            {!loading && classes.length === 0 && <p>Chưa có lớp học.</p>}
            {!loading && classes.map((item) => (
                <button type="button" key={item.id} className={`class-item ${selected?.id === item.id ? 'selected' : ''}`} onClick={() => loadClassData(item)}>
                  <strong>{item.code}</strong>
                  <span>{item.homeroomTeacherName || 'Chưa có GVCN'}</span>
                  <span>{item.studentCount}/{item.maximumStudents || '∞'} học sinh</span>
                  <em>{item.status}</em>
                </button>
            ))}
          </div>

          <div className="class-card class-detail">
            <h2>Chi tiết lớp</h2>
            {!selected && <p>Chọn một lớp để xem chi tiết.</p>}
            {selected && (
                <>
                  <dl>
                    <div><dt>Mã lớp</dt><dd>{selected.code}</dd></div>
                    <div><dt>Năm học</dt><dd>{selected.schoolYear}</dd></div>
                    <div><dt>Trạng thái</dt><dd>{selected.status}</dd></div>
                    <div><dt>Sĩ số</dt><dd>{selected.studentCount}/{selected.maximumStudents || '∞'}</dd></div>
                  </dl>

                  <section className="detail-section">
                    <h3>Thông tin lớp</h3>
                    <div className="class-row">
                      <label>Tên lớp<input value={editForm.name} disabled={selected.status !== 'ACTIVE'} onChange={(event) => setEditForm({ ...editForm, name: event.target.value })} /></label>
                      <label>Khối<input type="number" min="1" max="12" value={editForm.gradeLevel} disabled={selected.status !== 'ACTIVE'} onChange={(event) => setEditForm({ ...editForm, gradeLevel: event.target.value })} /></label>
                    </div>
                    <label>Sĩ số tối đa<input type="number" min="1" value={editForm.maximumStudents} disabled={selected.status !== 'ACTIVE'} onChange={(event) => setEditForm({ ...editForm, maximumStudents: event.target.value })} /></label>
                    <button type="button" disabled={actionLoading || selected.status !== 'ACTIVE' || !editForm.name.trim()} onClick={updateClass}>Lưu thông tin lớp</button>
                  </section>

                  <section className="detail-section">
                    <h3>Giáo viên chủ nhiệm</h3>
                    <div className="inline-form">
                      <select value={teacherId} disabled={selected.status !== 'ACTIVE'} onChange={(event) => setTeacherId(event.target.value)}>
                        <option value="">Chưa gán</option>
                        {teachers.map((teacher) => <option key={teacher.id} value={teacher.id}>{teacher.name}</option>)}
                      </select>
                      <button type="button" disabled={actionLoading || selected.status !== 'ACTIVE'} onClick={saveTeacher}>Lưu GVCN</button>
                    </div>
                  </section>

                  <section className="detail-section">
                    <div className="section-heading"><h3>Học sinh trong lớp</h3><span>{students.length} học sinh</span></div>
                    <div className="student-list">
                      {students.length === 0 && <p>Chưa có học sinh.</p>}
                      {students.map((student) => (
                          <div className="student-item" key={student.id}>
                            <span><strong>{student.name}</strong><small>{student.phoneNumber}</small></span>
                            <span className="student-actions">
                        <button type="button" className="secondary" disabled={actionLoading || selected.status !== 'ACTIVE'} onClick={() => openTransfer(student)}>Chuyển lớp</button>
                        <button type="button" className="danger compact" disabled={actionLoading || selected.status !== 'ACTIVE'} onClick={() => removeStudent(student)}>Gỡ</button>
                      </span>
                          </div>
                      ))}
                    </div>
                  </section>

                  {selected.status === 'ACTIVE' && (
                      <section className="detail-section">
                        <h3>Thêm học sinh chưa có lớp</h3>
                        <label>Ngày vào lớp<input type="date" value={joinedDate} onChange={(event) => setJoinedDate(event.target.value)} /></label>
                        <div className="candidate-list">
                          {unassignedStudents.length === 0 && <p>Không có học sinh phù hợp.</p>}
                          {unassignedStudents.map((student) => (
                              <label key={student.id} className="candidate-item">
                                <input type="checkbox" checked={selectedStudentIds.includes(student.id)} onChange={() => toggleStudent(student.id)} />
                                <span><strong>{student.name}</strong><small>{student.phoneNumber}</small></span>
                              </label>
                          ))}
                        </div>
                        <button type="button" disabled={actionLoading || selectedStudentIds.length === 0} onClick={addStudents}>Thêm học sinh đã chọn</button>
                      </section>
                  )}

                  {selected.status === 'ACTIVE' && <button type="button" className="danger close-class" disabled={actionLoading} onClick={closeClass}>Đóng lớp</button>}
                </>
            )}
          </div>
        </section>

        {transferStudent && (
            <div className="class-modal-backdrop" role="presentation" onMouseDown={() => setTransferStudent(null)}>
              <div className="class-modal" role="dialog" aria-modal="true" onMouseDown={(event) => event.stopPropagation()}>
                <h2>Chuyển lớp cho {transferStudent.name}</h2>
                <label>Lớp đích
                  <select value={transferTargetId} onChange={(event) => setTransferTargetId(event.target.value)}>
                    <option value="">Chọn lớp</option>
                    {targetClasses.map((item) => <option key={item.id} value={item.id}>{item.code} – {item.schoolYear}</option>)}
                  </select>
                </label>
                <label>Ngày hiệu lực<input type="date" value={actionDate} onChange={(event) => setActionDate(event.target.value)} /></label>
                <label>Lý do<textarea value={reason} onChange={(event) => setReason(event.target.value)} placeholder="Điều chỉnh phân lớp" /></label>
                <div className="modal-actions">
                  <button type="button" className="secondary" onClick={() => setTransferStudent(null)}>Hủy</button>
                  <button type="button" disabled={actionLoading || !transferTargetId} onClick={submitTransfer}>Xác nhận chuyển</button>
                </div>
              </div>
            </div>
        )}
      </div>
  );
}
