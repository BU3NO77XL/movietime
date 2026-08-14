export function getAgeRatingColor(rating?: string | null): string {
  const raw = rating?.replace(/[^\d]/g, '') || '';
  const num = parseInt(raw, 10);
  if (raw === '' || isNaN(num)) return '#46D369';
  if (num <= 10) return '#E6B616';
  if (num <= 12) return '#E87D2F';
  if (num <= 14) return '#E05A30';
  if (num <= 16) return '#D7262D';
  return '#A0131A';
}
