import { Amplify } from 'aws-amplify';

export default defineNuxtPlugin(() => {
  Amplify.configure({
    Auth: {
      Cognito: {
        userPoolId: 'us-east-1_nTZpyinXc',
        userPoolClientId: '5fpck32uhi8m87b5tkirvaf0iu',
        loginWith: {
          email: true,
          username: true
        },
        signUpVerificationMethod: 'code',
        userAttributes: {
          email: {
            required: true
          }
        },
        passwordFormat: {
          minLength: 8,
          requireLowercase: true,
          requireUppercase: true,
          requireNumbers: true,
          requireSpecialCharacters: false
        }
      }
    }
  });
});
