import { createSupabaseStarDataRepository } from "@/lib/star-data/repository/supabaseStarDataRepository.node";

type SummarySectionProps = {
  username: string;
};

export default async function SummarySection({ username }: SummarySectionProps) {
  const repository = createSupabaseStarDataRepository();
  try {
    const summary = await repository.fetchSummary(username);
    const latest = summary.latestCategories.length
      ? summary.latestCategories.join(", ")
      : "None";

    return (
      <section>
        <div>Daily: {summary.dailyCount}</div>
        <div>Weekly: {summary.weeklyCount}</div>
        <div>Monthly: {summary.monthlyCount}</div>
        <div>Latest: {latest}</div>
      </section>
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return (
      <section>
        <p>Failed to load summary.</p>
        <p>{message}</p>
      </section>
    );
  }
}
