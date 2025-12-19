export type FailoverSource = "primary" | "secondary";

export interface FailoverResult<T> {
  source: FailoverSource;
  value: T;
}

export async function runWithFailover<T>(
  primary: () => Promise<T>,
  secondary?: () => Promise<T>,
): Promise<FailoverResult<T>> {
  try {
    return { source: "primary", value: await primary() };
  } catch (primaryError) {
    if (!secondary) throw primaryError;
    const value = await secondary();
    return { source: "secondary", value };
  }
}



