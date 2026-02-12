enum CareAction {
  toilet,
  posture,
  check,
  transfer,
  hydration,
  other,
}

extension CareActionWire on CareAction {
  String get wireAction {
    switch (this) {
      case CareAction.toilet:
        return 'CARE_TOILET';
      case CareAction.posture:
        return 'CARE_POSTURE';
      case CareAction.check:
        return 'CARE_CHECK';
      case CareAction.transfer:
        return 'CARE_TRANSFER';
      case CareAction.hydration:
        return 'CARE_HYDRATION';
      case CareAction.other:
        return 'CARE_OTHER';
    }
  }
}
