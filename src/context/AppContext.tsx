import React, {
  createContext,
  useContext,
  useReducer,
  useEffect,
  useMemo,
  useCallback,
} from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { User, Theme } from '../types';
import StorageService from '../services/StorageService';
import { errorHandler, handleStorageError, ErrorType } from '../utils/errorHandler';

interface AppState {
  user: User | null;
  isAuthenticated: boolean;
  isFirstLaunch: boolean;
  theme: Theme;
  isLoading: boolean;
}

type AppAction =
  | { type: 'SET_USER'; payload: User | null }
  | { type: 'SET_AUTHENTICATED'; payload: boolean }
  | { type: 'SET_FIRST_LAUNCH'; payload: boolean }
  | { type: 'SET_THEME'; payload: Theme }
  | { type: 'SET_LOADING'; payload: boolean };

interface AppContextType {
  state: AppState;
  dispatch: React.Dispatch<AppAction>;
  login: (user: User) => Promise<void>;
  logout: () => Promise<void>;
  completeOnboarding: () => Promise<void>;
  updateTheme: (theme: Theme) => Promise<void>;
  // Data management methods
  dataActions: {
    addExpense: (expense: any) => Promise<void>;
    getExpenses: () => Promise<any[]>;
    updateExpense: (expenseId: string, updates: any) => Promise<void>;
    deleteExpense: (expenseId: string) => Promise<void>;
    addBudget: (budget: any) => Promise<void>;
    getBudgets: () => Promise<any[]>;
    updateBudget: (budgetId: string, updates: any) => Promise<void>;
    deleteBudget: (budgetId: string) => Promise<void>;
    addIncome: (income: any) => Promise<void>;
    getIncomes: () => Promise<any[]>;
    updateIncome: (incomeId: string, updates: any) => Promise<void>;
    deleteIncome: (incomeId: string) => Promise<void>;
    addSavingsGoal: (goal: any) => Promise<void>;
    getSavingsGoals: () => Promise<any[]>;
    updateSavingsGoal: (goalId: string, updates: any) => Promise<void>;
    deleteSavingsGoal: (goalId: string) => Promise<void>;
    getSavingsPrediction: (goalId: string) => Promise<any>;
    getSavingsSuggestions: (goalId: string) => Promise<any[]>;
    getBehavioralInsights: (userId: string) => Promise<any[]>;
    updateSavingsProgress: (goalId: string, amount: number) => Promise<void>;
  };
}

const initialState: AppState = {
  user: null,
  isAuthenticated: false,
  isFirstLaunch: true,
  theme: Theme.SYSTEM,
  isLoading: true,
};

const AppContext = createContext<AppContextType | undefined>(undefined);

