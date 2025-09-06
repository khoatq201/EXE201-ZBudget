export const Colors = {
  // Primary Colors from design system
  primary: {
    50: '#E8F5E8',
    100: '#C6E6C6',
    200: '#A0D6A0',
    300: '#7AC67A',
    400: '#5CB85C',
    500: '#3DA13D', // Main primary (Bangladesh Green)
    600: '#378537',
    700: '#2F6A2F',
    800: '#275027',
    900: '#1A351A',
  },

  // Secondary Colors
  secondary: {
    50: '#E8F8F8',
    100: '#C6EEEE',
    200: '#A0E3E3',
    300: '#7AD8D8',
    400: '#5ECFCF',
    500: '#42C5C5', // Mountain Meadow
    600: '#3CB8B8',
    700: '#34A6A6',
    800: '#2D9494',
    900: '#1F7474',
  },

  // Caribbean Green
  accent: {
    50: '#E8FBF8',
    100: '#C6F4EE',
    200: '#A0ECE3',
    300: '#7AE4D8',
    400: '#5EDECF',
    500: '#42D8C5', // Caribbean Green
    600: '#3CC5B3',
    700: '#34B09E',
    800: '#2D9B89',
    900: '#1F7A65',
  },

  // Dark colors
  dark: {
    50: '#F5F5F5',
    100: '#E0E0E0',
    200: '#BDBDBD',
    300: '#9E9E9E',
    400: '#757575',
    500: '#616161', // Rich Black
    600: '#424242',
    700: '#303030',
    800: '#212121',
    900: '#1C1C1C',
  },

  // Background colors
  background: {
    primary: '#FFFFFF',
    secondary: '#F5F5F5',
    tertiary: '#E8F5E8',
    dark: '#1C1C1C',
    darkSecondary: '#2A2A2A',
  },

  // Text colors
  text: {
    primary: '#1C1C1C',
    secondary: '#616161',
    tertiary: '#9E9E9E',
    inverse: '#FFFFFF',
    success: '#3DA13D',
    warning: '#FFA726',
    error: '#F44336',
  },

  // System colors
  success: '#3DA13D',
  warning: '#FFA726',
  error: '#F44336',
  info: '#42C5C5',

  // Vietnamese currency colors
  vnd: {
    positive: '#3DA13D',
    negative: '#F44336',
    neutral: '#616161',
  },

  // Gradient colors
  gradients: {
    primary: ['#3DA13D', '#42C5C5'] as const,
    secondary: ['#42C5C5', '#42D8C5'] as const,
    accent: ['#42D8C5', '#7AE4D8'] as const,
    dark: ['#1C1C1C', '#303030'] as const,
  },
};

export const ThemeColors = {
  light: {
    primary: Colors.primary[500],
    secondary: Colors.secondary[500],
    accent: Colors.accent[500],
    background: Colors.background.primary,
    surface: Colors.background.secondary,
    text: Colors.text.primary,
    textSecondary: Colors.text.secondary,
    border: Colors.dark[200],
    success: Colors.success,
    warning: Colors.warning,
    error: Colors.error,
  },
  dark: {
    primary: Colors.primary[400],
    secondary: Colors.secondary[400],
    accent: Colors.accent[400],
    background: Colors.background.dark,
    surface: Colors.background.darkSecondary,
    text: Colors.text.inverse,
    textSecondary: Colors.dark[300],
    border: Colors.dark[700],
    success: Colors.success,
    warning: Colors.warning,
    error: Colors.error,
  },
};
