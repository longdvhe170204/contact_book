import { useState, useRef } from 'react';
import { 
  UploadCloud, 
  FileText, 
  CheckCircle, 
  AlertTriangle, 
  RefreshCw, 
  ArrowRight,
  Database
} from 'lucide-react';
import * as XLSX from 'xlsx';
import api from '../services/api';
import './ImportExcel.css';

// Mapping dictionary to normalize columns from Vietnamese spreadsheet headers
const HEADER_MAP = {
  name: ['họ tên', 'họ và tên', 'tên học sinh', 'tên', 'name', 'student name', 'ho ten', 'ho va ten'],
  phoneNumber: ['số điện thoại', 'sđt', 'điện thoại', 'phone number', 'phone', 'so dien thoai', 'sdt'],
  className: ['lớp', 'lớp học', 'class', 'classname', 'lop', 'lop hoc'],
  email: ['email', 'địa chỉ email', 'dia chi email'],
  dateOfBirth: ['ngày sinh', 'ngày tháng năm sinh', 'date of birth', 'dob', 'ngay sinh'],
  parentName: ['tên phụ huynh', 'họ tên phụ huynh', 'phụ huynh', 'parent name', 'parent', 'ten phu huynh'],
  parentPhone: ['sđt phụ huynh', 'số điện thoại phụ huynh', 'parent phone', 'sdt phu huynh'],
  address: ['địa chỉ', 'nơi ở', 'address', 'dia chi']
};

const findMappedKey = (header) => {
  const cleanHeader = header.trim().toLowerCase();
  for (const [key, aliases] of Object.entries(HEADER_MAP)) {
    if (aliases.includes(cleanHeader)) {
      return key;
    }
  }
  return null;
};

