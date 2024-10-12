class Config {
  static const String apiURL = "ifscloud.tsunamit.com";

  static const clientId = 'I2S_Client';
  static const redirectUrl = 'org.i2s.erpvisualizer://login-callback';
  static const discoveryUrl =
      'https://ifscloud.tsunamit.com/auth/realms/tsutst/.well-known/openid-configuration';
  static const tokenUrl = 'auth/realms/tsutst/protocol/openid-connect/token';
  static const logoutUrl = 'auth/realms/tsutst/protocol/openid-connect/logout';
  // static String accessToken = '';
  // static String refreshToken = '';
  // static String idToken = '';
  static bool isFirstTime = true;
}