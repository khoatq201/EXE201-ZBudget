import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Search, Crown, X } from 'lucide-react';
import api from '../services/api';
import './UsersPage.css';

function UsersPage() {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const queryClient = useQueryClient();

  const { data: users, isLoading } = useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const response = await api.get('/admin/users');
      return response.data?.data?.users || [];
    },
  });

  const activatePremiumMutation = useMutation({
    mutationFn: async ({ userId, planType }) => {
      const response = await api.post(`/admin/users/${userId}/activate-premium`, {
        duration: planType,
      });
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
      setSelectedUser(null);
      alert('Đã kích hoạt Premium thành công!');
    },
    onError: (error) => {
      alert(error.response?.data?.message || 'Lỗi khi kích hoạt Premium');
    },
  });

  const filteredUsers = users?.filter(
    (user) =>
      user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.profile?.name?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (isLoading) {
    return <div className="loading">Đang tải...</div>;
  }

  return (
    <div className="users-page">
      <div className="page-header">
        <div className="search-box">
          <Search size={20} />
          <input
            type="text"
            placeholder="Tìm kiếm theo email hoặc tên..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <div className="users-table">
        <table>
          <thead>
            <tr>
              <th>Email</th>
              <th>Tên</th>
              <th>Trạng thái</th>
              <th>Ngày tạo</th>
              <th>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers?.map((user) => (
              <tr key={user._id}>
                <td>{user.email}</td>
                <td>{user.profile?.name || '-'}</td>
                <td>
                  {user.subscription?.tier === 'premium' ? (
                    <span className="badge badge-premium">
                      <Crown size={14} />
                      Premium
                    </span>
                  ) : (
                    <span className="badge badge-free">Free</span>
                  )}
                </td>
                <td>{new Date(user.createdAt).toLocaleDateString('vi-VN')}</td>
                <td>
                  {user.subscription?.tier !== 'premium' && (
                    <button
                      className="btn-activate"
                      onClick={() => setSelectedUser(user)}
                    >
                      Kích hoạt Premium
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selectedUser && (
        <ActivatePremiumModal
          user={selectedUser}
          onClose={() => setSelectedUser(null)}
          onActivate={activatePremiumMutation.mutate}
          isLoading={activatePremiumMutation.isPending}
        />
      )}
    </div>
  );
}

function ActivatePremiumModal({ user, onClose, onActivate, isLoading }) {
  const [planType, setPlanType] = useState('monthly');

  const handleActivate = () => {
    onActivate({ userId: user._id, planType });
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Kích hoạt Premium</h2>
          <button className="close-button" onClick={onClose}>
            <X size={24} />
          </button>
        </div>

        <div className="modal-body">
          <div className="user-info-box">
            <div className="label">User:</div>
            <div className="value">{user.email}</div>
          </div>

          <div className="form-group">
            <label>Chọn gói:</label>
            <select value={planType} onChange={(e) => setPlanType(e.target.value)}>
              <option value="monthly">Gói Tháng (30 ngày)</option>
              <option value="yearly">Gói Năm (365 ngày)</option>
            </select>
          </div>
        </div>

        <div className="modal-footer">
          <button className="btn-cancel" onClick={onClose} disabled={isLoading}>
            Hủy
          </button>
          <button
            className="btn-confirm"
            onClick={handleActivate}
            disabled={isLoading}
          >
            {isLoading ? 'Đang xử lý...' : 'Kích hoạt'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default UsersPage;