const appReducer = (state: AppState, action: AppAction): AppState => {
  switch (action.type) {
    case 'SET_USER':
      return { ...state, user: action.payload };
    case 'SET_AUTHENTICATED':
      return { ...state, isAuthenticated: action.payload };
    case 'SET_FIRST_LAUNCH':
      return { ...state, isFirstLaunch: action.payload };
    case 'SET_THEME':
      return { ...state, theme: action.payload };
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    default:
      return state;
  }
};

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(appReducer, initialState);

  useEffect(() => {
    initializeApp();
  }, []);

  const initializeApp = async () => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });

      // Check if it's first launch
      const hasLaunched = await AsyncStorage.getItem('hasLaunched');
      dispatch({ type: 'SET_FIRST_LAUNCH', payload: !hasLaunched });

      // Check authentication
      const userToken = await AsyncStorage.getItem('userToken');
      const userData = await AsyncStorage.getItem('userData');

      if (userToken && userData) {
        const user = JSON.parse(userData);
        dispatch({ type: 'SET_USER', payload: user });
        dispatch({ type: 'SET_AUTHENTICATED', payload: true });
      }

      // Load theme preference
      const savedTheme = await AsyncStorage.getItem('theme');
      if (savedTheme) {
        dispatch({ type: 'SET_THEME', payload: savedTheme as Theme });
      }
    } catch (error) {
      const appError = errorHandler.createError(
        ErrorType.UNKNOWN,
        'Không thể khởi tạo ứng dụng. Vui lòng thử lại.',
        error as Error
      );
      errorHandler.handleError(appError, 'initializeApp');
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  const login = useCallback(async (user: User) => {
    try {
      await AsyncStorage.setItem('userToken', 'dummy-token');
      await AsyncStorage.setItem('userData', JSON.stringify(user));
      dispatch({ type: 'SET_USER', payload: user });
      dispatch({ type: 'SET_AUTHENTICATED', payload: true });
    } catch (error) {
      const appError = errorHandler.createError(
        ErrorType.AUTHENTICATION,
        'Đăng nhập thất bại. Vui lòng thử lại.',
        error as Error
      );
      errorHandler.handleError(appError, 'login');
      throw appError;
    }
  }, []);

  const logout = useCallback(async () => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });

      // Add a small delay to show logout process
      await new Promise(resolve => setTimeout(resolve, 500));

      await AsyncStorage.removeItem('userToken');
      await AsyncStorage.removeItem('userData');
      dispatch({ type: 'SET_USER', payload: null });
      dispatch({ type: 'SET_AUTHENTICATED', payload: false });
    } catch (error) {
      const appError = errorHandler.createError(
        ErrorType.AUTHENTICATION,
        'Đăng xuất thất bại. Vui lòng thử lại.',
        error as Error
      );
      errorHandler.handleError(appError, 'logout');
      throw appError;
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  }, []);

  const completeOnboarding = useCallback(async () => {
    try {
      await AsyncStorage.setItem('hasLaunched', 'true');
      dispatch({ type: 'SET_FIRST_LAUNCH', payload: false });
    } catch (error) {
      console.error('Error completing onboarding:', error);
      throw error;
    }
  }, []);

  const updateTheme = useCallback(async (theme: Theme) => {
    try {
      await AsyncStorage.setItem('theme', theme);
      dispatch({ type: 'SET_THEME', payload: theme });
    } catch (error) {
      console.error('Error updating theme:', error);
      throw error;
    }
  }, []);

  // Expense management methods with improved error handling
  const addExpense = useCallback(async (expense: any) => {
    try {
      await StorageService.addExpense(expense);
    } catch (error) {
      const appError = errorHandler.createError(
        ErrorType.STORAGE,
        'Không thể thêm chi tiêu. Vui lòng thử lại.',
        error as Error
      );
      errorHandler.handleError(appError, 'addExpense');
      throw appError;
    }
  }, []);

  const getExpenses = useCallback(async () => {
    return await handleStorageError(() => StorageService.getExpenses(), []);
  }, []);

  const updateExpense = useCallback(async (expenseId: string, updates: any) => {
    try {
      await StorageService.updateExpense(expenseId, updates);
    } catch (error) {
      const appError = errorHandler.createError(
        ErrorType.STORAGE,
        'Không thể cập nhật chi tiêu. Vui lòng thử lại.',
        error as Error
      );
      errorHandler.handleError(appError, 'updateExpense');
      throw appError;
    }
  }, []);

  const deleteExpense = useCallback(async (expenseId: string) => {
    try {
      await StorageService.deleteExpense(expenseId);
    } catch (error) {
      const appError = errorHandler.createError(
        ErrorType.STORAGE,
        'Không thể xóa chi tiêu. Vui lòng thử lại.',
        error as Error
      );
      errorHandler.handleError(appError, 'deleteExpense');
      throw appError;
    }
  }, []);

  // Budget management methods
  const addBudget = async (budget: any) => {
    try {
      await StorageService.addBudget(budget);
    } catch (error) {
      console.error('Error adding budget:', error);
      throw error;
    }
  };

  const getBudgets = async () => {
    try {
      return await StorageService.getBudgets();
    } catch (error) {
      console.error('Error getting budgets:', error);
      return [];
    }
  };

  const updateBudget = async (budgetId: string, updates: any) => {
    try {
      await StorageService.updateBudget(budgetId, updates);
    } catch (error) {
      console.error('Error updating budget:', error);
      throw error;
    }
  };

  const deleteBudget = async (budgetId: string) => {
    try {
      await StorageService.deleteBudget(budgetId);
    } catch (error) {
      console.error('Error deleting budget:', error);
      throw error;
    }
  };

  // Income management methods
  const addIncome = async (income: any) => {
    try {
      await StorageService.addIncome(income);
    } catch (error) {
      console.error('Error adding income:', error);
      throw error;
    }
  };

  const getIncomes = async () => {
    try {
      return await StorageService.getIncomes();
    } catch (error) {
      console.error('Error getting incomes:', error);
      return [];
    }
  };

  const updateIncome = async (incomeId: string, updates: any) => {
    try {
      await StorageService.updateIncome(incomeId, updates);
    } catch (error) {
      console.error('Error updating income:', error);
      throw error;
    }
  };

  const deleteIncome = async (incomeId: string) => {
    try {
      await StorageService.deleteIncome(incomeId);
    } catch (error) {
      console.error('Error deleting income:', error);
      throw error;
    }
  };

  // Savings Goals management methods
  const addSavingsGoal = async (goal: any) => {
    try {
      await StorageService.addSavingsGoal(goal);
    } catch (error) {
      console.error('Error adding savings goal:', error);
      throw error;
    }
  };

  const getSavingsGoals = async () => {
    try {
      return await StorageService.getSavingsGoals();
    } catch (error) {
      console.error('Error getting savings goals:', error);
      return [];
    }
  };

  const updateSavingsGoal = async (goalId: string, updates: any) => {
    try {
      await StorageService.updateSavingsGoal(goalId, updates);
    } catch (error) {
      console.error('Error updating savings goal:', error);
      throw error;
    }
  };

  const deleteSavingsGoal = async (goalId: string) => {
    try {
      await StorageService.deleteSavingsGoal(goalId);
    } catch (error) {
      console.error('Error deleting savings goal:', error);
      throw error;
    }
  };

  // AI-powered savings methods
  const getSavingsPrediction = async (goalId: string) => {
    try {
      const predictions = await StorageService.getSavingsPredictions();
      return predictions.find(p => p.goalId === goalId);
    } catch (error) {
      console.error('Error getting savings prediction:', error);
      return null;
    }
  };

  const getSavingsSuggestions = async (goalId: string) => {
    try {
      const suggestions = await StorageService.getSavingsSuggestions();
      return suggestions.filter(s => s.goalId === goalId);
    } catch (error) {
      console.error('Error getting savings suggestions:', error);
      return [];
    }
  };

  const getBehavioralInsights = async (userId: string) => {
    try {
      const insights = await StorageService.getBehavioralInsights();
      return insights.filter(i => i.userId === userId);
    } catch (error) {
      console.error('Error getting behavioral insights:', error);
      return [];
    }
  };

  const updateSavingsProgress = async (goalId: string, amount: number) => {
    try {
      const goals = await StorageService.getSavingsGoals();
      const goal = goals.find(g => g.id === goalId);

      if (goal) {
        const updatedGoal = {
          currentAmount: goal.currentAmount + amount,
          updatedAt: new Date(),
        };

        await StorageService.updateSavingsGoal(goalId, updatedGoal);
      }
    } catch (error) {
      console.error('Error updating savings progress:', error);
      throw error;
    }
  };

  // Memoize data actions to prevent unnecessary re-renders
  const dataActions = useMemo(
    () => ({
      addExpense,
      getExpenses,
      updateExpense,
      deleteExpense,
      addBudget,
      getBudgets,
      updateBudget,
      deleteBudget,
      addIncome,
      getIncomes,
      updateIncome,
      deleteIncome,
      addSavingsGoal,
      getSavingsGoals,
      updateSavingsGoal,
      deleteSavingsGoal,
      getSavingsPrediction,
      getSavingsSuggestions,
      getBehavioralInsights,
      updateSavingsProgress,
    }),
    []
  );

  // Memoize the context value to prevent unnecessary re-renders
  const contextValue = useMemo(
    () => ({
      state,
      dispatch,
      login,
      logout,
      completeOnboarding,
      updateTheme,
      dataActions,
    }),
    [state, dispatch, login, logout, completeOnboarding, updateTheme, dataActions]
  );

  return <AppContext.Provider value={contextValue}>{children}</AppContext.Provider>;
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
