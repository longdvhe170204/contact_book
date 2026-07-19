import React, { useState, useEffect } from 'react';
import { Users, Plus, Edit, Trash2 } from 'lucide-react';
import { DataGrid } from '@mui/x-data-grid';
import { Dialog, DialogTitle, DialogContent, DialogActions, Button, TextField, IconButton } from '@mui/material';
import { adminTeacherApi } from '../services/adminTeacherApi';

const Teachers = () => {
  const [teachers, setTeachers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openModal, setOpenModal] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentTeacher, setCurrentTeacher] = useState({
    name: '',
    phoneNumber: '',
    subject: '',
    employeeCode: '',
    address: ''
  });

  const fetchTeachers = async () => {
    try {
      setLoading(true);
      const res = await adminTeacherApi.getAllTeachers();
      if (res.data.success) {
        setTeachers(res.data.data);
      }
    } catch (error) {
      console.error('Error fetching teachers', error);
      alert('Lỗi khi tải danh sách giáo viên');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTeachers();
  }, []);

  const handleOpenModal = (teacher = null) => {
    if (teacher) {
      setEditMode(true);
      setCurrentTeacher(teacher);
    } else {
      setEditMode(false);
      setCurrentTeacher({
        name: '',
        phoneNumber: '',
        subject: '',
        employeeCode: '',
        address: ''
      });
    }
    setOpenModal(true);
  };

  const handleCloseModal = () => {
    setOpenModal(false);
  };

  const handleChange = (e) => {
    setCurrentTeacher({
      ...currentTeacher,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async () => {
    try {
      if (editMode) {
        await adminTeacherApi.updateTeacher(currentTeacher.id, currentTeacher);
        alert('Cập nhật thành công');
      } else {
        await adminTeacherApi.addTeacher(currentTeacher);
        alert('Thêm giáo viên thành công');
      }
      handleCloseModal();
      fetchTeachers();
    } catch (error) {
      console.error('Error saving teacher', error);
      alert(error.response?.data?.message || 'Có lỗi xảy ra');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa giáo viên này?')) {
      try {
        await adminTeacherApi.deleteTeacher(id);
        alert('Xóa thành công');
        fetchTeachers();
      } catch (error) {
        console.error('Error deleting teacher', error);
        alert('Lỗi khi xóa giáo viên');
      }
    }
  };

  const columns = [
    { field: 'id', headerName: 'ID', width: 70 },
    { field: 'name', headerName: 'Họ và Tên', flex: 1 },
    { field: 'phoneNumber', headerName: 'Số điện thoại', flex: 1 },
    { field: 'employeeCode', headerName: 'Mã NV', flex: 1 },
    { field: 'subject', headerName: 'Bộ môn', flex: 1 },
    {
      field: 'actions',
      headerName: 'Hành động',
      width: 150,
      renderCell: (params) => (
        <div>
          <IconButton color="primary" onClick={() => handleOpenModal(params.row)}>
            <Edit size={18} />
          </IconButton>
          <IconButton color="error" onClick={() => handleDelete(params.row.id)}>
            <Trash2 size={18} />
          </IconButton>
        </div>
      ),
    },
  ];

  return (
    <div className="page-container">
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '20px' }}>
        <h2><Users className="inline-icon" /> Quản lý Giáo viên</h2>
        <button 
          onClick={() => handleOpenModal()}
          style={{
            display: 'flex', alignItems: 'center', gap: '8px', 
            backgroundColor: 'var(--primary)', color: 'white', 
            border: 'none', padding: '10px 16px', borderRadius: '8px', cursor: 'pointer'
        }}>
          <Plus size={18} /> Thêm Giáo viên
        </button>
      </div>
      
      <div className="card glass" style={{ height: 600, width: '100%', backgroundColor: 'white' }}>
        <DataGrid
          rows={teachers}
          columns={columns}
          pageSizeOptions={[10, 25, 50]}
          initialState={{
            pagination: { paginationModel: { pageSize: 10 } },
          }}
          loading={loading}
          disableRowSelectionOnClick
        />
      </div>

      <Dialog open={openModal} onClose={handleCloseModal} maxWidth="sm" fullWidth>
        <DialogTitle>{editMode ? 'Sửa thông tin Giáo viên' : 'Thêm Giáo viên mới'}</DialogTitle>
        <DialogContent dividers>
          <TextField
            autoFocus
            margin="dense"
            name="name"
            label="Họ và Tên"
            type="text"
            fullWidth
            variant="outlined"
            value={currentTeacher.name}
            onChange={handleChange}
            required
          />
          <TextField
            margin="dense"
            name="phoneNumber"
            label="Số điện thoại"
            type="text"
            fullWidth
            variant="outlined"
            value={currentTeacher.phoneNumber}
            onChange={handleChange}
            required
          />
          <TextField
            margin="dense"
            name="employeeCode"
            label="Mã nhân viên"
            type="text"
            fullWidth
            variant="outlined"
            value={currentTeacher.employeeCode}
            onChange={handleChange}
          />
          <TextField
            margin="dense"
            name="subject"
            label="Bộ môn"
            type="text"
            fullWidth
            variant="outlined"
            value={currentTeacher.subject}
            onChange={handleChange}
          />
          <TextField
            margin="dense"
            name="address"
            label="Địa chỉ"
            type="text"
            fullWidth
            variant="outlined"
            value={currentTeacher.address}
            onChange={handleChange}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseModal} color="inherit">Hủy</Button>
          <Button onClick={handleSubmit} variant="contained" color="primary">
            Lưu
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default Teachers;
