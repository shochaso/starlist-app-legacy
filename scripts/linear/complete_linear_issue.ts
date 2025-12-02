import "dotenv/config";
import { LinearClient } from "@linear/sdk";

type CliParseResult = {
  positional: string[];
  flags: Record<string, string | undefined>;
};

/**
 * Very small CLI parser that understands `--key value` and `--key=value`.
 */
function parseArgs(argv: string[]): CliParseResult {
  const positional: string[] = [];
  const flags: Record<string, string | undefined> = {};

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--")) {
      positional.push(token);
      continue;
    }

    const [rawKey, inlineValue] = token.slice(2).split("=", 2);
    if (!rawKey) {
      continue;
    }

    const key = rawKey.trim();
    if (inlineValue !== undefined) {
      flags[key] = inlineValue;
    } else if (i + 1 < argv.length && !argv[i + 1].startsWith("--")) {
      flags[key] = argv[i + 1];
      i += 1;
    } else {
      flags[key] = "true";
    }
  }

  return { positional, flags };
}

async function resolveIssueId(client: LinearClient, issueIdentifier: string): Promise<string> {
  if (!issueIdentifier) {
    throw new Error("Issue identifier is required (e.g., STA-43)");
  }

  const issue = await client.issue(issueIdentifier);
  if (!issue) {
    throw new Error(`Issue "${issueIdentifier}" not found.`);
  }

  return issue.id;
}

async function getDoneStateId(client: LinearClient, teamId: string): Promise<string> {
  const team = await client.team(teamId);
  if (!team) {
    throw new Error(`Team "${teamId}" not found.`);
  }

  const workflowStates = await team.states();
  const statesNodes = workflowStates.nodes;
  
  // 各状態を解決
  const states = [];
  for (const stateNode of statesNodes) {
    const state = await stateNode;
    states.push(state);
  }
  
  const doneState = states.find((state) => {
    const stateType = state.type;
    const stateName = state.name?.toLowerCase() ?? "";
    return stateType === "completed" || stateName === "done" || stateName === "完了";
  });

  if (!doneState) {
    const availableStates = states.map((s) => `${s.name} (${s.type})`).join(", ");
    throw new Error(`No "Done" state found for team "${teamId}". Available states: ${availableStates}`);
  }

  return doneState.id;
}

async function main() {
  const apiKey = process.env.LINEAR_API_KEY;
  if (!apiKey) {
    throw new Error("Missing LINEAR_API_KEY. Add it to your environment or .env file.");
  }

  const { positional, flags } = parseArgs(process.argv.slice(2));
  const issueIdentifier = (flags.issue ?? positional[0] ?? process.env.LINEAR_ISSUE_ID)?.trim();

  if (!issueIdentifier) {
    throw new Error("Issue identifier is required. Pass it as the first argument or via --issue / LINEAR_ISSUE_ID.");
  }

  const client = new LinearClient({ apiKey });
  const issueId = await resolveIssueId(client, issueIdentifier);
  const issue = await client.issue(issueId);

  if (!issue.team) {
    throw new Error("Issue has no team associated.");
  }

  const team = await issue.team;
  const teamId = team.id;
  const doneStateId = await getDoneStateId(client, teamId);

  const payload = await client.updateIssue(issueId, {
    stateId: doneStateId,
  });

  if (!payload.success) {
    throw new Error("Linear API responded with success=false.");
  }

  const updatedIssue = await client.issue(issueId);
  const identifier = updatedIssue.identifier ?? issueId;
  const issueUrl = updatedIssue.url ?? "(no url)";
  const state = updatedIssue.state ? await updatedIssue.state : null;
  const stateName = state?.name ?? "unknown";

  const logPayload = {
    id: updatedIssue.id,
    identifier,
    title: updatedIssue.title,
    state: stateName,
    url: issueUrl,
  };

  console.log("✅ Linear Issue completed:", identifier, issueUrl);
  console.log(JSON.stringify(logPayload, null, 2));
}

main().catch((error) => {
  console.error("❌ Failed to complete Linear issue.");
  if (error instanceof Error) {
    console.error(error.message);
  } else {
    console.error(error);
  }
  process.exitCode = 1;
});

