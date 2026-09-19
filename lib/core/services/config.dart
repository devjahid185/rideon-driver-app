class Config {
  static const googleKey = "AIzaSyCm-rRAsfqyVZuth4dXJQ11cU24rV-5Zzw";
  static const String oneSiginalAppid = 'YOUR_ONESIGNAL_APP_ID_HERE';
  static const String oneSiginalApiKey = 'YOUR_ONESIGNAL_API_KEY_HERE';
  static const String riderAppOneSiginalAppid =
      'YOUR_RIDER_APP_ONESIGNAL_APP_ID_HERE';
  static const String riderAppOneSiginalApiKey =
      'YOUR_RIDER_APP_ONESIGNAL_API_KEY_HERE';

  // Temporary base domain URL for setup (please add your final URL here)
  static const String baseDomain = 'https://admin.wgnmove.com';

  // static const String baseDomain = 'https://innovittree.in';
  // Do not change any code below this line. ==================================================

  static const String version = '/api/v1/';
  static const String bearerVersion = '/api/';
  static const String baseUrl = '$baseDomain$version';
  static const String baseUrlForBearer = '$baseDomain$bearerVersion';
  static const String secretKey = '49382716504938271650493827165049';
  static const String registerUser = 'userRegister';
  static const String socialLogin = 'socialLogin';
  static const String sendMobileLoginOtp = 'sendMobileLoginOtp';
  static const String userMobileLogin = 'userMobileLogin';
  static const String editProfile = 'editProfile';
  static const String deleteAccount = 'deleteAccount';
  static const String getAllCategories = 'getAllCategories';
  static const String fcmUpdate = 'fcmUpdate';
  static const String getMakes = 'getMakes';
  static const String addEditVerificationDocuments =
      'addEditVerificationDocuments';
  static const String getVendorWallet = 'getVendorWallet';
  static const String getVendorWalletTransactions =
      'getVendorWalletTransactions';
  static const String getPayoutTransactions = 'getPayoutTransactions';
  static const String getTotalPayoutAmount = 'getTotalPayoutAmount';
  static const String insertPayout = 'insertPayout';
  static const String getVerificationDocuments = 'getVerificationDocuments';
  static const String myItems = 'myItems';
  static const String editItem = 'editItem';
  static const String addEditItemImages = 'addEditItemImages';
  static const String generateToken = 'generateToken';
  static const String verifyResetToken = 'verifyResetToken';
  static const String userEmailLogin = 'userEmailLogin';
  static const String forgotPassword = 'forgotPassword';
  static const String resetPassword = 'resetPassword';
  static const String userLogin = 'userLogin';
  static const String userLogout = 'userLogout';
  static const String otpVerification = 'otpVerification';
  static const String resendOtp = 'ResendOtp';
  static const String resendToken = 'ResendToken';
  static const String resendTokenEmailChange = 'ResendTokenEmailChange';
  static const String checkMobileNumber = 'checkMobileNumber';
  static const String checkEmail = 'checkEmail';
  static const String changeEmail = 'changeEmail';
  static const String confirmBookingByHost = 'confirmBookingByHost';
  static const String uploadProfileImage = 'uploadProfileImage';
  static const String vendorbookingRecord = 'vendorbookingRecord';
  static const String updateBookingStatusByDriver =
      'updateBookingStatusByDriver';
  static const String rideAudioRecording = 'ride-audio-recordings';
  static const String changeMobileNumber = 'changeMobileNumber';
  static const String updatePaymentStatusByDriver =
      'updatePaymentStatusByDriver';
  static const String giveReviewByHost = 'giveReviewByHost';
  static const String getDriverEarings = 'getDriverEarings';
  static const String getDriverDashboardStats = 'getDriverDashboardStats';
  static const String getgeneralSettings = 'getgeneralSettings';
  static const String staticPage = 'StaticPage';
  static const String getPayoutType = 'get-payout-types';
  static const String getPayoutMethod = 'get-payout-methods';
  static const String addPaymentMethod = 'update-payout-method';
  static const String sos = 'sos';

  // Food delivery endpoints
  static const String foodAvailableOrders = 'food/orders/available';
  static const String foodMyOrders = 'food/orders/my';
  static const String foodAcceptOrder = 'food/order';
  static const String foodUpdateOrderStatus = 'food/order';
  static const String foodOrderTimeline = 'food/order';
  static const String foodOrderTracking = 'food/order';
}
