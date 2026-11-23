# RefactorBot API

All routes under `/api/v1/refactor` require the application's Bearer JWT.
Local CodeBERT/GNN detection never automatically sends contract source to an
external LLM. Users request explanations through this reviewed API.

## Review and consent

1. `POST /review` performs local rule-based screening. It does not call the LLM
   or save a conversation. Supply an `AiPayload`:

```json
{
  "operation": "advice",
  "code": "pragma solidity ^0.8.20; contract Example {}",
  "issue_description": "Review the local model finding and explain the evidence",
  "conversation_history": [],
  "language": "en",
  "thread_id": null,
  "context_id": "analysis-session-id:function-name"
}
```

2. Display the returned `payload`, `findings`, `provider` and
   `encrypted_transport` to the user. The model identifier remains in API/audit
   metadata but is not displayed in the web interface. The reviewed payload replaces recognized
   identity data with `[NAME]`, `[CCCD]`, `[EMAIL]`, `[PHONE]` and `[ADDRESS]`. Secrets are
   replaced with `[SECRET]` and block submission. Recognized instruction
   overrides, role spoofing and exfiltration requests also block submission.
   A blocked review returns no `review_token`.

3. Let the user cancel or edit the copy. Edits require another review. Only
   after explicit agreement, send the returned payload unchanged to `/advice`
   or `/conversation`, adding:

```json
{
  "review_token": "<token-returned-by-review>",
  "consent_confirmed": true
}
```

The token lasts five minutes and binds the complete reviewed payload, account,
operation, model and destination. It is consumed once before calling the LLM.
Changed content, expired tokens and reused approvals produce HTTP 409. A new
review is required after a failed external call. Consent is an authenticated
client attestation; this protocol cannot prove that a human clicked a button.

Screening rules are heuristic. They can miss names, credentials and injection
attempts or flag legitimate security discussion. Users must inspect the copy.
Do not automatically replace the uploaded contract with the redacted copy.
The external model has no filesystem, database, shell or deployment tools.
Code/comments and history are passed as untrusted context, separate from the
system policy. Model output is screened before it is saved or returned.

## Advice and conversation

`POST /advice` requires `operation: "advice"` and a nonempty
`issue_description`. It explains the hypothesis without generating a patch.
`POST /conversation` requires `operation: "conversation"`, an owned thread with
a confirmed human finding review, and a history ending with a user message. History roles are limited to `user`
and `assistant`; clients cannot submit a trusted system role.

Both endpoints return `RefactorResponse`:

- `thread_id`: the owned conversation identifier.
- `explanation`, `bot_message`, `suggestions`, `suggested_code`.
- `verification`: `status`, `message`, `compiler`, `warnings` and
  `security_verified: false`.
- `repair_attempts`: bounded automatic patch attempts.
- `finding_review`, `proposal_review`: authenticated, source-bound human decisions,
  initially `null`.
- `disclosure`: `ai_generated: true`, configured `model`, `confidence: null`,
  `confidence_calibrated: false` and a review warning.

`GET /threads?context_id=...` returns the latest conversation for that context
owned by the authenticated account, or `null`. Only reviewed/redacted source
and messages are stored. To continue it, include its `thread_id`, unchanged
`context_id`, saved history and one new user message in the next review.
Changed original source or stale history returns HTTP 409. Updates use a revision check to avoid silently
overwriting concurrent turns. Another account cannot read or continue the
thread.

The browser keeps the approved original source as conversation context rather
than replacing it with a generated patch. Earlier proposals remain in the
reviewed history, so follow-up repairs retain the original compiler pragma.
A failed compilation can populate a follow-up question with its diagnostics;
the user must still review and approve that request before it reaches the LLM.

Do not log source, issue text, messages, model responses, approval tokens or
credentials. LangGraph/model tracing is disabled for these operations because
consent names the model provider, not a third-party tracing service.

## Human confirmation

After inspecting the explanation and numbered source, a qualified reviewer calls
`POST /finding-review` (privacy consent alone does not unlock repair):

```json
{
  "thread_id": "<owned thread>",
  "decision": "confirmed",
  "start_line": 8,
  "end_line": 9,
  "evidence_note": "Caller-controlled state write violates the owner-only requirement.",
  "qualified_reviewer": true
}
```

Decisions are `confirmed`, `rejected` or `manual_review`. Line numbers are inclusive,
one-based and validated against the saved source. The server records account ID,
UTC time and source SHA-256. A rejected/unresolved finding cannot start repair.
Qualifications are **self-attested**: the application has no professional credential
registry or reviewer-role provisioning. The record identifies the authenticated
account and its attestation, not externally verified expertise. Review notes remain
local; only separately previewed/approved AI payloads reach the configured AstralX provider.

After compilation and behavioral tests, `POST /proposal-review` records a final
decision with `thread_id`, `proposal_sha256`, `decision`, `note` and
`qualified_reviewer: true`. Allowed decisions are `accepted_for_manual_application`,
`rejected` and `manual_review`. Acceptance requires a confirmed source-bound finding,
successful compilation and nonempty passing behavioral tests for the exact proposal
and stored test harness. Unsupported compilers, missing dependencies/tests/context,
failures and unresolved findings require further review. No code is applied or deployed.
New proposals, changed finding decisions and reverification clear the prior final decision.

