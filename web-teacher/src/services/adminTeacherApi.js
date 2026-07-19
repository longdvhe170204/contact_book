import api from './api';

export const adminTeacherApi = {
  getAllTeachers: () => api.get('/admin/teachers'),
  addTeacher: (teacher) => api.post('/admin/teachers', teacher),
  updateTeacher: (id, teacher) => api.put(`/admin/teachers/${id}`, teacher),
  deleteTeacher: (id) => api.delete(`/admin/teachers/${id}`),
};
