import DataPageShell from "./_components/DataPageShell";

type PageProps = {
  params: { username: string };
};

export default function StarDataPage({ params }: PageProps) {
  const { username } = params;
  const currentDate = new Date();
  // future imports
  // import { supabaseStarDataRepository } from "@/lib/star-data/repository/supabaseStarDataRepository";
  // import { buildPackId } from "@/lib/star-data/utils/buildPackId";
  return <DataPageShell username={username} date={currentDate} />;
}
