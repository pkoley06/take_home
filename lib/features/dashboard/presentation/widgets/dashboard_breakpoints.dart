int dashboardColumnsForWidth(double width) {
  if (width >= 1000) return 3;
  if (width >= 600) return 2;
  return 1;
}
