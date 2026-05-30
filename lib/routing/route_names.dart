abstract final class RouteNames {
  // Auth
  static const welcome = '/';
  static const authChoice = '/auth/choice';
  static const authPhone = '/auth/phone';
  static const authOtp = '/auth/otp';
  static const authEmail = '/auth/email';

  // Onboarding
  static const onboardingIdentity = '/onboarding/identity';
  static const onboardingInterests = '/onboarding/interests';
  static const onboardingNotifications = '/onboarding/notifications';

  // App (shell)
  static const feed = '/feed';
  static const trends = '/trends';
  static const create = '/create';
  static const notifications = '/notifications';
  static const myProfile = '/profile/me';

  // Deep links
  static const content = '/content/:id';
  static const profile = '/profile/:userId';
  static const alert = '/alert/:alertId';

  // Settings
  static const settings = '/settings';
  static const notificationSettings = '/settings/notifications';
  static const accountSettings = '/settings/account';

  // Legal
  static const legal = '/legal';
}
