import { useEffect, useMemo, useState } from 'react';
import {
  CalendarDays,
  Pencil,
  Plus,
  Trash2,
  X,
} from 'lucide-react';

import { adminClassApi } from '../../services/adminClassApi';
import { adminScheduleApi } from '../../services/adminScheduleApi';

import './ScheduleManagement.css';

const DEFAULT_SCHOOL_YEAR = '2026-2027';

const DAYS = [
  { value: 0, label: 'Thứ 2' },
  { value: 1, label: 'Thứ 3' },
  { value: 2, label: 'Thứ 4' },
  { value: 3, label: 'Thứ 5' },
  { value: 4, label: 'Thứ 6' },
  { value: 5, label: 'Thứ 7' },
  { value: 6, label: 'Chủ nhật' },
];

/*
 * period sử dụng String để đồng bộ với backend:
 * "1", "2", ..., "10".
 */
const PERIODS = Array.from(
    { length: 10 },
    (_, index) => String(index + 1),
);

const unwrap = (response) =>
    response?.data?.data ?? response?.data ?? [];

const messageOf = (error, fallback) =>
    error?.response?.data?.message
    || error?.response?.data?.error
    || fallback;

const createBlankForm = (
    schoolYear = DEFAULT_SCHOOL_YEAR,
) => ({
  classId: '',
  subjectId: '',
  teacherId: '',
  dayOfWeek: 0,
  period: '1',
  semester: 1,
  schoolYear,
  room: '',
});

