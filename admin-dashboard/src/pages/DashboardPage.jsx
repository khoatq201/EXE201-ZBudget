import { useQuery } from '@tanstack/react-query';
import { Users, CreditCard, TrendingUp, DollarSign } from 'lucide-react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts';
import api from '../services/api';
import './DashboardPage.css';

function DashboardPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const response = await api.get('/admin/stats');
      return response.data;
    },
  });

  if (isLoading) {
    return <div className="loading">Đang tải...</div>;
  }

  const statCards = [
    {
      title: 'Tổng Users',
      value: stats?.totalUsers || 0,
      icon: Users,
      color: '#667eea',
      bgColor: '#e6e9ff',
    },
    {
      title: 'Premium Users',
      value: stats?.premiumUsers || 0,
      icon: TrendingUp,
      color: '#f59e0b',
      bgColor: '#fef3c7',
    },
    {
      title: 'Thanh toán chờ duyệt',
      value: stats?.pendingPayments || 0,
      icon: CreditCard,
      color: '#10b981',
      bgColor: '#d1fae5',
    },
    {
      title: 'Doanh thu tháng',
      value: `${((stats?.monthlyRevenue || 0) / 1000).toFixed(0)}k VND`,
      icon: DollarSign,
      color: '#8b5cf6',
      bgColor: '#ede9fe',
    },
  ];

  return (
    <div className="dashboard-page">
      <div className="stats-grid">
        {statCards.map((card) => (
          <div key={card.title} className="stat-card">
            <div
              className="stat-icon"
              style={{ background: card.bgColor, color: card.color }}
            >
              <card.icon size={24} />
            </div>
            <div className="stat-content">
              <div className="stat-title">{card.title}</div>
              <div className="stat-value">{card.value}</div>
            </div>
          </div>
        ))}
      </div>

      <div className="dashboard-content">
        <div className="charts-grid">
          <div className="chart-card">
            <h3>Phân bổ Users</h3>
            <UserDistributionChart stats={stats} />
          </div>

          <div className="chart-card">
            <h3>Thống kê Thanh toán</h3>
            <PaymentStatsChart stats={stats} />
          </div>
        </div>

        <div className="section">
          <h2>Hoạt động gần đây</h2>
          <RecentActivity />
        </div>
      </div>
    </div>
  );
}

function UserDistributionChart({ stats }) {
  const data = [
    { name: 'Free Users', value: stats?.freeUsers || 0, color: '#94a3b8' },
    { name: 'Premium Users', value: stats?.premiumUsers || 0, color: '#f59e0b' },
  ];

  return (
    <ResponsiveContainer width="100%" height={250}>
      <PieChart>
        <Pie
          data={data}
          cx="50%"
          cy="50%"
          labelLine={false}
          label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
          outerRadius={80}
          fill="#8884d8"
          dataKey="value"
        >
          {data.map((entry, index) => (
            <Cell key={`cell-${index}`} fill={entry.color} />
          ))}
        </Pie>
        <Tooltip />
      </PieChart>
    </ResponsiveContainer>
  );
}

function PaymentStatsChart({ stats }) {
  const paymentData = stats?.payments || {};

  const data = [
    { name: 'Chờ duyệt', value: paymentData.pending || 0, color: '#f59e0b' },
    { name: 'Đã duyệt', value: paymentData.completed || 0, color: '#10b981' },
    { name: 'Đã từ chối', value: paymentData.rejected || 0, color: '#ef4444' },
    { name: 'Đã hủy', value: paymentData.cancelled || 0, color: '#6b7280' },
  ];

  return (
    <ResponsiveContainer width="100%" height={250}>
      <BarChart data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="name" />
        <YAxis />
        <Tooltip />
        <Bar dataKey="value" fill="#8884d8">
          {data.map((entry, index) => (
            <Cell key={`cell-${index}`} fill={entry.color} />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}

function RecentActivity() {
  const { data: response, isLoading } = useQuery({
    queryKey: ['recent-activity'],
    queryFn: async () => {
      const response = await api.get('/admin/recent-activity');
      return response.data;
    },
  });

  if (isLoading) {
    return <div className="loading-small">Đang tải...</div>;
  }

  const activity = response?.data || [];

  if (!activity || activity.length === 0) {
    return <div className="empty-state">Chưa có hoạt động nào</div>;
  }

  return (
    <div className="activity-list">
      {activity.map((item, index) => (
        <div key={index} className="activity-item">
          <div className="activity-icon">
            {item.type === 'payment' && <CreditCard size={18} />}
            {item.type === 'user' && <Users size={18} />}
          </div>
          <div className="activity-content">
            <div className="activity-text">{item.message}</div>
            <div className="activity-time">{item.time}</div>
          </div>
        </div>
      ))}
    </div>
  );
}

export default DashboardPage;
