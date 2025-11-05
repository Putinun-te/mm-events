import { signIn, signUp, signOut, getCurrentUser, fetchAuthSession, confirmSignUp, resendSignUpCode } from 'aws-amplify/auth';
import { ref } from 'vue';

export const useCognitoAuth = () => {
  const isAuthenticated = ref(false);
  const currentUser = ref<any>(null);
  const error = ref('');

  const login = async (username: string, password: string) => {
    try {
      const { isSignedIn, nextStep } = await signIn({ username, password });
      
      if (isSignedIn) {
        const user = await getCurrentUser();
        const session = await fetchAuthSession();
        
        currentUser.value = user;
        isAuthenticated.value = true;
        
        return {
          success: true,
          user,
          token: session.tokens?.idToken?.toString(),
          accessToken: session.tokens?.accessToken?.toString()
        };
      }
      
      return { success: false, nextStep };
    } catch (err: any) {
      error.value = err.message || 'Login failed';
      return { success: false, error: err.message };
    }
  };

  const register = async (username: string, email: string, password: string) => {
    try {
      const { isSignUpComplete, userId, nextStep } = await signUp({
        username,
        password,
        options: {
          userAttributes: {
            email
          }
        }
      });

      return {
        success: true,
        isSignUpComplete,
        userId,
        nextStep,
        message: 'Please check your email for verification code'
      };
    } catch (err: any) {
      error.value = err.message || 'Registration failed';
      return { success: false, error: err.message };
    }
  };

  const confirmSignup = async (username: string, code: string) => {
    try {
      const { isSignUpComplete, nextStep } = await confirmSignUp({
        username,
        confirmationCode: code
      });

      return { success: true, isSignUpComplete, nextStep };
    } catch (err: any) {
      error.value = err.message || 'Confirmation failed';
      return { success: false, error: err.message };
    }
  };

  const resendCode = async (username: string) => {
    try {
      await resendSignUpCode({ username });
      return { success: true, message: 'Verification code resent' };
    } catch (err: any) {
      error.value = err.message || 'Failed to resend code';
      return { success: false, error: err.message };
    }
  };

  const logout = async () => {
    try {
      await signOut();
      isAuthenticated.value = false;
      currentUser.value = null;
      return { success: true };
    } catch (err: any) {
      error.value = err.message || 'Logout failed';
      return { success: false, error: err.message };
    }
  };

  const checkAuth = async () => {
    try {
      const user = await getCurrentUser();
      const session = await fetchAuthSession();
      
      if (user && session) {
        currentUser.value = user;
        isAuthenticated.value = true;
        return { 
          authenticated: true, 
          user,
          token: session.tokens?.idToken?.toString()
        };
      }
      return { authenticated: false };
    } catch {
      isAuthenticated.value = false;
      currentUser.value = null;
      return { authenticated: false };
    }
  };

  return {
    login,
    register,
    confirmSignup,
    resendCode,
    logout,
    checkAuth,
    isAuthenticated,
    currentUser,
    error
  };
};