`GET /threads/{thread_id}/report` exports the owned source, history, proposal, current
decisions, verification and test harness. It may contain confidential source: share
it only through the project's approved artifact storage.

## Verification and bounded repair

### In-app IDE

Refactor Assistant opens a resizable workspace containing a locally bundled Monaco
editor, finding/file navigation, an editable diff, compiler diagnostics, tests and
separate assistant/expert-review panes. `Original.sol` is read-only;
`Proposal.sol` and `Tests.sol` are editable copies. Syntax highlighting, keyword
completion, folding and editor search do not imply Solidity semantic verification.
No editor assets or source are fetched from an external editor CDN.

Detection highlights the original code; initial advice only explains it. The IDE
shows the next required step: explain, confirm the finding, then **Generate AI
repair**. This action previews a conversation request containing the confirmed
function, evidence line range and reviewer rationale before explicit sending
consent. Returned code updates `Proposal.sol` and opens `Diff` automatically;
reopening a saved proposal also selects `Diff`. Missing or unchanged AI code is
reported explicitly. The uploaded source stays unchanged, and compiler/tests and
final human review remain separate requirements.

Compiler diagnostics include `severity`, `message`, `source_file`, `start_line`,
`start_column`, `end_line` and `end_column`. Solidity UTF-8 byte offsets are mapped
to one-based line numbers and UTF-16 columns for the editor. `Contract.sol` in
compiler input refers to the baseline or proposal selected for that run; `Tests.sol`
is the test harness. Clicking a located diagnostic opens that file and location.
Unknown locations are displayed without an invented line. Editing files makes
their previous diagnostics/results stale and blocks acceptance.

`POST /compile` accepts `code` and optional `test_source`. It compiles a baseline
or local draft without model calls, thread writes or review changes. It requires
authentication and uses the same isolated compiler/EVM runner as `/validate`.
Its result cannot replace the saved proposal's approval evidence.

`POST /proposal` saves a human-edited repair after finding confirmation:

```json
{
  "thread_id": "<owned thread>",
  "previous_proposal": "<exact saved proposal, or null before the first proposal>",
  "proposed_code": "<edited complete Solidity contract>"
}
```

The server checks ownership, confirmed source evidence, unchanged previous
proposal and a database revision. Stale edits return HTTP 409. Saving records
`proposal_origin: "human_edit"`, clears final approval and resets compiler/test
verification to `not_run`. The uploaded source and chat history are unchanged.
Compile/test actions save an edited proposal before verifying it; tests are stored
with their verification run. Unsaved buffers survive switching findings or closing
the assistant within the current page, and navigation warns about unsaved changes.
The IDE never writes the original project file or deploys a contract.

An AI chat turn previews the approved original and current proposal (or a selected
excerpt) before sending. Local edits are still screened/redacted in that preview.
The complete current proposal or selected code is included in the new user message.
The application does not truncate selections, source, message text or conversation
history, or impose a character/turn limit on LLM context. No editor operation
automatically calls the provider. The provider/model context window, HTTP transport,
server resources and MongoDB document size still apply; a provider rejection is
reported rather than silently shortening the request.

Workspace tests run with `npm test` in `web_react`. The component tests use a
deterministic editor boundary because Monaco needs a real browser layout engine;
they verify draft isolation, save/approval invalidation and diagnostic navigation.

The LangGraph workflow explains evidence first. After human confirmation, chat
can propose a patch and check it.
Only an actual compilation failure with a proposed patch can trigger another
repair. Missing context/tools stop the repair loop and require user input.
There are at most two total proposal/repair passes per approved chat request.
Conversation proposals use the same verifier.

`POST /validate` performs local verification without calling the LLM:

```json
{
  "original_code": "<previous source>",
  "suggested_code": "<complete proposed Solidity contract>",
  "thread_id": "<optional owned conversation identifier>",
  "test_source": "<optional Solidity assertion harness importing Contract.sol>"
}
```

Solidity pragma ranges are matched against the configured compilers 0.4.24,
0.8.0 and 0.8.20 using npm-compatible version constraints. The highest matching
version is selected; all actual pragma directives must match. Commented
pragmas and pragma-like string literals are ignored. When a complete proposal
omits its pragma, the original source's constraints select the compiler, with
an explicit warning and without rewriting the proposal. Missing, invalid or
incompatible constraints return an actionable `not_run` result.

When `thread_id` is supplied, the account must own the conversation and both
source and proposal must still match the stored version. The verification is
saved against that unchanged proposal so reopening the finding shows the new
result. Source code and conversation messages are not changed.

Compilers use preinstalled official `ethereum/solc` images. Compiler containers have
no network, no host-directory mounts, a read-only root filesystem and CPU,
memory, process and time limits. They receive only standard JSON on stdin.
Images are never pulled implicitly during an AI request.

- `passed`: the compiler produced contract artifacts without errors.
- `failed`: compilation returned errors, timed out or returned invalid output.
- `not_run`: no patch, a standalone fragment, unsupported compiler or unavailable
  Docker/image. Identical proposals are not treated as a verified repair.