const ImportExcel = () => {
  const [dragActive, setDragActive] = useState(false);
  const [fileName, setFileName] = useState('');
  const [parsedStudents, setParsedStudents] = useState([]);
  const [previewStudents, setPreviewStudents] = useState([]); // First few rows for display
  const [importing, setImporting] = useState(false);
  const [progress, setProgress] = useState(0);
  const [summary, setSummary] = useState(null);
  const [errorMsg, setErrorMsg] = useState('');

  const fileInputRef = useRef(null);

  const handleDrag = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      processFile(e.dataTransfer.files[0]);
    }
  };

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      processFile(e.target.files[0]);
    }
  };

  const processFile = (file) => {
    setErrorMsg('');
    setSummary(null);
    setFileName(file.name);

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target.result);
        const workbook = XLSX.read(data, { type: 'array' });
        
        // Use first worksheet
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        
        // Convert to JSON
        const rawRows = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
        if (rawRows.length < 2) {
          setErrorMsg('File Excel trống hoặc không có dòng tiêu đề cột!');
          return;
        }

        const headers = rawRows[0];
        const rows = rawRows.slice(1);
        
        // Map headers to fields
        const columnIndices = {};
        headers.forEach((header, index) => {
          if (header) {
            const mappedKey = findMappedKey(header.toString());
            if (mappedKey) {
              columnIndices[mappedKey] = index;
            }
          }
        });

        // Check required fields
        if (columnIndices.name === undefined || columnIndices.phoneNumber === undefined || columnIndices.className === undefined) {
          setErrorMsg('Thiếu các tiêu đề cột bắt buộc trong Excel! Cột cần có: "Họ tên", "Số điện thoại", "Lớp".');
          return;
        }

        // Parse rows
        const students = [];
        rows.forEach((row, idx) => {
          // Skip empty rows
          if (row.length === 0 || !row[columnIndices.name]) return;

          const getVal = (field) => {
            const index = columnIndices[field];
            if (index === undefined || row[index] === undefined) return '';
            return row[index].toString().trim();
          };

          // Format Date of Birth if it is an Excel serialized date
          let dob = getVal('dateOfBirth');
          if (dob && !isNaN(dob) && dob.length > 5) {
            // Excel dates are floating numbers, but sometimes it is parsed as string number
            try {
              const serialDate = parseFloat(dob);
              const dateObj = XLSX.SSF.parse_date_code(serialDate);
              if (dateObj) {
                const month = dateObj.m < 10 ? `0${dateObj.m}` : dateObj.m;
                const day = dateObj.d < 10 ? `0${dateObj.d}` : dateObj.d;
                dob = `${dateObj.y}-${month}-${day}`;
              }
            } catch (err) {
              // Ignore conversion and keep raw
            }
          } else if (dob) {
            // Standardize format dd/MM/yyyy to yyyy-MM-dd
            const parts = dob.split(/[/-]/);
            if (parts.length === 3) {
              if (parts[2].length === 4) { // dd/MM/yyyy
                dob = `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
              } else if (parts[0].length === 4) { // yyyy-MM-dd
                dob = `${parts[0]}-${parts[1].padStart(2, '0')}-${parts[2].padStart(2, '0')}`;
              }
            }
          }

          // Phone Number normalization: remove spaces, dots, dashes
          let phone = getVal('phoneNumber').replace(/[\s.-]/g, '');
          if (phone && phone.startsWith('84')) {
            phone = '0' + phone.substring(2);
          }

          students.push({
            name: getVal('name'),
            phoneNumber: phone,
            className: getVal('className'),
            email: getVal('email') || `${phone}@fschool.edu.vn`,
            dateOfBirth: dob || '2008-01-01',
            parentName: getVal('parentName') || `Phụ huynh ${getVal('name')}`,
            parentPhone: getVal('parentPhone') || '0900000000',
            address: getVal('address') || 'Hà Nội, Việt Nam'
          });
        });

        if (students.length === 0) {
          setErrorMsg('Không tìm thấy bản ghi học sinh hợp lệ nào trong file Excel!');
          return;
        }

        setParsedStudents(students);
        setPreviewStudents(students.slice(0, 15)); // Show first 15 rows for preview
      } catch (err) {
        console.error(err);
        setErrorMsg('Lỗi khi đọc file Excel. Vui lòng kiểm tra lại định dạng file!');
      }
    };
    reader.readAsArrayBuffer(file);
  };

  const handleStartImport = async () => {
    setImporting(true);
    setProgress(15);
    
    try {
      setProgress(40);
      const response = await api.post('/admin/students/import', parsedStudents);
      setProgress(85);
      
      if (response.data && response.data.success) {
        setSummary(response.data.data);
        setParsedStudents([]);
        setPreviewStudents([]);
        setFileName('');
      } else {
        setErrorMsg(response.data.message || 'Lỗi không xác định khi lưu vào CSDL.');
      }
    } catch (err) {
      console.error(err);
      setErrorMsg(err.response?.data?.message || 'Có lỗi xảy ra khi kết nối tới backend để import dữ liệu!');
    } finally {
      setProgress(100);
      setTimeout(() => {
        setImporting(false);
      }, 500);
    }
  };

  const resetUploader = () => {
    setFileName('');
    setParsedStudents([]);
    setPreviewStudents([]);
    setSummary(null);
    setErrorMsg('');
  };

  return (
    <div className="import-excel-container fade-in">
      <div className="import-header-section">
        <h2>Import Excel Học Sinh</h2>
        <p>Tạo nhanh hàng trăm tài khoản học sinh và phân bổ thẳng vào các lớp từ bảng tính Excel.</p>
      </div>

      <div className="import-grid">
        {/* Upload Zone */}
        {!parsedStudents.length && !summary && (
          <div className="card">
            <h3 className="card-title">Tải lên bảng tính</h3>
            <p className="card-description">Hỗ trợ các định dạng file .xlsx, .xls hoặc .csv.</p>
            
            <div 
              className={`upload-dropzone ${dragActive ? 'drag-active' : ''}`}
              onDragEnter={handleDrag}
              onDragOver={handleDrag}
              onDragLeave={handleDrag}
              onDrop={handleDrop}
            >
              <div className="upload-icon-circle">
                <UploadCloud size={32} />
              </div>
              <p className="upload-text">
                Kéo thả file vào đây hoặc <span>chọn từ máy tính</span>
              </p>
              <p className="card-description">Dung lượng tối đa 10MB</p>
              <input 
                type="file" 
                className="file-input" 
                accept=".xlsx, .xls, .csv"
                onChange={handleFileChange}
                ref={fileInputRef}
              />
            </div>

            <div className="template-info-box">
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 'bold', marginBottom: '8px' }}>
                <FileText size={16} color="var(--primary)" />
                <span>Yêu cầu cấu trúc cột tiêu đề trong file Excel:</span>
              </div>
              <p style={{ color: 'var(--text-muted)', fontSize: '0.825rem' }}>
                Các cột tiêu đề có thể viết hoa/thường hoặc có dấu tiếng Việt. Hệ thống sẽ tự động đối chiếu các từ khóa sau:
              </p>
              <div className="template-columns-list">
                <span className="column-tag required">Họ tên *</span>
                <span className="column-tag required">Số điện thoại *</span>
                <span className="column-tag required">Lớp *</span>
                <span className="column-tag">Email</span>
                <span className="column-tag">Ngày sinh</span>
                <span className="column-tag">Tên phụ huynh</span>
                <span className="column-tag">SĐT phụ huynh</span>
                <span className="column-tag">Địa chỉ</span>
              </div>
              <p style={{ marginTop: '12px', fontSize: '0.75rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                * Mật khẩu đăng nhập mặc định của tài khoản được tạo mới sẽ là: <strong>123456</strong>
              </p>
            </div>
          </div>
        )}

        {/* Error Alert */}
        {errorMsg && (
          <div className="card" style={{ borderLeft: '4px solid var(--error)', background: 'rgba(239, 68, 68, 0.05)' }}>
            <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
              <AlertTriangle color="var(--error)" size={24} style={{ flexShrink: 0 }} />
              <div>
                <h4 style={{ color: 'var(--error)', fontWeight: 700, marginBottom: '4px' }}>Phát hiện lỗi định dạng</h4>
                <p style={{ fontSize: '0.9rem', color: 'var(--text-main)' }}>{errorMsg}</p>
              </div>
            </div>
          </div>
        )}

        {/* Preview Container */}
        {parsedStudents.length > 0 && !importing && (
          <div className="card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h3 className="card-title">Xem trước dữ liệu Excel</h3>
                <p className="card-description">
                  Phát hiện <strong>{parsedStudents.length} học sinh</strong> trong file <strong>{fileName}</strong>. Vui lòng kiểm tra kỹ trước khi bấm lưu.
                </p>
              </div>
              <button className="btn btn-secondary" onClick={resetUploader}>
                <RefreshCw size={16} /> Chọn lại file
              </button>
            </div>

            <div className="preview-table-container">
              <table className="preview-table">
                <thead>
                  <tr>
                    <th>STT</th>
                    <th>Họ và Tên</th>
                    <th>Số điện thoại</th>
                    <th>Lớp học</th>
                    <th>Email</th>
                    <th>Ngày sinh</th>
                    <th>Phụ huynh</th>
                    <th>SĐT Phụ huynh</th>
                  </tr>
                </thead>
                <tbody>
                  {previewStudents.map((st, i) => {
                    const phoneValid = st.phoneNumber && st.phoneNumber.length === 10;
                    return (
                      <tr key={i}>
                        <td style={{ fontWeight: 'bold' }}>{i + 1}</td>
                        <td style={{ fontWeight: 600 }}>{st.name}</td>
                        <td className={phoneValid ? '' : 'cell-error'}>
                          {st.phoneNumber || <span className="cell-error">Trống</span>}
                        </td>
                        <td style={{ fontWeight: 'bold', color: 'var(--primary)' }}>{st.className}</td>
                        <td>{st.email}</td>
                        <td>{st.dateOfBirth}</td>
                        <td>{st.parentName}</td>
                        <td>{st.parentPhone}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {parsedStudents.length > 15 && (
              <p style={{ textAlign: 'center', fontSize: '0.85rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                Hiển thị tối đa 15 dòng đầu tiên xem trước. Còn lại {parsedStudents.length - 15} học sinh ẩn bên dưới.
              </p>
            )}

            <div className="button-row">
              <button className="btn btn-secondary" onClick={resetUploader}>
                Hủy bỏ
              </button>
              <button className="btn btn-primary" onClick={handleStartImport}>
                <Database size={18} /> Bắt đầu Import ({parsedStudents.length} học sinh) <ArrowRight size={16} />
              </button>
            </div>
          </div>
        )}

        {/* Importing Progress Bar */}
        {importing && (
          <div className="card">
            <h3 className="card-title" style={{ textAlign: 'center' }}>Đang nạp dữ liệu vào cơ sở dữ liệu...</h3>
            <div className="progress-box">
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', fontWeight: 600 }}>
                <span>Tiến trình xử lý tài khoản</span>
                <span>{progress}%</span>
              </div>
              <div className="progress-bar-bg">
                <div className="progress-bar-fill" style={{ width: `${progress}%` }}></div>
              </div>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', textAlign: 'center', fontStyle: 'italic' }}>
                Hệ thống đang mã hóa mật khẩu bảo mật BCrypt cho các học sinh, tạo các lớp học tương ứng và kiểm tra ràng buộc số điện thoại...
              </p>
            </div>
          </div>
        )}

        {/* Success Summary */}
        {summary && (
          <div className="card summary-box success">
            <div className="summary-header success">
              <CheckCircle size={28} />
              <span>Import dữ liệu học sinh thành công!</span>
            </div>
            
            <p style={{ fontSize: '0.95rem', color: 'var(--text-main)', marginBottom: '16px' }}>
              {summary.message}
            </p>

            <div className="summary-stats-list">
              <div className="summary-stat-item">
                <span className="summary-stat-val" style={{ color: 'var(--success)' }}>
                  {summary.importedCount}
                </span>
                <span className="summary-stat-lbl">Đã nhập thành công</span>
              </div>
              <div className="summary-stat-item">
                <span className="summary-stat-val" style={{ color: summary.skippedCount > 0 ? 'var(--warning)' : 'var(--text-muted)' }}>
                  {summary.skippedCount}
                </span>
                <span className="summary-stat-lbl">Bỏ qua (Bị trùng/Lỗi)</span>
              </div>
            </div>

            {summary.skippedCount > 0 && (
              <div className="skipped-list-box">
                <h4 className="skipped-list-title">Danh sách số điện thoại bị bỏ qua:</h4>
                <div className="skipped-items">
                  {summary.skippedPhones.map((ph, idx) => (
                    <span key={idx} className="skipped-item">
                      #{idx + 1}: {ph}
                    </span>
                  ))}
                </div>
              </div>
            )}

            <div className="button-row" style={{ borderTop: '1px solid var(--border)', paddingTop: '20px', marginTop: '10px' }}>
              <button className="btn btn-primary" onClick={resetUploader}>
                Tiếp tục Import File mới
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ImportExcel;
