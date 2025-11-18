import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Search, Check, X, Eye } from 'lucide-react';
import api from '../services/api';
import './PaymentsPage.css';

function PaymentsPage() {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedPayment, setSelectedPayment] = useState(null);
  const [filterStatus, setFilterStatus] = useState('all');
  const queryClient = useQueryClient();

  const { data: payments, isLoading } = useQuery({
    queryKey: ['payments'],
    queryFn: async () => {
      const response = await api.get('/admin/payments');
      return response.data?.data?.payments || [];
    },
  });

  const approvePaymentMutation = useMutation({
    mutationFn: async (paymentId) => {
      const response = await api.post(`/admin/payments/${paymentId}/approve`);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['payments']);
      alert('Đã duyệt thanh toán thành công!');
    },
  });

  const rejectPaymentMutation = useMutation({
    mutationFn: async (paymentId) => {
      const response = await api.post(`/admin/payments/${paymentId}/reject`);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['payments']);
      alert('Đã từ chối thanh toán!');
    },
  });

  const filteredPayments = payments?.filter((payment) => {
    const matchesSearch =
      payment.referenceCode.toLowerCase().includes(searchTerm.toLowerCase()) ||
      payment.userId?.email?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus =
      filterStatus === 'all' || payment.status === filterStatus;

    return matchesSearch && matchesStatus;
  });

  if (isLoading) {
    return <div className="loading">Đang tải...</div>;
  }

  return (
    <div className="payments-page">
      <div className="page-header">
        <div className="search-box">
          <Search size={20} />
          <input
            type="text"
            placeholder="Tìm kiếm theo mã thanh toán hoặc email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <select
          className="status-filter"
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
        >
          <option value="all">Tất cả</option>
          <option value="pending">Chờ duyệt</option>
          <option value="completed">Đã duyệt</option>
          <option value="rejected">Đã từ chối</option>
          <option value="cancelled">Đã hủy</option>
        </select>
      </div>

      <div className="payments-table">
        <table>
          <thead>
            <tr>
              <th>Mã thanh toán</th>
              <th>Email</th>
              <th>Gói</th>
              <th>Số tiền</th>
              <th>Trạng thái</th>
              <th>Ngày tạo</th>
              <th>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {filteredPayments?.map((payment) => (
              <tr key={payment._id}>
                <td className="mono">{payment.referenceCode}</td>
                <td>{payment.userId?.email || '-'}</td>
                <td>
                  <span className="plan-badge">
                    {payment.planType === 'monthly' ? 'Tháng' : 'Năm'}
                  </span>
                </td>
                <td>{payment.amount.toLocaleString('vi-VN')} VND</td>
                <td>
                  <span className={`status-badge status-${payment.status}`}>
                    {getStatusText(payment.status)}
                  </span>
                </td>
                <td>{new Date(payment.createdAt).toLocaleString('vi-VN')}</td>
                <td>
                  <div className="action-buttons">
                    <button
                      className="btn-view"
                      onClick={() => setSelectedPayment(payment)}
                      title="Xem chi tiết"
                    >
                      <Eye size={16} />
                    </button>
                    {payment.status === 'pending' && (
                      <>
                        <button
                          className="btn-approve"
                          onClick={() =>
                            approvePaymentMutation.mutate(payment._id)
                          }
                          title="Duyệt"
                        >
                          <Check size={16} />
                        </button>
                        <button
                          className="btn-reject"
                          onClick={() =>
                            rejectPaymentMutation.mutate(payment._id)
                          }
                          title="Từ chối"
                        >
                          <X size={16} />
                        </button>
                      </>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selectedPayment && (
        <PaymentDetailModal
          payment={selectedPayment}
          onClose={() => setSelectedPayment(null)}
          onApprove={() => {
            approvePaymentMutation.mutate(selectedPayment._id);
            setSelectedPayment(null);
          }}
          onReject={() => {
            rejectPaymentMutation.mutate(selectedPayment._id);
            setSelectedPayment(null);
          }}
        />
      )}
    </div>
  );
}

function PaymentDetailModal({ payment, onClose, onApprove, onReject }) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Chi tiết thanh toán</h2>
          <button className="close-button" onClick={onClose}>
            <X size={24} />
          </button>
        </div>

        <div className="modal-body">
          <div className="detail-row">
            <span className="label">Mã thanh toán:</span>
            <span className="value mono">{payment.referenceCode}</span>
          </div>
          <div className="detail-row">
            <span className="label">Email:</span>
            <span className="value">{payment.userId?.email || '-'}</span>
          </div>
          <div className="detail-row">
            <span className="label">Tên:</span>
            <span className="value">{payment.userId?.fullName || '-'}</span>
          </div>
          <div className="detail-row">
            <span className="label">Loại gói:</span>
            <span className="value">
              {payment.planType === 'monthly' ? 'Gói Tháng' : 'Gói Năm'}
            </span>
          </div>
          <div className="detail-row">
            <span className="label">Số tiền:</span>
            <span className="value">
              {payment.amount.toLocaleString('vi-VN')} VND
            </span>
          </div>
          <div className="detail-row">
            <span className="label">Trạng thái:</span>
            <span className={`status-badge status-${payment.status}`}>
              {getStatusText(payment.status)}
            </span>
          </div>
          <div className="detail-row">
            <span className="label">Ngày tạo:</span>
            <span className="value">
              {new Date(payment.createdAt).toLocaleString('vi-VN')}
            </span>
          </div>

          <div className="qr-section">
            <span className="label">Mã QR:</span>
            <img
              src={payment.qrCodeUrl}
              alt="QR Code"
              className="qr-code"
            />
          </div>
        </div>

        {payment.status === 'pending' && (
          <div className="modal-footer">
            <button className="btn-cancel" onClick={onClose}>
              Đóng
            </button>
            <button className="btn-reject-modal" onClick={onReject}>
              <X size={18} />
              Từ chối
            </button>
            <button className="btn-approve-modal" onClick={onApprove}>
              <Check size={18} />
              Duyệt thanh toán
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function getStatusText(status) {
  const statusMap = {
    pending: 'Chờ duyệt',
    completed: 'Đã duyệt',
    rejected: 'Đã từ chối',
    cancelled: 'Đã hủy',
  };
  return statusMap[status] || status;
}

export default PaymentsPage;
