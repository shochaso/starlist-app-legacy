import { headers } from "next/headers";
import StarSignUpLPRedesign from "./teaser/StarSignUpLPRedesign";

export const dynamic = "force-dynamic";
export const revalidate = 0;
export const fetchCache = "force-no-store";

export default function Page() {
  headers();
  return <StarSignUpLPRedesign />;
}
