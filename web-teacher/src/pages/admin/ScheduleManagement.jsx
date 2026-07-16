import { useEffect, useMemo, useState } from 'react';
import { CalendarDays, Pencil, Plus, Trash2, X } from 'lucide-react';
import { adminClassApi } from '../../services/adminClassApi';
import { adminScheduleApi } from '../../services/adminScheduleApi';
import './ScheduleManagement.css';

const DAYS = [
  { value: 2, label: 'Thứ 2' }, { value: 3, label: 'Thứ 3' },
  { value: 4, label: 'Thứ 4' }, { value: 5, label: 'Thứ 5' },
  { value: 6, label: 'Thứ 6' }, { value: 7, label: 'Thứ 7' },
];
const PERIODS = Array.from({ length: 10 }, (_, index) => index + 1);
const unwrap = (response) => response?.data?.data ?? response?.data ?? [];
const messageOf = (error, fallback) => error?.response?.data?.message || fallback;

const blankForm = (schoolYear = '2026-2027') => ({
  classId: '', subjectId: '', teacherId: '', dayOfWeek: 2, period: 1,
  semester: 1, schoolYear, room: '', startTime: '07:00', endTime: '07:45',
});

export default function ScheduleManagement() {
  const [classes, setClasses] = useState([]);
  const [teachers, setTeachers] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [schedules, setSchedules] = useState([]);
  const [filter, setFilter] = useState({ schoolYear: '2026-2027', semester: 1, classId: '' });
  const [form, setForm] = useState(blankForm());
  const [editingId, setEditingId] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const activeClasses = useMemo(() => classes.filter((item) => item.status === 'ACTIVE'), [classes]);
  const selectedClass = activeClasses.find((item) => String(item.id) === String(filter.classId));

  const loadOptions = async () => {
    const [classRes, teacherRes, subjectRes] = await Promise.all([
      adminClassApi.getClasses(), adminClassApi.getTeachers(), adminScheduleApi.getSubjects(),
    ]);
    const classData = unwrap(classRes);
    setClasses(classData);
    setTeachers(unwrap(teacherRes));
    setSubjects(unwrap(subjectRes));
    if (!filter.classId && classData.length) {
      const first = classData.find((item) => item.status === 'ACTIVE');
      if (first) setFilter((current) => ({ ...current, classId: String(first.id), schoolYear: first.schoolYear }));
    }
  };

  const loadSchedules = async () => {
    if (!filter.classId) { setSchedules([]); return; }
    setLoading(true); setError('');
    try {
      const response = await adminScheduleApi.getSchedules({
        schoolYear: filter.schoolYear, semester: Number(filter.semester), classId: Number(filter.classId),
      });
      setSchedules(unwrap(response));
    } catch (requestError) {
      setError(messageOf(requestError, 'Không tải được thời khóa biểu'));
    } finally { setLoading(false); }
  };

  useEffect(() => {
    loadOptions().catch((requestError) => setError(messageOf(requestError, 'Không tải được dữ liệu lựa chọn')));
  }, []);
  useEffect(() => { loadSchedules(); }, [filter.classId, filter.schoolYear, filter.semester]);

  const openCreate = (dayOfWeek = 2, period = 1) => {
    setEditingId(null);
    setForm({ ...blankForm(filter.schoolYear), classId: filter.classId, semester: Number(filter.semester), dayOfWeek, period });
    setShowForm(true); setError('');
  };

  const openEdit = (item) => {
    setEditingId(item.id);
    setForm({
      classId: String(item.classId), subjectId: String(item.subjectId), teacherId: String(item.teacherId),
      dayOfWeek: item.dayOfWeek, period: item.period, semester: item.semester,
      schoolYear: item.schoolYear, room: item.room || '', startTime: item.startTime || '', endTime: item.endTime || '',
    });
    setShowForm(true); setError('');
  };

  const save = async (event) => {
    event.preventDefault(); setSaving(true); setError('');
    const payload = {
      ...form, classId: Number(form.classId), subjectId: Number(form.subjectId), teacherId: Number(form.teacherId),
      dayOfWeek: Number(form.dayOfWeek), period: Number(form.period), semester: Number(form.semester),
    };
    try {
      if (editingId) await adminScheduleApi.updateSchedule(editingId, payload);
      else await adminScheduleApi.createSchedule(payload);
      setSuccess(editingId ? 'Cập nhật tiết học thành công' : 'Xếp tiết học thành công');
      setShowForm(false); setEditingId(null); await loadSchedules();
      window.setTimeout(() => setSuccess(''), 2500);
    } catch (requestError) { setError(messageOf(requestError, 'Không thể lưu tiết học')); }
    finally { setSaving(false); }
  };

  const remove = async (item) => {
    if (!window.confirm(`Xóa ${item.subjectName} - ${item.classCode}, thứ ${item.dayOfWeek}, tiết ${item.period}?`)) return;
    try { await adminScheduleApi.deleteSchedule(item.id); await loadSchedules(); }
    catch (requestError) { setError(messageOf(requestError, 'Không thể xóa tiết học')); }
  };

  const slot = (day, period) => schedules.find((item) => item.dayOfWeek === day && item.period === period);

  return (
    <div className="schedule-page fade-in">
      <div className="schedule-heading">
        <div><h2><CalendarDays size={26} /> Xếp Thời khóa biểu</h2><p>Quản trị viên xếp lịch; giáo viên chỉ xem lịch được giao.</p></div>
        <button className="primary-btn" onClick={() => openCreate()}><Plus size={18} /> Thêm tiết học</button>
      </div>

      {error && <div className="schedule-alert error">{error}</div>}
      {success && <div className="schedule-alert success">{success}</div>}

      <div className="schedule-filters">
        <label>Lớp<select value={filter.classId} onChange={(e) => {
          const item = activeClasses.find((c) => String(c.id) === e.target.value);
          setFilter((current) => ({ ...current, classId: e.target.value, schoolYear: item?.schoolYear || current.schoolYear }));
        }}><option value="">Chọn lớp</option>{activeClasses.map((item) => <option key={item.id} value={item.id}>{item.code} - {item.schoolYear}</option>)}</select></label>
        <label>Năm học<input value={filter.schoolYear} onChange={(e) => setFilter({ ...filter, schoolYear: e.target.value })} /></label>
        <label>Học kỳ<select value={filter.semester} onChange={(e) => setFilter({ ...filter, semester: Number(e.target.value) })}><option value={1}>Học kỳ 1</option><option value={2}>Học kỳ 2</option></select></label>
      </div>

      <div className="schedule-summary">Đang xem: <strong>{selectedClass?.code || 'Chưa chọn lớp'}</strong> · {filter.schoolYear} · Học kỳ {filter.semester}</div>

      <div className="schedule-grid-wrap">
        {loading ? <div className="schedule-empty">Đang tải...</div> : (
          <table className="schedule-grid"><thead><tr><th>Tiết</th>{DAYS.map((day) => <th key={day.value}>{day.label}</th>)}</tr></thead>
            <tbody>{PERIODS.map((period) => <tr key={period}><th>Tiết {period}</th>{DAYS.map((day) => {
              const item = slot(day.value, period);
              return <td key={day.value}>{item ? <div className="schedule-card">
                <strong>{item.subjectName}</strong><span>{item.teacherName}</span><small>{item.room || 'Chưa có phòng'} {item.startTime ? `· ${item.startTime}-${item.endTime}` : ''}</small>
                <div className="schedule-actions"><button onClick={() => openEdit(item)} title="Sửa"><Pencil size={15}/></button><button onClick={() => remove(item)} title="Xóa"><Trash2 size={15}/></button></div>
              </div> : <button className="empty-slot" onClick={() => openCreate(day.value, period)}>+</button>}</td>;
            })}</tr>)}</tbody></table>
        )}
      </div>

      {showForm && <div className="schedule-modal-backdrop"><div className="schedule-modal">
        <div className="modal-title"><h3>{editingId ? 'Sửa tiết học' : 'Xếp tiết học mới'}</h3><button onClick={() => setShowForm(false)}><X /></button></div>
        <form onSubmit={save} className="schedule-form">
          <label>Lớp<select required value={form.classId} onChange={(e) => {
            const item = activeClasses.find((c) => String(c.id) === e.target.value);
            setForm({ ...form, classId: e.target.value, schoolYear: item?.schoolYear || form.schoolYear });
          }}>{activeClasses.map((item) => <option key={item.id} value={item.id}>{item.code}</option>)}</select></label>
          <label>Môn học<select required value={form.subjectId} onChange={(e) => setForm({ ...form, subjectId: e.target.value })}><option value="">Chọn môn</option>{subjects.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
          <label>Giáo viên<select required value={form.teacherId} onChange={(e) => setForm({ ...form, teacherId: e.target.value })}><option value="">Chọn giáo viên</option>{teachers.map((item) => <option key={item.id} value={item.id}>{item.name}{item.subject ? ` - ${item.subject}` : ''}</option>)}</select></label>
          <div className="form-row"><label>Ngày<select value={form.dayOfWeek} onChange={(e) => setForm({ ...form, dayOfWeek: Number(e.target.value) })}>{DAYS.map((day) => <option key={day.value} value={day.value}>{day.label}</option>)}</select></label><label>Tiết<select value={form.period} onChange={(e) => setForm({ ...form, period: Number(e.target.value) })}>{PERIODS.map((p) => <option key={p} value={p}>Tiết {p}</option>)}</select></label></div>
          <div className="form-row"><label>Phòng<input value={form.room} onChange={(e) => setForm({ ...form, room: e.target.value })} placeholder="A101" /></label><label>Học kỳ<select value={form.semester} onChange={(e) => setForm({ ...form, semester: Number(e.target.value) })}><option value={1}>1</option><option value={2}>2</option></select></label></div>
          <div className="form-row"><label>Bắt đầu<input type="time" value={form.startTime} onChange={(e) => setForm({ ...form, startTime: e.target.value })}/></label><label>Kết thúc<input type="time" value={form.endTime} onChange={(e) => setForm({ ...form, endTime: e.target.value })}/></label></div>
          <label>Năm học<input required pattern="\d{4}-\d{4}" value={form.schoolYear} onChange={(e) => setForm({ ...form, schoolYear: e.target.value })}/></label>
          <button className="primary-btn submit" disabled={saving}>{saving ? 'Đang lưu...' : 'Lưu tiết học'}</button>
        </form>
      </div></div>}
    </div>
  );
}
