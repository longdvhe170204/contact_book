import api from './api';

export const adminNotificationApi = {
  getAllNotifications: () => api.get('/notifications'),
  createNotification: (notification) => api.post('/notifications', notification),
  deleteNotification: (id) => api.delete(`/notifications/${id}`),
};
