import api from './api';

export const adminScheduleApi = {
  getSchedules: (params) => api.get('/admin/schedules', { params }),
  createSchedule: (payload) => api.post('/admin/schedules', payload),
  updateSchedule: (id, payload) => api.put(`/admin/schedules/${id}`, payload),
  deleteSchedule: (id) => api.delete(`/admin/schedules/${id}`),
  getSubjects: () => api.get('/admin/schedules/options/subjects'),
};
