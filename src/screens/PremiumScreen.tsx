import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { Colors } from '../constants/colors';
import { BackButton, CustomAlert } from '../components';

interface PremiumFeature {
  icon: keyof typeof Ionicons.glyphMap;
  title: string;
  description: string;
}

interface PricingPlan {
  id: string;
  name: string;
  duration: string;
  originalPrice: number;
  discountPrice: number;
  discount?: string;
  isPopular?: boolean;
}

const PremiumScreen: React.FC = () => {
  const navigation = useNavigation();
  const [selectedPlan, setSelectedPlan] = useState<string>('monthly');
  const [showSubscribeAlert, setShowSubscribeAlert] = useState(false);
  const [showSuccessAlert, setShowSuccessAlert] = useState(false);
  const [selectedPlanData, setSelectedPlanData] = useState<PricingPlan | null>(null);

  const premiumFeatures: PremiumFeature[] = [
    {
      icon: 'analytics',
      title: 'Phân tích AI thông minh',
      description: 'Insights cá nhân hóa về thói quen chi tiêu và lời khuyên tiết kiệm',
    },
    {
      icon: 'infinite',
      title: 'Ngân sách không giới hạn',
      description: 'Tạo vô số ngân sách cho mọi mục đích và khoảng thời gian',
    },
    {
      icon: 'document-text',
      title: 'Báo cáo xuất Excel/PDF',
      description: 'Xuất báo cáo chi tiết với biểu đồ chuyên nghiệp',
    },
    {
      icon: 'people',
      title: 'Chia sẻ gia đình (5 người)',
      description: 'Quản lý tài chính chung với gia đình và bạn bè',
    },
    {
      icon: 'trending-up',
      title: 'Theo dõi đầu tư chứng khoán',
      description: 'Kết nối tài khoản đầu tư và theo dõi lợi nhuận real-time',
    },
    {
      icon: 'chatbubble-ellipses',
      title: 'Hỗ trợ chat 24/7',
      description: 'Tư vấn trực tiếp với chuyên gia tài chính mọi lúc',
    },
    {
      icon: 'card',
      title: 'Kết nối ngân hàng tự động',
      description: 'Đồng bộ giao dịch từ Vietcombank, Techcombank, BIDV...',
    },
    {
      icon: 'trending-down',
      title: 'Cảnh báo vượt ngân sách',
      description: 'Thông báo thông minh khi sắp vượt mức chi tiêu đã đặt',
    },
  ];

  const pricingPlans: PricingPlan[] = [
    {
      id: 'monthly',
      name: 'Hàng tháng',
      duration: '1 tháng',
      originalPrice: 59000,
      discountPrice: 45000,
      discount: '24% OFF',
      isPopular: true,
    },
    {
      id: 'quarterly',
      name: 'Hàng quý',
      duration: '3 tháng',
      originalPrice: 177000,
      discountPrice: 120000,
      discount: '32% OFF',
    },
    {
      id: 'yearly',
      name: 'Hàng năm',
      duration: '12 tháng',
      originalPrice: 708000,
      discountPrice: 450000,
      discount: '37% OFF',
    },
  ];

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  const handleSubscribe = (planId: string) => {
    const plan = pricingPlans.find(p => p.id === planId);
    if (plan) {
      setSelectedPlanData(plan);
      setShowSubscribeAlert(true);
    }
  };

  const confirmSubscribe = () => {
    setShowSubscribeAlert(false);
    setShowSuccessAlert(true);
  };

  const renderFeatureItem = (feature: PremiumFeature, index: number) => (
    <View key={index} style={styles.featureItem}>
      <View style={styles.featureIcon}>
        <Ionicons name={feature.icon} size={24} color={Colors.primary[500]} />
      </View>
      <View style={styles.featureContent}>
        <Text style={styles.featureTitle}>{feature.title}</Text>
        <Text style={styles.featureDescription}>{feature.description}</Text>
      </View>
      <Ionicons name="checkmark-circle" size={24} color={Colors.primary[500]} />
    </View>
  );

  const renderPricingCard = (plan: PricingPlan) => (
    <TouchableOpacity
      key={plan.id}
      style={[
        styles.pricingCard,
        selectedPlan === plan.id && styles.selectedPricingCard,
        plan.isPopular && styles.popularCard,
      ]}
      onPress={() => setSelectedPlan(plan.id)}
    >
      {plan.isPopular && (
        <View style={styles.popularBadge}>
          <Text style={styles.popularText}>PHỔ BIẾN</Text>
        </View>
      )}

      <Text style={styles.planName}>{plan.name}</Text>
      <Text style={styles.planDuration}>{plan.duration}</Text>

      <View style={styles.priceContainer}>
        <Text style={styles.originalPrice}>{formatCurrency(plan.originalPrice)}</Text>
        <Text style={styles.discountPrice}>{formatCurrency(plan.discountPrice)}</Text>
      </View>

      {plan.discount && (
        <View style={styles.discountBadge}>
          <Text style={styles.discountText}>{plan.discount}</Text>
        </View>
      )}

      <Text style={styles.pricePerMonth}>
        {formatCurrency(
          Math.round(
            plan.discountPrice / (plan.id === 'monthly' ? 1 : plan.id === 'quarterly' ? 3 : 12)
          )
        )}
        /tháng
      </Text>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <BackButton title="Premium" showHomeIcon={true} />
      {/* Header */}
      <LinearGradient
        colors={[Colors.primary[500], '#2E8B57']}
        style={styles.header}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
      >
        <View style={styles.headerContent}>
          <Ionicons name="star" size={32} color="#FFFFFF" />
          <Text style={styles.headerTitle}>ZBudget Premium</Text>
          <Text style={styles.headerSubtitle}>Nâng cấp trải nghiệm quản lý tài chính của bạn</Text>
        </View>
      </LinearGradient>

      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        {/* Features Section */}
        <View style={styles.featuresSection}>
          <Text style={styles.sectionTitle}>Tính năng Premium</Text>
          {premiumFeatures.map(renderFeatureItem)}
        </View>

        {/* Pricing Section */}
        <View style={styles.pricingSection}>
          <Text style={styles.sectionTitle}>Chọn gói đăng ký</Text>
          <View style={styles.pricingGrid}>{pricingPlans.map(renderPricingCard)}</View>
        </View>

        {/* Subscribe Button */}
        <View style={styles.subscribeSection}>
          <TouchableOpacity
            style={styles.subscribeButton}
            onPress={() => handleSubscribe(selectedPlan)}
          >
            <LinearGradient
              colors={[Colors.primary[500], '#2E8B57']}
              style={styles.subscribeGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
            >
              <Text style={styles.subscribeButtonText}>
                Đăng ký ngay -{' '}
                {formatCurrency(pricingPlans.find(p => p.id === selectedPlan)?.discountPrice || 0)}
              </Text>
            </LinearGradient>
          </TouchableOpacity>

          <Text style={styles.subscribeNote}>
            • Hủy bất cứ lúc nào{'\n'}• Dùng thử 7 ngày miễn phí{'\n'}• Đồng bộ trên tất cả thiết bị
          </Text>
        </View>

        <View style={styles.bottomSpacing} />
      </ScrollView>

      {/* Custom Alerts */}
      <CustomAlert
        visible={showSubscribeAlert}
        onClose={() => setShowSubscribeAlert(false)}
        title="Xác nhận đăng ký Premium"
        message={
          selectedPlanData
            ? `Bạn có muốn đăng ký gói ${selectedPlanData.name} với giá ${formatCurrency(selectedPlanData.discountPrice)}?\n\n✨ Dùng thử 7 ngày miễn phí\n💳 Hủy bất cứ lúc nào\n📱 Đồng bộ trên tất cả thiết bị`
            : ''
        }
        type="info"
        buttons={[
          {
            text: 'Hủy',
            onPress: () => setShowSubscribeAlert(false),
            type: 'secondary',
            icon: 'close-outline',
          },
          {
            text: 'Đăng ký ngay',
            onPress: confirmSubscribe,
            type: 'primary',
            icon: 'star-outline',
          },
        ]}
      />

      <CustomAlert
        visible={showSuccessAlert}
        onClose={() => setShowSuccessAlert(false)}
        title="🎉 Chào mừng đến Premium!"
        message="Cảm ơn bạn đã đăng ký Premium! Tất cả tính năng cao cấp đã được kích hoạt cho tài khoản của bạn.\n\nBạn có thể bắt đầu sử dụng các tính năng AI phân tích, báo cáo xuất Excel và nhiều hơn nữa!"
        type="success"
        buttons={[
          {
            text: 'Khám phá ngay',
            onPress: () => {
              setShowSuccessAlert(false);
              navigation.goBack();
            },
            type: 'primary',
            icon: 'rocket-outline',
          },
        ]}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 30,
    alignItems: 'center',
  },
  headerContent: {
    alignItems: 'center',
    marginTop: 20,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginTop: 12,
    marginBottom: 8,
  },
  headerSubtitle: {
    fontSize: 16,
    color: '#FFFFFF',
    opacity: 0.9,
    textAlign: 'center',
  },
  scrollContainer: {
    flex: 1,
  },
  featuresSection: {
    paddingHorizontal: 20,
    paddingVertical: 30,
  },
  sectionTitle: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 20,
    textAlign: 'center',
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  featureIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  featureContent: {
    flex: 1,
  },
  featureTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  featureDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 20,
  },
  pricingSection: {
    paddingHorizontal: 20,
    paddingBottom: 30,
  },
  pricingGrid: {
    gap: 12,
  },
  pricingCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    borderWidth: 2,
    borderColor: 'transparent',
    position: 'relative',
  },
  selectedPricingCard: {
    borderColor: Colors.primary[500],
  },
  popularCard: {
    borderColor: '#FFD700',
  },
  popularBadge: {
    position: 'absolute',
    top: -10,
    right: 20,
    backgroundColor: '#FFD700',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  popularText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#000000',
  },
  planName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  planDuration: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 12,
  },
  priceContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  originalPrice: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.5)',
    textDecorationLine: 'line-through',
    marginRight: 8,
  },
  discountPrice: {
    fontSize: 24,
    fontWeight: 'bold',
    color: Colors.primary[500],
  },
  discountBadge: {
    backgroundColor: '#FF6B6B',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    alignSelf: 'flex-start',
    marginBottom: 8,
  },
  discountText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  pricePerMonth: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  subscribeSection: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  subscribeButton: {
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 16,
  },
  subscribeGradient: {
    paddingVertical: 18,
    alignItems: 'center',
  },
  subscribeButtonText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  subscribeNote: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
    lineHeight: 20,
  },
  bottomSpacing: {
    height: 40,
  },
});

export default PremiumScreen;
