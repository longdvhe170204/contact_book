import api from './api';

export const adminClassApi = {
  getClasses: () => api.get('/admin/classes'),
  getClass: (classId) => api.get(`/admin/classes/${classId}`),
  createClass: (payload) => api.post('/admin/classes', payload),
  updateClass: (classId, payload) => api.put(`/admin/classes/${classId}`, payload),
  closeClass: (classId) => api.post(`/admin/classes/${classId}/close`),
  assignHomeroomTeacher: (classId, teacherId) =>
      api.put(`/admin/classes/${classId}/homeroom-teacher`, { teacherId }),
  removeHomeroomTeacher: (classId) =>
      api.delete(`/admin/classes/${classId}/homeroom-teacher`),
  getStudents: (classId) => api.get(`/admin/classes/${classId}/students`),
  getUnassignedStudents: (schoolYear) =>
      api.get('/admin/classes/unassigned-students', { params: { schoolYear } }),
  addStudents: (classId, payload) => api.post(`/admin/classes/${classId}/students`, payload),
  removeStudent: (classId, studentId, payload) =>
      api.post(`/admin/classes/${classId}/students/${studentId}/remove`, payload),
  transferStudent: (studentId, payload) => api.put(`/admin/students/${studentId}/class`, payload),
  getTeachers: () => api.get('/admin/teachers'),
};
