import { headers } from "next/headers";
import StarSignUpLPRedesign from "./StarSignUpLPRedesign";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default function TeaserPage() {
  headers();
  return <StarSignUpLPRedesign />;
}
