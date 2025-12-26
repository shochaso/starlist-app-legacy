import { Suspense } from "react";

import Header from "./Header";
import PackSection from "./PackSection";
import SummarySection from "./SummarySection";
import TimelineSection from "./TimelineSection";

type DataPageShellProps = {
  username: string;
  date: Date;
};

export default function DataPageShell({ username, date }: DataPageShellProps) {
  return (
    <div className="flex flex-col gap-6">
      <Header />
      <SummarySection username={username} />
      <Suspense fallback={<div>Loading pack …</div>}>
        <PackSection username={username} date={date} />
      </Suspense>
      <TimelineSection />
    </div>
  );
}