export default function ScheduleManagement() {
  const [classes, setClasses] = useState([]);
  const [teachers, setTeachers] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [schedules, setSchedules] = useState([]);

  const [filter, setFilter] = useState({
    schoolYear: DEFAULT_SCHOOL_YEAR,
    semester: 1,
    classId: '',
  });

  const [form, setForm] = useState(
      createBlankForm(),
  );

  const [editingId, setEditingId] = useState(null);
  const [showForm, setShowForm] = useState(false);

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const activeClasses = useMemo(
      () =>
          classes.filter(
              (item) => item.status === 'ACTIVE',
          ),
      [classes],
  );

  const selectedClass = useMemo(
      () =>
          activeClasses.find(
              (item) =>
                  String(item.id) === String(filter.classId),
          ),
      [activeClasses, filter.classId],
  );

  const getDayLabel = (dayOfWeek) =>
      DAYS.find(
          (day) =>
              Number(day.value) === Number(dayOfWeek),
      )?.label ?? `Ngày ${dayOfWeek}`;

  const loadOptions = async () => {
    try {
      const [
        classResponse,
        teacherResponse,
        subjectResponse,
      ] = await Promise.all([
        adminClassApi.getClasses(),
        adminClassApi.getTeachers(),
        adminScheduleApi.getSubjects(),
      ]);

      const classData = unwrap(classResponse);
      const teacherData = unwrap(teacherResponse);
      const subjectData = unwrap(subjectResponse);

      setClasses(
          Array.isArray(classData) ? classData : [],
      );

      setTeachers(
          Array.isArray(teacherData)
              ? teacherData
              : [],
      );

      setSubjects(
          Array.isArray(subjectData)
              ? subjectData
              : [],
      );

      const firstActiveClass = classData.find(
          (item) => item.status === 'ACTIVE',
      );

      if (firstActiveClass) {
        setFilter((current) => {
          if (current.classId) {
            return current;
          }

          return {
            ...current,
            classId: String(firstActiveClass.id),
            schoolYear:
                firstActiveClass.schoolYear
                || current.schoolYear,
          };
        });
      }
    } catch (requestError) {
      setError(
          messageOf(
              requestError,
              'Không tải được dữ liệu lựa chọn',
          ),
      );
    }
  };

  const loadSchedules = async () => {
    if (!filter.classId) {
      setSchedules([]);
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response =
          await adminScheduleApi.getSchedules({
            schoolYear: filter.schoolYear.trim(),
            semester: Number(filter.semester),
            classId: Number(filter.classId),
          });

      const data = unwrap(response);

      setSchedules(
          Array.isArray(data) ? data : [],
      );
    } catch (requestError) {
      setError(
          messageOf(
              requestError,
              'Không tải được thời khóa biểu',
          ),
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadOptions();
  }, []);

  useEffect(() => {
    loadSchedules();
  }, [
    filter.classId,
    filter.schoolYear,
    filter.semester,
  ]);

  const openCreate = (
      dayOfWeek = 0,
      period = '1',
  ) => {
    setEditingId(null);

    setForm({
      ...createBlankForm(filter.schoolYear),
      classId: String(filter.classId || ''),
      semester: Number(filter.semester),
      dayOfWeek: Number(dayOfWeek),
      period: String(period),
    });

    setError('');
    setSuccess('');
    setShowForm(true);
  };

  const openEdit = (item) => {
    setEditingId(item.id);

    setForm({
      classId: String(item.classId ?? ''),
      subjectId: String(item.subjectId ?? ''),
      teacherId: String(item.teacherId ?? ''),
      dayOfWeek: Number(item.dayOfWeek ?? 0),
      period: String(item.period ?? '1'),
      semester: Number(item.semester ?? 1),
      schoolYear:
          item.schoolYear
          || filter.schoolYear
          || DEFAULT_SCHOOL_YEAR,
      room: item.room ?? '',
    });

    setError('');
    setSuccess('');
    setShowForm(true);
  };

  const closeForm = () => {
    if (saving) {
      return;
    }

    setShowForm(false);
    setEditingId(null);
    setError('');
  };

  const save = async (event) => {
    event.preventDefault();

    setSaving(true);
    setError('');
    setSuccess('');

    const payload = {
      classId: Number(form.classId),
      subjectId: Number(form.subjectId),
      teacherId: Number(form.teacherId),
      dayOfWeek: Number(form.dayOfWeek),

      /*
       * Không chuyển period sang Number.
       * Backend nhận String.
       */
      period: String(form.period),

      semester: Number(form.semester),
      schoolYear: form.schoolYear.trim(),
      room: form.room.trim(),
    };

    try {
      if (editingId !== null) {
        await adminScheduleApi.updateSchedule(
            editingId,
            payload,
        );
      } else {
        await adminScheduleApi.createSchedule(
            payload,
        );
      }

      setSuccess(
          editingId !== null
              ? 'Cập nhật tiết học thành công'
              : 'Xếp tiết học thành công',
      );

      setShowForm(false);
      setEditingId(null);

      await loadSchedules();

      window.setTimeout(() => {
        setSuccess('');
      }, 2500);
    } catch (requestError) {
      setError(
          messageOf(
              requestError,
              'Không thể lưu tiết học',
          ),
      );
    } finally {
      setSaving(false);
    }
  };

  const remove = async (item) => {
    const confirmed = window.confirm(
        `Bạn có chắc muốn xóa ${
            item.subjectName || item.subject || 'môn học'
        } - ${
            item.classCode || item.className || ''
        }, ${getDayLabel(item.dayOfWeek)}, tiết ${
            item.period
        }?`,
    );

    if (!confirmed) {
      return;
    }

    setError('');
    setSuccess('');

    try {
      await adminScheduleApi.deleteSchedule(
          item.id,
      );

      setSuccess('Xóa tiết học thành công');

      await loadSchedules();

      window.setTimeout(() => {
        setSuccess('');
      }, 2500);
    } catch (requestError) {
      setError(
          messageOf(
              requestError,
              'Không thể xóa tiết học',
          ),
      );
    }
  };

  /*
   * String(...) giúp tương thích cả dữ liệu mới dạng "1"
   * và dữ liệu API cũ dạng 1.
   */
  const findScheduleSlot = (
      dayOfWeek,
      period,
  ) =>
      schedules.find(
          (item) =>
              Number(item.dayOfWeek)
              === Number(dayOfWeek)
              && String(item.period)
              === String(period),
      );

  return (
      <div className="schedule-page fade-in">
        <div className="schedule-heading">
          <div>
            <h2>
              <CalendarDays size={26} />
              Xếp Thời khóa biểu
            </h2>

            <p>
              Quản trị viên xếp lịch; giáo viên
              chỉ xem lịch được giao.
            </p>
          </div>

          <button
              type="button"
              className="primary-btn"
              onClick={() => openCreate()}
              disabled={!filter.classId}
          >
            <Plus size={18} />
            Thêm tiết học
          </button>
        </div>

        {error && (
            <div className="schedule-alert error">
              {error}
            </div>
        )}

        {success && (
            <div className="schedule-alert success">
              {success}
            </div>
        )}

        <div className="schedule-filters">
          <label>
            Lớp

            <select
                value={filter.classId}
                onChange={(event) => {
                  const classId = event.target.value;

                  const selected =
                      activeClasses.find(
                          (item) =>
                              String(item.id) === classId,
                      );

                  setFilter((current) => ({
                    ...current,
                    classId,
                    schoolYear:
                        selected?.schoolYear
                        || current.schoolYear,
                  }));
                }}
            >
              <option value="">
                Chọn lớp
              </option>

              {activeClasses.map((item) => (
                  <option
                      key={item.id}
                      value={String(item.id)}
                  >
                    {item.code}
                    {item.schoolYear
                        ? ` - ${item.schoolYear}`
                        : ''}
                  </option>
              ))}
            </select>
          </label>

          <label>
            Năm học

            <input
                value={filter.schoolYear}
                pattern="\d{4}-\d{4}"
                placeholder="2026-2027"
                onChange={(event) =>
                    setFilter((current) => ({
                      ...current,
                      schoolYear: event.target.value,
                    }))
                }
            />
          </label>

          <label>
            Học kỳ

            <select
                value={filter.semester}
                onChange={(event) =>
                    setFilter((current) => ({
                      ...current,
                      semester: Number(
                          event.target.value,
                      ),
                    }))
                }
            >
              <option value={1}>
                Học kỳ 1
              </option>

              <option value={2}>
                Học kỳ 2
              </option>
            </select>
          </label>
        </div>

        <div className="schedule-summary">
          Đang xem:{' '}
          <strong>
            {selectedClass?.code
                || 'Chưa chọn lớp'}
          </strong>
          {' · '}
          {filter.schoolYear}
          {' · '}
          Học kỳ {filter.semester}
        </div>

        <div className="schedule-grid-wrap">
          {loading ? (
              <div className="schedule-empty">
                Đang tải...
              </div>
          ) : !filter.classId ? (
              <div className="schedule-empty">
                Vui lòng chọn lớp học
              </div>
          ) : (
              <table className="schedule-grid">
                <thead>
                <tr>
                  <th>Tiết</th>

                  {DAYS.map((day) => (
                      <th key={day.value}>
                        {day.label}
                      </th>
                  ))}
                </tr>
                </thead>

                <tbody>
                {PERIODS.map((period) => (
                    <tr key={period}>
                      <th>Tiết {period}</th>

                      {DAYS.map((day) => {
                        const item =
                            findScheduleSlot(
                                day.value,
                                period,
                            );

                        return (
                            <td key={day.value}>
                              {item ? (
                                  <div className="schedule-card">
                                    <strong>
                                      {item.subjectName
                                          || item.subject}
                                    </strong>

                                    <span>
                              {item.teacherName
                                  || item.teacher}
                            </span>

                                    <small>
                                      {item.room
                                          || 'Chưa có phòng'}

                                      {item.startTime
                                          ? ` · ${item.startTime}-${item.endTime}`
                                          : ''}
                                    </small>

                                    <div className="schedule-actions">
                                      <button
                                          type="button"
                                          onClick={() =>
                                              openEdit(item)
                                          }
                                          title="Sửa"
                                      >
                                        <Pencil size={15} />
                                      </button>

                                      <button
                                          type="button"
                                          onClick={() =>
                                              remove(item)
                                          }
                                          title="Xóa"
                                      >
                                        <Trash2 size={15} />
                                      </button>
                                    </div>
                                  </div>
                              ) : (
                                  <button
                                      type="button"
                                      className="empty-slot"
                                      onClick={() =>
                                          openCreate(
                                              day.value,
                                              period,
                                          )
                                      }
                                      title={`Thêm ${day.label}, tiết ${period}`}
                                  >
                                    +
                                  </button>
                              )}
                            </td>
                        );
                      })}
                    </tr>
                ))}
                </tbody>
              </table>
          )}
        </div>

        {showForm && (
            <div className="schedule-modal-backdrop">
              <div className="schedule-modal">
                <div className="modal-title">
                  <h3>
                    {editingId !== null
                        ? 'Sửa tiết học'
                        : 'Xếp tiết học mới'}
                  </h3>

                  <button
                      type="button"
                      onClick={closeForm}
                      disabled={saving}
                      title="Đóng"
                  >
                    <X />
                  </button>
                </div>

                <form
                    onSubmit={save}
                    className="schedule-form"
                >
                  <label>
                    Lớp

                    <select
                        required
                        value={form.classId}
                        onChange={(event) => {
                          const classId =
                              event.target.value;

                          const selected =
                              activeClasses.find(
                                  (item) =>
                                      String(item.id)
                                      === classId,
                              );

                          setForm((current) => ({
                            ...current,
                            classId,
                            schoolYear:
                                selected?.schoolYear
                                || current.schoolYear,
                          }));
                        }}
                    >
                      <option value="">
                        Chọn lớp
                      </option>

                      {activeClasses.map((item) => (
                          <option
                              key={item.id}
                              value={String(item.id)}
                          >
                            {item.code}
                          </option>
                      ))}
                    </select>
                  </label>

                  <label>
                    Môn học

                    <select
                        required
                        value={form.subjectId}
                        onChange={(event) =>
                            setForm((current) => ({
                              ...current,
                              subjectId:
                              event.target.value,
                            }))
                        }
                    >
                      <option value="">
                        Chọn môn
                      </option>

                      {subjects.map((item) => (
                          <option
                              key={item.id}
                              value={String(item.id)}
                          >
                            {item.name}
                          </option>
                      ))}
                    </select>
                  </label>

                  <label>
                    Giáo viên

                    <select
                        required
                        value={form.teacherId}
                        onChange={(event) =>
                            setForm((current) => ({
                              ...current,
                              teacherId:
                              event.target.value,
                            }))
                        }
                    >
                      <option value="">
                        Chọn giáo viên
                      </option>

                      {teachers.map((item) => (
                          <option
                              key={item.id}
                              value={String(item.id)}
                          >
                            {item.name}
                            {item.subject
                                ? ` - ${item.subject}`
                                : ''}
                          </option>
                      ))}
                    </select>
                  </label>

                  <div className="form-row">
                    <label>
                      Ngày

                      <select
                          value={form.dayOfWeek}
                          onChange={(event) =>
                              setForm((current) => ({
                                ...current,
                                dayOfWeek: Number(
                                    event.target.value,
                                ),
                              }))
                          }
                      >
                        {DAYS.map((day) => (
                            <option
                                key={day.value}
                                value={day.value}
                            >
                              {day.label}
                            </option>
                        ))}
                      </select>
                    </label>

                    <label>
                      Tiết

                      <select
                          value={form.period}
                          onChange={(event) =>
                              setForm((current) => ({
                                ...current,

                                // Giữ period là String.
                                period:
                                event.target.value,
                              }))
                          }
                      >
                        {PERIODS.map((period) => (
                            <option
                                key={period}
                                value={period}
                            >
                              Tiết {period}
                            </option>
                        ))}
                      </select>
                    </label>
                  </div>

                  <div className="form-row">
                    <label>
                      Phòng

                      <input
                          value={form.room}
                          onChange={(event) =>
                              setForm((current) => ({
                                ...current,
                                room: event.target.value,
                              }))
                          }
                          placeholder="A101"
                      />
                    </label>

                    <label>
                      Học kỳ

                      <select
                          value={form.semester}
                          onChange={(event) =>
                              setForm((current) => ({
                                ...current,
                                semester: Number(
                                    event.target.value,
                                ),
                              }))
                          }
                      >
                        <option value={1}>1</option>
                        <option value={2}>2</option>
                      </select>
                    </label>
                  </div>

                  <label>
                    Năm học

                    <input
                        required
                        pattern="\d{4}-\d{4}"
                        title="Năm học phải có dạng 2026-2027"
                        value={form.schoolYear}
                        onChange={(event) =>
                            setForm((current) => ({
                              ...current,
                              schoolYear:
                              event.target.value,
                            }))
                        }
                        placeholder="2026-2027"
                    />
                  </label>

                  <button
                      type="submit"
                      className="primary-btn submit"
                      disabled={saving}
                  >
                    {saving
                        ? 'Đang lưu...'
                        : 'Lưu tiết học'}
                  </button>
                </form>
              </div>
            </div>
        )}
      </div>
  );
}