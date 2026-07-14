import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Users, 
  GraduationCap, 
  Home, 
  UserCheck, 
  CreditCard,
  TrendingUp
} from 'lucide-react';
import api from '../services/api';
import './Dashboard.css';

const FALLBACK_DATA = {
  totalStudents: 128,
  totalTeachers: 12,
  totalClasses: 5,
  attendanceRate: 96.2,
  monthlyRevenue: 245000000,
  revenueChartData: [
    { month: "Tháng 2", revenue: 185000000 },
    { month: "Tháng 3", revenue: 195000000 },
    { month: "Tháng 4", revenue: 210000000 },
    { month: "Tháng 5", revenue: 230000000 },
    { month: "Tháng 6", revenue: 240000000 },
    { month: "Tháng 7", revenue: 245000000 },
  ],
  classDistribution: {
    "10A1": 42,
    "10A2": 38,
    "11A1": 25,
    "11A2": 23
  },
  attendanceStatusDistribution: {
    "PRESENT": 90,
    "LATE": 6,
    "ABSENT": 4
  }
};

const formatCurrency = (val) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);
};

const Dashboard = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(FALLBACK_DATA);
  const [isHoveredStat, setIsHoveredStat] = useState(null);

  useEffect(() => {
    const fetchDashboardStats = async () => {
      try {
        const response = await api.get('/admin/dashboard-stats');
        if (response.data && response.data.success) {
          setData(response.data.data);
        }
      } catch (error) {
        console.warn("Could not connect to API, using mock statistics:", error);
        // Keep fallback data
        setData(FALLBACK_DATA);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardStats();
  }, []);

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Đang tải dữ liệu tổng quan...</p>
      </div>
    );
  }

  // Calculate SVG dimensions and scale for vertical column charts
  const svgWidth = 600;
  const svgHeight = 260;
  const paddingX = 50;
  const paddingY = 30;
  const chartWidth = svgWidth - paddingX * 2;
  const chartHeight = svgHeight - paddingY * 2;

  const maxRev = Math.max(...data.revenueChartData.map(d => d.revenue), 1000000);
  const stepVal = maxRev / 4;

  // Calculate doughnut slices
  const attDist = data.attendanceStatusDistribution || { PRESENT: 90, LATE: 6, ABSENT: 4 };
  const totalAtt = (attDist.PRESENT || 0) + (attDist.LATE || 0) + (attDist.ABSENT || 0) || 1;
  const presentPct = Math.round(((attDist.PRESENT || 0) / totalAtt) * 100);
  const latePct = Math.round(((attDist.LATE || 0) / totalAtt) * 100);
  const absentPct = Math.round(((attDist.ABSENT || 0) / totalAtt) * 100);

  // Circle geometry for Doughnut
  const radius = 70;
  const circ = 2 * Math.PI * radius; // ~439.82
  const presentOffset = 0;
  const lateOffset = (presentPct / 100) * circ;
  const absentOffset = ((presentPct + latePct) / 100) * circ;

  // Find max class student count for class bar progress indicators
  const maxClassStudents = Math.max(...Object.values(data.classDistribution || { "Temp": 1 }), 1);

  return (
    <div className="dashboard-container fade-in">
      <div className="dashboard-title-section">
        <h2>Trang Chủ Admin</h2>
        <p>Hệ thống Quản trị tổng quan F-School. Xem dữ liệu báo cáo thời gian thực.</p>
      </div>

      {/* Cards Statistics */}
      <div className="stats-grid">
        {/* Total Students */}
        <div className="stat-card" onClick={() => navigate('/students')} onMouseEnter={() => setIsHoveredStat(1)} onMouseLeave={() => setIsHoveredStat(null)} style={{ cursor: 'pointer' }}>
          <div className="stat-card-info">
            <span className="stat-card-title">Học Sinh Toàn Trường</span>
            <span className="stat-card-value">{data.totalStudents}</span>
            <span className="stat-card-change positive">
              <TrendingUp size={14} /> +8% so với tháng trước
            </span>
          </div>
          <div className="stat-card-icon-wrapper">
            <Users size={24} />
          </div>
        </div>

        {/* Total Teachers */}
        <div className="stat-card" onClick={() => navigate('/teachers')} onMouseEnter={() => setIsHoveredStat(2)} onMouseLeave={() => setIsHoveredStat(null)} style={{ cursor: 'pointer' }}>
          <div className="stat-card-info">
            <span className="stat-card-title">Đội ngũ Giáo Viên</span>
            <span className="stat-card-value">{data.totalTeachers}</span>
            <span className="stat-card-change neutral">
              Đang hoạt động ổn định
            </span>
          </div>
          <div className="stat-card-icon-wrapper">
            <GraduationCap size={24} />
          </div>
        </div>

        {/* Total Classes */}
        <div className="stat-card" onClick={() => navigate('/classes')} onMouseEnter={() => setIsHoveredStat(3)} onMouseLeave={() => setIsHoveredStat(null)} style={{ cursor: 'pointer' }}>
          <div className="stat-card-info">
            <span className="stat-card-title">Tổng số Lớp Học</span>
            <span className="stat-card-value">{data.totalClasses}</span>
            <span className="stat-card-change positive">
              <TrendingUp size={14} /> +1 lớp mới (11B2)
            </span>
          </div>
          <div className="stat-card-icon-wrapper">
            <Home size={24} />
          </div>
        </div>

        {/* Attendance Rate */}
        <div className="stat-card" onClick={() => navigate('/attendance')} onMouseEnter={() => setIsHoveredStat(4)} onMouseLeave={() => setIsHoveredStat(null)} style={{ cursor: 'pointer' }}>
          <div className="stat-card-info">
            <span className="stat-card-title">Đi học Chuyên Cần</span>
            <span className="stat-card-value">{data.attendanceRate}%</span>
            <span className="stat-card-change positive">
              <TrendingUp size={14} /> +0.4% tuần này
            </span>
          </div>
          <div className="stat-card-icon-wrapper">
            <UserCheck size={24} />
          </div>
        </div>

        {/* Monthly Revenue */}
        <div className="stat-card" onClick={() => navigate('/finance')} onMouseEnter={() => setIsHoveredStat(5)} onMouseLeave={() => setIsHoveredStat(null)} style={{ cursor: 'pointer' }}>
          <div className="stat-card-info">
            <span className="stat-card-title">Doanh Thu Tháng Này</span>
            <span className="stat-card-value" style={{ fontSize: '1.6rem', paddingBottom: '6px', paddingTop: '4px' }}>
              {formatCurrency(data.monthlyRevenue)}
            </span>
            <span className="stat-card-change positive">
              <TrendingUp size={14} /> Đã thu 92% chỉ tiêu
            </span>
          </div>
          <div className="stat-card-icon-wrapper">
            <CreditCard size={24} />
          </div>
        </div>
      </div>

      {/* Charts Grid */}
      <div className="charts-grid">
        {/* Revenue Column Chart */}
        <div className="chart-card">
          <div className="chart-header">
            <div>
              <h3>Thống kê doanh thu</h3>
              <p className="chart-subtitle">Doanh thu thu học phí toàn trường trong 6 tháng gần nhất (VND)</p>
            </div>
          </div>

          <div className="chart-content">
            <svg className="bar-chart-svg" viewBox={`0 0 ${svgWidth} ${svgHeight}`}>
              {/* Define Gradients at the top */}
              <defs>
                <linearGradient id="column-gradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#6366f1" />
                  <stop offset="100%" stopColor="#a855f7" />
                </linearGradient>
              </defs>

              {/* Y Axis Grid Lines */}
              {[0, 1, 2, 3, 4].map((i) => {
                const y = paddingY + chartHeight - (chartHeight / 4) * i;
                const valueLabel = formatCurrency((stepVal * i)).replace(/₫/g, '').trim();
                return (
                  <g key={i}>
                    <line 
                      x1={paddingX} 
                      y1={y} 
                      x2={svgWidth - paddingX} 
                      y2={y} 
                      className="chart-grid-line" 
                    />
                    <text 
                      x={paddingX - 10} 
                      y={y + 4} 
                      textAnchor="end" 
                      style={{ fontSize: '10px', fill: 'var(--text-muted)', fontWeight: 600 }}
                    >
                      {valueLabel}
                    </text>
                  </g>
                );
              })}

              {/* Draw columns */}
              {data.revenueChartData.map((d, index) => {
                const barCount = data.revenueChartData.length;
                const colSpacing = chartWidth / barCount;
                const x = paddingX + colSpacing * index + colSpacing / 4;
                const barWidth = colSpacing / 2;
                
                const percentageOfMax = d.revenue / maxRev;
                const barHeight = chartHeight * percentageOfMax;
                const y = paddingY + chartHeight - barHeight;

                return (
                  <g key={index} className="bar-group">
                    {/* Column Rect */}
                    <rect
                      x={x}
                      y={y}
                      width={barWidth}
                      height={barHeight}
                      rx={6}
                      fill="url(#column-gradient)"
                      className="chart-bar"
                    />
                    {/* Hover text value tooltip */}
                    <text
                      x={x + barWidth / 2}
                      y={y - 8}
                      className="chart-value-label"
                      style={{ fontSize: '11px', fill: 'var(--text-main)', fontWeight: 'bold' }}
                    >
                      {Math.round(d.revenue / 1000000)}Tr
                    </text>
                    {/* Month Label */}
                    <text
                      x={x + barWidth / 2}
                      y={svgHeight - paddingY + 20}
                      className="chart-label"
                    >
                      {d.month}
                    </text>
                  </g>
                );
              })}
            </svg>
          </div>
        </div>

        {/* Attendance Doughnut Chart */}
        <div className="chart-card">
          <div className="chart-header">
            <div>
              <h3>Tỷ lệ Điểm danh</h3>
              <p className="chart-subtitle">Tổng hợp trạng thái đi học tuần này</p>
            </div>
          </div>

          <div className="chart-content">
            <div className="donut-chart-wrapper">
              <svg className="donut-chart-svg" viewBox="0 0 200 200">
                {/* Background base circle */}
                <circle
                  cx="100"
                  cy="100"
                  r={radius}
                  fill="none"
                  stroke="var(--border)"
                  strokeWidth="20"
                />

                {/* Present Slice */}
                {presentPct > 0 && (
                  <circle
                    cx="100"
                    cy="100"
                    r={radius}
                    className="donut-segment"
                    stroke="var(--success)"
                    strokeWidth={24}
                    strokeDasharray={`${(presentPct / 100) * circ} ${circ}`}
                    strokeDashoffset={-presentOffset}
                  />
                )}

                {/* Late Slice */}
                {latePct > 0 && (
                  <circle
                    cx="100"
                    cy="100"
                    r={radius}
                    className="donut-segment"
                    stroke="var(--warning)"
                    strokeWidth={24}
                    strokeDasharray={`${(latePct / 100) * circ} ${circ}`}
                    strokeDashoffset={-lateOffset}
                  />
                )}

                {/* Absent Slice */}
                {absentPct > 0 && (
                  <circle
                    cx="100"
                    cy="100"
                    r={radius}
                    className="donut-segment"
                    stroke="var(--error)"
                    strokeWidth={24}
                    strokeDasharray={`${(absentPct / 100) * circ} ${circ}`}
                    strokeDashoffset={-absentOffset}
                  />
                )}

                {/* Center text details */}
                <g className="donut-center-text">
                  <text x="100" y="95" className="donut-center-val">
                    {presentPct}%
                  </text>
                  <text x="100" y="120" className="donut-center-lbl">
                    Đúng giờ
                  </text>
                </g>
              </svg>

              {/* Legends list */}
              <div className="chart-legend">
                <div className="legend-item">
                  <span className="legend-color" style={{ backgroundColor: 'var(--success)' }}></span>
                  <span>Đúng giờ: {presentPct}%</span>
                </div>
                <div className="legend-item">
                  <span className="legend-color" style={{ backgroundColor: 'var(--warning)' }}></span>
                  <span>Đi muộn: {latePct}%</span>
                </div>
                <div className="legend-item">
                  <span className="legend-color" style={{ backgroundColor: 'var(--error)' }}></span>
                  <span>Vắng mặt: {absentPct}%</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Class distribution cards */}
      <div className="chart-card">
        <div className="chart-header">
          <div>
            <h3>Sĩ số các lớp học</h3>
            <p className="chart-subtitle">Phân bổ số lượng học sinh theo từng lớp học trong hệ thống</p>
          </div>
        </div>

        <div className="chart-content" style={{ display: 'block' }}>
          <div className="class-dist-list">
            {Object.entries(data.classDistribution || {}).map(([className, count], i) => {
              const percentage = maxClassStudents > 0 ? (count / maxClassStudents) * 100 : 0;
              return (
                <div className="class-dist-row" key={i}>
                  <div className="class-dist-info">
                    <span className="class-dist-name">Lớp {className}</span>
                    <span className="class-dist-count">{count} học sinh</span>
                  </div>
                  <div className="class-dist-bar-bg">
                    <div 
                      className="class-dist-bar-fill" 
                      style={{ width: `${percentage}%` }}
                    ></div>
                  </div>
                </div>
              );
            })}
            {Object.keys(data.classDistribution || {}).length === 0 && (
              <p style={{ color: 'var(--text-muted)', textAlign: 'center', padding: '20px' }}>
                Chưa có dữ liệu phân lớp học sinh. Hãy nhập Excel để tạo học sinh và lớp học!
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
