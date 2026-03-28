/// Metadata for a shared home-screen widget (Firestore + Storage).
///
/// Extend with fields like [senderId], [imageUrl], [text], [createdAt], etc.
class WidgetPayload {
  const WidgetPayload({
    required this.id,
  });

  final String id;
}
