import React from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import Svg, { Path, G, Text as SvgText, Circle } from 'react-native-svg';

import { Colors } from '../constants/colors';
import { Typography } from '../constants/typography';
import { Spacing } from '../constants/spacing';

interface PieChartData {
  value: number;
  color: string;
  label: string;
  percentage: number;
}

interface PieChartProps {
  data: PieChartData[];
  size?: number;
  strokeWidth?: number;
  showLabels?: boolean;
  centerText?: {
    title: string;
    value: string;
  };
}

const PieChart: React.FC<PieChartProps> = ({
  data,
  size = 200,
  strokeWidth = 30,
  showLabels = true,
  centerText,
}) => {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const center = size / 2;

  // Tính toán angles cho từng segment
  let currentAngle = 0;
  const segments = data.map(item => {
    const angle = (item.percentage / 100) * 360;
    const startAngle = currentAngle;
    const endAngle = currentAngle + angle;
    currentAngle = endAngle;

    // Tạo path cho SVG arc
    const x1 = center + radius * Math.cos((startAngle * Math.PI) / 180);
    const y1 = center + radius * Math.sin((startAngle * Math.PI) / 180);
    const x2 = center + radius * Math.cos((endAngle * Math.PI) / 180);
    const y2 = center + radius * Math.sin((endAngle * Math.PI) / 180);

    const largeArcFlag = angle > 180 ? 1 : 0;

    const path = `M ${center} ${center} L ${x1} ${y1} A ${radius} ${radius} 0 ${largeArcFlag} 1 ${x2} ${y2} Z`;

    // Vị trí label
    const labelAngle = (startAngle + endAngle) / 2;
    const labelRadius = radius + strokeWidth / 2 + 20;
    const labelX = center + labelRadius * Math.cos((labelAngle * Math.PI) / 180);
    const labelY = center + labelRadius * Math.sin((labelAngle * Math.PI) / 180);

    return {
      ...item,
      path,
      labelX,
      labelY,
      startAngle,
      endAngle,
      angle,
    };
  });

  return (
    <View style={styles.container}>
      <Svg width={size + 80} height={size + 80}>
        <G x={40} y={40}>
          {/* Vẽ các segments */}
          {segments.map((segment, index) => (
            <Path
              key={index}
              d={segment.path}
              fill={segment.color}
              stroke={Colors.background.dark}
              strokeWidth={2}
            />
          ))}

          {/* Vẽ center circle để tạo donut effect */}
          <Circle
            cx={center}
            cy={center}
            r={radius - strokeWidth / 2}
            fill={Colors.background.dark}
          />

          {/* Center text */}
          {centerText && (
            <G>
              <SvgText
                x={center}
                y={center - 8}
                textAnchor="middle"
                fontSize="14"
                fill={Colors.text.inverse}
                fontWeight="400"
                fontFamily="System"
              >
                {centerText.title}
              </SvgText>
              <SvgText
                x={center}
                y={center + 12}
                textAnchor="middle"
                fontSize="18"
                fill={Colors.text.inverse}
                fontWeight="bold"
                fontFamily="System"
              >
                {centerText.value}
              </SvgText>
            </G>
          )}

          {/* Labels */}
          {showLabels &&
            segments.map((segment, index) => {
              if (segment.percentage < 5) return null; // Không hiển thị label cho segment nhỏ

              return (
                <G key={`label-${index}`}>
                  {/* Đường kẻ từ segment đến label */}
                  <Path
                    d={`M ${center + (radius - 10) * Math.cos((((segment.startAngle + segment.endAngle) / 2) * Math.PI) / 180)} ${center + (radius - 10) * Math.sin((((segment.startAngle + segment.endAngle) / 2) * Math.PI) / 180)} L ${segment.labelX - 40} ${segment.labelY - 40}`}
                    stroke={Colors.text.tertiary}
                    strokeWidth={1}
                    strokeDasharray="3,3"
                  />

                  {/* Label text */}
                  <SvgText
                    x={segment.labelX - 40}
                    y={segment.labelY - 35}
                    textAnchor="middle"
                    fontSize="10"
                    fill={Colors.text.inverse}
                    fontWeight="600"
                  >
                    {segment.percentage}%
                  </SvgText>
                </G>
              );
            })}
        </G>
      </Svg>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
  },
});

export default PieChart;
