class DashboardBuildInfo {
  static const String dashboardBuildVersion = String.fromEnvironment(
    'OPENSPENT_DASHBOARD_VERSION',
    defaultValue: '0.1.0+1',
  );
  static const String dashboardCompanyName = 'Code Growers s.r.o.';
  static const String dashboardLogoAssetPath = 'web/logo.svg';
}
