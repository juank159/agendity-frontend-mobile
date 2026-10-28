/// Cliente del ranking por gasto neto (`GET /payments/stats/top-clients`).
class TopClientEntity {
  final String clientId;
  final String clientName;
  final int visitCount;
  final double totalSpent;

  const TopClientEntity({
    required this.clientId,
    required this.clientName,
    required this.visitCount,
    required this.totalSpent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopClientEntity &&
          other.clientId == clientId &&
          other.clientName == clientName &&
          other.visitCount == visitCount &&
          other.totalSpent == totalSpent;

  @override
  int get hashCode => Object.hash(clientId, clientName, visitCount, totalSpent);
}