`verification.tests` is separate from compiler status. Without a test harness its
status is `not_run`. With `test_source`, both files compile to bytecode; deployable
contracts in `Tests.sol` expose public zero-argument `test*()` functions with no
return values. Use `require`/`assert` to check behavior; optional zero-argument
`setUp()` runs before each test. Each case uses a fresh deployment and disposable
local PyEVM state. Constructor arguments, linked libraries, Foundry cheatcodes,
external RPC services and fuzz tests are not supported by this runner. There are
at most 20 tests, 8 million deployment gas, 3 million gas per setup/test transaction
and a 45-second worker timeout. Test code is EVM bytecode, never Python or shell.
No test data is sent to the LLM. Reports bind source and harness with SHA-256.

Compilation success and passing supplied assertions do not establish coverage,
security or behavioral equivalence; Slither is not rerun against the proposal.
Warnings and absence of warnings both require judgment. The application shows the
diff and requires the reviewer's final decision before recording acceptance.

## IDE/CI evidence and reproducible demonstration

`GET /api/v1/sessions/{session_id}/sarif` exports owner-only SARIF 2.1.0 for IDE
SARIF viewers or CI artifact/code-scanning ingestion. Locations come from Solidity's
UTF-8 byte offsets and include inclusive source lines. Legacy results use a unique
exact snippet match; unknown or ambiguous locations are omitted. Contract-level
findings have no invented function line. Scores are uncalibrated, diagnostics are
unconfirmed hypotheses, and an empty report is not a security verdict. Match the
original filename at the CI checkout root (or explicitly remap artifact URIs for
your repository layout) and check the report's source SHA-256 before using locations.

The exported repair report supports a CI gate:

```bash
.venv/bin/python -m src.services.repair_report repair-review.json
```

This exits nonzero without source-bound human decisions, compilation and supplied
passing tests. It checks artifact consistency, not the authenticity of an edited
offline JSON file; CI must retrieve reports through authenticated API access and
protect artifact integrity. It does not certify security.

The deterministic fixtures in `examples/reviewed_repair/` demonstrate the flow:

1. Analyze `Vulnerable.sol`. Treat any model prediction as a hypothesis; if the model
   misses it, inspect the explicit owner-only requirement manually. The fixture's
   actual defect is the unchecked state write in `Vault.set` at lines 8–9.
2. Request an explanation through preview/consent, inspect the source, then have a
   qualified reviewer confirm or reject the hypothesis with those evidence lines.
3. Request a minimal fix through a separately approved chat turn. `Fixed.sol` is a
   deterministic reference proposal, not a claim about what the configured model must output.
4. Paste `Tests.sol` into the local test field. The original compiles but fails
   `testUnauthorizedCannotSet`; the reference repair passes that test and
   `testOwnerCanSet`. Inspect the diff, test coverage and remaining risks before
   recording acceptance for manual application.
5. Repeat with `pragma solidity 0.7.6` or a missing import. Expect `not_run` or a
   compiler failure, tests not passed and acceptance blocked; record manual review.

Automated verification (synthetic reviewer/provider fixtures do not impersonate
real human approval or claim measured detector accuracy):

```bash
.venv/bin/python -m pytest -q
RUN_SOLIDITY_INTEGRATION=1 .venv/bin/python -m pytest -q tests/test_human_repair.py
```

The integration case uses installed `ethereum/solc:0.8.20` and the managed local
EVM dependencies. It runs actual compilation and EVM assertions on the fixtures.

## Model disclosures and transport

Local detection streams include `ai_generated`, `model`,
`confidence_calibrated: false` and a warning. Existing softmax scores are not
calibrated probabilities of correctness and must not determine severity.
A negative classifier result does not establish that a contract is secure.

The active OpenAI-compatible endpoint is `https://token.astralx.com.vn/v1`, with
model `byok/astral-x/claude-haiku-5-5`. Store the supplied credential only in the
server-side `GEMINI_API_KEY1` setting (the existing legacy variable name); it is not
a frontend variable or part of exported review payloads. Reviews show the recipient and encrypted transport; model identifiers are kept
in API/audit metadata and hidden from the web interface. No Qwen-specific `thinking` parameter is sent.

`CHATBOT_MAX_TOKENS` is an output budget, independent of input context. The active
AstralX deployment sets it to `16384` and sends the proxy's supported `max_tokens`
field. A synthetic integration check confirmed a complete answer exceeding 4096
output tokens with this setting. Leaving the setting unset instead uses the
provider's output default, which may truncate complete-contract proposals.
Provider limits still apply. A `finish_reason: length` answer is rejected rather
than saved, compiled or shown as a complete repair. The client does not shorten
input context or use Markdown separators as stop sequences.
Each provider request has a 120-second timeout and at most one SDK retry for
transient failures. Empty/non-text answers and token-limit truncation are
reported explicitly rather than presented as complete advice. Provider
authentication, parameter/context rejection, rate limits and timeouts have
distinct safe error messages; upstream bodies are not exposed or logged.
