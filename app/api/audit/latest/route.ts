import { NextResponse } from "next/server";

const CACHE_HEADERS = { "cache-control": "no-store" };

export async function GET() {
  if (process.env.NEXT_PHASE === "phase-production-build") {
    return NextResponse.json({}, { headers: CACHE_HEADERS });
  }

  const target = new URL("/dashboard/data/latest.json", process.env.NEXT_PUBLIC_BASE_URL || "http://localhost:3000");
  try {
    const res = await fetch(target);
    const data = await res.json().catch(() => ({}));
    return NextResponse.json(data, { headers: CACHE_HEADERS });
  } catch (error) {
    console.warn("Failed to fetch latest audit data", error);
    return NextResponse.json({}, { headers: CACHE_HEADERS });
  }
}
